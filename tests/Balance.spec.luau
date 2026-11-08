local Shared = if script then game:GetService("ReplicatedStorage").Shared else nil
local Run = if Shared then require(Shared.Run) else require("../src/shared/Run")
local Curve = if Shared then require(Shared.RestockCurve) else require("../src/shared/RestockCurve")
local Board = if Shared then require(Shared.Board) else require("../src/shared/Board")
local Catalog = if Shared then require(Shared.Catalog) else require("../src/shared/Catalog")

local function close(actual, expected, message)
    assert(math.abs(actual - expected) < 1e-7, message .. ": " .. actual .. " ~= " .. expected)
end

local function active(ids, level)
    local run = Run.new(10)
    run.slots = math.max(4, #ids)
    for index = 1, run.slots do
        run.inventory[index] = { id = ids[index] or "", level = ids[index] and level or 0 }
    end
    assert(run:action("launch", { angle = 0 }))
    return run
end

local function resolve(run)
    for _ = 1, math.ceil(Run.Config.maxActivationsPerShot / Run.Config.effectsPerStep) + 2 do
        run:_processQueue()
        if #run.queue == 0 then
            break
        end
    end
    assert(#run.queue == 0 and next(run.pending) == nil, "Causal queue did not converge")
end

return function()
    local cases = 0
    local function test(name, callback)
        local ok, message = pcall(callback)
        assert(ok, "Balance [" .. name .. "]: " .. tostring(message))
        cases += 1
    end

    test("stage budgets and exponentially increasing thresholds", function()
        for _, entry in
            {
                { 1, 6 },
                { 15, 6 },
                { 16, 8 },
                { 40, 8 },
                { 41, 10 },
                { 65, 10 },
                { 66, 12 },
                {
                    10000,
                    12,
                },
            }
        do
            assert(Curve.limit(entry[1]) == entry[2], "Stage restock budget changed")
        end
        for _, limit in { 6, 8, 10, 12 } do
            for count = 1, limit do
                local threshold = 100 * (2 ^ count - 1)
                local before = Curve.compute(threshold - 0.01, 100, limit)
                local at = Curve.compute(threshold, 100, limit)
                assert(
                    before.completed == count - 1 and not before.capped,
                    "Premature quota crossing"
                )
                assert(
                    at.completed == count and at.capped == (count == limit),
                    "Exact threshold/cap mismatch"
                )
                if count < limit then
                    assert(
                        at.fraction == 0 and at.nextQuota == 100 * 2 ^ count,
                        "Threshold did not double/reset"
                    )
                    local half = Curve.compute(threshold + at.nextQuota / 2, 100, limit)
                    close(half.fraction, 0.5, "Next threshold progress")
                end
            end
        end
    end)

    test("one quota cannot feed Quota Bonus indefinitely", function()
        for level = 1, 5 do
            local run = active({ "quota_bonus" }, level)
            assert(run.quota == 10, "Original early runaway fixture changed")
            run:_addScore(run.quota)
            resolve(run)
            close(run.score, run.quota * (1 + 0.05 * level), "Quota Bonus score")
            assert(
                run.itemTriggers == 1 and run.restocks == 1,
                "Quota Bonus recursively retriggered"
            )
            run:_addScore(run.quota * 3 - run.score)
            resolve(run)
            assert(
                run.itemTriggers == 2 and run.restocks == 2,
                "A fresh crossing must trigger again"
            )
        end
    end)

    test("flat rewards scale with the round and cannot clear it on their own", function()
        for _, data in
            {
                { "wall_meter", "wall", 2, 0.08 },
                { "landing_fund", "drain", 1, 0.15 },
                { "pulse_cell", "time", 1, 0.03 },
            }
        do
            for level = 1, 5 do
                local run = active({ data[1] }, level)
                run:_signal(data[2], data[3])
                resolve(run)
                close(run.score, run.quota * data[4] * level, "Scaled item score")
                assert(run.restocks == 0, "One flat payout bypassed first quota")
                local text = Catalog.detail(data[1], level).effects[1].text
                assert(
                    string.find(text, "of round quota", 1, true),
                    "Tooltip must explain scaled payout"
                )
            end
        end
    end)

    test("own generated pops cannot refill their ancestor trigger", function()
        local run = active({ "tap_driver" }, 5)
        for index = 1, #run.values do
            run.values[index] = 1024
        end
        run:_signal("pop", 6)
        resolve(run)
        assert(
            run.pops == 5 and run.itemTriggers == 1 and run.itemCounts[1] == 0,
            "Own pops refilled the source trigger"
        )
        run:_signal("pop", 6)
        resolve(run)
        assert(run.pops == 10 and run.itemTriggers == 2, "Fresh ball events lost their triggers")
    end)

    test("upgraded relays retain repetitions without revisiting an ancestor", function()
        local run = active({ "relay", "echo_plate" }, 5)
        run:_queue("item", 1)
        resolve(run)
        assert(
            run.itemTriggers == 6,
            "Relay L5 should fire its neighbor five times, without looping back"
        )
        run:_queue("item", 1)
        resolve(run)
        assert(run.itemTriggers == 12, "Independent cascades must remain independent")
    end)

    test("evolved channels preserve a grow-harvest combo without recursion", function()
        local run = active({ "aurora_aquarium" }, 5)
        for index = 1, #run.values do
            run.values[index] = 1024
        end
        run:_signal("pop", 6)
        resolve(run)
        assert(
            run.doubles == 5 and run.pops == 5 and run.itemTriggers == 2,
            "Evolved grow-harvest channel chain changed"
        )
        run:_signal("pop", 6)
        resolve(run)
        assert(run.itemTriggers > 2, "Evolution stopped accepting fresh physical events")
    end)

    test("goal perk descendants cannot recreate their own perk", function()
        local run = active({ "quota_bonus", "quota_bonus", "quota_bonus" }, 5)
        run.perks = { "milestone", "milestone" }
        run:_addScore(run.quota)
        resolve(run)
        assert(
            run.activationCount < 40 and run.restocks <= 2,
            "Milestone feedback remains self sustaining"
        )
        assert(not run.activationCapped, "Routine quota build exhausted the safety fallback")
    end)

    test("bounded rewards never skip campaign rounds", function()
        for _, round in { 1, 10, 15, 16, 40, 41, 65, 66, 100 } do
            local run = Run.new(round)
            run.round = round
            run:_resetShot()
            local initialPotential = Board.potential(run.baseline)
            assert(run:action("launch", { angle = 0 }))
            run:_addScore(1e300)
            local limit = Curve.limit(round)
            assert(
                run.restocks == limit and run:snapshot().maxRestocks == limit,
                "Server and snapshot budgets disagree"
            )
            assert(run.round == round and run.phase == "flight", "Scoring skipped the current shot")
            assert(run:action("endShot"))
            assert(run.phase == "result" and run.coins == 3 + limit, "Capped payout mismatch")
            assert(
                run.settlementReceipt.earnedRestocks == limit and run.reserves == 5,
                "Receipt/reserve rewards mismatch"
            )
            assert(run:action("continue"))
            assert(run.round == round + 1, "A large score advanced more than one round")
            assert((run.phase == "victory") == (round == 100), "Premature campaign victory")
            local maxGrowth = 2 * #Board.Slots * limit * 2 ^ math.floor(round / 5)
            assert(
                Board.potential(run.baseline) <= initialPotential + maxGrowth + #Board.Slots,
                "One shot exceeded its finite refill budget"
            )
        end
    end)

    test("evolution discovery persists without carrying run power", function()
        local run = Run.new(10)
        run.inventory[1] = { id = "goldfish", level = 5 }
        run.inventory[2] = { id = "fishbowl", level = 5 }
        run:_openShop(false)
        local index
        for i, offer in run.shopOffers do
            if offer.id == "aurora_aquarium" then
                index = i
            end
        end
        assert(index and run:action("buy", { offer = index }), "Ready evolution purchase rejected")
        assert(run.unlocks.aurora_aquarium, "Evolution discovery was not recorded")
        local restarted = Run.new(11, run:profile())
        assert(
            restarted.unlocks.aurora_aquarium and #restarted:_occupied() == 0,
            "Discovery must persist without inventory"
        )
        assert(
            restarted.coins == Run.Config.startingCoins,
            "Discovery carried spending power across runs"
        )
    end)

    test("adversarial mixed builds stay finite and reward bounded", function()
        local builds = {
            {
                "quota_bonus",
                "gain_dial",
                "relay",
                "echo_plate",
                "encore",
                "growth_array",
                "resonator",
            },
            {
                "aurora_aquarium",
                "spectrum_reef",
                "tidal_engine",
                "storm_clock",
                "pearl_turbine",
                "current_nexus",
                "ocean_orchestra",
            },
            {
                "goldfish",
                "fishbowl",
                "tap_driver",
                "growth_array",
                "burst_capsule",
                "soft_saw",
                "balance_scale",
            },
        }
        for _, ids in builds do
            for level = 1, 5 do
                local run = active(ids, level)
                for index = 1, #run.values do
                    run.values[index] = 64
                end
                run.perks = { "first_spark", "tailwind", "growth_ring", "milestone", "recovery" }
                run:_signal("first")
                run:_signal("pop", 30)
                run:_signal("drain")
                resolve(run)
                assert(run.score == run.score and run.score < math.huge, "Non-finite score")
                assert(
                    run.activationCount <= Run.Config.maxActivationsPerShot,
                    "Activation budget bypassed"
                )
                assert(
                    run.restocks <= 6 and run.round == 1,
                    "Early reward or progression budget bypassed"
                )
                assert(run:action("endShot") or run.ending, "Adversarial chain could not end")
                assert(
                    run.phase == "result" and run.coins <= 9,
                    "Adversarial rewards did not settle within budget"
                )
            end
        end
    end)

    print(
        "PASS balance: "
            .. cases
            .. " causal-chain, reward-curve, early-game and discovery contracts"
    )
    return cases
end
