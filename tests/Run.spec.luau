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
        for _ = 1, 4 do
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
        equal(#run.shopOffers, 4, "Slot expansion must not unlock early supplies")
        expect(not run:action("buySlot"))
        run.round = Run.Config.suppliesRound
        run:_openShop(false)
        equal(#run.shopOffers, 6)
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
        -- Direct relay chains retain their depth even when activations coalesce.
        run.inventory[1], run.inventory[2] = run.inventory[2], run.inventory[1]
        expect(run:action("launch", { angle = 0 }))
        run:_queue("item", 1)
        run:_processQueue()
        equal(#run.queue, 0, "A relay pair must finish its direct activation chain")
        equal(run.itemTriggers, run.slots)
        run:_signal("pop", 26)
        for _ = 1, 20 do
            run:_processQueue()
        end
        equal(#run.queue, 0, "Fresh natural triggers may activate another finite chain")
        expect(run.itemTriggers > run.slots)
        expect(run:action("endShot"))
        equal(#run.queue, 0)
    end)

    test(function()
        local run = Run.new(52)
        run.round = 100
        run:_resetShot()
        finishRound(run)
        expect(run:action("continue"))
        equal(run.phase, "victory")
        expect(run.unlocks.endless)
        expect(run.unlocks.relay_kit)
        local profile = run:profile()
        equal(profile.bestRound, 100)
        expect(type(profile.unlocks[1]) == "string")
        expect(run:action("endless"))
        equal(run.phase, "aim")
        equal(run.round, 101)
        expect(not run:action("endless"))
        local restored = Run.new(53, profile)
        equal(restored.bestRound, 100)
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
        expect(#run.events <= Run.Config.eventHistory)
    end)

    test(function()
        local run = Run.new(80)
        for remaining = 4, 0, -1 do
            expect(run:action("launch", { angle = 0 }))
            equal(run.reserves, remaining, "Launch must consume one of five total balls")
            expect(run:action("endShot"))
            if remaining > 0 then
                equal(run.phase, "result")
                expect(run:action("continue"))
            end
        end
        equal(run.phase, "gameover")
        equal(run.reserves, 0)
        expect(not run:action("launch", { angle = 0 }))
        expect(run:action("restart"))
        run.reserves = 1
        expect(run:action("launch", { angle = 0 }))
        equal(run.reserves, 0)
        run:_addScore(run.quota)
        equal(run.coins, 3, "Goal crossings must not pay out before the shot settles")
        expect(run:action("endShot"))
        equal(run.phase, "result", "Last ball may earn its replacement")
        equal(run.reserves, 1)
        equal(run.coins, 4)
        expect(not run:action("endShot"))
        equal(run.reserves, 1)
        equal(run.coins, 4)
    end)

    test(function()
        for _, count in ipairs({ 1, 3, 8, 9, 10000 }) do
            local run = Run.new(100 + count)
            local original = Board.copy(run.baseline)
            expect(run:action("launch", { angle = 0 }))
            run:_pop(1)
            local shot = Board.copy(run.values)
            run:_addScore(run.quota * count - run.score)
            expect(run:action("endShot"))
            if count > Run.Config.restocksPerStep then
                equal(run.settlementReceipt, nil, "Partial receipt must not be published")
            end
            finishSettlement(run)
            local receipt = run:snapshot().settlementReceipt
            equal(receipt.earnedRestocks, count)
            equal(receipt.round, 1)
            equal(receipt.coinsBefore, 3)
            equal(receipt.coinsAfter, 3 + count)
            equal(receipt.reservesBefore, 4)
            equal(receipt.reservesAfter, 5)
            sameValues(receipt.shotValues, shot)
            sameValues(receipt.restoredValues, original)
            equal(#receipt.cycles, if count <= 8 then count else 5)
            local replay = Board.copy(receipt.restoredValues)
            local previous = 0
            for _, cycle in ipairs(receipt.cycles) do
                if cycle.index > previous + 1 then
                    replay = Board.copy(cycle.beforeValues)
                end
                sameValues(replay, cycle.beforeValues)
                for _, refill in ipairs(cycle.refills) do
                    equal(replay[refill.to], 0, "Refill must target an empty slot")
                    replay[refill.to] = refill.value
                end
                for _, merge in ipairs(cycle.merges) do
                    equal(replay[merge.from], replay[merge.to], "Merge values must match")
                    replay[merge.from] = 0
                    replay[merge.to] = merge.value
                end
                sameValues(replay, cycle.afterValues)
                previous = cycle.index
            end
            equal(previous, count)
            sameValues(replay, receipt.finalValues)
            sameValues(replay, run.baseline)
            receipt.finalValues[1] = -100
            expect(run.settlementReceipt.finalValues[1] >= 0, "Snapshot mutated the receipt")
            expect(run:action("continue"))
            equal(run.settlementReceipt, nil, "Starting the next shot must clear the prior receipt")
        end
    end)

    test(function()
        local run = Run.new(81)
        run.reserves = 1
        expect(run:action("launch", { angle = 0 }))
        expect(run:action("endShot"))
        local firstId = run.settlementReceipt.id
        local firstEvent = run.eventSerial
        equal(#run.settlementReceipt.cycles, 0)
        sameValues(run.settlementReceipt.finalValues, run.baseline)
        expect(run:action("restart"))
        expect(run.eventSerial > firstEvent)
        equal(run.settlementReceipt, nil)
        finishRound(run, 2)
        equal(run.settlementReceipt.id, firstId + 1)
        for _ = 1, Run.Config.eventHistory + 10 do
            run:_event("trigger", { text = "test" })
        end
        equal(#run.events, Run.Config.eventHistory)
        equal(
            run:snapshot().settlementReceipt.id,
            firstId + 1,
            "Receipt must survive event-history eviction"
        )
    end)

    test(function()
        local run = Run.new(82)
        expect(run:action("launch", { angle = 0 }))
        run:_addScore(run.quota * 2, { slot = 2 })
        local scoreEvent, goalEvent, launchEvent
        for _, event in ipairs(run.events) do
            if event.kind == "score" then
                scoreEvent = event
            elseif event.kind == "goal" then
                goalEvent = event
            elseif event.kind == "life" then
                launchEvent = event
            end
        end
        equal(scoreEvent.slot, 2)
        equal(scoreEvent.fromScore, 0)
        equal(scoreEvent.toScore, run.quota * 2)
        equal(goalEvent.from, 0)
        equal(goalEvent.to, 2)
        equal(goalEvent.count, 2)
        equal(launchEvent.amount, -1)
        equal(launchEvent.balance, 4)
        equal(launchEvent.reason, "launch")
        expect(run:action("endShot"))
        local paid = 0
        for _, event in ipairs(run.events) do
            if event.kind == "coins" and event.reason == "restock" then
                paid += event.amount
            end
        end
        equal(paid, 2)
    end)

    test(function()
        local run = Run.new(201)
        run.coins = 100
        run.round = Run.Config.suppliesRound - 1
        run:_openShop(false)
        equal(#run.shopOffers, 4)
        for _ = 1, 3 do
            expect(run:action("buySlot"))
        end
        equal(#run.shopOffers, 4)
        run.shopOffers[5] = { id = "reserve_pack", price = 8, sold = false }
        local before = run.coins
        expect(not run:action("buy", { offer = 5 }), "A stale early supply offer must be rejected")
        equal(run.coins, before)
        expect(not run.shopOffers[5].sold)
        run:_rollShop()
        equal(#run.shopOffers, 4, "Early shop roll must remove stale supplies")

        local later = Run.new(202)
        later.round, later.coins = Run.Config.suppliesRound, 100
        later:_openShop(false)
        equal(later.slots, 4)
        equal(#later.shopOffers, 6, "Supplies depend on round, not rack size")
        expect(later.shopOffers[5].consumable and later.shopOffers[6].consumable)
        expect(not later:action("buy", { offer = 7 }))
        expect(not later:action("freeze", { offer = 5 }))
        later.shopOffers[5] = { id = "reserve_pack", price = 8, sold = false, consumable = true }
        later.reserves = 1
        expect(later:action("buy", { offer = 5 }))
        equal(later.reserves, 3)
        equal(#later:_occupied(), 0)
        local purchased, other = later.shopOffers[5], later.shopOffers[6]
        for _ = 1, 3 do
            expect(later:action("buySlot"))
            equal(later.shopOffers[5], purchased, "Slot purchase refreshed supplies")
            equal(later.shopOffers[6], other)
            expect(later.shopOffers[5].sold)
        end
        expect(not later:action("buy", { offer = 5 }))
        expect(later:action("reroll"))
        equal(#later.shopOffers, 6)
        expect(not later:action("reroll"))
    end)

    test(function()
        local run = Run.new(203)
        for _, phase in ipairs({ "aim", "flight", "result", "shop", "event", "gameover", "victory" }) do
            run.phase = phase
            expect(not run:action("skipPerk"), "Perk skip accepted outside the perk phase")
            equal(run.coins, Run.Config.startingCoins)
        end
        run.round = 9
        run:_resetShot()
        finishRound(run)
        expect(run:action("continue"))
        equal(run.phase, "perk")
        equal(run:snapshot().perkSkipCoins, 5)
        expect(not run:action("skipPerk", "invalid"))
        local before = run.coins
        expect(run:action("skipPerk"))
        equal(run.coins, before + 5)
        equal(#run.perks, 0)
        equal(#run.perkOffers, 0)
        equal(run.phase, "aim")
        equal(run:snapshot().perkSkipCoins, 0)
        expect(not run:action("skipPerk"))
        expect(not run:action("choosePerk", { index = 1 }))
        equal(run.coins, before + 5)
        local found = false
        for _, event in ipairs(run.events) do
            if event.kind == "perkChoice" then
                equal(event.action, "coins")
                equal(event.amount, 5)
                found = true
            end
        end
        expect(found)
    end)

    test(function()
        local run = Run.new(204)
        run.slots, run.coins = 7, 100
        for slot = 1, 7 do
            run.inventory[slot] = { id = Catalog.ItemIds[slot], level = 1 }
        end
        run.inventory[3] = { id = "seed_bank", level = Catalog.MaxLevel - 1 }
        run:_openShop(false)
        local function offer()
            run.shopOffers[1] = { id = "seed_bank", price = 5, sold = false }
            return Catalog.purchaseState(run.inventory, run.slots, run.shopOffers[1], run.coins)
        end
        local intent = offer()
        equal(intent.action, "upgrade")
        equal(intent.slot, 3)
        expect(intent.allowed)
        expect(run:action("buy", { offer = 1 }))
        equal(run.inventory[3].level, Catalog.MaxLevel)
        equal(#run:_occupied(), 7)
        equal(run.coins, 95)
        equal(offer().action, "maxLevel")
        local before, serial = run.coins, run.eventSerial
        local ok, message = run:action("buy", { offer = 1 })
        expect(not ok and string.find(message, "max level", 1, true))
        equal(run.coins, before)
        equal(run.eventSerial, serial, "Rejected purchase emitted feedback")
        expect(not run.shopOffers[1].sold)
        run.inventory[7] = { id = "", level = 0 }
        equal(offer().action, "maxLevel", "Free capacity must not allow another capped copy")
        expect(not run:action("buy", { offer = 1 }))
        run.inventory[6] = { id = "seed_bank", level = 1 }
        intent = offer()
        equal(intent.action, "upgrade")
        equal(intent.slot, 6, "A basic copy takes precedence over a capped copy")
        expect(run:action("buy", { offer = 1 }))
        equal(run.inventory[6].level, 2)
        equal(run.inventory[7].id, "")
        equal(
            Catalog.purchaseState(run.inventory, run.slots, run.shopOffers[1], run.coins).action,
            "sold"
        )
        run.shopOffers[1] = { id = "goldfish", price = 6, sold = false }
        intent = Catalog.purchaseState(run.inventory, run.slots, run.shopOffers[1], 0)
        equal(intent.action, "purchase")
        equal(intent.reason, "coins")
        expect(not intent.allowed)
        run.inventory[7] = { id = "compass", level = 1 }
        equal(
            Catalog.purchaseState(run.inventory, run.slots, run.shopOffers[1], 100).action,
            "full"
        )
        local upgrades = 0
        for _, event in ipairs(run.events) do
            if event.kind == "purchase" then
                equal(event.itemId, "seed_bank")
                equal(event.action, "upgrade")
                upgrades += 1
            end
        end
        equal(upgrades, 2)
    end)

    test(function()
        local run = Run.new(205)
        run.round = 5
        run:_resetShot()
        run.inventory[1] = { id = "goldfish", level = 1 }
        run.inventory[2] = { id = "soft_saw", level = 1 }
        run.perks = { "first_spark" }
        for id = 1, #run.values do
            run.values[id] = 64
        end
        expect(run:action("launch", { angle = 0 }))
        run:_pop(1)
        run:_processQueue()
        run:_activateItem(2)
        run.wallHits = 2
        run.elapsed = 3.5
        run:_signal("drain")
        run:_addScore(run.quota * 2)
        expect(run:action("endShot"))
        finishSettlement(run)
        local state = run:snapshot()
        local stats = state.lastShotStats
        equal(stats.shotId, 1)
        equal(stats.round, 5)
        equal(stats.pops, 2)
        equal(stats.walls, 2)
        equal(stats.doubles, 1)
        equal(stats.halves, 2)
        equal(stats.first, 1)
        equal(stats.drain, 1)
        equal(stats.clear, 0)
        equal(stats.time, 3.5)
        equal(stats.itemTriggers, 2)
        equal(stats.perkTriggers, 1)
        equal(stats.quotas, run.restocks)
        equal(state.settlementReceipt.stats.itemTriggers, stats.itemTriggers)
        expect(run:action("continue"))
        equal(run.phase, "shop")
        equal(run:snapshot().lastShotStats.round, 5)
        expect(run:action("continue"))
        equal(run.phase, "aim")
        equal(run:snapshot().shotStats.pops, 0)
        equal(run:snapshot().lastShotStats.pops, 2, "Auto-aim discarded the last shot counters")
        expect(run:action("jumble"))
        equal(run:snapshot().lastShotStats.pops, 2)
        stats.pops = -100
        equal(run.lastShotStats.pops, 2, "Stats snapshot was not isolated")
        expect(run:action("launch", { angle = 0 }))
        equal(run:snapshot().lastShotStats, nil)
        equal(run:snapshot().shotStats.shotId, 2)
    end)

    test(function()
        local run = Run.new(206)
        for id = 1, #run.values do
            run.values[id] = 64
        end
        run.inventory[1] = { id = "goldfish", level = 1 }
        run.inventory[2] = { id = "soft_saw", level = 1 }
        run.inventory[3] = { id = "tap_driver", level = 1 }
        expect(run:action("launch", { angle = 0 }))
        for slot = 1, 3 do
            run:_activateItem(slot)
        end
        local actions = {}
        for _, event in ipairs(run.events) do
            if event.kind == "trigger" and event.targetPegId then
                equal(event.slot, event.sourceSlot)
                equal(event.pegId, event.targetPegId)
                equal(event.itemId, run.inventory[event.slot].id)
                equal(event.effect, Catalog.Items[event.itemId].effect)
                expect(event.old > 0 and event.new >= 0)
                actions[event.action] = true
            end
        end
        expect(
            actions.double and actions.halve and actions.pop,
            "Targeted trigger metadata incomplete"
        )
        for _, id in ipairs(Catalog.ItemIds) do
            local definition = Catalog.Items[id]
            expect(type(definition.family) == "string" and #Catalog.evolutionsFor(id) > 0)
        end
        equal(Catalog.Items.fishbowl.unlock, "growth_kit")
        expect(Catalog.Items.fishbowl.price > Catalog.Items.resonator.price)
    end)

    test(function()
        local function harvest(fish, bowl, level)
            local run = Run.new(207)
            run.quota = 100000
            for id = 1, #run.values do
                run.values[id] = 2
            end
            run.values[21] = 64
            if fish then
                run.inventory[1] = { id = "goldfish", level = level }
            end
            if bowl then
                run.inventory[2] = { id = "fishbowl", level = level }
            end
            expect(run:action("launch", { angle = 0 }))
            -- Eighteen low-value hits feed growth while a high-value peg remains available.
            for id = 1, 18 do
                run:_pop(id)
                for _ = 1, 20 do
                    local before = run.itemTriggers
                    run:_processQueue()
                    expect(run.itemTriggers - before <= Run.Config.effectsPerStep)
                    if #run.queue == 0 then
                        break
                    end
                end
                equal(#run.queue, 0, "Fish feedback chain did not converge")
            end
            return run
        end
        for level = 1, Catalog.MaxLevel do
            local fish = harvest(true, false, level)
            local bowl = harvest(false, true, level)
            local pair = harvest(true, true, level)
            expect(
                pair.score > math.max(fish.score, bowl.score) * 2,
                "Grow-and-harvest pair should beat either isolated item in this fixture"
            )
            expect(pair.pops > fish.pops and pair.doubles > bowl.doubles)
            expect(pair.itemTriggers > fish.itemTriggers)
            if level == 1 then
                equal(fish.score, 36)
                equal(bowl.score, 36)
                equal(pair.score, 100)
            end
        end
        local capped = Run.new(208)
        capped.inventory[1] = { id = "goldfish", level = Catalog.MaxLevel }
        capped.inventory[2] = { id = "fishbowl", level = Catalog.MaxLevel }
        for id = 1, #capped.values do
            capped.values[id] = Run.Config.maxPeg
        end
        expect(capped:action("launch", { angle = 0 }))
        capped:_signal("pop", 600)
        for _ = 1, 100 do
            capped:_processQueue()
            if #capped.queue == 0 then
                break
            end
        end
        equal(#capped.queue, 0)
        equal(capped.doubles, 0, "Capped pegs must not emit false doubles")
        equal(capped.pops, 0, "Fishbowl must not harvest from a nonexistent double")
        for _, value in ipairs(capped.values) do
            expect(value == Run.Config.maxPeg and value < math.huge)
        end
    end)

    test(function()
        local run = Run.new(209)
        run.inventory[1] = { id = "relay", level = 1 }
        run.inventory[2] = { id = "echo_plate", level = 1 }
        expect(run:action("launch", { angle = 0 }))
        run:_queue("item", 1, 3)
        run:_queue("item", 1, 2, run.slots - 1)
        for _ = 1, 20 do
            run:_processQueue()
            if #run.queue == 0 then
                break
            end
        end
        equal(
            run.itemTriggers,
            3 * run.slots + 2,
            "Queue coalescing renewed an exhausted relay depth"
        )
        equal(#run.queue, 0)
        run.ball.active = false
        run:step(1 / 60)
        equal(run.phase, "result", "A completed relay chain must allow natural shot settlement")
    end)

    test(function()
        for level = 1, Catalog.MaxLevel do
            local run = Run.new(210)
            run.quota = 100000
            for id = 1, #run.values do
                run.values[id] = 64
            end
            run.values[1] = 128
            run.inventory[1] = { id = "gain_dial", level = level }
            expect(run:action("launch", { angle = 0 }))
            run:_addScore(1000)
            local before = run.eventSerial
            run:_activateItem(1)
            equal(run.score, 1000 + 150 * level)
            equal(run.values[1], 64, "Score growth must pay its highest-peg cost exactly once")
            equal(run.halves, 1)
            local order = {}
            for _, event in ipairs(run.events) do
                if event.id > before and (event.kind == "score" or event.action == "halve") then
                    table.insert(order, event.kind == "score" and "score" or "halve")
                end
            end
            equal(table.concat(order, ","), "score,halve")
            run.score = Run.Config.maxScore
            run:_activateItem(1)
            equal(run.score, Run.Config.maxScore)
            expect(run.score < math.huge)
        end
    end)

    test(function()
        local function trim(partner)
            local run = Run.new(211)
            run.quota = 100000
            for id = 1, #run.values do
                run.values[id] = 64
            end
            run.values[1] = 8
            run.inventory[1] = { id = "soft_saw", level = 1 }
            if partner then
                run.inventory[2] = { id = "balance_scale", level = 1 }
            end
            expect(run:action("launch", { angle = 0 }))
            local potential = Board.potential(run.values)
            run:_activateItem(1)
            expect(
                Board.potential(run.values) < potential,
                "Trimming must retain its future-score cost"
            )
            local actions = {}
            for _, event in ipairs(run.events) do
                if event.kind == "trigger" and event.targetPegId then
                    table.insert(actions, event.action)
                end
            end
            equal(table.concat(actions, ","), "halve,halve,pop")
            run:_processQueue()
            equal(#run.queue, 0)
            return run
        end
        local alone, paired = trim(false), trim(true)
        expect(
            paired.score > alone.score,
            "Pearl Scale must convert the trimming cost into extra score"
        )
        equal(paired.halves, 2)
        equal(paired.pops, 1)
        equal(paired.itemTriggers, 2)
    end)

    test(function()
        for level = 1, Catalog.MaxLevel do
            local run = Run.new(212)
            run.quota = 100000
            for id = 1, #run.values do
                run.values[id] = 64
            end
            run.inventory[1] = { id = "burst_capsule", level = level }
            expect(run:action("launch", { angle = 0 }))
            run:_activateItem(1)
            local actions, center = {}, nil
            for _, event in ipairs(run.events) do
                if event.kind == "trigger" and event.targetPegId then
                    table.insert(actions, event.action)
                    if event.action == "double" then
                        center = event.targetPegId
                    end
                    if event.action == "pop" then
                        expect(event.targetPegId ~= center)
                    end
                    if event.action == "halve" then
                        equal(event.targetPegId, center)
                    end
                end
            end
            equal(actions[1], "double")
            equal(actions[#actions], "halve")
            equal(#actions, 2 + 2 * level)
            equal(run.values[center], 64, "Temporary center growth must be paid back")
            equal(run.score, 128 * level, "Only neighbors should score")
            equal(run.pops, 2 * level)
            equal(run.doubles, 1)
            equal(run.halves, 1)
        end
        local scores = {}
        for build, ids in ipairs({
            { "soft_saw", "balance_scale" },
            { "burst_capsule", "resonator", "balance_scale" },
            { "goldfish", "fishbowl", "gain_dial" },
        }) do
            local run = Run.new(213)
            run.quota = 100000
            for id = 1, #run.values do
                run.values[id] = 64
            end
            for slot, id in ipairs(ids) do
                run.inventory[slot] = { id = id, level = Catalog.MaxLevel }
            end
            expect(run:action("launch", { angle = 0 }))
            for _ = 1, 4 do
                run:_activateItem(1)
            end
            for _ = 1, 100 do
                local before = run.itemTriggers
                run:_processQueue()
                expect(run.itemTriggers - before <= Run.Config.effectsPerStep)
                if #run.queue == 0 then
                    break
                end
            end
            equal(#run.queue, 0, "A mixed hybrid build did not settle its trigger chain")
            expect(run.score == run.score and run.score < math.huge)
            scores[build] = run.score
        end
        expect(
            scores[1] ~= scores[2] and scores[2] ~= scores[3],
            "Different trigger families should produce different outcomes"
        )
        for _, id in ipairs({ "gain_dial", "soft_saw", "burst_capsule" }) do
            local definition = Catalog.Items[id]
            equal(#definition.operations, #definition.effectLines)
            expect(#definition.operations >= 2 and #definition.operations <= 3)
            expect(type(definition.tradeoff) == "string" and #definition.tradeoff > 0)
        end
    end)

    return checks
end
