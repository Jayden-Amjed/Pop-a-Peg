local Shared = if script then game:GetService("ReplicatedStorage").Shared else nil
local Catalog = if Shared then require(Shared.Catalog) else require("../src/shared/Catalog")
local Run = if Shared then require(Shared.Run) else require("../src/shared/Run")
local Curve = if Shared then require(Shared.RestockCurve) else require("../src/shared/RestockCurve")

local function resolve(run)
    for _ = 1, 150 do
        run:_processQueue()
        if #run.queue == 0 then
            break
        end
    end
    assert(#run.queue == 0 and next(run.pending) == nil, "Discovery effects did not converge")
    assert(
        run.activationCount < Run.Config.maxActivationsPerShot,
        "Build exhausted the emergency cap"
    )
end

local function active(ids, level, seed)
    local run = Run.new(seed or 901)
    run.slots = math.max(4, #ids)
    for index = 1, run.slots do
        run.inventory[index] = { id = ids[index] or "", level = ids[index] and level or 0 }
    end
    assert(run:action("launch", { angle = 0 }))
    return run
end

return function()
    local cases = 0
    local function test(name, callback)
        local ok, failure = pcall(callback)
        assert(ok, "Discovery items [" .. name .. "]: " .. tostring(failure))
        cases += 1
    end

    test("substantial catalog expansion and readable bounded operations", function()
        assert(
            #Catalog.ItemIds == 40 and #Catalog.NewItemIds == 18,
            "Expected eighteen additions to the original 22"
        )
        local signatures, ids = {}, {}
        for _, id in ipairs(Catalog.NewItemIds) do
            local definition = Catalog.Items[id]
            assert(not ids[id] and Catalog.isBaseItem(id), "Duplicate/non-base discovery")
            ids[id] = true
            assert(Catalog.Tiers[definition.tier], "Missing tier")
            assert(
                #definition.operations >= 2 and #definition.operations <= 3,
                "Expected two or three effects"
            )
            local signature = definition.trigger.event .. ":" .. definition.trigger.every
            for _, op in ipairs(definition.operations) do
                signature ..= "/" .. op.effect .. (op.fixed and "fixed" or "scaled")
            end
            assert(not signatures[signature], "Duplicate discovery behavior")
            signatures[signature] = true
            for level = 1, Catalog.MaxLevel do
                local detail = Catalog.detail(id, level)
                assert(#detail.effects == #definition.operations, "Inspection omitted an operation")
                assert(
                    detail.tier == definition.tier and #detail.evolutions == 0,
                    "Inspection tier or recipes differ"
                )
            end
        end
        assert(
            not Catalog.isBaseItem("reserve_pack") and not Catalog.isBaseItem("aurora_aquarium"),
            "Unlock pool includes non-base items"
        )
    end)

    test("new account offers contain only its eight starters", function()
        local starters = Catalog.itemUnlockSet()
        local seen = {}
        for seed = 1, 200 do
            local run = Run.new(seed)
            run.round = 31
            run:_openShop(false)
            for _ = 1, 4 do
                for index = 1, 4 do
                    local id = run.shopOffers[index].id
                    assert(starters[id], "Locked item entered starter shop: " .. id)
                    seen[id] = true
                end
                run:_rollShop()
            end
            assert(#run.shopOffers == 6, "Chest gates accidentally removed Supplies")
        end
        for _, id in ipairs(Catalog.StarterIds) do
            assert(seen[id], "Starter never offered")
        end
    end)

    test("unlock pool is a frozen independent snapshot", function()
        local profile = {
            itemUnlocks = {
                "rain_catcher",
                "aurora_kite",
                "unknown",
                "reserve_pack",
                "aurora_aquarium",
            },
        }
        local run = Run.new(304, profile)
        table.insert(profile.itemUnlocks, "ozone_orb")
        assert(not run.itemUnlocks.ozone_orb, "Live profile mutation changed an existing run")
        local saved = run:profile()
        table.insert(saved.itemUnlocks, "monsoon_loom")
        assert(not run.itemUnlocks.monsoon_loom, "Profile snapshot changed run ownership")
        assert(
            not run.itemUnlocks.reserve_pack and not run.itemUnlocks.aurora_aquarium,
            "Invalid unlock IDs survived"
        )
        local seen = {}
        for _ = 1, 4000 do
            local id = run:_drawItem()
            assert(run.itemUnlocks[id], "Fallback bypassed unlock gate")
            seen[id] = true
        end
        assert(seen.rain_catcher and seen.aurora_kite, "Unlocked items cannot roll")
        local newRun = Run.new(305, profile)
        assert(
            newRun.itemUnlocks.ozone_orb and not newRun.itemUnlocks.monsoon_loom,
            "Fresh run did not use current unlocks"
        )
        local oldTokens =
            Run.new(306, { unlocks = { "workshop_access", "growth_kit", "relay_kit" } })
        assert(not oldTokens.itemUnlocks.gain_dial, "Run bypassed profile migration/chest gate")
    end)

    test("tier rates remain meaningful with a complete collection", function()
        local run = Run.new(11071, { itemUnlocks = Catalog.ItemIds })
        local counts = { common = 0, uncommon = 0, rare = 0, legendary = 0 }
        local seen = {}
        for _ = 1, 20000 do
            local id = run:_drawItem()
            counts[Catalog.Items[id].tier] += 1
            seen[id] = true
        end
        assert(
            counts.common > counts.uncommon
                and counts.uncommon > counts.rare
                and counts.rare > counts.legendary,
            "Higher tiers were more frequent than lower tiers"
        )
        assert(
            counts.legendary >= 200 and counts.legendary <= 600,
            "Legendary frequency escaped 1–3% band"
        )
        for _, id in ipairs(Catalog.ItemIds) do
            assert(seen[id], "Unlocked equipment unreachable: " .. id)
        end
    end)

    test("locked purchase/held offers fail safely while owned upgrades work", function()
        local run = Run.new(501)
        run.phase, run.coins = "shop", 99
        run.shopOffers = { { id = "ozone_orb", price = 12 } }
        local ok = run:action("buy", { offer = 1 })
        assert(
            not ok and run.coins == 99 and run.inventory[1].id == "",
            "Locked purchase changed inventory or coins"
        )
        run.frozenOffer = { index = 1, offer = { id = "ozone_orb", price = 12, frozen = true } }
        run:_rollShop()
        assert(run.frozenOffer == nil, "Locked held offer persisted")
        for index = 1, 4 do
            assert(run.itemUnlocks[run.shopOffers[index].id], "Locked held offer entered shop")
        end
        run.inventory[1] = { id = "ozone_orb", level = 2 }
        run.shopOffers[1] = { id = "ozone_orb", price = 12 }
        assert(run:action("buy", { offer = 1 }))
        assert(run.inventory[1].level == 3, "Owned item upgrade wrongly requires another discovery")
    end)

    test("all eighteen trigger effects execute at every level", function()
        for _, id in ipairs(Catalog.NewItemIds) do
            local definition = Catalog.Items[id]
            for level = 1, Catalog.MaxLevel do
                local run = active({ "tap_driver", id, "split_prism" }, level)
                run.quota, run.score = 1e9, 1000
                for peg = 1, #run.values do
                    run.values[peg] = 256 + peg * 16
                end
                run:_signal(definition.trigger.event, definition.trigger.every)
                resolve(run)
                assert(run.itemTriggers > 0, "Trigger failed: " .. id)
                assert(
                    run.score > 1000 or run.doubles > 0 or run.pops > 0,
                    "No positive output: " .. id
                )
                for _, operation in ipairs(definition.operations) do
                    if operation.effect == "halve" or operation.effect == "halveHighest" then
                        assert(run.halves > 0, "Advertised cost was not paid: " .. id)
                    end
                end
                assert(run.score == run.score and run.score < math.huge, "Non-finite item score")
            end
        end
    end)

    test("mixed discovery relays converge without self-feeding quotas", function()
        local builds = {
            {
                "lagoon_synth",
                "ozone_orb",
                "moss_capacitor",
                "quota_bonus",
                "tide_valve",
                "nectar_pump",
                "biolume_jar",
            },
            {
                "monsoon_loom",
                "stream_wheel",
                "rain_catcher",
                "pearl_diver",
                "aurora_kite",
                "echo_plate",
                "encore",
            },
            {
                "mist_fan",
                "lily_pad",
                "dew_lantern",
                "coral_fork",
                "bubble_wand",
                "cloud_mirror",
                "solar_leaf",
            },
        }
        for seed = 1, 20 do
            for _, ids in ipairs(builds) do
                local run = active(ids, 5, seed)
                for peg = 1, #run.values do
                    run.values[peg] = 8
                end
                run:_signal("first")
                run:_signal("wall", 8)
                run:_signal("time", 5)
                run:_signal("drain")
                run:_addScore(run.quota)
                resolve(run)
                assert(run.restocks <= Curve.limit(1), "Early restock cap bypassed")
                assert(run.score <= Run.Config.maxScore, "Score escaped numeric bounds")
            end
        end
    end)

    test("clear progress and Endless records distinguish reached and completed", function()
        local run = Run.new(601)
        run.round = 15
        run:_resetShot()
        assert(run:action("launch", { angle = 0 }))
        assert(run:action("endShot"))
        assert(
            run.highestClearedRound == 0 and run.bestEndlessRound == 0,
            "A failed campaign shot awarded progress"
        )
        run:_resetShot()
        assert(run:action("launch", { angle = 0 }))
        run:_addScore(run.quota)
        assert(run:action("endShot"))
        assert(run.highestClearedRound == 15, "Successful round was not recorded")
        run.round, run.phase = 101, "victory"
        assert(run:action("endless"))
        assert(run.endlessMode and run.bestEndlessRound == 101, "Endless entry was not recorded")
        run.lastResult = { success = true }
        run:_afterResult()
        assert(
            run.bestEndlessRound == 102 and run.highestClearedRound == 15,
            "Reached and cleared records were conflated"
        )
        local snapshot = run:snapshot()
        assert(
            snapshot.endlessMode and snapshot.bestEndlessRound == 102,
            "Snapshot omitted Endless record"
        )
        local restarted = Run.new(602, run:profile())
        assert(
            not restarted.endlessMode
                and restarted.highestClearedRound == 0
                and restarted.bestEndlessRound == 102,
            "Fresh run failed to reset progress or retain Endless record"
        )
    end)

    print(
        "PASS discovery equipment: "
            .. cases
            .. " unlock, tier, trigger, cascade and Endless contracts"
    )
end
