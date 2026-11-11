local settings = require("chena.settings")

local count = #settings.workspaces.keys

-- split-monitor-workspaces gives every monitor its own run of ids, such as
-- 1 to 9 and 10 to 18, so the run tells which monitor a workspace is for.
local function run(id)
    return (id - 1) // count
end

local function windowsOn(workspace)
    local list = {}
    for _, window in ipairs(hl.get_windows()) do
        if window.mapped and window.workspace and window.workspace.id == workspace.id then
            table.insert(list, window)
        end
    end
    return list
end

-- Hyprland moves the workspaces of a monitor that goes to one that stays.
-- Their windows come to the workspace that monitor shows, and the workspaces
-- stop being kept, so each monitor keeps only its own run.
-- split-monitor-workspaces keeps them again when the monitor comes back.
local function gather(monitor)
    local shown = hl.get_active_workspace(monitor)
    if not shown or not shown.id or shown.special then
        return
    end

    for _, workspace in ipairs(hl.get_workspaces()) do
        local here = workspace.monitor and workspace.monitor.name == monitor.name
        if here and not workspace.special and workspace.id and run(workspace.id) ~= run(shown.id) then
            for _, window in ipairs(windowsOn(workspace)) do
                hl.dispatch(hl.dsp.window.move({ workspace = shown.name, window = window, follow = false }))
            end
            hl.workspace_rule({ workspace = workspace.name, persistent = false })
        end
    end
end

hl.on("monitor.removed", function()
    for _, monitor in ipairs(hl.get_monitors()) do
        gather(monitor)
    end
end)
