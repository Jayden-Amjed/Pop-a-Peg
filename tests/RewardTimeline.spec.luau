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
    print(
        "PASS reward timeline: ordered restoration/refill/merge, exact batch counts, bounded duration"
    )
end
