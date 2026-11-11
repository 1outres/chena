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
expect(settings.touchpad.scroll_factor, 0.5, "touchpad.scroll_factor")

expect(settings.cursor.name, "Adwaita", "cursor.name")
expect(settings.cursor.size, 24, "cursor.size")

expect(settings.style.gaps_in, 2, "style.gaps_in")
expect(settings.style.gaps_out, 4, "style.gaps_out")
expect(settings.style.border_size, 2, "style.border_size")
expect(settings.style.rounding, 0, "style.rounding")
expect(settings.style.colors.active_border, "rgb(bd93f9)", "style.colors.active_border")
expect(settings.style.colors.inactive_border, "rgb(44475a)", "style.colors.inactive_border")
expect(settings.style.colors.desktop, "rgb(191a21)", "style.colors.desktop")

if not settings.programs.menu:find("/bin/walker$") then
    error("programs.menu is not walker: " .. tostring(settings.programs.menu))
end

if not settings.programs.osd:find("/bin/swayosd%-client$") then
    error("programs.osd is not swayosd-client: " .. tostring(settings.programs.osd))
end

expect(table.concat(settings.workspaces.keys), "ZXCSDFWER", "workspaces.keys")

if not settings.programs.clipboard:find("/bin/walker %-%-provider clipboard$") then
    error("programs.clipboard is not the walker clipboard: " .. tostring(settings.programs.clipboard))
end

if not settings.programs.screenshot:find("/bin/hyprshot %-%-freeze %-%-clipboard%-only %-%-mode$") then
    error("programs.screenshot is not hyprshot: " .. tostring(settings.programs.screenshot))
end

for _, program in ipairs({ "terminal", "menu", "shutdown", "power", "clipboard", "screenshot", "osd", "brightness", "lock", "session_start", "session_end" }) do
    local path = settings.programs[program]
    if type(path) ~= "string" or not path:find("^/nix/store/") then
        error("programs." .. program .. " is not a store path: " .. tostring(path))
    end
end
