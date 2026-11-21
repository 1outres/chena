local settings = dofile(arg[1])
local script = arg[2]

local function expect(actual, expected, what)
    if actual ~= expected then
        error(string.format("%s: expected %s, got %s", what, tostring(expected), tostring(actual)), 2)
    end
end

expect(settings.displays.state, "/home/test/.local/state/chena/displays.lua", "state file")

-- Each test case starts from a state file that does not exist yet.
local function freshState()
    local path = os.tmpname()
    os.remove(path)
    settings.displays.state = path
end

local function monitor(name, description, fields)
    local m = {
        name = name,
        description = description,
        enabled = true,
        width = 1920,
        height = 1080,
        refresh_rate = 60,
        x = 0,
        y = 0,
        scale = 1,
        transform = 0,
    }
    for key, value in pairs(fields or {}) do
        m[key] = value
    end
    return m
end

local function panel()
    return monitor("eDP-1", "Apple Computer Inc Apple Panel 4e5a6d92", {
        width = 3024,
        height = 1890,
        refresh_rate = 120,
        scale = 2,
    })
end

local function dell()
    return monitor("DP-1", "Dell Inc. DELL U2720QM CGV4Q83", {
        width = 3840,
        height = 2160,
        refresh_rate = 59.997001647949219,
        x = 1512,
        scale = 1.5,
    })
end

local function docked()
    return { panel(), dell() }
end

-- Loads displays.lua against a fake compositor with the given monitors, and
-- returns what it listens to, the monitor rules it applied, the window rules
-- it added and the module it returned.
local function load(monitors)
    local world = { handlers = {}, rules = {}, window_rules = {}, monitors = monitors }

    hl = {
        on = function(event, callback)
            world.handlers[event] = world.handlers[event] or {}
            table.insert(world.handlers[event], callback)
        end,
        monitor = function(rule)
            table.insert(world.rules, rule)
        end,
        window_rule = function(rule)
            table.insert(world.window_rules, rule)
        end,
        get_monitors = function(options)
            local list = {}
            for _, m in ipairs(world.monitors) do
                if m.enabled or (options and options.all) then
                    table.insert(list, m)
                end
            end
            return list
        end,
    }

    package.preload["chena.settings"] = function()
        return settings
    end
    package.loaded["chena.settings"] = nil

    world.module = dofile(script)
    return world
end

local function fire(world, event)
    for _, callback in ipairs(world.handlers[event] or {}) do
        callback()
    end
end

-- The last rule for an output, as Hyprland uses the last one given.
local function ruleFor(world, output)
    local found
    for _, rule in ipairs(world.rules) do
        if rule.output == output then
            found = rule
        end
    end
    return found
end

local function find(world, name)
    for _, m in ipairs(world.monitors) do
        if m.name == name then
            return m
        end
    end
end

-- Arranges the docked monitors the way a display tool would, and lets the
-- module see the change.
local function saveDockedLayout()
    local world = load(docked())
    find(world, "DP-1").x = 0
    find(world, "DP-1").scale = 1.25
    find(world, "eDP-1").x = 3072
    fire(world, "monitor.layout_changed")
    return world
end

