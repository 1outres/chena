local settings = dofile(arg[1])

local function expect(actual, expected, what)
    if actual ~= expected then
        error(string.format("%s: expected %s, got %s", what, tostring(expected), tostring(actual)), 2)
    end
end

expect(settings.keyboard.layout, "us", "keyboard.layout")
expect(table.concat(settings.keyboard.options, ","), "ctrl:nocaps,compose:ralt", "keyboard.options")

expect(#settings.monitors, 1, "number of monitors")
expect(settings.monitors[1].output, "DP-1", "monitors[1].output")
expect(settings.monitors[1].mode, "2560x1440@144", "monitors[1].mode")
expect(settings.monitors[1].position, "0x0", "monitors[1].position")
expect(settings.monitors[1].scale, 1.5, "monitors[1].scale")

expect(settings.touchpad.natural_scroll, false, "touchpad.natural_scroll")

expect(settings.cursor.name, "Adwaita", "cursor.name")
expect(settings.cursor.size, 24, "cursor.size")

for _, program in ipairs({ "terminal", "menu", "shutdown", "wpctl", "brightnessctl", "playerctl" }) do
    local path = settings.programs[program]
    if type(path) ~= "string" or not path:find("^/nix/store/") then
        error("programs." .. program .. " is not a store path: " .. tostring(path))
    end
end
