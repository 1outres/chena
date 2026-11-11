local programs = require("chena.settings").programs

local mainMod = "SUPER"

hl.bind(mainMod .. " + Q", hl.dsp.exec_cmd(programs.terminal))
hl.bind(mainMod .. " + C", hl.dsp.window.close())
hl.bind(mainMod .. " + M", hl.dsp.exec_cmd(programs.shutdown))
hl.bind(mainMod .. " + L", hl.dsp.exec_cmd(programs.lock))
hl.bind(mainMod .. " + V", hl.dsp.window.float({ action = "toggle" }))
hl.bind(mainMod .. " + R", hl.dsp.exec_cmd(programs.menu))
hl.bind(mainMod .. " + P", hl.dsp.window.pseudo())
hl.bind(mainMod .. " + J", hl.dsp.layout("togglesplit"))

hl.bind(mainMod .. " + left",  hl.dsp.focus({ direction = "left" }))
hl.bind(mainMod .. " + right", hl.dsp.focus({ direction = "right" }))
hl.bind(mainMod .. " + up",    hl.dsp.focus({ direction = "up" }))
hl.bind(mainMod .. " + down",  hl.dsp.focus({ direction = "down" }))

for i = 1, 10 do
    -- Workspace 10 sits on the 0 key.
    local key = i % 10
    hl.bind(mainMod .. " + " .. key,         hl.dsp.focus({ workspace = i }))
    hl.bind(mainMod .. " + SHIFT + " .. key, hl.dsp.window.move({ workspace = i }))
end

hl.bind(mainMod .. " + S",         hl.dsp.workspace.toggle_special("magic"))
hl.bind(mainMod .. " + SHIFT + S", hl.dsp.window.move({ workspace = "special:magic" }))

hl.bind(mainMod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
hl.bind(mainMod .. " + mouse_up",   hl.dsp.focus({ workspace = "e-1" }))

hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(),   { mouse = true })
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

local function exec(...)
    return hl.dsp.exec_cmd(table.concat({ ... }, " "))
end

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
