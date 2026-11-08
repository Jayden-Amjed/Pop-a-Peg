local Shared = if script then game:GetService("ReplicatedStorage"):WaitForChild("Shared") else nil
local Run = if Shared then require(Shared.Run) else require("../src/shared/Run")
local Catalog = if Shared then require(Shared.Catalog) else require("../src/shared/Catalog")

local function equal(actual, expected, message)
    assert(actual == expected, message .. ": " .. tostring(actual) .. " ~= " .. tostring(expected))
end

local function fixture(ids, level, seed)
    local run = Run.new(seed or 9009)
    run.slots, run.coins, run.round = #ids, 500, 11
    run.inventory = {}
    for _, id in ipairs(ids) do
        table.insert(run.inventory, { id = id, level = if id == "" then 0 else level or 1 })
    end
    return run
end

local function fixedDraw(run, id)
    run._drawItem = function()
        return id
    end
end

local function offer(id, price)
    return { id = id, price = price or Catalog.Items[id].price, sold = false, frozen = false }
end

local function guaranteedCount(run)
    local count = 0
    for index = 1, 4 do
        if run.shopOffers[index].guaranteedUpgrade then
            count += 1
        end
    end
    return count
end

local function assertUpgrade(run, index)
    local entry = run.shopOffers[index]
    assert(entry.guaranteedUpgrade, "Reserved upgrade flag absent at " .. index)
    local intent = Catalog.purchaseState(run.inventory, run.slots, entry, run.coins)
    equal(intent.action, "upgrade", "Reserved card must upgrade an owned item")
    assert(intent.allowed, "Reserved upgrade is unavailable")
    assert(not Catalog.Items[entry.id].evolved, "An evolved item entered the upgrade pool")
    return entry.id
end

local function findOffer(run, id)
    for index, entry in ipairs(run.shopOffers) do
        if entry.id == id and not entry.sold then
            return index
        end
    end
    return nil
end

