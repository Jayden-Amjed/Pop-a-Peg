local Server = if script then game:GetService("ServerScriptService").Server else nil
local Shared = if script then game:GetService("ReplicatedStorage").Shared else nil
local Access = if Server
    then require(Server.PlaytestAccess)
    else require("../src/server/PlaytestAccess")
local Arcade = if Server
    then require(Server.ArcadeSessions)
    else require("../src/server/ArcadeSessions")
local Catalog = if Shared then require(Shared.Catalog) else require("../src/shared/Catalog")
local Profile = if Shared then require(Shared.Profile) else require("../src/shared/Profile")
local Run = if Shared then require(Shared.Run) else require("../src/shared/Run")
local Stages = if Shared then require(Shared.Stages) else require("../src/shared/Stages")

local function same(actual, expected, path)
    path = path or "profile"
    if type(expected) ~= "table" then
        assert(actual == expected, path .. " changed")
        return
    end
    assert(type(actual) == "table", path .. " is missing")
    for key, value in expected do
        same(actual[key], value, path .. "." .. tostring(key))
    end
    for key in actual do
        assert(expected[key] ~= nil, path .. " has unexpected " .. tostring(key))
    end
end

local function shop(run, id, price)
    run.phase = "shop"
    run.shopOffers = { { id = id, price = price, sold = false, frozen = false } }
end

