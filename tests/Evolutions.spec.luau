local Shared = if script then game:GetService("ReplicatedStorage"):WaitForChild("Shared") else nil
local Run = if Shared then require(Shared.Run) else require("../src/shared/Run")
local Catalog = if Shared then require(Shared.Catalog) else require("../src/shared/Catalog")
local Board = if Shared then require(Shared.Board) else require("../src/shared/Board")
local Stages = if Shared then require(Shared.Stages) else require("../src/shared/Stages")

local function equal(actual, expected, message)
    assert(actual == expected, message .. ": " .. tostring(actual) .. " ~= " .. tostring(expected))
end

local function offer(id, price)
    return { id = id, price = price or Catalog.Items[id].price, sold = false, frozen = false }
end

local function inventory(ids, level)
    local result = {}
    for _, id in ipairs(ids) do
        table.insert(result, { id = id, level = if id == "" then 0 else level or 5 })
    end
    return result
end

local function shop(ids, level)
    local run = Run.new(7007)
    run.round = 11
    run.coins = 100
    run.slots = #ids
    run.inventory = inventory(ids, level)
    run:_openShop(false)
    return run
end

local function findOffer(run, id)
    for index, entry in ipairs(run.shopOffers) do
        if entry.id == id and not entry.sold then
            return index
        end
    end
    return nil
end

local function sameMechanics(actual, expected, label)
    for index, value in ipairs(expected.values) do
        equal(actual.values[index], value, label .. " peg " .. index)
    end
    for _, field in { "score", "pops", "halves", "doubles", "restocks" } do
        equal(actual[field], expected[field], label .. " " .. field)
    end
    -- Relay targets receive the same number of activations at the same depth.
    -- Newly generated self-trigger channels intentionally differ after evolution.
    local function relays(run)
        local result = {}
        for _, queued in ipairs(run.queue) do
            if queued.index ~= 2 then
                local key = queued.index .. ":" .. queued.relayDepth
                result[key] = (result[key] or 0) + queued.count
            end
        end
        return result
    end
    local first, second = relays(actual), relays(expected)
    for key, count in pairs(first) do
        equal(count, second[key], label .. " relay " .. key)
    end
    for key, count in pairs(second) do
        equal(count, first[key], label .. " relay " .. key)
    end
end

local function activeItem(id)
    local run = Run.new(7123)
    run.inventory = inventory({ "wall_meter", id, "pulse_cell", "" })
    assert(run:action("launch", { angle = 0 }), "Activation fixture must launch")
    run.quota = 1e100
    run.score = 1200
    for index = 1, #run.values do
        run.values[index] = 2 ^ (18 + index % 4)
    end
    return run
end

local function finishTarget(round, success)
    local run = Run.new(7040)
    run.round = round
    run:_resetShot()
    assert(run:action("launch", { angle = 0 }), "Stage fixture must launch")
    if success then
        run:_addScore(run.quota)
    end
    assert(run:action("endShot"), "Stage fixture must finish")
    for _ = 1, 400 do
        if run.phase ~= "flight" then
            break
        end
        run:step(1 / 30)
    end
    equal(run.phase, "result", "Stage settlement must finish")
    return run
end

