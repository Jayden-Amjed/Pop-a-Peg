local Progress = if script
    then require(game:GetService("Players").LocalPlayer.PlayerScripts.Client.CounterProgress)
    else require("../src/client/CounterProgress")

return function()
    local function check(score, quota, expectedCount, capped)
        local result = Progress.compute(score, quota, 10000, 5)
        assert(
            result.completed == expectedCount,
            "Displayed quota count differs from bounded count"
        )
        assert(result.capped == capped, "Restock cap state is incorrect")
        assert(result.fraction >= 0 and result.fraction <= 1, "Progress fill escaped its bounds")
        assert(result.remainder >= 0 and result.remainder <= quota, "Progress remainder is invalid")
        assert(
            result.nextLayer >= 1 and result.nextLayer <= 5 and result.nextLayer % 1 == 0,
            "Next palette index is not a valid integer"
        )
        assert(
            result.previousLayer >= 0
                and result.previousLayer <= 5
                and result.previousLayer % 1 == 0,
            "Previous palette index is not a valid integer"
        )
        return result
    end
    local empty = check(0, 100, 0, false)
    assert(empty.fraction == 0 and empty.remainder == 0, "Empty score must show empty progress")
    local half = check(150, 100, 1, false)
    assert(half.fraction == 0.5 and half.remainder == 50, "Ordinary score progress changed")
    local exact = check(200, 100, 2, false)
    assert(exact.fraction == 0 and exact.remainder == 0, "Exact quota must start a fresh layer")
    local below = check(999999, 100, 9999, false)
    assert(math.abs(below.fraction - 0.99) < 1e-8, "Progress immediately below cap is incorrect")
    for _, score in { 1000000, 1e107, 1e300, math.huge } do
        local full = check(score, 100, 10000, true)
        assert(full.fraction == 1 and full.remainder == 0, "Capped progress must stay full")
    end
    local hugeQuota = 2 ^ 900
    local precise = check(hugeQuota * 7, hugeQuota, 7, false)
    assert(precise.fraction == 0, "Large exact quotas must remain stable below cap")
    local partial = check(hugeQuota * 7.5, hugeQuota, 7, false)
    assert(
        partial.fraction == 0.5 and partial.remainder == hugeQuota * 0.5,
        "Large partial quota must remain stable below cap"
    )
    local custom = Progress.compute(999999999, 1, 17, 3)
    assert(
        custom.completed == 17 and custom.capped and custom.nextLayer == 3,
        "Server-provided cap and palette count must be respected"
    )
    print(
        "PASS counter progress: ordinary quotas, extreme scores, exact boundaries and capped palette indices"
    )
end
