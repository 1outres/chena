local settings = require("chena.settings")
local split = require("chena.split.split-monitor-workspaces")

split.setup({
    workspace_count = #settings.workspaces.keys,
    -- A dock can drop its displays for a moment. Keeping the ranges brings
    -- each workspace back to the same monitor.
    restore_workspaces_on_monitor_reconnect = true,
})
