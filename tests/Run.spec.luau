local function expect(condition, message)
    if not condition then
        error(message or "Run expectation failed", 2)
    end
end
local Shared = if script then game:GetService("ReplicatedStorage"):WaitForChild("Shared") else nil
local Run = if Shared then require(Shared.Run) else require("../src/shared/Run")
local Board = if Shared then require(Shared.Board) else require("../src/shared/Board")
local Catalog = if Shared then require(Shared.Catalog) else require("../src/shared/Catalog")

local function equal(actual, expected, message)
    expect(
        actual == expected,
        (message or "values differ") .. ": " .. tostring(actual) .. " ~= " .. tostring(expected)
    )
end

local function finishSettlement(run)
    for _ = 1, 400 do
        if run.phase ~= "flight" then
            return
        end
        run:step(1 / 30)
    end
    error("settlement did not complete")
end

local function finishRound(run, multiples)
    expect(run:action("launch", { angle = 0 }))
    -- Inject a deterministic score to isolate progression from collision physics.
    run:_addScore(run.quota * (multiples or 1))
    expect(run:action("endShot"))
    finishSettlement(run)
    equal(run.phase, "result")
end

local function sameValues(a, b)
    for index, value in ipairs(a) do
        equal(value, b[index], "peg " .. index)
    end
end

