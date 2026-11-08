local Board = {}

Board.Geometry = {
    width = 20,
    bottom = -2.8,
    top = 25,
    launchX = 0,
    launchY = 22,
    pegRadius = 0.82,
    ballRadius = 0.48,
}

Board.Slots = {}
for row = 1, 5 do
    for column = 1, 5 do
        local omitted = (row == 1 and column >= 2 and column <= 4) or (row == 2 and column == 3)
        if not omitted then
            table.insert(Board.Slots, {
                id = #Board.Slots + 1,
                x = (column - 3) * 3.4,
                y = 15 - (row - 1) * 3.4,
            })
        end
    end
end

local MAX_VALUE = 2 ^ 996
local MAX_TOTAL = 1e300
local MULTIPLIERS = {
    1 / 4.25,
    1 / 3,
    1 / 2.25,
    1 / 1.8,
    1 / 1.75,
    1 / 1.6,
    1 / 1.45,
    1 / 1.25,
    1 / 1.1,
    1,
    1.1,
    1.15,
    1.25,
    1.5,
    1.6,
    1.75,
    1.95,
}

function Board.copy(values)
    local result = {}
    for id = 1, #Board.Slots do
        result[id] = values[id] or 0
    end
    return result
end

function Board.new(rng)
    local values = {}
    for id = 1, #Board.Slots do
        values[id] = if id <= 11 then 2 else 1
    end
    rng:shuffle(values)
    return values
end

function Board.potential(values)
    local total = 0
    for _, value in ipairs(values) do
        if value > 0 then
            total = math.min(MAX_TOTAL, total + 2 * value - 1)
        end
    end
    return total
end

function Board.quota(values, shopsVisited)
    local visits = math.max(0, math.floor(shopsVisited))
    local multiplier = MULTIPLIERS[visits + 1]
    if not multiplier then
        multiplier = 2 * 1.3 ^ math.min(2600, visits - 17)
    end
    return math.max(1, math.floor(math.min(MAX_TOTAL, Board.potential(values) * multiplier) + 0.5))
end

function Board.jumble(values, rng)
    rng:shuffle(values)
    return values
end

function Board.restock(values, completedRound, _rng, capture)
    local transitions = {}
    local cycle = if capture
        then { beforeValues = Board.copy(values), refills = {}, merges = {} }
        else nil
    local fillValue = 2 ^ math.min(996, math.max(0, math.floor(completedRound / 5)))
    for id = 1, #Board.Slots do
        if not values[id] or values[id] == 0 then
            values[id] = fillValue
            table.insert(transitions, { from = 0, to = id, value = fillValue })
            if cycle then
                table.insert(cycle.refills, { to = id, value = fillValue })
            end
        end
    end

    -- Snapshot values so a merge product cannot participate in this generation.
    local snapshot = Board.copy(values)
    local waiting = {}
    for id, value in ipairs(snapshot) do
        local partner = waiting[value]
        if partner then
            local merged = math.min(MAX_VALUE, value * 2)
            values[partner] = merged
            values[id] = 0
            waiting[value] = nil
            table.insert(transitions, { from = id, to = partner, value = merged })
            if cycle then
                table.insert(cycle.merges, { from = id, to = partner, value = merged })
            end
        else
            waiting[value] = id
        end
    end
    if cycle then
        cycle.afterValues = Board.copy(values)
    end
    return transitions, cycle
end

function Board.pop(values, id)
    local old = values[id] or 0
    if old <= 0 then
        return 0, 0, 0
    end
    local new = if old <= 1 then 0 else old / 2
    values[id] = new
    return old, old, new
end

function Board.isClear(values)
    for _, value in ipairs(values) do
        if value > 0 then
            return false
        end
    end
    return true
end

return Board
