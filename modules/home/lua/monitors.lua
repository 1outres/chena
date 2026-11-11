local settings = require("chena.settings")

for _, monitor in ipairs(settings.monitors) do
    hl.monitor(monitor)
end
