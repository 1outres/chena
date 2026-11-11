local settings = dofile(arg[1])
local script = arg[2]
local expected = arg[3]

local handlers, ran = {}, {}

hl = {
    on = function(event, callback)
        handlers[event] = callback
    end,
    exec_cmd = function(command)
        table.insert(ran, command)
    end,
}

package.preload["chena.settings"] = function()
    return settings
end

dofile(script)

-- Each monitor that comes runs the command once. Without one, nothing
-- listens for monitors.
if expected == "none" then
    if handlers["monitor.added"] then
        error("listens for monitor.added without a command")
    end
else
    handlers["monitor.added"]({ name = "eDP-1" })
    if #ran ~= 1 or not ran[1]:find(expected, 1, true) then
        error("monitor.added ran " .. tostring(ran[1]) .. ", not " .. expected)
    end
end
