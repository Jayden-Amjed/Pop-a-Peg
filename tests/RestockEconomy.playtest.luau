-- Repeatable ordinary-action economy playtest, separate from the fast contract suite.
-- No score, coins, items or currency are granted. The second cohort models an
-- already-discovered catalog, while still buying every run item at its real cost.
local Arcade = require("../src/server/ArcadeSessions")
local Profile = require("../src/shared/Profile")
local Catalog = require("../src/shared/Catalog")
local Board = require("../src/shared/Board")
local Simulation = require("../src/shared/Simulation")
local Chests = require("../src/shared/ChestProgression")

local function copy(value)
    if type(value) ~= "table" then
        return value
    end
    local result = {}
    for key, entry in value do
        result[key] = copy(entry)
    end
    return setmetatable(result, getmetatable(value))
end

local function aim(run, shot, planned)
    if planned then
        -- An explicit upper-bound cohort: choose among 25 fully simulated shots.
        -- This uses future outcome knowledge a normal player does not have.
        local best, chosen = -1, 0
        for index = 0, 24 do
            local trial = copy(run)
            local angle = -1.2 + index * 0.1
            assert(trial:action("launch", { angle = angle }))
            while trial.phase == "flight" and trial.elapsed < 45 do
                trial:step(1 / 30)
            end
            if trial.phase == "flight" then
                assert(trial:action("endShot"))
            end
            if trial.score > best then
                best, chosen = trial.score, angle
            end
        end
        return chosen
    end
    local candidates = {}
    for i = 0, 46 do
        local angle = -1.15 + i * 0.05
        local points = Simulation.preview(angle, run.values)
        local last = points[#points]
        local value = 0
        for id, slot in Board.Slots do
            local distance = ((last.x - slot.x) ^ 2 + (last.y - slot.y) ^ 2) ^ 0.5
            if distance < Board.Geometry.pegRadius + Board.Geometry.ballRadius + 0.001 then
                value = run.values[id]
                break
            end
        end
        table.insert(candidates, { angle = angle, value = value })
    end
    table.sort(candidates, function(a, b)
        return if a.value == b.value then a.angle < b.angle else a.value > b.value
    end)
    return candidates[(shot - 1) % 3 + 1].angle
end

local priority = {
    split_prism = 10,
    seed_bank = 9,
    goldfish = 9,
    growth_array = 9,
    moss_capacitor = 9,
    fishbowl = 8,
    tap_driver = 7,
    resonator = 7,
}
local function shop(arcade, session)
    local run = session.run
    for _ = 1, 6 do
        local chosen, score = nil, -math.huge
        for index, offer in run.shopOffers do
            local intent = Catalog.purchaseState(run.inventory, run.slots, offer, run.coins)
            if intent.allowed and intent.action ~= "use" then
                local rank = (priority[offer.id] or 4) - offer.price * 0.1
                if intent.action == "evolve" then
                    rank = 100
                end
                if rank > score then
                    chosen, score = index, rank
                end
            end
        end
        if not chosen then
            break
        end
        assert(arcade:action(1, "buy", { offer = chosen }))
    end
    assert(arcade:action(1, "continue"))
end

local function play(seed, established, planned)
    local arcade = Arcade.new()
    local profile =
        Profile.clean({ version = 2, itemUnlocks = established and Catalog.ItemIds or nil })
    local session = arcade:add(1, "Economy", profile)
    assert(arcade:action(1, "startRun", {}, seed))
    local run = session.run
    local shots, simSeconds, decisionSeconds, maxRestocks, lastReceipt = 0, 0, 0, 0, 0
    local first100
    for _ = 1, 200000 do
        if run.phase == "aim" then
            if run.lastResult and not run.lastResult.success and run.canJumble then
                assert(arcade:action(1, "jumble"))
            end
            shots += 1
            decisionSeconds += 3
            assert(arcade:action(1, "launch", { angle = aim(run, shots, planned) }))
        elseif run.phase == "flight" or run.phase == "settling" then
            arcade:step(1 / 30)
            simSeconds += 1 / 30
            if run.phase == "flight" and run.elapsed >= 45 then
                assert(arcade:action(1, "endShot"))
            end
        elseif run.phase == "result" then
            maxRestocks = math.max(maxRestocks, run.restocks)
            assert(arcade:action(1, "continue"))
        elseif run.phase == "shop" then
            decisionSeconds += 10
            shop(arcade, session)
        elseif run.phase == "perk" then
            decisionSeconds += 5
            assert(arcade:action(1, "choosePerk", { index = 1 }))
        elseif run.phase == "event" then
            decisionSeconds += 5
            local choice = 1
            for i, entry in run.eventChoices do
                if entry.id == "grow" or entry.id == "upgrade" then
                    choice = i
                end
            end
            assert(arcade:action(1, "chooseEvent", { index = choice }))
        elseif run.phase == "victory" or run.phase == "gameover" then
            break
        else
            error("Unhandled phase " .. run.phase)
        end
        local receipt = run.settlementReceipt
        if receipt and receipt.id ~= lastReceipt then
            lastReceipt = receipt.id
            if session.profile.restockCredits >= 100 and not first100 then
                first100 = run.highestClearedRound
            end
        end
        if shots >= 220 then
            break
        end
    end
    arcade:capture(session)
    assert(run.phase == "gameover" or run.phase == "victory", "Economy run must finish normally")
    local credits = session.profile.restockCredits
    local modeledMinutes = (simSeconds / 4 + decisionSeconds) / 60
    print(
        string.format(
            "%s seed=%d cleared=%d shots=%d credits=%d maxRestocks=%d first100=%s simulatedSeconds=%.1f modeled4xMinutes=%.2f",
            if established then "discovered" else "starter",
            seed,
            run.highestClearedRound,
            shots,
            credits,
            maxRestocks,
            tostring(first100),
            simSeconds,
            modeledMinutes
        )
    )
    return { credits = credits, minutes = modeledMinutes, rounds = run.highestClearedRound }
end

for _, cohort in { { false, false }, { true, false }, { false, true }, { true, true } } do
    local established, planned = cohort[1], cohort[2]
    print("AIM " .. (if planned then "25-shot oracle upper bound" else "visible first-peg preview"))
    local totalCredits, totalMinutes, totalRounds, count = 0, 0, 0, 0
    for _, seed in { 17, 23, 41, 79, 137, 613 } do
        local result = play(seed, established, planned)
        totalCredits += result.credits
        totalMinutes += result.minutes
        totalRounds += result.rounds
        count += 1
    end
    print(
        string.format(
            "SUMMARY %s runs=%d credits=%d meanCredits=%.2f meanCleared=%.2f creditsPerModeledMinute=%.2f",
            if established then "discovered" else "starter",
            count,
            totalCredits,
            totalCredits / count,
            totalRounds / count,
            totalCredits / totalMinutes
        )
    )
    for _, tier in Chests.Tiers do
        if totalCredits > 0 then
            print(
                string.format(
                    "  %s cost=%d modeledMinutes=%.1f equivalentRuns=%.1f",
                    tier.id,
                    tier.restockCost,
                    tier.restockCost * totalMinutes / totalCredits,
                    tier.restockCost * count / totalCredits
                )
            )
        else
            print(
                string.format(
                    "  %s cost=%d no purchases reached by this cohort",
                    tier.id,
                    tier.restockCost
                )
            )
        end
    end
end
