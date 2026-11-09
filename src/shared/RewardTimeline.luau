-- A bounded visual plan built from the server's recorded board transitions.
local RewardTimeline = {}

local function copy(values)
    return table.clone(values or {})
end

function RewardTimeline.plan(receipt, activationDuration)
    local steps = {}
    local earned = receipt.earnedRestocks or 0
    local pace = if earned <= 2 then 1 elseif earned <= 8 then 0.78 else 0.6
    local function add(kind, duration, data)
        data = data or {}
        data.kind = kind
        data.duration = duration * pace
        table.insert(steps, data)
    end
    local drainValues = copy(receipt.drainStart and receipt.drainStart.values)
    for _, group in ipairs(receipt.drainSteps or {}) do
        local before = copy(drainValues)
        for _, change in ipairs(group.changes or {}) do
            drainValues[change.pegId] = change.value
        end
        -- Drain performances keep their actual model duration; the shorter
        -- large-restock pace must not collapse them into simultaneous bursts.
        table.insert(steps, {
            kind = "drain",
            duration = activationDuration and activationDuration(group) or 1.8,
            beforeValues = before,
            afterValues = copy(drainValues),
            events = group.events,
        })
    end
    if receipt.kind == "event" then
        add("eventChange", 0.85, {
            beforeValues = copy(receipt.shotValues),
            afterValues = copy(receipt.eventValues),
        })
        add("shuffle", 0.75, {
            beforeValues = copy(receipt.eventValues),
            afterValues = copy(receipt.restoredValues),
            moves = receipt.shuffleMoves,
        })
    else
        add("restore", 0.42, {
            beforeValues = copy(receipt.shotValues),
            afterValues = copy(receipt.restoredValues),
        })
    end
    local previous = copy(receipt.restoredValues)
    local previousIndex = 0
    local cycles = receipt.cycles or {}
    for position, cycle in ipairs(cycles) do
        -- Also bound older/uncompressed receipts: show the first three and last two.
        -- Gaps still credit every reward and advance to the recorded board state.
        if #cycles > 5 and position > 3 and position <= #cycles - 2 then
            continue
        end
        local gap = cycle.index - previousIndex - 1
        if gap > 0 then
            add("batch", 0.5, {
                index = cycle.index - 1,
                count = gap,
                beforeValues = previous,
                afterValues = copy(cycle.beforeValues),
            })
        end
        local filled = copy(cycle.beforeValues)
        for _, refill in ipairs(cycle.refills) do
            filled[refill.to] = refill.value
        end
        add("refill", 0.6, {
            index = cycle.index,
            count = 1,
            beforeValues = copy(cycle.beforeValues),
            afterValues = filled,
            refills = cycle.refills,
        })
        add("merge", 0.54, {
            index = cycle.index,
            beforeValues = filled,
            afterValues = copy(cycle.afterValues),
            merges = cycle.merges,
        })
        previous = copy(cycle.afterValues)
        previousIndex = cycle.index
    end
    if previousIndex < earned then
        add("batch", 0.5, {
            index = earned,
            count = earned - previousIndex,
            beforeValues = previous,
            afterValues = copy(receipt.finalValues),
        })
    end
    if #(receipt.nextShotSeeds or {}) > 0 then
        add("seed", 0.65, {
            beforeValues = copy(receipt.finalValues),
            afterValues = copy(receipt.nextShotValues),
            seeds = receipt.nextShotSeeds,
        })
    end
    add("finish", if earned > 0 then 0.42 else 0.68, {
        afterValues = copy(receipt.nextShotValues or receipt.finalValues or receipt.restoredValues),
    })
    return steps
end

return RewardTimeline
