local settings = dofile(arg[1])

if settings.clamshell ~= nil then
    error("clamshell is set without being configured")
end

hl = setmetatable({}, {
    __index = function(_, key)
        error("clamshell.lua used hl." .. key .. " without being configured")
    end,
})

package.preload["chena.settings"] = function()
    return settings
end

dofile(arg[2])
