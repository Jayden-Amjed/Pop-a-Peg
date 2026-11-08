local Profile = if script
    then require(game:GetService("ReplicatedStorage").Shared.Profile)
    else require("../src/shared/Profile")

return function()
    local a = Profile.clean({
        bestScore = 200,
        bestRound = 8,
        unlocks = { "relay", "relay", "bad/path" },
        coins = 900,
    })
    assert(
        a.bestScore == 200 and a.bestRound == 8 and #a.unlocks == 1,
        "Valid records and unique unlocks must survive"
    )
    assert(a.coins == nil, "Run power must never be saved")
    local b = Profile.merge(a, { bestScore = 10, bestRound = 20, unlocks = { "spark", "relay" } })
    assert(
        b.bestScore == 200 and b.bestRound == 20 and #b.unlocks == 2,
        "Merges keep best records and union unlocks"
    )
    local invalid = Profile.clean({ bestScore = 0 / 0, bestRound = math.huge })
    assert(invalid.bestScore == 0 and invalid.bestRound == 0, "Nonfinite records must be rejected")
    assert(Profile.clean("bad").bestScore == 0, "Invalid profile containers start clean")
    print("PASS profile: monotonic records, unlock union, reset boundaries, invalid input")
end