return function()
    local owner = 583716264
    assert(Access.active(owner), "Requested account has temporary access")
    for _, id in { owner - 1, owner + 1, 1, -1, 0, tostring(owner), false } do
        assert(not Access.active(id), "Access must match the exact numeric account ID")
    end

    local original = Profile.clean({
        version = 2,
        bestScore = 12345,
        bestRound = 18,
        bestEndlessRound = 0,
        playSeconds = 110,
        robuxSpent = 7,
        itemUnlocks = { "gain_dial" },
        unlocks = { "level_1" },
        chests = { common = 1 },
        research = 20,
        restockCredits = 71,
    })
    local arcade = Arcade.new()
    local session = arcade:add(owner, "Owner", original)
    local ordinary = arcade:add(owner + 1, "bulkyamyed", original)
    local hub = arcade:snapshot(owner)
    assert(
        hub.temporaryAccess and not arcade:snapshot(owner + 1).temporaryAccess,
        "Hub access is account-specific"
    )
    assert(#hub.hub.profile.itemUnlocks == #Catalog.ItemIds, "All blueprint previews are available")
    for _, entry in hub.hub.chests.unlocks do
        assert(entry.owned, "Workshop matches effective equipment access")
    end
    for _, id in Catalog.EvolvedIds do
        assert(table.find(hub.hub.profile.unlocks, id), "Every evolution preview is visible")
    end
    assert(not table.find(hub.hub.profile.unlocks, "level_2"), "No fabricated level clear")
    assert(not table.find(hub.hub.profile.unlocks, "endless"), "No fabricated campaign win")
    assert(hub.hub.profile.bestRound == original.bestRound, "Real records stay truthful")
    same(session.profile, original)
    same(ordinary.profile, original)
    same(arcade:capture(session), original)

    assert(arcade:action(owner, "startRun", {}, 281))
    assert(arcade:action(owner + 1, "startRun", { userId = owner, temporaryAccess = true }, 281))
    local run = session.run
    assert(arcade:snapshot(owner).temporaryAccess, "Run declares temporary ownership")
    assert(run.round == 1 and run.slots == 4 and #run.perks == 0, "Run starts with normal power")
    assert(run.coins == Run.Config.startingCoins, "No test coins granted")
    assert(run.reserves == Run.Config.startingReserves, "No test balls granted")
    for _, id in Catalog.ItemIds do
        assert(run.itemUnlocks[id], "All base equipment enters the owner's shop pool")
    end
    assert(not ordinary.run.itemUnlocks.lagoon_synth, "Other users retain chest gates")
    assert(not arcade:action(owner, "endless"), "Endless still requires completing the run")
    same(arcade:capture(session), original)
    for _, round in { 1, 16, 41, 66, 101 } do
        run.round = round
        local snapshot = arcade:snapshot(owner)
        assert(
            snapshot.stage.index == Stages.forRound(round).index,
            "Every stage remains available normally"
        )
    end
    run.round = 1

    -- Exercise the actual purchase gate for every blueprint, with an ordinary
    -- player's equivalent locked offer kept blocked.
    for _, id in Catalog.ItemIds do
        local candidate = Run.new(281, Access.runProfile(owner, original))
        shop(candidate, id, 1)
        assert(candidate:action("buy", { offer = 1 }), "Owner can buy " .. id)
        assert(
            candidate.inventory[1].id == id and candidate.inventory[1].level == 1,
            "Purchased item starts at level 1"
        )
        assert(candidate.coins == Run.Config.startingCoins - 1, "Normal price is charged")
    end
    shop(ordinary.run, "lagoon_synth", 1)
    assert(not ordinary.run:action("buy", { offer = 1 }), "Wrong user cannot buy locked equipment")

    -- Discoverability does not grant level-5 parts or bypass the recipe itself.
    for _, recipe in Catalog.Evolutions do
        local candidate = Run.new(281, Access.runProfile(owner, original))
        candidate.inventory[1] = { id = recipe.ingredients[1], level = 4 }
        candidate.inventory[2] = { id = recipe.ingredients[2], level = 5 }
        shop(candidate, recipe.id, 0)
        assert(not candidate:action("buy", { offer = 1 }), "Low-level evolution stays blocked")
        candidate.inventory[1].level = 5
        assert(candidate:action("buy", { offer = 1 }), "All eligible evolution recipes work")
        assert(
            candidate.inventory[1].id == recipe.id and candidate.inventory[1].level == 5,
            "Evolution combines level-5 ingredients"
        )
    end

    -- Save/capture and pause/restart cannot turn the overlay into permanent
    -- ownership. A chest explicitly opened by the player still earns its item.
    run.phase = "aim"
    assert(arcade:action(owner, "enterHub"))
    same(session.profile, original)
    local researched =
        arcade:action(owner, "researchItem", { id = "lagoon_synth", requestId = "test-research" })
    assert(
        not researched and session.profile.research == original.research,
        "Do not charge for temporarily accessible equipment"
    )
    assert(
        arcade:action(
            owner,
            "openChest",
            { tier = "common", requestId = "owner-earned-chest" },
            281
        )
    )
    assert(
        #session.profile.itemUnlocks == #original.itemUnlocks + 1,
        "A real chest still earns a real unlock"
    )
    assert(
        session.profile.chests.common == 0 and session.profile.restockCredits == 71,
        "Only the requested chest is consumed"
    )
    local earned = Profile.clean(session.profile)
    assert(arcade:action(owner, "startRun"))
    assert(session.run == run, "Resume keeps the existing run")
    same(arcade:capture(session), earned)
    run.unlocks.spectrum_reef = true
    run.bestRound = 25
    run.bestScore = 15000
    local captured = arcade:capture(session)
    assert(table.find(captured.unlocks, "spectrum_reef"), "Actually earned discoveries persist")
    assert(captured.bestRound == 25 and captured.bestScore == 15000, "Actual run records persist")
    assert(#captured.itemUnlocks == #earned.itemUnlocks, "Temporary blueprints never save")
    run.phase = "gameover"
    assert(arcade:action(owner, "restart", {}, 282))
    assert(
        session.run.itemUnlocks.lagoon_synth and session.temporaryRunAccess,
        "Restart reapplies the policy"
    )

    -- Disable is intentionally a single server-owned switch. Existing temporary
    -- runs remain marked so a late save cannot leak ownership after the switch.
    local wasEnabled = Access.Enabled
    Access.Enabled = false
    local ok, failure = pcall(function()
        assert(not Access.active(owner), "Fresh playtest switch disables the policy")
        assert(
            #Access.runProfile(owner, captured).itemUnlocks == #captured.itemUnlocks,
            "Disable restores earned collection"
        )
        assert(
            not arcade:snapshot(owner + 1).temporaryAccess,
            "Other account remains unaffected by disable"
        )
        assert(
            #arcade:capture(session).itemUnlocks == #captured.itemUnlocks,
            "Late capture still filters temporary grants"
        )
        session.run.phase = "gameover"
        assert(arcade:action(owner, "restart", {}, 283))
        assert(
            not session.temporaryRunAccess and not session.run.itemUnlocks.lagoon_synth,
            "Next run uses real ownership"
        )
        assert(session.run.bestRound == 25, "Disabling does not reset earned records")
    end)
    Access.Enabled = wasEnabled
    assert(ok, failure)
    local removed = arcade:remove(owner)
    assert(
        #removed.profile.itemUnlocks == #captured.itemUnlocks,
        "Departure preserves the real collection"
    )
    same(ordinary.profile, original)
    print(
        "PASS temporary owner access: exact account, all equipment/evolutions, normal stages, real saves, disable and isolation"
    )
end
