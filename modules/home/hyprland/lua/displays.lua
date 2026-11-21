local settings = require("chena.settings")
local config = settings.displays

local displays = {}

-- The saved rules for the monitors connected now, by output name.
local current = {}

function displays.rule_for(output)
    return current[output]
end

if not config then
    return displays
end

-- The lid turns the built-in screen on and off, so its state is never saved.
local panel = settings.clamshell and settings.clamshell.output

local function serialize(value, indent)
    if type(value) == "string" then
        return string.format("%q", value)
    elseif type(value) == "number" then
        return string.format("%.17g", value)
    elseif type(value) == "boolean" then
        return tostring(value)
    end

    local keys = {}
    for key in pairs(value) do
        table.insert(keys, key)
    end
    table.sort(keys)

    local inner = indent .. "    "
    local lines = { "{" }
    for _, key in ipairs(keys) do
        table.insert(lines, string.format("%s[%q] = %s,", inner, key, serialize(value[key], inner)))
    end
    table.insert(lines, indent .. "}")
    return table.concat(lines, "\n")
end

local function read()
    local file = io.open(config.state, "r")
    if not file then
        return {}
    end
    file:close()

    local chunk, err = loadfile(config.state, "t", {})
    if not chunk then
        error("chena displays: cannot read " .. config.state .. ": " .. err)
    end
    return chunk()
end

local function write(layouts)
    local temporary = config.state .. ".new"
    local file = assert(io.open(temporary, "w"))
    file:write("return ", serialize(layouts, ""), "\n")
    file:close()
    assert(os.rename(temporary, config.state))
end

-- Layouts by set of monitors, then by monitor.
local layouts = read()

-- The set whose layout was applied last.
local appliedSet

-- A monitor is known by its make, model and serial number, so the layout
-- follows it to another port. Two of the same model are told apart by port.
local function identities(monitors)
    local count = {}
    for _, monitor in ipairs(monitors) do
        count[monitor.description] = (count[monitor.description] or 0) + 1
    end

    local ids = {}
    for _, monitor in ipairs(monitors) do
        if count[monitor.description] > 1 then
            ids[monitor] = monitor.description .. " on " .. monitor.name
        else
            ids[monitor] = monitor.description
        end
    end
    return ids
end

local function setOf(ids)
    local list = {}
    for _, id in pairs(ids) do
        table.insert(list, id)
    end
    table.sort(list)
    return table.concat(list, "\n")
end

local function entryOf(monitor)
    if not monitor.enabled then
        return { disabled = true }
    end
    return {
        mode = string.format("%dx%d@%.3f", monitor.width, monitor.height, monitor.refresh_rate),
        position = string.format("%dx%d", monitor.x, monitor.y),
        scale = monitor.scale,
        transform = monitor.transform,
        disabled = false,
    }
end

local function rulesFor(layout, monitors, ids)
    local rules = {}
    for _, monitor in ipairs(monitors) do
        local entry = layout[ids[monitor]]
        if entry then
            local rule = { output = monitor.name }
            for key, value in pairs(entry) do
                rule[key] = value
            end
            rules[monitor.name] = rule
        end
    end
    return rules
end

local function turnedOffByLid(monitor)
    return monitor.name == panel and not monitor.enabled
end

local function apply()
    local monitors = hl.get_monitors({ all = true })
    local ids = identities(monitors)
    appliedSet = setOf(ids)
    current = rulesFor(layouts[appliedSet] or {}, monitors, ids)

    for _, monitor in ipairs(monitors) do
        local rule = current[monitor.name]
        if rule and not turnedOffByLid(monitor) then
            hl.monitor(rule)
        end
    end
end

local function save()
    local monitors = hl.get_monitors({ all = true })
    local ids = identities(monitors)
    local set = setOf(ids)

    -- A monitor that was just plugged in or out shows up here before the
    -- event for it, with a layout that is not the one to keep.
    if set ~= appliedSet then
        return
    end

    local layout = layouts[set] or {}
    for _, monitor in ipairs(monitors) do
        if not turnedOffByLid(monitor) then
            layout[ids[monitor]] = entryOf(monitor)
        end
    end
    layouts[set] = layout
    write(layouts)
    current = rulesFor(layout, monitors, ids)
end

hl.window_rule({
    name  = "float-displays",
    match = { class = "^network\\.cycles\\.wdisplays$" },

    float  = true,
    center = true,
})

-- A reload applies the Nix rules again, and at login the monitors are not up
-- yet while this file loads.
apply()
hl.on("hyprland.start", apply)
hl.on("monitor.added", apply)
hl.on("monitor.removed", apply)
hl.on("monitor.layout_changed", save)

return displays