return function()
    local checks = 0
    local function test(callback)
        callback()
        checks += 1
    end

    test(function()
        local run = Run.new(41)
        equal(run.phase, "aim")
        equal(run.reserves, 5)
        equal(run.coins, 3)
        equal(#run.inventory, 4)
        for _, angle in ipairs({ math.huge, -math.huge, 0 / 0, 2, -2, "0" }) do
            expect(not run:action("launch", { angle = angle }))
        end
        expect(not run:action("launch", "invalid"))
        expect(not run:action("buy", { offer = 1 }))
        expect(not run:action("choosePerk", { index = 1 }))
        expect(not run:action("continue"))
        expect(not run:action("restart"))
        expect(not run:action("unknown"))
        expect(run:action("launch", { angle = 0.4 }))
        expect(not run:action("launch", { angle = 0 }))
        expect(not run:action("jumble"))
        expect(not run:action("move", { from = 1, to = 2 }))
    end)

    test(function()
        local run = Run.new(42)
        local potential = Board.potential(run.values)
        expect(run:action("jumble"))
        equal(Board.potential(run.values), potential)
        expect(not run:action("jumble"))
        local baseline = Board.copy(run.baseline)
        expect(run:action("launch", { angle = 0 }))
        run:_pop(1)
        run.score = 0
        expect(run:action("endShot"))
        equal(run.reserves, 4)
        expect(run:action("continue"))
        equal(run.round, 1)
        equal(run.score, 0)
        expect(run.canJumble)
        sameValues(run.values, baseline)
    end)

    test(function()
        local run = Run.new(43)
        run.reserves = 2
        local before = Board.copy(run.baseline)
        finishRound(run, 3)
        equal(run.restocks, 3)
        equal(run.coins, 6)
        equal(run.reserves, 4)
        equal(run.lastResult.success, true)
        expect(Board.potential(run.baseline) > Board.potential(before))
        expect(run:action("continue"))
        equal(run.round, 2)
        equal(run.score, 0)
        equal(run.phase, "aim")
        sameValues(run.values, run.baseline)
    end)

    test(function()
        local run = Run.new(44)
        run.inventory[1] = { id = "landing_fund", level = 1 }
        expect(run:action("launch", { angle = 0 }))
        expect(run:action("endShot"))
        equal(run.score, 0, "manual end must not trigger drain rewards")
        for _ = 1, 5 do
            expect(run:action("continue"))
            expect(run:action("launch", { angle = 0 }))
            expect(run:action("endShot"))
        end
        equal(run.phase, "gameover")
        expect(not run:action("continue"))
        expect(run:action("restart"))
        equal(run.round, 1)
        equal(run.reserves, 5)
        equal(run.coins, 3)
        equal(run.inventory[1].id, "")
        equal(#run.perks, 0)
        equal(run.bestRound, 1)
    end)

    test(function()
        local run = Run.new(45)
        run.coins = 100
        run:_openShop(false)
        run.shopOffers[1] = { id = "tap_driver", price = 4, sold = false, frozen = false }
        expect(not run:action("buy", { offer = 0 }))
        expect(not run:action("buy", { offer = 1.5 }))
        expect(run:action("buy", { offer = 1 }))
        equal(run.inventory[1].level, 1)
        equal(run.coins, 96)
        expect(not run:action("buy", { offer = 1 }))
        run.shopOffers[2] = { id = "tap_driver", price = 4, sold = false, frozen = false }
        expect(run:action("buy", { offer = 2 }))
        equal(run.inventory[1].level, 2)
        equal(run.inventory[2].id, "")
        expect(run:action("move", { from = 1, to = 4 }))
        equal(run.inventory[4].level, 2)
        expect(not run:action("sell", { slot = 1 }))
        expect(run:action("sell", { slot = 4 }))
        equal(run.inventory[4].id, "")
        for _ = 1, 3 do
            expect(run:action("buySlot"))
        end
        equal(run.slots, 7)
        equal(#run.shopOffers, 7)
        expect(not run:action("buySlot"))
        run.reserves = 1
        run.shopOffers[5] = { id = "reserve_pack", price = 8, sold = false, consumable = true }
        expect(run:action("buy", { offer = 5 }))
        equal(run.reserves, 3)
        equal(#run:_occupied(), 0)
        expect(not run:action("freeze", { offer = 5 }))
        run.coins = 0
        expect(not run:action("buy", { offer = 6 }))
    end)

    test(function()
        local run = Run.new(46)
        run.coins = 100
        run:_openShop(false)
        expect(run:action("freeze", { offer = 2 }))
        local id, price = run.shopOffers[2].id, run.shopOffers[2].price
        expect(run:action("reroll"))
        equal(run.shopOffers[2].id, id)
        equal(run.shopOffers[2].price, price)
        expect(run.shopOffers[2].frozen)
        expect(not run:action("reroll"))
        expect(run:action("continue"))
        run:_openShop(false)
        equal(run.shopOffers[2].id, id)
        expect(run:action("freeze", { offer = 2 }))
        expect(not run.shopOffers[2].frozen)
    end)

    test(function()
        local run = Run.new(47)
        for slot = 1, 4 do
            run.inventory[slot] = { id = "tap_driver", level = 2 }
        end
        run.coins = 100
        run:_openShop(false)
        run.shopOffers[1] = { id = "wall_meter", price = 4, sold = false }
        expect(not run:action("buy", { offer = 1 }))
        equal(run.coins, 100)
        run.inventory[1].level = 1
        run.inventory[2].level = 1
        expect(run:action("move", { from = 1, to = 2 }))
        equal(run.inventory[2].level, 2)
        equal(run.inventory[1].id, "")
    end)

    test(function()
        local run = Run.new(48)
        run.round = 5
        run:_resetShot()
        finishRound(run)
        expect(run.unlocks.workshop_access)
        expect(run:action("continue"))
        equal(run.phase, "shop")
        equal(run.shopsVisited, 1)
        expect(run:action("continue"))
        run.round = 7
        run:_resetShot()
        finishRound(run)
        expect(run:action("continue"))
        equal(run.phase, "event")
        expect(not run:action("chooseEvent", { index = 3 }))
        expect(run:action("chooseEvent", { index = 1 }))
        equal(run.phase, "aim")
        run.round = 9
        run:_resetShot()
        finishRound(run)
        expect(run:action("continue"))
        equal(run.phase, "perk")
        equal(#run.perkOffers, 2)
        expect(run.perkOffers[1] ~= run.perkOffers[2])
        expect(not run:action("continue"))
        expect(run:action("choosePerk", { index = 2 }))
        equal(#run.perks, 1)
        equal(run.phase, "aim")
    end)

    test(function()
        local run = Run.new(49)
        run.inventory[1] = { id = "split_prism", level = 1 }
        run.inventory[2] = { id = "resonator", level = 1 }
        run.perks = { "first_spark", "growth_ring" }
        for index = 1, #run.values do
            run.values[index] = 64
        end
        expect(run:action("launch", { angle = 0 }))
        run:_pop(1)
        run:_processQueue()
        expect(run.doubles >= 1, "first-hit perk must activate the doubling item")
        run:_double(2)
        run:_double(3)
        local before = run.pops
        run:_processQueue()
        expect(run.pops > before, "double threshold must trigger a pop")
        expect(run.score > 0)
    end)

    test(function()
        local run = Run.new(50)
        run.inventory[1] = { id = "landing_fund", level = 2 }
        run.perks = { "first_spark" }
        for index = 1, #run.values do
            run.values[index] = 0
        end
        run.values[1] = 1
        run.quota = 1
        expect(run:action("launch", { angle = 0 }))
        run:_pop(1)
        finishSettlement(run)
        equal(run.score, 2, "clear doubles score before pending rewards")
        equal(run.lastResult.reason, "clear")
        expect(run.clearBonus)
        equal(#run.queue, 0)
    end)

    test(function()
        local run = Run.new(51)
        run.inventory[1] = { id = "echo_plate", level = 1 }
        run.inventory[2] = { id = "relay", level = 1 }
        -- An intentionally cyclic arrangement keeps work pending, but each frame is bounded.
        run.inventory[1], run.inventory[2] = run.inventory[2], run.inventory[1]
        expect(run:action("launch", { angle = 0 }))
        run:_queue("item", 1)
        run:_processQueue()
        expect(#run.queue > 0)
        expect(#run.queue <= 2)
        expect(run:action("endShot"))
        equal(#run.queue, 0)
    end)

    test(function()
        local run = Run.new(52)
        run.round = 80
        run:_resetShot()
        finishRound(run)
        expect(run:action("continue"))
        equal(run.phase, "victory")
        expect(run.unlocks.endless)
        expect(run.unlocks.relay_kit)
        local profile = run:profile()
        equal(profile.bestRound, 80)
        expect(type(profile.unlocks[1]) == "string")
        expect(run:action("endless"))
        equal(run.phase, "aim")
        equal(run.round, 81)
        expect(not run:action("endless"))
        local restored = Run.new(53, profile)
        equal(restored.bestRound, 80)
        expect(restored.unlocks.relay_kit)
        equal(restored.coins, 3)
        equal(restored.inventory[1].id, "")
        local snapshot = restored:snapshot()
        snapshot.inventory[1].id = "forged"
        snapshot.values[1] = -1
        equal(restored.inventory[1].id, "")
        expect(restored.values[1] >= 0)
    end)

    test(function()
        local run = Run.new(54)
        expect(not run:action("speed", { value = 0 / 0 }))
        expect(not run:action("speed", { value = 3 }))
        expect(run:action("speed", { value = 4 }))
        equal(run:snapshot().speed, 4)
        expect(run:action("launch", { angle = 0 }))
        run:step(1 / 60)
        expect(math.abs(run.elapsed - 4 / 60) < 1e-6)
        run:_addScore(1e99)
        expect(run:action("endShot"))
        expect(run.settlement ~= nil, "large restock work must be spread over frames")
        finishSettlement(run)
        equal(run.restocks, Run.Config.maxRestocks)
        expect(run.score < math.huge and run.quota < math.huge)
    end)

    test(function()
        local run = Run.new(55)
        for _ = 1, 100 do
            local id = run:_drawItem()
            expect(not Catalog.Items[id].unlock, "locked equipment must not enter offers")
        end
        run.inventory[1] = { id = "landing_fund", level = 1 }
        expect(run:action("launch", { angle = 0 }))
        run.ball.active = false
        run:_signal("drain")
        run:step(1 / 60)
        finishSettlement(run)
        equal(run.score, 150)
        equal(run.lastResult.reason, "drain")
        expect(#run.events <= 32)
    end)

    return checks
end
