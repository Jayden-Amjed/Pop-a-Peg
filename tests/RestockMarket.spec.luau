local Shared = if script then game:GetService("ReplicatedStorage").Shared else nil
local Profile = if Shared then require(Shared.Profile) else require("../src/shared/Profile")
local Chests = if Shared
    then require(Shared.ChestProgression)
    else require("../src/shared/ChestProgression")
local Arcade = if script
    then require(game:GetService("ServerScriptService").Server.ArcadeSessions)
    else require("../src/server/ArcadeSessions")

return function()
    for _, invalid in { -5, math.huge, 0 / 0, "100" } do
        assert(
            Profile.clean({ restockCredits = invalid }).restockCredits == 0,
            "Reject invalid wallet"
        )
    end
    assert(Profile.clean(nil).restockCredits == 0, "Existing profiles migrate with an empty wallet")
    assert(Profile.clean({ restockCredits = 109.9 }).restockCredits == 109, "Credits stay integral")
    assert(
        Profile.clean({ restockCredits = 1e20 }).restockCredits == Profile.RestockCreditLimit,
        "Credits clamp safely"
    )
    local merged = Profile.merge({ restockCredits = 35 }, { restockCredits = 999 })
    assert(merged.restockCredits == 35, "Run record merging cannot resurrect spent currency")

    local arcade = Arcade.new()
    local a = arcade:add(41, "One", { restockCredits = 98 })
    local b = arcade:add(42, "Two")
    assert(arcade:action(41, "startRun", {}, 17))
    local function shot(restocks)
        assert(arcade:action(41, "launch", { angle = 0 }))
        a.run.score = a.run.quota * (2 ^ restocks - 1)
        assert(arcade:action(41, "endShot"))
    end
    shot(3)
    assert(a.profile.restockCredits == 100, "The first restock is baseline; only two extras bank")
    assert(a.run.restocks == 3 and a.run.coins == 6, "Currency cannot consume normal run rewards")
    for _ = 1, 12 do
        arcade:capture(a)
        arcade:snapshot(41)
        arcade:step(0.01)
    end
    assert(a.profile.restockCredits == 100, "Repeated observations cannot mint more currency")
    assert(
        not arcade:action(41, "buyChest", { tier = "common", requestId = "board" }),
        "Run cannot buy hub chests"
    )
    assert(
        a.profile.restockCredits == 100 and a.profile.chests.common == 0,
        "Rejected purchase is unchanged"
    )
    assert(arcade:action(41, "enterHub"))
    local snap = arcade:snapshot(41)
    assert(
        snap.hub.profile.restockCredits == 100 and snap.hub.chests.restockCredits == 100,
        "Hub exposes wallet"
    )
    assert(snap.hub.chests.tiers[1].restockCost == 100, "Hub exposes authoritative cost")
    assert(arcade:action(41, "startRun", {}, 999), "Resume retains the previous receipt identity")
    assert(a.profile.restockCredits == 100 and a.runId == 1, "Resume does not award twice")
    assert(arcade:action(41, "enterHub"))

    assert(arcade:action(41, "buyChest", { tier = "common", requestId = "buyA" }))
    assert(
        a.profile.restockCredits == 0 and a.profile.chests.common == 1,
        "Exact-price purchase succeeds"
    )
    assert(
        b.profile.restockCredits == 0 and b.profile.chests.common == 0,
        "Other player remains unchanged"
    )
    assert(arcade:action(41, "buyChest", { tier = "common", requestId = "buyA" }))
    assert(
        a.profile.restockCredits == 0 and a.profile.chests.common == 1,
        "Retry is free and grants once"
    )
    assert(
        not arcade:action(41, "buyChest", { tier = "common", requestId = "poor" }),
        "Cannot overdraw"
    )
    assert(
        not arcade:action(41, "buyChest", { tier = "rare", requestId = "buyA" }),
        "Retry cannot change tier"
    )
    assert(
        not arcade:action(41, "openChest", { tier = "common", requestId = "buyA" }),
        "Retry cannot change action"
    )
    assert(arcade:action(41, "openChest", { tier = "common", requestId = "openA" }, 83))
    local unlocked = #a.profile.itemUnlocks
    local saved = arcade:capture(a)
    arcade:remove(41)
    a = arcade:add(41, "One", saved)
    assert(arcade:action(41, "buyChest", { tier = "common", requestId = "buyA" }))
    assert(
        a.profile.restockCredits == 0
            and a.profile.chests.common == 0
            and #a.profile.itemUnlocks == unlocked,
        "Reconnect replay cannot replenish a chest already opened"
    )
    assert(
        a.profile.lastOpened.kind == "purchase" and a.profile.lastOpened.restockCost == 100,
        "Replay retains purchase detail"
    )

    assert(arcade:action(41, "startRun", {}, 23))
    shot(1)
    assert(a.profile.restockCredits == 0, "A baseline win grants no extra currency")
    a.run.phase = "gameover"
    assert(arcade:action(41, "restart", {}, 24))
    shot(6)
    assert(a.profile.restockCredits == 5, "A new run may credit receipt one again")
    a.run.phase = "gameover"
    assert(arcade:action(41, "restart", {}, 25))
    shot(0)
    assert(a.profile.restockCredits == 5, "Failed shots neither award nor deduct wallet funds")

    local wealthy = Profile.clean({ restockCredits = 10000, chests = { common = 10000 } })
    assert(not Chests.buy(wealthy, "common", "full"), "Chest cap rejects purchase")
    assert(wealthy.restockCredits == 10000, "Full chest storage never charges")
    for _, tier in Chests.Tiers do
        wealthy.chests[tier.id] = 0
        local before = wealthy.restockCredits
        assert(Chests.buy(wealthy, tier.id, "tier" .. tier.id))
        assert(
            wealthy.restockCredits == before - tier.restockCost and wealthy.chests[tier.id] == 1,
            "Each tier charges its own price"
        )
    end
    for _, bad in { "unknown", "", 1 } do
        assert(not Chests.buy(wealthy, bad, "bad"), "Unknown tier is invalid")
    end
    assert(not Chests.buy(wealthy, "common", ""), "Empty request is invalid")
    assert(not Chests.buy(wealthy, "common", string.rep("x", 97)), "Oversized request is invalid")
    assert(arcade:action(41, "enterHub"))
    a.profile.restockCredits = 1000
    for _, status in { "locked", "unavailable" } do
        a.profileStatus = status
        assert(
            not arcade:action(41, "buyChest", { tier = "common", requestId = status }),
            "Unsafe storage rejects purchase"
        )
        assert(a.profile.restockCredits == 1000, "Unavailable saving blocks wallet spending")
    end
    print(
        "PASS restock market: settled extras, run/resume/reconnect dedupe, hub-only chosen tiers, atomic costs, storage caps and retry receipts"
    )
end
