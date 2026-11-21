local settings = dofile(arg[1])

if settings.displays ~= nil then
    error("displays is set without being turned on")
end

hl = setmetatable({}, {
    __index = function(_, key)
        error("displays.lua used hl." .. key .. " without being turned on")
    end,
})

package.preload["chena.settings"] = function()
    return settings
end

local displays = dofile(arg[2])

if displays.rule_for("eDP-1") ~= nil then
    error("rule_for gave a rule without being turned on")
end
