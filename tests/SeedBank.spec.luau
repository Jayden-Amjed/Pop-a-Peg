local Shared = if script then game:GetService("ReplicatedStorage").Shared else nil
local Run = if Shared then require(Shared.Run) else require("../src/shared/Run")
local Board = if Shared then require(Shared.Board) else require("../src/shared/Board")
local Catalog = if Shared then require(Shared.Catalog) else require("../src/shared/Catalog")

local function equal(a, b, message)
    assert(a == b, (message or "Mismatch") .. ": " .. tostring(a) .. " ~= " .. tostring(b))
end

local function same(a, b)
    for id, value in ipairs(a) do
        equal(value, b[id], "Peg " .. id)
    end
end

local function prepared(id, level, round)
    local run = Run.new(29031)
    run.round = round or 1
    run:_resetShot()
    run.inventory[1] = { id = id or "seed_bank", level = level or 1 }
    assert(run:action("launch", { angle = 0 }))
    return run
end

local function drain(run, successful)
    if successful then
        run:_addScore(run.quota)
    end
    -- Exercise the natural Simulation drain path rather than injecting the signal.
    run.ball.y = Board.Geometry.bottom + 0.001
    run.ball.vx, run.ball.vy = 0, -10
    for _ = 1, 200 do
        run:step(1 / 60)
        if run.phase ~= "flight" then
            break
        end
    end
    equal(run.phase, "result")
    equal(run.drainCount, 1)
end