-- Nothing is saved yet, so the rules from Nix stay as they are.
do
    freshState()
    local world = load(docked())
    expect(#world.rules, 0, "first load: rules")
    for _, event in ipairs({ "monitor.layout_changed", "monitor.added", "monitor.removed", "hyprland.start" }) do
        expect(world.handlers[event] ~= nil, true, "listens to " .. event)
    end
end

-- The display tool opens as a floating window.
do
    freshState()
    local world = load(docked())
    local rule = world.window_rules[1]
    expect(rule.match.class, "^network\\.cycles\\.wdisplays$", "tool rule: class")
    expect(rule.float, true, "tool rule: float")
end

-- A change is saved and comes back after a reload.
do
    freshState()
    saveDockedLayout()
    local world = load(docked())
    local rule = ruleFor(world, "DP-1")
    expect(rule.mode, "3840x2160@59.997", "reload: mode")
    expect(rule.position, "0x0", "reload: position")
    expect(rule.scale, 1.25, "reload: scale")
    expect(rule.transform, 0, "reload: transform")
    expect(rule.disabled, false, "reload: disabled")
    expect(ruleFor(world, "eDP-1").position, "3072x0", "reload: panel position")
    expect(ruleFor(world, "eDP-1").mode, "3024x1890@120.000", "reload: panel mode")
end

-- Each set of monitors has its own layout.
do
    freshState()
    saveDockedLayout()
    local world = load({ panel() })
    expect(#world.rules, 0, "other set: rules")
end

-- At login the monitors are not up yet while the file loads.
do
    freshState()
    saveDockedLayout()
    local world = load({})
    expect(#world.rules, 0, "before the monitors are up: rules")
    world.monitors = docked()
    fire(world, "hyprland.start")
    expect(ruleFor(world, "DP-1").scale, 1.25, "start: scale")
end

-- Plugging a monitor in brings back the layout of the new set. The change
-- that comes before the plug event is not saved over it.
do
    freshState()
    saveDockedLayout()
    local world = load({ panel() })
    table.insert(world.monitors, dell())
    fire(world, "monitor.layout_changed")
    fire(world, "monitor.added")
    expect(ruleFor(world, "DP-1").scale, 1.25, "plugged in: scale")
    expect(ruleFor(load(docked()), "DP-1").scale, 1.25, "plugged in: saved scale")
end

-- Unplugging goes back to the layout of the set that is left.
do
    freshState()
    local alone = load({ panel() })
    alone.monitors[1].scale = 1.75
    fire(alone, "monitor.layout_changed")
    local world = load(docked())
    world.monitors[2] = nil
    fire(world, "monitor.removed")
    expect(ruleFor(world, "eDP-1").scale, 1.75, "unplugged: scale")
end

-- A monitor that was turned off stays off.
do
    freshState()
    local world = load(docked())
    find(world, "DP-1").enabled = false
    fire(world, "monitor.layout_changed")
    expect(ruleFor(load(docked()), "DP-1").disabled, true, "turned off: disabled")
end

-- Two monitors of the same model are told apart by their port.
do
    freshState()
    local twins = function()
        return {
            monitor("DP-1", "Same Model 0000"),
            monitor("DP-2", "Same Model 0000", { x = 1920 }),
        }
    end
    local world = load(twins())
    find(world, "DP-2").scale = 2
    fire(world, "monitor.layout_changed")
    local reloaded = load(twins())
    expect(ruleFor(reloaded, "DP-1").scale, 1, "twins: first scale")
    expect(ruleFor(reloaded, "DP-2").scale, 2, "twins: second scale")
end

-- The built-in screen is turned off and on by the lid, not by the layout.
if settings.clamshell then
    -- Closing the lid keeps the saved layout of the panel.
    do
        freshState()
        saveDockedLayout()
        local world = load(docked())
        find(world, "eDP-1").enabled = false
        find(world, "DP-1").x = 100
        fire(world, "monitor.layout_changed")
        local reloaded = load(docked())
        expect(ruleFor(reloaded, "eDP-1").position, "3072x0", "lid closed: panel position")
        expect(ruleFor(reloaded, "eDP-1").disabled, false, "lid closed: panel disabled")
        expect(ruleFor(reloaded, "DP-1").position, "100x0", "lid closed: other position")
    end

    -- A layout applied while the lid is closed leaves the panel off.
    do
        freshState()
        saveDockedLayout()
        local monitors = docked()
        monitors[1].enabled = false
        local world = load(monitors)
        expect(ruleFor(world, "eDP-1"), nil, "applied with the lid closed: panel rule")
        expect(ruleFor(world, "DP-1").scale, 1.25, "applied with the lid closed: other scale")
    end

    -- The lid asks for the saved rule of the panel when it opens.
    do
        freshState()
        expect(load(docked()).module.rule_for("eDP-1"), nil, "nothing saved: panel rule")
        saveDockedLayout()
        local world = load(docked())
        local rule = world.module.rule_for("eDP-1")
        expect(rule.output, "eDP-1", "panel rule: output")
        expect(rule.position, "3072x0", "panel rule: position")
        expect(rule.disabled, false, "panel rule: disabled")
    end
end
