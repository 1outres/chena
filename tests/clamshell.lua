local settings = dofile(arg[1])
local script = arg[2]

local function expect(actual, expected, what)
    if actual ~= expected then
        error(string.format("%s: expected %s, got %s", what, tostring(expected), tostring(actual)), 2)
    end
end

-- Loads clamshell.lua against a fake compositor with the given monitors and
-- lid state, and returns what it bound, what it listens to and the monitor
-- rules it applied.
local function load(monitors, lidClosed)
    local world = { binds = {}, handlers = {}, rules = {}, monitors = monitors }

    hl = {
        bind = function(keys, action, options)
            world.binds[keys] = { action = action, options = options or {} }
        end,
        on = function(event, callback)
            world.handlers[event] = callback
        end,
        monitor = function(rule)
            table.insert(world.rules, rule)
            for _, monitor in ipairs(world.monitors) do
                if monitor.name == rule.output then
                    monitor.enabled = not rule.disabled
                end
            end
        end,
        get_monitors = function(options)
            local list = {}
            for _, monitor in ipairs(world.monitors) do
                if monitor.enabled or (options and options.all) then
                    table.insert(list, monitor)
                end
            end
            return list
        end,
    }

    io.popen = function(command)
        expect(command, settings.clamshell.lid_state, "lid state command")
        return {
            read = function()
                return lidClosed and "b true" or "b false"
            end,
            close = function() end,
        }
    end

    package.preload["chena.settings"] = function()
        return settings
    end
    package.loaded["chena.settings"] = nil

    dofile(script)
    return world
end

local function docked()
    return {
        { name = "eDP-1", enabled = true },
        { name = "DP-1", enabled = true },
    }
end

local function alone()
    return { { name = "eDP-1", enabled = true } }
end

local function lastRule(world)
    return world.rules[#world.rules]
end

local closeKeys = "switch:on:Apple SMC power/lid events"
local openKeys = "switch:off:Apple SMC power/lid events"

-- The lid works while the screen is locked too.
do
    local world = load(docked(), false)
    expect(world.binds[closeKeys].options.locked, true, "close bind is locked")
    expect(world.binds[openKeys].options.locked, true, "open bind is locked")
    expect(#world.rules, 0, "rules while the lid is open")
end

-- Closing the lid with another monitor turns the panel off.
do
    local world = load(docked(), false)
    world.binds[closeKeys].action()
    expect(lastRule(world).output, "eDP-1", "close: output")
    expect(lastRule(world).disabled, true, "close: disabled")
end

-- Without another monitor the panel stays on, and logind suspends.
do
    local world = load(alone(), false)
    world.binds[closeKeys].action()
    expect(#world.rules, 0, "close alone: rules")
end

-- Opening the lid brings the panel back with its own rule. disabled = false
-- has to be given, or the rule that turned it off stays.
do
    local world = load(docked(), false)
    world.binds[closeKeys].action()
    world.binds[openKeys].action()
    local rule = lastRule(world)
    expect(rule.output, "eDP-1", "open: output")
    expect(rule.disabled, false, "open: disabled")
    expect(rule.scale, 2, "open: scale")
    expect(rule.mode, "preferred", "open: mode")
end

-- A reload with the lid closed keeps the panel off.
do
    local world = load(docked(), true)
    expect(lastRule(world).disabled, true, "reload with the lid closed")
end

-- A login with the lid closed turns the panel off once the monitors are up.
do
    local world = load({}, true)
    expect(#world.rules, 0, "rules before the monitors are up")
    world.monitors = docked()
    world.handlers["hyprland.start"]()
    expect(lastRule(world).disabled, true, "start with the lid closed")
end

-- Unplugging the other monitor with the lid closed brings the panel back, so
-- there is always a screen.
do
    local world = load(docked(), true)
    world.monitors[2] = nil
    world.handlers["monitor.removed"]()
    expect(lastRule(world).output, "eDP-1", "unplugged: output")
    expect(lastRule(world).disabled, false, "unplugged: disabled")
end

-- Unplugging a monitor while the panel is on changes nothing.
do
    local world = load(docked(), false)
    world.monitors[2] = nil
    world.handlers["monitor.removed"]()
    expect(#world.rules, 0, "unplugged with the lid open: rules")
end