return function()
    local cases, rolls = 0, 0
    local function test(name, callback)
        local ok, failure = pcall(callback)
        assert(ok, "Shop roll contract [" .. name .. "]: " .. tostring(failure))
        cases += 1
    end

    test("two valid distinct upgrades across seeded full racks and rerolls", function()
        local ids = {
            "tap_driver",
            "wall_meter",
            "pulse_cell",
            "seed_bank",
            "compass",
            "clockwork",
            "split_prism",
        }
        for slots = 4, 7 do
            for seed = 1, 100 do
                local selected = {}
                for index = 1, slots do
                    table.insert(selected, ids[index])
                end
                local run = fixture(selected, 1 + seed % 4, seed)
                run.round = if seed % 2 == 0 then 5 else 11
                run:_openShop(seed % 3 == 0)
                equal(guaranteedCount(run), 2, "Full rack must reserve two offers")
                assert(
                    assertUpgrade(run, 1) ~= assertUpgrade(run, 2),
                    "Distinct eligible IDs should not repeat"
                )
                equal(#run.shopOffers, if run.round < 11 then 4 else 6, "Supply count changed")
                for index = 1, 2 do
                    local entry = run.shopOffers[index]
                    equal(
                        entry.price,
                        math.max(
                            1,
                            Catalog.Items[entry.id].price
                                - (if run.shopKind == "surplus" then 1 else 0)
                        ),
                        "Upgrade discount changed"
                    )
                end
                assert(run:action("reroll"), "Full-rack reroll rejected")
                equal(guaranteedCount(run), 2, "Reroll lost reserved offers")
                assert(
                    assertUpgrade(run, 1) ~= assertUpgrade(run, 2),
                    "Rerolled upgrade IDs should differ"
                )
                rolls += 2
            end
        end
    end)

    test("two remaining lanes retain ordinary random draws", function()
        local run = fixture({ "tap_driver", "wall_meter", "pulse_cell", "seed_bank" }, 2)
        fixedDraw(run, "compass")
        run:_openShop(false)
        assertUpgrade(run, 1)
        assertUpgrade(run, 2)
        for index = 3, 4 do
            equal(
                run.shopOffers[index].id,
                "compass",
                "Random lane was replaced by an owned recommendation"
            )
            assert(not run.shopOffers[index].guaranteedUpgrade, "Random lane was reserved")
        end
        local original = run.inventory[1].level
        fixedDraw(run, "tap_driver")
        run:_rollShop()
        equal(run.shopOffers[3].id, "tap_driver", "Random lane cannot naturally roll an upgrade")
        equal(run.shopOffers[4].id, "tap_driver", "Random lane cannot naturally repeat")
        equal(run.inventory[1].level, original, "Rolling mutated inventory")
    end)

    test("buying both reserved offers upgrades in place without replenishing", function()
        local run = fixture({ "tap_driver", "wall_meter", "pulse_cell", "seed_bank" }, 2)
        fixedDraw(run, "compass")
        run:_openShop(false)
        local bought = {}
        for index = 1, 2 do
            local entry = run.shopOffers[index]
            bought[index] = entry
            local intent = Catalog.purchaseState(run.inventory, run.slots, entry, run.coins)
            local coins = run.coins
            assert(
                run:action("buy", { offer = index, itemId = entry.id }),
                "Reserved purchase failed"
            )
            equal(run.inventory[intent.slot].level, 3, "Purchase must add one level")
            equal(run.coins, coins - entry.price, "Incorrect upgrade charge")
            equal(run.shopOffers[index], bought[index], "Purchased reserved card was rerolled")
            assert(run.shopOffers[index].sold, "Purchased reserved card was replenished")
        end
        equal(#run:_occupied(), run.slots, "In-place upgrades changed occupancy")
        assert(
            not run:action("buy", { offer = 1, itemId = bought[1].id }),
            "Sold upgrade purchased twice"
        )
    end)

    test("one eligible item can supply two sequential levels", function()
        local run = fixture({ "tap_driver", "wall_meter", "pulse_cell", "seed_bank" }, 5)
        run.inventory[1].level = 3
        fixedDraw(run, "compass")
        run:_openShop(false)
        equal(guaranteedCount(run), 2, "Two remaining levels should produce two upgrades")
        equal(assertUpgrade(run, 1), "tap_driver", "Wrong remaining item")
        equal(assertUpgrade(run, 2), "tap_driver", "Wrong repeated item")
        assert(run:action("buy", { offer = 2 }), "First sequential upgrade failed")
        equal(run.inventory[1].level, 4, "First sequential level")
        assert(run:action("buy", { offer = 1 }), "Second sequential upgrade failed")
        equal(run.inventory[1].level, 5, "Second sequential level")
    end)

    test("duplicate copies contribute their remaining level capacity", function()
        local run = fixture({ "tap_driver", "tap_driver", "aurora_aquarium", "spectrum_reef" }, 5)
        run.inventory[1].level, run.inventory[2].level = 4, 4
        fixedDraw(run, "compass")
        run:_openShop(false)
        equal(guaranteedCount(run), 2, "Two eligible copies should permit two offers")
        for index = 1, 2 do
            equal(
                assertUpgrade(run, index),
                "tap_driver",
                "Duplicate capacity chose a different item"
            )
            assert(run:action("buy", { offer = index }), "Duplicate upgrade failed")
        end
        equal(run.inventory[1].level, 5, "First duplicate not maxed")
        equal(run.inventory[2].level, 5, "Second duplicate not maxed")
    end)

    test("one or no remaining levels never fabricate unusable reservations", function()
        local run = fixture({ "tap_driver", "wall_meter", "pulse_cell", "seed_bank" }, 5)
        run.inventory[1].level = 4
        fixedDraw(run, "compass")
        run:_openShop(false)
        equal(guaranteedCount(run), 1, "Only one remaining level should reserve one offer")
        equal(assertUpgrade(run, 1), "tap_driver", "Wrong last upgrade")
        for index = 2, 4 do
            equal(run.shopOffers[index].id, "compass", "Unfillable reservation must be random")
        end
        run.inventory[1].level = 5
        run:_rollShop()
        equal(guaranteedCount(run), 0, "Capped rack fabricated an upgrade")
        for index = 1, 4 do
            equal(run.shopOffers[index].id, "compass", "Capped rack fallback changed")
        end
        local evolved =
            fixture({ "aurora_aquarium", "spectrum_reef", "current_nexus", "solar_treasury" }, 5)
        fixedDraw(evolved, "compass")
        evolved:_openShop(false)
        equal(guaranteedCount(evolved), 0, "Evolved equipment cannot be upgraded")
    end)

    test("held eligible upgrades retain price and migrate into reserved lanes", function()
        local run = fixture({ "tap_driver", "wall_meter", "pulse_cell", "seed_bank" }, 2)
        fixedDraw(run, "compass")
        run:_openShop(false)
        run.shopOffers[4] = offer("seed_bank", 2)
        assert(run:action("freeze", { offer = 4 }), "Could not hold upgrade")
        assert(run:action("reroll"), "Held-upgrade reroll failed")
        local index = findOffer(run, "seed_bank")
        assert(index and index <= 2, "Held eligible upgrade did not occupy a reserved lane")
        assert(run.shopOffers[index].frozen, "Held upgrade lost held state")
        equal(run.shopOffers[index].price, 2, "Held price changed")
        equal(run.frozenOffer.index, index, "Held index did not follow relocated card")
        equal(guaranteedCount(run), 2, "Held upgrade consumed both reservations")
        assertUpgrade(run, 1)
        assertUpgrade(run, 2)
        assert(
            run.shopOffers[1].id ~= run.shopOffers[2].id,
            "Held item repeated despite alternatives"
        )
    end)

    test("held random cards remain available outside upgrade lanes", function()
        local run = fixture({ "tap_driver", "wall_meter", "pulse_cell", "seed_bank" }, 2)
        fixedDraw(run, "compass")
        run:_openShop(false)
        run.shopOffers[1] = offer("survey_lens", 2)
        assert(run:action("freeze", { offer = 1 }), "Could not hold random offer")
        assert(run:action("reroll"), "Held-random reroll failed")
        local index = findOffer(run, "survey_lens")
        assert(index and index >= 3 and index <= 4, "Held random offer occupied a guaranteed lane")
        equal(run.shopOffers[index].price, 2, "Held random price changed")
        assert(run.shopOffers[index].frozen, "Held random offer lost freeze")
        equal(run.frozenOffer.index, index, "Held random index became stale")
        assertUpgrade(run, 1)
        assertUpgrade(run, 2)
    end)

    test("evolutions and their navigation cannot displace reserved upgrades", function()
        local run = fixture({
            "goldfish",
            "fishbowl",
            "split_prism",
            "resonator",
            "tap_driver",
            "wall_meter",
            "pulse_cell",
        }, 5)
        for index = 5, 7 do
            run.inventory[index].level = 2
        end
        run:_openShop(false)
        local first, second = run.shopOffers[1], run.shopOffers[2]
        assertUpgrade(run, 1)
        assertUpgrade(run, 2)
        for index = 3, 4 do
            assert(
                Catalog.Items[run.shopOffers[index].id].evolved,
                "Evolution not shown in free lane"
            )
        end
        local seen = {}
        for _ = 1, 5 do
            for index = 3, 4 do
                seen[run.shopOffers[index].id] = true
            end
            assert(
                run:action("cycleEvolution", { offer = 3, itemId = run.shopOffers[3].id }),
                "Hidden evolution navigation failed"
            )
            equal(run.shopOffers[1], first, "Evolution navigation replaced upgrade lane 1")
            equal(run.shopOffers[2], second, "Evolution navigation replaced upgrade lane 2")
        end
        for _, id in ipairs(run:_evolutionChoices()) do
            assert(seen[id], "Eligible evolution unreachable: " .. id)
        end
        assert(
            run:action("buy", { offer = 1, itemId = first.id }),
            "Reserved upgrade alongside evolution failed"
        )
        run:_refreshEvolutions()
        equal(run.shopOffers[1], first, "Evolution replaced a sold reserved offer")
        assert(first.sold, "Evolution refresh replenished sold upgrade")
        equal(run.shopOffers[2], second, "Evolution refresh displaced remaining upgrade")
    end)

    test("held ordinary offer still leaves one navigable evolution lane", function()
        local run = fixture({
            "goldfish",
            "fishbowl",
            "split_prism",
            "resonator",
            "tap_driver",
            "wall_meter",
            "pulse_cell",
        }, 5)
        for index = 5, 7 do
            run.inventory[index].level = 2
        end
        run:_openShop(false)
        run.shopOffers[1] = offer("compass", 2)
        assert(run:action("freeze", { offer = 1 }), "Could not hold spare offer")
        assert(run:action("reroll"), "Held-plus-evolution reroll failed")
        local held = findOffer(run, "compass")
        assert(held and held >= 3, "Held spare offer missing or in reserved lane")
        local evolutionIndex = if held == 3 then 4 else 3
        local seen = {}
        for _ = 1, 6 do
            seen[run.shopOffers[evolutionIndex].id] = true
            assert(
                run:action("cycleEvolution", { offer = evolutionIndex }),
                "Held offer blocked hidden evolution cycle"
            )
        end
        for _, id in ipairs(run:_evolutionChoices()) do
            assert(seen[id], "Held offer starved recipe " .. id)
        end
        assertUpgrade(run, 1)
        assertUpgrade(run, 2)
        equal(run.shopOffers[held].price, 2, "Cycling changed held price")
    end)

    test("held evolution moves safely outside the reserved lanes", function()
        local run = fixture({ "goldfish", "fishbowl", "tap_driver", "wall_meter" }, 5)
        run.inventory[3].level, run.inventory[4].level = 2, 3
        run:_openShop(false)
        run.shopOffers[1] = offer("aurora_aquarium", 0)
        assert(run:action("freeze", { offer = 1 }), "Could not hold eligible evolution")
        assert(run:action("reroll"), "Held evolution reroll failed")
        local index = findOffer(run, "aurora_aquarium")
        assert(index and index >= 3, "Held evolution collided with reserved upgrades")
        assert(run.shopOffers[index].frozen, "Held evolution flag lost")
        equal(run.frozenOffer.index, index, "Held evolution index stale")
        assertUpgrade(run, 1)
        assertUpgrade(run, 2)
        assert(
            run:action("buy", { offer = index, itemId = "aurora_aquarium" }),
            "Held evolution purchase failed"
        )
        equal(#run:_occupied(), 3, "Evolution did not free a slot")
    end)

    test("partial racks preserve the single owned-upgrade opportunity", function()
        local run = fixture({ "tap_driver", "wall_meter", "pulse_cell", "" }, 2)
        fixedDraw(run, "compass")
        run:_openShop(false)
        local upgrades = 0
        for index = 1, 4 do
            local intent =
                Catalog.purchaseState(run.inventory, run.slots, run.shopOffers[index], run.coins)
            if intent.action == "upgrade" then
                upgrades += 1
            end
        end
        equal(upgrades, 1, "Partial rack guarantee changed")
        equal(guaranteedCount(run), 0, "Partial rack retained full-rack role markers")
    end)

    test("purchases and slot expansion do not reroll an existing shop", function()
        local full = fixture({ "tap_driver", "wall_meter", "pulse_cell", "seed_bank" }, 2)
        fixedDraw(full, "compass")
        full:_openShop(false)
        local offers = table.clone(full.shopOffers)
        assert(full:action("buySlot"), "Slot expansion failed")
        for index, old in ipairs(offers) do
            equal(full.shopOffers[index], old, "Slot expansion rerolled offers")
        end
        equal(full.slots, 5, "Slot not added")
        equal(#full:_occupied(), 4, "Expansion filled a slot")
        assert(full:action("freeze", { offer = 1 }), "Could not hold old reserved upgrade")
        assert(full:action("reroll"), "Partial reroll failed")
        equal(guaranteedCount(full), 0, "Old held role survived a partial-rack reroll")

        local partial = fixture({ "tap_driver", "wall_meter", "pulse_cell", "" }, 2)
        fixedDraw(partial, "compass")
        partial:_openShop(false)
        partial.shopOffers[1] = offer("compass")
        local remaining = { partial.shopOffers[2], partial.shopOffers[3], partial.shopOffers[4] }
        assert(
            partial:action("buy", { offer = 1, itemId = "compass" }),
            "Last-slot purchase failed"
        )
        equal(#partial:_occupied(), 4, "Rack should now be full")
        for offset, old in ipairs(remaining) do
            equal(partial.shopOffers[offset + 1], old, "Filling rack rerolled an existing offer")
        end
        assert(partial:action("reroll"), "New full-rack reroll failed")
        equal(guaranteedCount(partial), 2, "Next roll did not adopt full-rack guarantee")
    end)

    print(
        "PASS shop rolls: "
            .. cases
            .. " contracts, "
            .. rolls
            .. " seeded full-rack rolls, held offers and protected evolution lanes"
    )
    return cases
end
