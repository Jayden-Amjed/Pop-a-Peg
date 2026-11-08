local Timeline = if script
    then require(game:GetService("ReplicatedStorage").Shared.RewardTimeline)
    else require("../src/shared/RewardTimeline")

return function()
    local receipt = {
        earnedRestocks = 1,
        shotValues = { 0, 1 },
        restoredValues = { 2, 0 },
        finalValues = { 4, 0 },
        cycles = {
            {
                index = 1,
                beforeValues = { 2, 0 },
                refills = { { to = 2, value = 2 } },
                merges = { { from = 2, to = 1, value = 4 } },
                afterValues = { 4, 0 },
            },
        },
    }
    local plan = Timeline.plan(receipt)
    assert(#plan == 4 and plan[1].kind == "restore", "Board restoration must precede restocking")
    assert(
        plan[2].kind == "refill" and plan[2].afterValues[2] == 2,
        "Fill must appear before merge"
    )
    assert(
        plan[3].kind == "merge" and plan[3].afterValues[1] == 4,
        "Merge must use recorded targets"
    )
    assert(receipt.restoredValues[2] == 0, "Visual planning mutated authoritative values")
    receipt.earnedRestocks = 10000
    receipt.cycles[1].index = 10000
    plan = Timeline.plan(receipt)
    local credited = 0
    local duration = 0
    for _, step in ipairs(plan) do
        credited += step.count or 0
        duration += step.duration
    end
    assert(
        credited == 10000 and #plan == 5 and duration < 3,
        "Batched rewards lost count or became unbounded"
    )
    receipt.earnedRestocks = 0
    receipt.cycles = {}
    plan = Timeline.plan(receipt)
    assert(
        #plan == 2 and plan[2].kind == "finish",
        "A failed shot must restore without reward cycles"
    )
    for earned = 1, 12 do
        local cycles = {}
        for index = 1, earned do
            table.insert(cycles, {
                index = index,
                beforeValues = { index - 1 },
                refills = {},
                merges = {},
                afterValues = { index },
            })
        end
        local bounded = Timeline.plan({
            earnedRestocks = earned,
            shotValues = { 0 },
            restoredValues = { 0 },
            finalValues = { earned },
            cycles = cycles,
        })
        local refills, merges, rewards = 0, 0, 0
        for _, step in bounded do
            refills += step.kind == "refill" and 1 or 0
            merges += step.kind == "merge" and 1 or 0
            rewards += step.count or 0
        end
        assert(refills == math.min(5, earned) and merges == refills, "At most five complete cycles")
        assert(rewards == earned, "Compressed cycles must retain every reward")
        assert(bounded[#bounded].afterValues[1] == earned, "Final authoritative board preserved")
    end
    print(
        "PASS reward timeline: ordered restoration/refill/merge, exact batch counts, bounded duration"
    )
end
