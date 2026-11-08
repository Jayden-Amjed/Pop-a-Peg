local Shared = if script then game:GetService("ReplicatedStorage").Shared else nil
local Profile = if Shared then require(Shared.Profile) else require("../src/shared/Profile")
local Chests = if Shared
    then require(Shared.ChestProgression)
    else require("../src/shared/ChestProgression")
local Lease = if Shared then require(Shared.ProfileLease) else require("../src/shared/ProfileLease")
local Boards = if Shared
    then require(Shared.Leaderboards)
    else require("../src/shared/Leaderboards")
local Catalog = if Shared then require(Shared.Catalog) else require("../src/shared/Catalog")
local ArcadeSessions = if script
    then require(game:GetService("ServerScriptService").Server.ArcadeSessions)
    else require("../src/server/ArcadeSessions")

return function()
    local migrated = Profile.clean({
        unlocks = { "goldfish", "growth_kit", "relay_kit", "workshop_access", "level_1" },
        bestRound = 40,
        coins = 100,
    })
    for _, id in { "goldfish", "growth_array", "fishbowl", "echo_plate", "encore", "gain_dial" } do
        assert(table.find(migrated.itemUnlocks, id), "Legacy owned access migrates: " .. id)
    end
    assert(
        migrated.bestRound == 40 and migrated.coins == nil and migrated.version == 2,
        "Migration preserves records, not run coins"
    )
    local current = Profile.clean({ version = 2, unlocks = { "growth_kit" } })
    assert(
        not table.find(current.itemUnlocks, "growth_array"),
        "Current achievements do not bypass chest gating"
    )
    current = Profile.merge(
        current,
        { unlocks = { "growth_kit" }, chests = { common = 900 }, research = 900, playSeconds = 900 }
    )
    assert(
        not table.find(current.itemUnlocks, "growth_array")
            and current.chests.common == 0
            and current.research == 0
            and current.playSeconds == 0,
        "Run capture cannot import balances or create ownership from tokens"
    )
    assert(
        Profile.clean({ chests = { common = -1, rare = 0 / 0 }, playSeconds = math.huge }).chests.rare
            == 0,
        "Invalid counters clean to zero"
    )

    local p = Profile.clean(nil)
    local availableTier
    for _, tier in Chests.Tiers do
        if #Chests.pool(p, tier.id) > 0 then
            availableTier = tier.id
            break
        end
    end
    assert(availableTier, "A fresh profile has locked equipment")
    Chests.award(p, availableTier)
    local count = #p.itemUnlocks
    assert(Chests.open(p, availableTier, "first", 412))
    local firstId = p.lastOpened.itemId
    assert(
        firstId and #p.itemUnlocks == count + 1 and p.chests[availableTier] == 0,
        "Opening consumes exactly one chest and grants one unlock"
    )
    assert(
        Chests.tierFor(firstId) == availableTier and table.find(Catalog.ItemIds, firstId),
        "Chest grants base equipment of its exact tier"
    )
    assert(Chests.open(p, availableTier, "first", 999), "Retried response is idempotent")
    assert(#p.itemUnlocks == count + 1 and p.chestSerial == 1, "Replay preserves award serial")
    assert(not Chests.open(p, availableTier, "second", 2), "Cannot open absent chest")
    assert(not Chests.open(p, "invalid", "request", 2), "Unknown tier rejected")
    assert(not Chests.open(p, availableTier, {}, 2), "Malformed request rejected")
    local snapshot = Chests.snapshot(p)
    snapshot.tiers[1].count = 999
    assert(p.chests.common ~= 999, "UI snapshot is a copy")

    p = Profile.clean({ version = 2, itemUnlocks = Catalog.ItemIds, chests = { legendary = 2 } })
    assert(Chests.open(p, "legendary", "complete", 1))
    assert(
        p.research == 10 and p.lastOpened.allCollected and p.lastOpened.itemId == nil,
        "Completed tier converts to research"
    )
    local stored = Profile.clean(p)
    assert(
        stored.chests.legendary == 1 and stored.lastOpened.requestId == "complete",
        "Cleaning preserves consumption receipt"
    )
    assert(Chests.open(stored, "legendary", "later", 3))
    local serialAfterB, researchAfterB = stored.chestSerial, stored.research
    stored = Profile.clean(stored) -- Reconnect after request B.
    assert(Chests.open(stored, "legendary", "complete", 4))
    assert(
        stored.chests.legendary == 0
            and stored.chestSerial == serialAfterB
            and stored.research == researchAfterB,
        "A/B/reconnect/replayA cannot consume another chest"
    )
    assert(
        stored.lastOpened.requestId == "complete" and stored.lastOpened.serial == 1,
        "Replay acknowledges the original result without increasing serial"
    )
    assert(
        not Chests.open(stored, "common", "complete", 5),
        "Request ID cannot be rebound to another chest tier"
    )
    assert(
        not Chests.research(stored, Catalog.ItemIds[1], "complete"),
        "Request ID cannot be rebound to another operation"
    )
    stored = Profile.clean(stored)
    assert(
        #stored.chestReceipts == 2 and stored.chestSerial == serialAfterB,
        "Receipt ledger survives sanitization and older acknowledgement"
    )
    local many = {}
    for index = 1, 70 do
        table.insert(many, {
            serial = index,
            requestId = "id" .. index,
            tier = "common",
            kind = "chest",
            research = 1,
        })
    end
    local bounded = Profile.clean({ version = 2, chestReceipts = many })
    assert(
        #bounded.chestReceipts == 64 and bounded.chestReceipts[1].requestId == "id7",
        "Persistent retry history is bounded to newest64"
    )
    local invalidReceipts = Profile.clean({
        chestReceipts = {
            { requestId = string.rep("x", 97), tier = "common" },
            { requestId = "a", tier = "fake" },
            { requestId = "b", tier = "common", kind = "research", itemId = "fake" },
        },
    })
    assert(
        #invalidReceipts.chestReceipts == 0,
        "Invalid receipts are rejected instead of truncating IDs"
    )
    stored.chests.legendary = 1
    assert(
        Chests.open(stored, "legendary", "complete", 2) and stored.chests.legendary == 1,
        "Reconnect retry cannot consume again"
    )
    local owned = Profile.clean(nil)
    local target
    for _, id in Catalog.ItemIds do
        if not table.find(owned.itemUnlocks, id) then
            target = id
            break
        end
    end
    assert(not Chests.research(owned, target, "poor"), "Insufficient research rejected")
    owned.research = 100
    local cost
    for _, info in Chests.snapshot(owned).unlocks do
        if info.id == target then
            cost = info.cost
        end
    end
    assert(
        Chests.research(owned, target, "research") and owned.research == 100 - cost,
        "Research buys selected blueprint"
    )
    assert(
        Chests.research(owned, target, "research") and owned.research == 100 - cost,
        "Research retry cannot charge twice"
    )
    assert(not Chests.research(owned, target, "repeat"), "Already owned cannot consume research")

    local arcade = ArcadeSessions.new()
    local a = arcade:add(1, "One")
    local b = arcade:add(2, "Two")
    assert(arcade:action(1, "startRun", {}, 17))
    a.run.highestClearedRound = 2
    a.run.phase = "gameover"
    arcade:capture(a)
    assert(a.profile.chests.common == 0, "Early losses do not farm chests")
    assert(arcade:action(1, "restart", {}, 18))
    assert(
        a.runId == 2 and not a.terminalRewarded,
        "Restart resets reward eligibility and run identity"
    )
    a.run.highestClearedRound = 3
    a.run.phase = "gameover"
    for _ = 1, 10 do
        arcade:capture(a)
    end
    assert(a.profile.chests.common == 1, "Terminal reward once per run")
    assert(
        not arcade:action(1, "openChest", { tier = "common", requestId = "notHub" }, 1),
        "Chest opening is hub only"
    )
    assert(arcade:action(1, "enterHub"))
    assert(arcade:action(1, "openChest", { tier = "common", requestId = "open" }, 1))
    assert(arcade:action(1, "openChest", { tier = "common", requestId = "open" }, 2))
    assert(
        a.profile.chests.common == 0 and b.profile.chests.common == 0,
        "One player opening cannot alter another inventory"
    )
    assert(arcade:action(1, "startRun", {}, 19))
    a.run.highestClearedRound = 100
    a.run.phase = "victory"
    arcade:capture(a)
    assert(
        a.profile.chests.uncommon == 1
            and a.profile.chests.rare == 2
            and a.profile.chests.legendary == 1,
        "Each completed campaign milestone awards its tier once"
    )
    arcade:capture(a)
    assert(a.profile.chests.legendary == 1, "Paused victory does not repeat milestone reward")
    a.run.highestClearedRound = 200
    a.run.endlessMode = true
    arcade:capture(a)
    assert(a.profile.chests.legendary == 3, "Every completed Endless50 grants once")
    arcade:capture(a)
    assert(a.profile.chests.legendary == 3, "Repeated Endless capture does not duplicate chests")
    for _ = 1, 10 do
        arcade:step(0.1, 0.25)
    end
    assert(
        a.profile.playSeconds == 2 and b.profile.playSeconds == 2,
        "Real elapsed time includes hub and run; fractions retained"
    )
    arcade:step(0.1, 0.5)
    assert(a.profile.playSeconds == 3, "Fractional time carries to next whole second")
    a.profileStatus = "unavailable"
    assert(arcade:action(1, "enterHub"))
    assert(
        not arcade:action(1, "openChest", { tier = "legendary", requestId = "unsafe" }, 1),
        "Unavailable save blocks further spending"
    )

    local locked = Lease.acquire({ chests = { common = 2 } }, "serverA", 1000)
    assert(
        locked and not Lease.acquire(locked, "serverB", 1001),
        "Active lease excludes second server"
    )
    local consumed = Profile.clean(locked)
    consumed.chests.common = 0
    locked = Lease.write(locked, consumed, "serverA", 1010, false)
    assert(locked.chests.common == 0, "Consumed balances replace, never max-merge")
    locked = Lease.write(locked, consumed, "serverA", 1011, false)
    assert(locked.chests.common == 0, "Ambiguous successful write retry is idempotent")
    local takeover = Lease.acquire(locked, "serverB", 1300)
    assert(
        takeover and not Lease.write(takeover, { chests = { common = 2 } }, "serverA", 1301, false),
        "Stale owner cannot resurrect balances"
    )
    local released = Lease.write(takeover, consumed, "serverB", 1302, true)
    assert(
        released._session == nil and Lease.acquire(released, "serverC", 1303),
        "Release permits immediate rejoin"
    )
    assert(
        not Lease.write(nil, Profile.clean(nil), "notLoaded", 1304, false),
        "Failed/default load never writes real data"
    )

    local entries = {}
    for i = 1, 13 do
        table.insert(entries, { userId = i, name = tostring(i), value = i })
    end
    local rank = Boards.rank(entries)
    assert(
        #rank == 10 and rank[1].value == 13 and rank[10].value == 4,
        "Leaderboards show descending top ten"
    )
    local boards = Boards.session(arcade.players)
    assert(
        boards.mode == "session"
            and #boards.categories.time.entries == 2
            and #boards.categories.robux.entries == 0,
        "Session time board is explicit and no spending is invented"
    )
    assert(
        #boards.categories.endless.entries == 0,
        "Campaign best does not masquerade as Endless record"
    )
    print(
        "PASS hub progression: migration, tier unlocks/research, idempotent chest actions, run awards, play clock, lease races and leaderboard separation"
    )
end