local function assertSeeds(run, count)
    equal(#run.nextShotSeeds, count, "Assigned seeds")
    equal(run:snapshot().pendingSeeds, count)
    equal(#run.settlementReceipt.nextShotSeeds, count)
    local seen = {}
    for _, seed in ipairs(run.nextShotSeeds) do
        assert(not seen[seed.pegId], "A peg received multiple banked doubles")
        seen[seed.pegId] = true
        equal(seed.old, run.baseline[seed.pegId])
        equal(seed.new, math.min(Run.Config.maxPeg, seed.old * 2))
        equal(run.settlementReceipt.nextShotValues[seed.pegId], seed.new)
    end
    same(run.settlementReceipt.finalValues, run.baseline)
end

return function()
    local checks = 0
    local function test(name, callback)
        local ok, err = pcall(callback)
        assert(ok, "Seed banking [" .. name .. "]: " .. tostring(err))
        checks += 1
    end

    test("natural drain gives useful growth on failed-round retry", function()
        local run = prepared()
        local baseline, quota = Board.copy(run.baseline), run.quota
        drain(run)
        equal(run.itemTriggers, 1)
        equal(run.doubles, 4, "Current-shot double synergies remain")
        equal(run.score, 0)
        assertSeeds(run, 4)
        same(run.baseline, baseline)
        local bankEvents = 0
        for _, event in ipairs(run.events) do
            if event.action == "bank" then
                bankEvents += 1
                equal(event.itemId, "seed_bank")
                assert(event.pegId and event.new > event.old, "Bank event must identify its gain")
            end
        end
        equal(bankEvents, 4)
        local preview = run.settlementReceipt.nextShotValues
        assert(run:action("continue"))
        equal(run.phase, "aim")
        equal(run.round, 1)
        equal(run.quota, quota, "Banked growth must not raise the target")
        same(run.values, preview)
        equal(#run.nextShotSeeds, 0)
        equal(#run.activeSeeds, 4)
        assert(run:action("launch", { angle = 0 }))
        assert(run:action("endShot"))
        equal(run:snapshot().pendingSeeds, 0, "Manual end earns no seeds")
        assert(run:action("continue"))
        same(run.values, baseline)
        equal(#run.activeSeeds, 0, "Seeds last for exactly one shot")
    end)

    test("manual end does not trigger the bank", function()
        local run = prepared()
        assert(run:action("endShot"))
        equal(run.drainCount, 0)
        assertSeeds(run, 0)
    end)

    test("timer or relay activation before drain still doubles live values", function()
        local run = prepared()
        local before = Board.potential(run.values)
        run:_activateItem(1)
        equal(run.doubles, 4)
        assert(Board.potential(run.values) > before, "Early activation must raise live value")
        equal(#run.seedRequests, 0)
        assert(run:action("endShot"))
        assertSeeds(run, 0)
    end)

    test("restocks finish before assigning seeds to live next-shot slots", function()
        local run = prepared(nil, 5)
        drain(run, true)
        local eligible = 0
        for _, value in ipairs(run.baseline) do
            if value > 0 then
                eligible += 1
            end
        end
        assertSeeds(run, math.min(20, eligible))
        assert(run:action("continue"))
        equal(run.quota, Board.quota(run.baseline, run.shopsVisited))
        assert(
            Board.potential(run.values) > Board.potential(run.baseline),
            "Seeds must help next shot"
        )
    end)

    test("shop keeps earned seeds even after selling the source item", function()
        local run = prepared(nil, 1, 5)
        drain(run, true)
        assertSeeds(run, 4)
        assert(run:action("continue"))
        equal(run.phase, "shop")
        equal(run:snapshot().pendingSeeds, 4)
        assert(run:action("sell", { slot = 1 }))
        assert(run:action("reroll"))
        equal(run:snapshot().pendingSeeds, 4)
        assert(run:action("continue"))
        equal(run.phase, "aim")
        equal(#run.activeSeeds, 4)
    end)

    test("perk selection preserves seeds until the next shot", function()
        local run = prepared(nil, 1, 9)
        drain(run, true)
        assert(run:action("continue"))
        equal(run.phase, "perk")
        equal(run:snapshot().pendingSeeds, 4)
        assert(run:action("choosePerk", { index = 1 }))
        equal(run.phase, "aim")
        equal(#run.activeSeeds, 4)
    end)

    test("event growth and seeds multiply the updated baseline", function()
        local run = prepared(nil, 5, 7)
        drain(run, true)
        assert(run:action("continue"))
        equal(run.phase, "event")
        local seeds = run:snapshot().nextShotSeeds
        assert(run:action("chooseEvent", { index = 2 }))
        equal(run.phase, "aim")
        local grown = 0
        for _, seed in ipairs(seeds) do
            local value = run.baseline[seed.pegId]
            equal(run.values[seed.pegId], math.min(Run.Config.maxPeg, value * 2))
            if value > seed.old then
                grown += 1
            end
        end
        assert(grown > 0, "Fixture must include event growth on a seeded peg")
        equal(run.quota, Board.quota(run.baseline, run.shopsVisited))
    end)

    test("Rain and Monsoon bank their respective growth quantities", function()
        for _, id in ipairs({ "rain_catcher", "monsoon_loom" }) do
            local run = prepared(id, 2)
            drain(run)
            assertSeeds(run, if id == "rain_catcher" then 2 else 8)
            assert(run.halves > 0, "Current-shot cost must still happen")
            if id == "rain_catcher" then
                equal(run.score, run.quota * 0.06)
                for _, seed in ipairs(run.nextShotSeeds) do
                    equal(seed.old, 1, "Rain seeds the lowest restored pegs")
                end
            end
            local detail = Catalog.detail(id, 2)
            equal(detail.effects[#detail.effects].text, "Halve the highest live peg once")
        end
    end)

    test("Eden Greenhouse inherits the level-five bank", function()
        local run = prepared("eden_greenhouse", 1)
        drain(run)
        assertSeeds(run, 20)
        equal(run.nextShotSeeds[1].itemId, "eden_greenhouse")
    end)

    test("stacked Encore relays cannot double next-shot pegs exponentially", function()
        local run = prepared("seed_bank", 5)
        run.inventory[2] = { id = "encore", level = 5 }
        run.inventory[3] = { id = "monsoon_loom", level = 5 }
        run.inventory[4] = { id = "rain_catcher", level = 5 }
        drain(run)
        local eligible = 0
        for _, value in ipairs(run.baseline) do
            if value > 0 then
                eligible += 1
            end
        end
        assertSeeds(run, eligible)
        assert(#run.seedRequests <= #Board.Slots, "Pending work must stay bounded")
        for id, value in ipairs(run.settlementReceipt.nextShotValues) do
            assert(value <= run.baseline[id] * 2, "One-double cap was bypassed")
        end
        assert(run.activationCount < Run.Config.maxActivationsPerShot, "Relay chain must converge")
    end)

    test("generic doubles stay temporary even when Encore invokes them at drain", function()
        local run = prepared("split_prism", 5)
        run.inventory[2] = { id = "encore", level = 1 }
        drain(run)
        assert(run.doubles > 0, "Encore must activate ordinary doubles")
        assertSeeds(run, 0)
    end)

    test("saturated and empty restored slots never receive useless seeds", function()
        local run = prepared()
        for id = 1, #Board.Slots do
            run.baseline[id], run.values[id] = 0, 0
        end
        run.baseline[1], run.values[1] = Run.Config.maxPeg, Run.Config.maxPeg
        drain(run)
        assertSeeds(run, 0)
        same(run.settlementReceipt.nextShotValues, run.baseline)
    end)

    test("seed benefit is bounded to one double per slot across many relay activations", function()
        local run = prepared(nil, 5)
        run.inventory[2] = { id = "encore", level = 5 }
        drain(run)
        assertSeeds(run, #Board.Slots)
        equal(#run.seedRequests, #Board.Slots)
        assert(run.itemTriggers > 2, "Fixture must activate Seed Bank multiple times")
    end)

    test("snapshot mutation and restart cannot leak banked progress", function()
        local run = prepared()
        drain(run)
        local snap = run:snapshot()
        snap.nextShotSeeds[1].new = -1
        snap.settlementReceipt.nextShotValues[1] = -1
        assert(run.nextShotSeeds[1].new > 0, "Snapshot leaked seed mutation")
        assert(run.settlementReceipt.nextShotValues[1] >= 0, "Snapshot leaked preview mutation")
        run.phase = "gameover"
        assert(run:action("restart"))
        equal(run:snapshot().pendingSeeds, 0)
        equal(#run.activeSeeds, 0)
    end)

    test("direct scoring drain items retain useful outcomes", function()
        for _, id in ipairs({ "landing_fund", "pearl_diver", "ocean_orchestra" }) do
            local run = prepared(id, 1)
            drain(run)
            assert(run.score > 0, id .. " must score before settlement")
            assertSeeds(run, 0)
        end
    end)

    print("PASS seed banking: " .. checks .. " natural-drain, carryover, route and cap cases")
end
