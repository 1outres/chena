local programs = require("chena.settings").programs

hl.on("hyprland.start", function()
    hl.exec_cmd(programs.session_start)
end)

-- Runs to the end before Hyprland exits, so the login screen that comes next
-- already sees what this did.
hl.on("hyprland.shutdown", function()
    os.execute(programs.session_end)
end)

if programs.monitor_added then
    hl.on("monitor.added", function()
        hl.exec_cmd(programs.monitor_added)
    end)
end