return function()
    local cases = 0
    local function test(name, callback)
        local ok, failure = pcall(callback)
        assert(ok, "Evolution contract [" .. name .. "]: " .. tostring(failure))
        cases += 1
    end

    test("five incremental upgrades in a full rack", function()
        equal(Catalog.MaxLevel, 5, "Equipment cap")
        local run = shop({ "seed_bank", "tap_driver", "wall_meter", "pulse_cell" }, 1)
        for level = 1, 4 do
            run.shopOffers[1] = offer("seed_bank", 6)
            local coins = run.coins
            local intent = Catalog.purchaseState(run.inventory, run.slots, run.shopOffers[1], coins)
            assert(intent.allowed and intent.action == "upgrade", "Full rack blocked upgrade")
            equal(intent.level, level + 1, "Upgrade must add exactly one level")
            assert(
                run:action("buy", { offer = 1, itemId = "seed_bank" }),
                "Server rejected upgrade"
            )
            equal(run.inventory[1].level, level + 1, "Server upgrade level")
            equal(run.coins, coins - 6, "Upgrade price charged exactly once")
            equal(#run:_occupied(), 4, "Upgrade must retain the occupied slot count")
        end
        run.shopOffers[1] = offer("seed_bank", 6)
        local coins = run.coins
        assert(not run:action("buy", { offer = 1 }), "Level 5 cannot upgrade")
        equal(run.coins, coins, "Rejected capped purchase charged coins")
        assert(not run.shopOffers[1].sold, "Rejected capped purchase consumed offer")
        run.shopOffers[1] = offer("compass", 6)
        assert(not run:action("buy", { offer = 1 }), "New equipment needs an empty slot")
    end)

    test("capacity, duplicates and affordability", function()
        local entries = inventory({ "seed_bank", "seed_bank", "", "pulse_cell" })
        entries[2].level = 2
        local intent = Catalog.purchaseState(entries, 4, offer("seed_bank", 6), 6)
        equal(intent.slot, 2, "Prefer the uncapped copy")
        equal(intent.level, 3, "Upgrade the actual copy by one level")
        entries[2].level = 5
        assert(
            not Catalog.purchaseState(entries, 4, offer("seed_bank"), 100).allowed,
            "Capped duplicates cannot buy another copy"
        )
        local missing = Catalog.purchaseState(entries, 4, offer("compass", 6), 5)
        assert(
            not missing.allowed and missing.reason == "coins",
            "Unaffordable item must be blocked"
        )
        local run = shop({ "seed_bank", "", "", "" }, 2)
        run.coins = 5
        run.shopOffers[1] = offer("seed_bank", 6)
        assert(not run:action("buy", { offer = 1 }), "Unaffordable upgrade accepted")
        equal(run.inventory[1].level, 2, "Rejected upgrade changed inventory")
        equal(run.coins, 5, "Rejected upgrade changed coins")
        assert(not run.shopOffers[1].sold, "Rejected upgrade marked offer sold")
        run.shopOffers[1] = offer("compass", 5)
        assert(run:action("buy", { offer = 1 }), "Affordable new item rejected")
        equal(run.inventory[2].level, 1, "New items begin at level 1")
    end)

    test("all recipes require both level-five ingredients", function()
        equal(#Catalog.Evolutions, 13, "Recipe count")
        local covered = {}
        for _, recipe in ipairs(Catalog.Evolutions) do
            local left, right = table.unpack(recipe.ingredients)
            covered[left], covered[right] = true, true
            for ingredient = 1, 2 do
                for level = 1, 4 do
                    local entries = inventory({ left, right, "", "" })
                    entries[ingredient].level = level
                    local state = Catalog.evolutionState(entries, 4, recipe.id)
                    assert(not state.ready, "An under-level ingredient unlocked " .. recipe.id)
                    equal(state.levels[ingredient], level, "Recipe ingredient level")
                    assert(state.owned[ingredient], "Owned ingredient must remain visible")
                    assert(
                        not Catalog.purchaseState(entries, 4, offer(recipe.id), 100).allowed,
                        "Server intent accepted under-level ingredients"
                    )
                end
            end
            local entries = inventory({ left, right, left, "" })
            entries[1].level = 2
            local state = Catalog.evolutionState(entries, 4, recipe.id)
            assert(state.ready, "A second max-level copy must qualify")
            equal(state.slots[1], 3, "Select the max-level ingredient copy")
            equal(state.slots[2], 2, "Select the matching second ingredient")
            entries[2] = { id = "", level = 0 }
            state = Catalog.evolutionState(entries, 4, recipe.id)
            assert(not state.ready and not state.owned[2], "Missing ingredient cannot qualify")
        end
        for _, id in ipairs(Catalog.ItemIds) do
            if not table.find(Catalog.NewItemIds, id) then
                assert(covered[id], "Original equipment lost its evolution path: " .. id)
            end
        end
        assert(not Catalog.evolutionState({}, 0, "unknown").ready, "Unknown recipe cannot qualify")
    end)

    test("all evolutions atomically consume two slots without coins", function()
        for _, recipe in ipairs(Catalog.Evolutions) do
            local run = shop({
                "pulse_cell",
                recipe.ingredients[1],
                "pulse_cell",
                "pulse_cell",
                "pulse_cell",
                recipe.ingredients[2],
                "pulse_cell",
            }, 1)
            run.inventory[2].level, run.inventory[6].level = 5, 5
            run.coins = 0
            local selected = offer(recipe.id, 0)
            run.shopOffers[1] = selected
            assert(
                run:action("buy", { offer = 1, itemId = recipe.id }),
                "Eligible full-rack evolution rejected"
            )
            equal(run.inventory[2].id, recipe.id, "Evolved item replaces first ingredient")
            equal(run.inventory[2].level, 5, "Evolved power stays at max level")
            equal(run.inventory[6].id, "", "Second ingredient slot must be freed")
            equal(run.inventory[6].level, 0, "Freed slot has no leftover level")
            equal(#run:_occupied(), 6, "Evolution must free exactly one slot")
            equal(#run.inventory, 7, "Evolution preserves unlocked capacity")
            equal(run.coins, 0, "Evolution is free after obtaining both ingredients")
            assert(selected.sold, "Evolution consumes its offer")
            for _, slot in { 1, 3, 4, 5, 7 } do
                equal(run.inventory[slot].id, "pulse_cell", "Unrelated slot changed")
                equal(run.inventory[slot].level, 1, "Unrelated item upgraded")
            end
            local event
            for _, candidate in ipairs(run.events) do
                if candidate.kind == "purchase" and candidate.action == "evolve" then
                    event = candidate
                end
            end
            assert(
                event and event.itemId == recipe.id and event.slot == 2,
                "Evolution feedback identity missing"
            )
        end
    end)

    test("stale ingredient and offer identity checks", function()
        local run = shop({ "goldfish", "fishbowl", "pulse_cell", "wall_meter" })
        local slot = findOffer(run, "aurora_aquarium")
        assert(slot, "Eligible evolution missing from shop")
        local selected = run.shopOffers[slot]
        run.inventory[2].level = 4
        local coins = run.coins
        assert(
            not run:action("buy", { offer = slot, itemId = "aurora_aquarium" }),
            "Purchase must recheck ingredients"
        )
        equal(run.inventory[1].id, "goldfish", "Rejected evolution consumed first ingredient")
        equal(run.inventory[2].id, "fishbowl", "Rejected evolution consumed second ingredient")
        equal(run.coins, coins, "Rejected evolution changed coins")
        assert(not selected.sold, "Rejected evolution consumed its offer")
        run.inventory[2].level = 5
        assert(
            not run:action("buy", { offer = slot, itemId = "storm_clock" }),
            "Stale card identity accepted"
        )
        assert(run:action("sell", { slot = 2 }), "Ingredient sale failed")
        assert(not findOffer(run, "aurora_aquarium"), "Sale left an invalid evolution offered")
        run.phase = "flight"
        assert(not run:action("buy", { offer = 1 }), "Evolution purchases must be shop-only")
    end)

    test("upgrades immediately expose evolutions and preserve held offers", function()
        local run = shop({ "tap_driver", "burst_capsule", "pulse_cell", "wall_meter" })
        run.inventory[1].level = 4
        run.shopOffers[1], run.shopOffers[2] = offer("tap_driver", 4), offer("compass", 6)
        assert(run:action("freeze", { offer = 2 }), "Hold fixture failed")
        assert(run:action("buy", { offer = 1 }), "Final ingredient upgrade failed")
        assert(findOffer(run, "bubble_reactor"), "Newly eligible evolution must appear immediately")
        equal(run.shopOffers[2].id, "compass", "Evolution replaced a held offer")
        assert(run.shopOffers[2].frozen, "Held offer lost its state")
        local coins = run.coins
        assert(run:action("reroll"), "Reroll fixture failed")
        equal(run.coins, coins - Run.Config.rerollPrice, "Reroll charge")
        assert(findOffer(run, "bubble_reactor"), "Reroll dropped an eligible evolution")
        equal(#run.shopOffers, 6, "Evolution must not create a seventh offer")
        for index = 5, 6 do
            assert(
                Catalog.Items[run.shopOffers[index].id].consumable,
                "Evolution displaced a Supply"
            )
        end
    end)

    test("overlapping recipes invalidate together after evolution", function()
        local run = shop({ "goldfish", "fishbowl", "split_prism", "resonator" })
        assert(
            findOffer(run, "aurora_aquarium") and findOffer(run, "spectrum_reef"),
            "Initial alternatives missing"
        )
        local slot = findOffer(run, "sun_koi")
        assert(slot and run:action("buy", { offer = slot }), "Alternative evolution unavailable")
        assert(
            not findOffer(run, "aurora_aquarium") and not findOffer(run, "spectrum_reef"),
            "Consumed shared ingredients left stale recipes"
        )
        equal(run.inventory[2].id, "fishbowl", "Unconsumed alternative ingredient changed")
        equal(run.inventory[4].id, "resonator", "Unconsumed alternative ingredient changed")
    end)

    test("five eligible choices fit four cards through cycling", function()
        local run = shop({
            "goldfish",
            "fishbowl",
            "split_prism",
            "resonator",
            "clockwork",
            "pulse_cell",
            "spring_coil",
        })
        equal(#run:snapshot().evolutionChoices, 5, "Fixture must expose five recipe choices")
        equal(#run.shopOffers, 6, "More recipes cannot increase 4+2 shop size")
        local seen = {}
        local coins = run.coins
        for _ = 1, 6 do
            for index = 1, 4 do
                seen[run.shopOffers[index].id] = true
            end
            local previous = run.shopOffers[1].id
            assert(
                run:action("cycleEvolution", { offer = 1, itemId = previous }),
                "Hidden eligible recipe must be cyclable"
            )
            assert(run.shopOffers[1].id ~= previous, "Cycling must change the selected recipe")
        end
        for _, id in ipairs(run:snapshot().evolutionChoices) do
            assert(seen[id], "Cycling failed to expose an eligible recipe")
        end
        equal(run.coins, coins, "Cycling recipes must not cost coins")
        assert(
            not run:action("cycleEvolution", { offer = 1, itemId = "missing" }),
            "Stale cycle identity accepted"
        )
        assert(not run:action("cycleEvolution", { offer = 5 }), "Supply cannot cycle recipes")
        run.shopOffers[4] = offer("compass", 6)
        assert(run:action("freeze", { offer = 4 }), "Held normal offer fixture failed")
        run:_refreshEvolutions()
        seen = {}
        for _ = 1, 10 do
            for index = 1, 3 do
                seen[run.shopOffers[index].id] = true
            end
            assert(
                run:action("cycleEvolution", { offer = 1 }),
                "Cycling with a held normal offer failed"
            )
        end
        for _, id in ipairs(run:snapshot().evolutionChoices) do
            assert(seen[id], "Held offer caused a hidden recipe to become unreachable")
        end
        equal(run.shopOffers[4].id, "compass", "Cycling replaced the held normal offer")
        assert(run.shopOffers[4].frozen, "Cycling cleared an unrelated held offer")
    end)

    test("evolutions never enter random drops", function()
        local run = Run.new(7051, { unlocks = { "workshop_access", "growth_kit", "relay_kit" } })
        for _, id in ipairs(Catalog.ItemIds) do
            assert(not Catalog.Items[id].evolved, "Random item pool includes an evolution")
        end
        for _ = 1, 600 do
            assert(not Catalog.Items[run:_drawItem()].evolved, "Random draw awarded an evolution")
        end
    end)

    test("each evolved channel equals its max-level ingredient", function()
        for _, recipe in ipairs(Catalog.Evolutions) do
            for channelIndex, ingredient in ipairs(recipe.ingredients) do
                local evolved, base = activeItem(recipe.id), activeItem(ingredient)
                evolved:_activateItem(2, 0, channelIndex)
                base:_activateItem(2, 0)
                sameMechanics(evolved, base, recipe.id .. " channel " .. channelIndex)
            end
            local evolved, sequential = activeItem(recipe.id), activeItem(recipe.ingredients[1])
            evolved:_activateItem(2, 0)
            sequential:_activateItem(2, 0)
            sequential.inventory[2].id = recipe.ingredients[2]
            sequential:_activateItem(2, 0)
            sameMechanics(evolved, sequential, recipe.id .. " combined activation")
        end
        local burst = activeItem("bubble_reactor")
        burst:_activateItem(2, 0, 2)
        equal(burst.doubles, 1, "Burst center growth remains fixed once")
        equal(burst.halves, 1, "Burst center cost remains fixed once")
        equal(burst.pops, 10, "Level-five burst pops ten neighbors")
    end)

    test("independent trigger counters and coalescing channels", function()
        local run = activeItem("current_nexus")
        run:_signal("pop", 156)
        run:_signal("pop", 156)
        equal(#run.queue, 2, "Two trigger channels must not coalesce together")
        local counts = {}
        for _, queued in ipairs(run.queue) do
            counts[queued.channel] = queued.count
        end
        equal(counts[1], 24, "Right relay threshold")
        equal(counts[2], 26, "Left relay threshold")
        run:_queue("item", 2, 1)
        run:_queue("item", 2, 1, 1, 1)
        equal(#run.queue, 4, "Direct activations and relay depths need distinct queue entries")
        local clock = activeItem("storm_clock")
        clock.inventory[3] = { id = "", level = 0 }
        clock:_signal("time", 0.5)
        equal(#clock.queue, 0, "Timed channels triggered early")
        clock:_signal("time", 0.5)
        equal(#clock.queue, 1, "One-second channel did not trigger")
        equal(clock.queue[1].channel, 2, "Wrong one-second channel")
        clock:_signal("time", 0.5)
        equal(#clock.queue, 2, "One-and-a-half-second channel lost its independent remainder")
    end)

    test("details have correct levels and independent recipe values", function()
        for level = 1, 5 do
            local detail = Catalog.detail("tap_driver", level)
            equal(detail.level, level, "Inspection level")
            assert(
                string.find(detail.effects[1].text, "Pop " .. level, 1, true),
                "Inspection shows stale power"
            )
        end
        assert(
            string.find(Catalog.detail("seed_bank", 5).effects[1].text, "20", 1, true),
            "Level-five seed bank must show twenty doubles"
        )
        assert(
            string.find(Catalog.detail("gain_dial", 5).effects[1].text, "75%", 1, true),
            "Level-five score multiplier inspection"
        )
        for _, id in ipairs(Catalog.EvolvedIds) do
            local detail = Catalog.detail(id, 1)
            equal(detail.kind, "evolved", "Evolved inspection kind")
            equal(detail.level, 5, "Evolved inspection power")
            equal(#detail.evolutions, 0, "Evolved cards cannot advertise further recipes")
            local triggers = 0
            for _, row in ipairs(detail.effects) do
                if row.tone == "trigger" then
                    triggers += 1
                end
            end
            equal(triggers, 2, "Both evolved triggers must be listed")
        end
        for _, ids in { Catalog.PerkIds, Catalog.ConsumableIds } do
            for _, id in ipairs(ids) do
                equal(#Catalog.detail(id, 1).evolutions, 0, "Perks and Supplies cannot evolve")
            end
        end
        local first = Catalog.evolutionsFor("goldfish")
        local original = first[1].ingredients[1]
        first[1].ingredients[1] = "changed"
        equal(
            Catalog.evolutionsFor("goldfish")[1].ingredients[1],
            original,
            "Recipe view aliases catalog source"
        )
        local detail = Catalog.detail("bubble_reactor", 5)
        detail.effects[1].text = "changed"
        assert(
            Catalog.detail("bubble_reactor", 5).effects[1].text ~= "changed",
            "Detail view aliases shared data"
        )
    end)

    test("Supplies and events add one level and exclude capped evolutions", function()
        local run = shop({ "seed_bank", "aurora_aquarium", "spectrum_reef", "solar_treasury" })
        run.inventory[1].level = 3
        run:_consume("upgrade")
        equal(run.inventory[1].level, 4, "Tuning Oil adds one level")
        run.phase, run.eventChoices = "event", { { id = "upgrade" } }
        assert(run:action("chooseEvent", { index = 1 }), "Upgrade event rejected")
        equal(run.inventory[1].level, 5, "Upgrade event adds one level")
        local coins = run.coins
        run:_consume("upgrade")
        equal(run.coins, coins + 4, "No eligible item gives fallback coins")
        for index = 2, 4 do
            equal(run.inventory[index].level, 5, "Evolved items cannot upgrade")
        end
        local final = shop({ "seed_bank", "growth_array", "wall_meter", "pulse_cell" })
        final.inventory[1].level = 4
        final.shopOffers[5] = offer("tuning_oil", 8)
        assert(final:action("buy", { offer = 5 }), "Tuning Oil purchase rejected")
        equal(final.inventory[1].level, 5, "Supply must finish exactly one upgrade")
        assert(findOffer(final, "eden_greenhouse"), "Supply upgrade must reveal its new evolution")
    end)

    test("duplicate merges only combine equal levels by one", function()
        local run = shop({ "tap_driver", "tap_driver", "aurora_aquarium", "aurora_aquarium" }, 5)
        run.inventory[1].level, run.inventory[2].level = 2, 2
        assert(run:action("move", { from = 1, to = 2 }), "Equal-level merge failed")
        equal(run.inventory[2].level, 3, "Duplicate merge must increment once")
        equal(run.inventory[1].id, "", "Duplicate merge consumes one copy")
        run.inventory[1] = { id = "tap_driver", level = 1 }
        assert(run:action("move", { from = 1, to = 2 }), "Different-level swap failed")
        equal(run.inventory[1].level, 3, "Different levels should swap intact")
        equal(run.inventory[2].level, 1, "Different levels must not merge")
        assert(run:action("move", { from = 3, to = 4 }), "Capped evolution swap failed")
        equal(#run:_occupied(), 4, "Capped evolved copies cannot merge into level six")
    end)

    test("run restart retains records but resets levels and evolution power", function()
        local run = shop({ "aurora_aquarium", "current_nexus", "seed_bank", "tap_driver" })
        run.bestRound, run.bestScore, run.unlocks.level_2 = 40, 123456, true
        run.phase = "gameover"
        local profile = run:profile()
        assert(
            profile.inventory == nil and profile.stage == nil and profile.coins == nil,
            "Power leaked into persistent profile"
        )
        assert(run:action("restart"), "Restart rejected")
        equal(run.round, 1, "Restart round")
        equal(run:snapshot().stage.index, 1, "Restart stage")
        equal(#run:_occupied(), 0, "Evolutions survived run reset")
        equal(run.coins, Run.Config.startingCoins, "Coins survived reset")
        equal(run.bestRound, 40, "Record lost on reset")
        assert(run.unlocks.level_2, "Level record unlock lost on reset")
    end)

    test("stage rewards require successful goal clears", function()
        for _, round in { 15, 40, 65, 100, 150 } do
            local failed = finishTarget(round, false)
            assert(
                failed.stageCleared == nil and failed.settlementReceipt.stageCleared == nil,
                "Failed target awarded a level"
            )
            assert(
                not failed.unlocks["level_" .. Stages.forRound(round).index],
                "Failed target saved level unlock"
            )
            assert(failed:action("continue"), "Failed target retry unavailable")
            equal(failed.round, round, "Failure advanced the goal")
            local success = finishTarget(round, true)
            assert(
                success.stageCleared and success.stageCleared.targetRound == round,
                "Successful target did not clear level"
            )
            assert(success.settlementReceipt.stageCleared.cleared, "Settlement lost level clear")
            assert(
                success.unlocks["level_" .. success.stageCleared.index],
                "Successful level unlock missing"
            )
            assert(success:action("continue"), "Successful target continuation rejected")
            equal(success.round, round + 1, "Successful goal did not advance")
            equal(
                success:snapshot().stage.index,
                Stages.forRound(round).index + 1,
                "Next stage index"
            )
        end
        local ordinary = finishTarget(14, true)
        assert(ordinary.stageCleared == nil, "Intermediate round awarded a level")
    end)

    test("campaign victory and bosses align with stage goals", function()
        for _, round in { 15, 40, 65, 100 } do
            local run = Run.new(7055)
            run.round = round
            run:_resetShot()
            assert(
                run.boss == Catalog.Bosses[Stages.forRound(round).index],
                "Boss is not at its level goal"
            )
        end
        local oldEnd = finishTarget(80, true)
        assert(not oldEnd.unlocks.endless, "Old round-80 endpoint still awards endless")
        assert(oldEnd:action("continue"), "Round 80 continuation rejected")
        assert(oldEnd.phase ~= "victory", "Campaign still ends at round 80")
        local finale = finishTarget(100, true)
        assert(
            finale.unlocks.endless and finale.unlocks.challenge,
            "Campaign completion unlocks missing"
        )
        assert(finale:action("continue"), "Finale continuation rejected")
        equal(finale.phase, "victory", "Fourth level must conclude the campaign")
        assert(finale:action("endless"), "Endless continuation unavailable")
        equal(finale.phase, "aim", "Endless must return to aiming")
        equal(finale.round, 101, "Endless begins after the campaign")
        equal(finale:snapshot().stage.targetRound, 150, "Next endless goal")
        assert(finale.boss == nil, "Campaign boss leaked into endless")
    end)

    test("max-level relay cascades settle within a hard activation budget", function()
        local run = shop({
            "encore",
            "ocean_orchestra",
            "current_nexus",
            "relay",
            "echo_plate",
            "wall_meter",
            "pulse_cell",
        })
        run:_resetShot()
        assert(run:action("launch", { angle = 0 }), "Cascade fixture must launch")
        run.quota = 1e100
        run.ball.active = false
        run:_queue("item", 1, 1)
        local budget = Run.Config.maxActivationsPerShot
        assert(type(budget) == "number" and budget > 0 and budget <= 4096, "Cascade budget missing")
        for _ = 1, math.ceil(budget / Run.Config.effectsPerStep) + 3 do
            run:step(1 / 30)
            if run.phase ~= "flight" then
                break
            end
        end
        equal(run.phase, "result", "Relay cascade stranded the ball after drain")
        assert(
            run.itemTriggers + run.perkTriggers <= budget,
            "Cascade exceeded its activation budget"
        )
        equal(#run.queue, 0, "Cascade cap left queued work")
        assert(next(run.pending) == nil, "Cascade cap left coalescing entries")
        local signals = 0
        for _, event in ipairs(run.events) do
            if event.kind == "chainLimit" then
                signals += 1
            end
        end
        equal(signals, 1, "Cascade cap needs one clear feedback event")
        assert(run:action("continue"), "Post-cascade continuation rejected")
        equal(run.itemTriggers, 0, "New shot retained item trigger count")
        equal(run.perkTriggers, 0, "New shot retained perk trigger count")
        assert(run:action("launch", { angle = 0 }), "New shot after cap could not launch")
        run:_activateItem(6)
        equal(run.itemTriggers, 1, "New shot retained the spent activation budget")
        assert(Board.potential(run.values) > 0, "Cascade test corrupted the board")
    end)

    test("perks and equipment share the cascade budget", function()
        local run = activeItem("wall_meter")
        run.perks = { "first_spark" }
        run.ball.active = false
        local budget = Run.Config.maxActivationsPerShot
        run:_queue("perk", 1, budget + 1)
        for _ = 1, math.ceil(budget / Run.Config.effectsPerStep) + 3 do
            run:step(1 / 30)
            if run.phase ~= "flight" then
                break
            end
        end
        equal(run.phase, "result", "Perk cascades must settle after drain")
        assert(
            run.itemTriggers > 0 and run.perkTriggers > 0,
            "Fixture did not mix activation types"
        )
        assert(
            run.itemTriggers + run.perkTriggers <= budget,
            "Perk work bypassed the shared budget"
        )
        equal(#run.queue, 0, "Perk cascade left pending work")
        local before = run.itemTriggers + run.perkTriggers
        run:_activatePerk(1)
        equal(
            run.itemTriggers + run.perkTriggers,
            before,
            "Direct perk activation bypassed the spent budget"
        )
    end)

    test("boss quotas stay reachable at the numerical score ceiling", function()
        for _, round in ipairs({ 15, 40, 65, 100 }) do
            local run = Run.new(1711)
            run.round, run.shopsVisited = round, 30
            for id = 1, #run.baseline do
                run.baseline[id] = Run.Config.maxPeg
            end
            run:_resetShot()
            assert(
                run.quota <= Run.Config.maxScore and run.quota > 0,
                "Boss quota exceeds available score range"
            )
            assert(run:action("launch", { angle = 0 }), "Could not launch saturated fixture")
            run:_addScore(Run.Config.maxScore)
            assert(run.restocks >= 1, "Maximum permitted score cannot clear saturated boss")
        end
    end)

    print(
        "PASS evolutions: "
            .. cases
            .. " purchase, recipe, channel, stage and bounded-cascade cases"
    )
    return cases
end
