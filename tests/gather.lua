local settings = dofile(arg[1])
local script = arg[2]

local function expect(actual, expected, what)
    if actual ~= expected then
        error(string.format("%s: expected %s, got %s", what, tostring(expected), tostring(actual)), 2)
    end
end

-- Loads gather.lua against a fake compositor. Each monitor shows the
-- workspace named in active, and windows maps a workspace id to the number
-- of windows on it.
local function load(monitors, workspaces, windows)
    local world = { handlers = {}, moves = {}, rules = {} }

    local byMonitor, all, list = {}, {}, {}
    for _, monitor in ipairs(monitors) do
        byMonitor[monitor.name] = { name = monitor.name }
    end
    for _, workspace in ipairs(workspaces) do
        local entry = {
            id = workspace.id,
            name = workspace.name or tostring(workspace.id),
            special = workspace.special or false,
            monitor = byMonitor[workspace.monitor],
        }
        all[entry.id] = entry
        table.insert(list, entry)
    end
    local windowList = {}
    for id, count in pairs(windows) do
        for index = 1, count do
            table.insert(windowList, { address = id .. ":" .. index, mapped = true, workspace = all[id] })
        end
    end

    hl = {
        dsp = {
            window = {
                move = function(argument)
                    return { name = "window.move", argument = argument }
                end,
            },
        },
        dispatch = function(action)
            table.insert(world.moves, action)
        end,
        on = function(event, callback)
            world.handlers[event] = callback
        end,
        workspace_rule = function(rule)
            world.rules[rule.workspace] = rule
        end,
        get_monitors = function()
            local result = {}
            for _, monitor in ipairs(monitors) do
                table.insert(result, byMonitor[monitor.name])
            end
            return result
        end,
        get_active_workspace = function(monitor)
            for _, entry in ipairs(monitors) do
                if entry.name == monitor.name then
                    return all[entry.active]
                end
            end
        end,
        get_workspaces = function()
            return list
        end,
        get_windows = function()
            return windowList
        end,
    }

    package.preload["chena.settings"] = function()
        return settings
    end
    package.loaded["chena.settings"] = nil

    dofile(script)
    return world
end

local function range(first, last, monitor)
    local list = {}
    for id = first, last do
        table.insert(list, { id = id, monitor = monitor })
    end
    return list
end

local function concat(...)
    local list = {}
    for _, part in ipairs({ ... }) do
        for _, item in ipairs(part) do
            table.insert(list, item)
        end
    end
    return list
end

expect(#settings.workspaces.keys, 9, "workspaces per monitor")

-- After the panel goes, its workspaces 1 to 9 sit on DP-1 next to its own
-- 10 to 18. Their windows come to the workspace DP-1 shows, and they stop
-- being kept, so the empty ones go away.
do
    local world = load(
        { { name = "DP-1", active = 11 } },
        concat(range(1, 9, "DP-1"), range(10, 18, "DP-1")),
        { [1] = 2, [3] = 1, [12] = 1 }
    )
    world.handlers["monitor.removed"]({ name = "eDP-1" })

    expect(#world.moves, 3, "windows moved")
    for _, move in ipairs(world.moves) do
        expect(move.name, "window.move", "move dispatcher")
        expect(move.argument.workspace, "11", "move target")
        expect(move.argument.follow, false, "move follows")
        local from = move.argument.window.workspace.id
        if from ~= 1 and from ~= 3 then
            error("moved a window from workspace " .. from)
        end
    end

    for id = 1, 9 do
        expect(world.rules[tostring(id)] and world.rules[tostring(id)].persistent, false, "workspace " .. id .. " kept")
    end
    for id = 10, 18 do
        expect(world.rules[tostring(id)], nil, "rule for own workspace " .. id)
    end
end

-- The same holds when the second monitor goes and the panel stays.
do
    local world = load(
        { { name = "eDP-1", active = 2 } },
        concat(range(1, 9, "eDP-1"), range(10, 18, "eDP-1")),
        { [15] = 1 }
    )
    world.handlers["monitor.removed"]({ name = "DP-1" })

    expect(#world.moves, 1, "windows moved from DP-1")
    expect(world.moves[1].argument.workspace, "2", "move target on the panel")
    expect(world.rules["15"].persistent, false, "workspace 15 kept")
    expect(world.rules["2"], nil, "rule for own workspace 2")
end

-- Special workspaces such as the scratchpad keep their windows.
do
    local world = load(
        { { name = "DP-1", active = 10 } },
        concat(range(10, 18, "DP-1"), { { id = -98, name = "special:scratch", special = true, monitor = "DP-1" } }),
        { [-98] = 1 }
    )
    world.handlers["monitor.removed"]({ name = "eDP-1" })

    expect(#world.moves, 0, "windows moved from a special workspace")
    expect(world.rules["special:scratch"], nil, "rule for a special workspace")
end

-- With no monitor left there is nowhere to gather to.
do
    local world = load({}, range(1, 9, nil), { [1] = 1 })
    world.handlers["monitor.removed"]({ name = "eDP-1" })

    expect(#world.moves, 0, "windows moved with no monitor")
end
