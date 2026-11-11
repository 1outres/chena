local settings = dofile(arg[1])
local programs = settings.programs

local function dispatcher(path)
    return setmetatable({}, {
        __index = function(_, key)
            return dispatcher(path == "" and key or path .. "." .. key)
        end,
        __call = function(_, argument)
            return { name = path, argument = argument }
        end,
    })
end

local binds = {}

hl = {
    dsp = dispatcher(""),
    bind = function(keys, action, options)
        if binds[keys] then
            error("bound twice: " .. keys)
        end
        binds[keys] = { action = action, options = options or {} }
    end,
}

local function splitAction(name)
    return function(argument)
        return { name = "split." .. name, argument = argument }
    end
end

package.preload["chena.settings"] = function()
    return settings
end

package.preload["chena.split.split-monitor-workspaces"] = function()
    return {
        workspace = splitAction("workspace"),
        move_to_workspace = splitAction("move_to_workspace"),
        cycle_workspaces = splitAction("cycle_workspaces"),
    }
end

dofile(arg[2])

local function bound(keys)
    local bind = binds[keys]
    if not bind then
        error("not bound: " .. keys, 3)
    end
    return bind
end

local function expectAction(keys, name, argument)
    local action = bound(keys).action
    if action.name ~= name or action.argument ~= argument then
        error(string.format("%s: expected %s(%s), got %s(%s)", keys, name, tostring(argument),
            tostring(action.name), tostring(action.argument)), 2)
    end
end

local function expectField(keys, name, field, value)
    local action = bound(keys).action
    if action.name ~= name or action.argument[field] ~= value then
        error(string.format("%s: expected %s with %s = %s", keys, name, field, tostring(value)), 2)
    end
end

local function expectUnbound(keys)
    if binds[keys] then
        error("should not be bound: " .. keys, 2)
    end
end

expectAction("SUPER + Q", "exec_cmd", programs.terminal)
expectAction("SUPER + Space", "exec_cmd", programs.menu)
expectAction("SUPER + L", "exec_cmd", programs.lock)
expectAction("SUPER + Escape", "exec_cmd", programs.power)
expectAction("SUPER + SHIFT + M", "exec_cmd", programs.shutdown)
expectAction("ALT + Space", "exec_cmd", programs.clipboard)
expectAction("SUPER + W", "window.close")
expectField("SUPER + F", "window.fullscreen", "mode", "fullscreen")

expectAction("SUPER + SHIFT + S", "exec_cmd", programs.screenshot .. " region")
expectAction("SUPER + SHIFT + 4", "exec_cmd", programs.screenshot .. " region")
expectAction("SUPER + SHIFT + A", "exec_cmd", programs.screenshot_edit)
expectAction("SUPER + period", "exec_cmd", programs.emoji)

for _, keys in ipairs({ "Print", "SHIFT + Print", "SUPER + Print", "SUPER + R", "SUPER + C", "SUPER + M", "SUPER + V", "SUPER + P", "SUPER + J", "SUPER + S" }) do
    expectUnbound(keys)
end

for key, direction in pairs({ H = "left", J = "down", K = "up", L = "right" }) do
    expectField("ALT + " .. key, "focus", "direction", direction)
    expectField("ALT + SHIFT + " .. key, "window.move", "direction", direction)
end

for key, delta in pairs({ H = { -40, 0 }, J = { 0, 40 }, K = { 0, -40 }, L = { 40, 0 } }) do
    local keys = "ALT + CTRL + " .. key
    expectField(keys, "window.resize", "x", delta[1])
    expectField(keys, "window.resize", "y", delta[2])
    expectField(keys, "window.resize", "relative", true)
    if not bound(keys).options.repeating then
        error(keys .. " does not repeat")
    end
end

expectField("ALT + T", "window.float", "action", "toggle")
expectAction("ALT + B", "layout", "togglesplit")
expectAction("ALT + P", "window.pseudo")
expectAction("ALT + I", "window.center")
expectAction("ALT + A", "workspace.toggle_special", "magic")
expectField("ALT + SHIFT + A", "window.move", "workspace", "special:magic")

for index, key in ipairs(settings.workspaces.keys) do
    expectAction("ALT + " .. key, "split.workspace", tostring(index))
    expectAction("ALT + SHIFT + " .. key, "split.move_to_workspace", tostring(index))
    expectAction("ALT + " .. index, "split.workspace", tostring(index))
    expectAction("ALT + SHIFT + " .. index, "split.move_to_workspace", tostring(index))
end

expectAction("ALT + left", "split.cycle_workspaces", "prev")
expectAction("ALT + right", "split.cycle_workspaces", "next")

expectField("ALT + mouse_down", "focus", "workspace", "m+1")
expectField("ALT + mouse_up", "focus", "workspace", "m-1")

for _, keys in ipairs({ "ALT + mouse:272", "ALT + mouse:273" }) do
    if not bound(keys).options.mouse then
        error(keys .. " is not a mouse bind")
    end
end

expectAction("XF86AudioRaiseVolume", "exec_cmd", programs.volume_up)
expectAction("XF86AudioLowerVolume", "exec_cmd", programs.volume_down)
expectAction("XF86AudioMute", "exec_cmd", programs.volume_mute)
expectAction("XF86AudioMicMute", "exec_cmd", programs.mic_mute)
expectAction("XF86AudioNext", "exec_cmd", programs.media_next)
expectAction("XF86AudioPlay", "exec_cmd", programs.media_play_pause)
expectAction("XF86AudioPause", "exec_cmd", programs.media_play_pause)
expectAction("XF86AudioPrev", "exec_cmd", programs.media_previous)

-- Only a shell that has quick settings gets the key.
if programs.quick_settings then
    expectAction("SUPER + N", "exec_cmd", programs.quick_settings)
else
    expectUnbound("SUPER + N")
end
