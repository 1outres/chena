local settings = require("chena.settings")
local split = require("chena.split.split-monitor-workspaces")

local programs = settings.programs

-- SUPER starts apps and controls the system. ALT controls the windows.
local app = "SUPER"
local wm = "ALT"

local function exec(...)
    return hl.dsp.exec_cmd(table.concat({ ... }, " "))
end

hl.bind(app .. " + Q",         exec(programs.terminal))
hl.bind(app .. " + Space",     exec(programs.menu))
hl.bind(app .. " + L",         exec(programs.lock))
hl.bind(app .. " + Escape",    exec(programs.power))
hl.bind(app .. " + SHIFT + M", exec(programs.shutdown))
hl.bind(app .. " + W",         hl.dsp.window.close())
hl.bind(app .. " + F",         hl.dsp.window.fullscreen({ mode = "fullscreen" }))
hl.bind(wm  .. " + Space",     exec(programs.clipboard))
hl.bind(app .. " + period",    exec(programs.emoji))

hl.bind(app .. " + SHIFT + S", exec(programs.screenshot, "region"))
hl.bind(app .. " + SHIFT + 4", exec(programs.screenshot, "region"))
hl.bind(app .. " + SHIFT + A", exec(programs.screenshot_edit))

local resizeStep = 40

local directions = {
    H = { name = "left",  x = -resizeStep, y = 0 },
    J = { name = "down",  x = 0,           y = resizeStep },
    K = { name = "up",    x = 0,           y = -resizeStep },
    L = { name = "right", x = resizeStep,  y = 0 },
}

for key, direction in pairs(directions) do
    hl.bind(wm .. " + " .. key,           hl.dsp.focus({ direction = direction.name }))
    hl.bind(wm .. " + SHIFT + " .. key,   hl.dsp.window.move({ direction = direction.name }))
    hl.bind(wm .. " + CTRL + " .. key,
        hl.dsp.window.resize({ x = direction.x, y = direction.y, relative = true }),
        { repeating = true })
end

hl.bind(wm .. " + T", hl.dsp.window.float({ action = "toggle" }))
hl.bind(wm .. " + B", hl.dsp.layout("togglesplit"))
hl.bind(wm .. " + P", hl.dsp.window.pseudo())
hl.bind(wm .. " + I", hl.dsp.window.center())

for index, letter in ipairs(settings.workspaces.keys) do
    -- Workspace 10 sits on the 0 key.
    for _, key in ipairs({ letter, index % 10 }) do
        hl.bind(wm .. " + " .. key,         split.workspace(tostring(index)))
        hl.bind(wm .. " + SHIFT + " .. key, split.move_to_workspace(tostring(index)))
    end
end

hl.bind(wm .. " + left",  split.cycle_workspaces("prev"))
hl.bind(wm .. " + right", split.cycle_workspaces("next"))

hl.bind(wm .. " + A",         hl.dsp.workspace.toggle_special("magic"))
hl.bind(wm .. " + SHIFT + A", hl.dsp.window.move({ workspace = "special:magic" }))

hl.bind(wm .. " + mouse_down", hl.dsp.focus({ workspace = "m+1" }))
hl.bind(wm .. " + mouse_up",   hl.dsp.focus({ workspace = "m-1" }))

hl.bind(wm .. " + mouse:272", hl.dsp.window.drag(),   { mouse = true })
hl.bind(wm .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

local repeatable = { locked = true, repeating = true }

hl.bind("XF86AudioRaiseVolume", exec(programs.osd, "--output-volume raise --max-volume 100"), repeatable)
hl.bind("XF86AudioLowerVolume", exec(programs.osd, "--output-volume lower"),                  repeatable)
hl.bind("XF86AudioMute",        exec(programs.osd, "--output-volume mute-toggle"),            repeatable)
hl.bind("XF86AudioMicMute",     exec(programs.osd, "--input-volume mute-toggle"),             repeatable)

-- The backlight only reaches the built-in panel. The external displays
-- cannot be dimmed from here because apple-dcp gives Linux no DDC/CI bus
-- for them.
local function setBuiltinBrightness(step)
    return function()
        local monitor = hl.get_active_monitor()
        if monitor and monitor.name:find("^eDP%-") then
            hl.exec_cmd(programs.brightness .. " " .. step)
        end
    end
end

hl.bind("XF86MonBrightnessUp",   setBuiltinBrightness("5%+"), repeatable)
hl.bind("XF86MonBrightnessDown", setBuiltinBrightness("5%-"), repeatable)

local locked = { locked = true }

hl.bind("XF86AudioNext",  exec(programs.osd, "--playerctl next"),       locked)
hl.bind("XF86AudioPause", exec(programs.osd, "--playerctl play-pause"), locked)
hl.bind("XF86AudioPlay",  exec(programs.osd, "--playerctl play-pause"), locked)
hl.bind("XF86AudioPrev",  exec(programs.osd, "--playerctl prev"),       locked)
