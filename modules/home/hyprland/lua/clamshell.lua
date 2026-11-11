local settings = require("chena.settings")
local clamshell = settings.clamshell

if not clamshell then
    return
end

local panel = clamshell.output

-- A rule that names the output wins over one for every output, the same way
-- Hyprland picks between them.
local function configuredRule()
    local named, any
    for _, monitor in ipairs(settings.monitors) do
        if monitor.output == panel then
            named = monitor
        elseif monitor.output == "" then
            any = monitor
        end
    end
    return named or any or {}
end

local function panelEnabled()
    for _, monitor in ipairs(hl.get_monitors({ all = true })) do
        if monitor.name == panel then
            return monitor.enabled
        end
    end
    return false
end

local function otherMonitorEnabled()
    for _, monitor in ipairs(hl.get_monitors()) do
        if monitor.name ~= panel and monitor.enabled then
            return true
        end
    end
    return false
end

local function lidClosed()
    local state = io.popen(clamshell.lid_state)
    local value = state:read("l")
    state:close()
    return value == "b true"
end

-- With no other monitor, the panel stays on and logind suspends.
local function close()
    if otherMonitorEnabled() then
        hl.monitor({ output = panel, disabled = true })
    end
end

local function open()
    local rule = {}
    for key, value in pairs(configuredRule()) do
        rule[key] = value
    end
    rule.output = panel
    rule.disabled = false
    hl.monitor(rule)
end

local function followLid()
    if lidClosed() then
        close()
    end
end

hl.bind("switch:on:" .. clamshell.switch, close, { locked = true })
hl.bind("switch:off:" .. clamshell.switch, open, { locked = true })

-- A reload applies the rules again, and at login the monitors are not up yet
-- while this file loads.
followLid()
hl.on("hyprland.start", followLid)

hl.on("monitor.removed", function()
    if not panelEnabled() and not otherMonitorEnabled() then
        open()
    end
end)
