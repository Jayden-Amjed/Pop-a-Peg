local Shared = if script then game:GetService("ReplicatedStorage").Shared else nil
local Run = if Shared then require(Shared.Run) else require("../src/shared/Run")
local Board = if Shared then require(Shared.Board) else require("../src/shared/Board")
local Catalog = if Shared then require(Shared.Catalog) else require("../src/shared/Catalog")
local Timeline = if Shared
    then require(Shared.RewardTimeline)
    else require("../src/shared/RewardTimeline")
local Chests = if Shared
    then require(Shared.ChestProgression)
    else require("../src/shared/ChestProgression")
local Profile = if Shared then require(Shared.Profile) else require("../src/shared/Profile")

local function same(a, b)
    for id, value in ipairs(a) do
        assert(value == b[id], "Mismatched peg " .. id)
    end
end

local function drain(run)
    assert(run:action("launch", { angle = 0 }))
    run.ball.y = Board.Geometry.bottom + 0.001
    run.ball.vx, run.ball.vy = 0, -10
    for _ = 1, 200 do
        run:step(1 / 60)
        if run.phase ~= "flight" then
            return
        end
    end
    error("Drain did not settle")
end

return function()
    local run = Run.new(31041)
    run.inventory[1] = { id = "landing_fund", level = 1 }
    run.inventory[2] = { id = "seed_bank", level = 1 }
    run.inventory[3] = { id = "tap_driver", level = 1 }
    run.perks = { "last_word" }
    drain(run)
    local receipt = run.settlementReceipt
    assert(
        receipt.drainStart and #receipt.drainSteps == 5,
        "Last Word must retain two separate activations"
    )
    local order, cueIds, total = {}, {}, 0
    local values = Board.copy(receipt.drainStart.values)
    for _, group in ipairs(receipt.drainSteps) do
        assert(
            group.beforeValues == nil and group.afterValues == nil,
            "Receipt stores sparse changes, not repeated boards"
        )
        for _, event in ipairs(group.events) do
            assert(
                event.drainReplay and not cueIds[event.id],
                "Drain cue must replay once from its receipt"
            )
            cueIds[event.id] = true
            total += 1
            if event.action == "activate" then
                table.insert(order, event.itemId)
            elseif event.action == "perk" then
                table.insert(order, event.perkId)
            end
        end
        for _, change in ipairs(group.changes) do
            values[change.pegId] = change.value
        end
    end
    assert(
        table.concat(order, ",") == "landing_fund,seed_bank,last_word,tap_driver,tap_driver",
        "Causal activation order changed"
    )
    same(values, receipt.shotValues)
    for _ = 1, Run.Config.eventHistory + 20 do
        run:_event("test")
    end
    local durable = run:snapshot().settlementReceipt
    assert(
        #durable.drainSteps == 5 and total > 5,
        "Drain detail must survive rolling event history"
    )
    local plan = Timeline.plan(durable, function()
        return 1.37
    end)
    for index = 1, 5 do
        assert(
            plan[index].kind == "drain" and plan[index].duration == 1.37,
            "Use sequential model-duration steps"
        )
    end
    assert(plan[6].kind == "restore", "Settlement must follow every drain activation")
    same(plan[5].afterValues, receipt.shotValues)

    local cascade = Run.new(31045)
    cascade.inventory[3] = { id = "landing_fund", level = 1 }
    for _ = 1, 50 do
        table.insert(cascade.perks, "last_word")
    end
    drain(cascade)
    assert(
        #cascade.events == Run.Config.eventHistory,
        "Fixture must overflow the rolling event log"
    )
    assert(
        #cascade.settlementReceipt.drainSteps == 151,
        "Durable drain receipt cannot truncate long legal chains"
    )
    assert(
        cascade.itemTriggers == 101 and cascade.perkTriggers == 50,
        "All independent Last Word activations apply exactly once"
    )

    local manual = Run.new(31042)
    manual.inventory[1] = { id = "landing_fund", level = 5 }
    assert(manual:action("launch", { angle = 0 }))
    assert(manual:action("endShot"))
    assert(
        manual.score == 0 and manual.settlementReceipt.drainStart == nil,
        "Manual end must not earn drain effects"
    )
    local pending = Run.new(31043)
    assert(pending:action("launch", { angle = 0 }))
    pending.draining, pending.ball.active = true, false
    pending:_queue("perk", 1)
    assert(not pending:action("endShot"), "End Shot must not discard a drain queue")
    assert(
        #pending.queue == 1 and not pending.ending,
        "Rejected manual end must preserve pending effects"
    )

    local clear = Run.new(31044)
    for id in ipairs(clear.values) do
        clear.values[id] = if id == 1 then 1 else 0
    end
    clear.inventory[3] = { id = "tap_driver", level = 1 }
    clear.perks = { "last_word" }
    drain(clear)
    assert(clear.lastResult.reason == "clear", "Drain-caused clear retains its reason")
    assert(
        clear.itemTriggers == 2 and #clear.settlementReceipt.drainSteps == 3,
        "Clear must not discard Last Word's second activation"
    )

    for eventIndex, reserves in { [1] = 3, [3] = 5 } do
        local eventRun = Run.new(31050 + eventIndex)
        eventRun.round, eventRun.reserves = 8, reserves
        eventRun.phase, eventRun.eventChoices =
            "event", table.clone(Catalog.Events[eventIndex].choices)
        if eventIndex == 3 then
            eventRun.routes = { { kind = "shop" } }
        end
        local before, coins = Board.copy(eventRun.baseline), eventRun.coins
        local round, highest = eventRun.round, eventRun.highestClearedRound
        assert(eventRun:action("chooseEvent", { index = 2 }))
        local eventReceipt = eventRun.settlementReceipt
        assert(
            eventReceipt.kind == "event" and eventReceipt.earnedRestocks == 1,
            "Board choice needs a distinct free-restock receipt"
        )
        assert(
            eventRun.phase == "result" and #eventRun.eventChoices == 0,
            "Choice must await playback and reject repeat requests"
        )
        assert(
            not eventRun:action("chooseEvent", { index = 2 }),
            "Duplicated click must not reward again"
        )
        assert(
            eventRun.coins == coins + 1 and eventRun.reserves == math.min(5, reserves + 1),
            "Free restock grants exactly one capped coin/ball reward"
        )
        local changed = 0
        for id, value in ipairs(before) do
            if eventReceipt.eventValues[id] ~= value then
                changed += 1
                assert(eventReceipt.eventValues[id] == value * 2, "Only chosen pegs double")
            end
        end
        assert(changed == 4, "Event doubles four distinct live pegs")
        for _, move in ipairs(eventReceipt.shuffleMoves) do
            assert(
                eventReceipt.restoredValues[move.to] == eventReceipt.eventValues[move.from],
                "Shuffle must preserve the changed values"
            )
        end
        local eventPlan = Timeline.plan(eventReceipt)
        assert(
            eventPlan[1].kind == "eventChange"
                and eventPlan[2].kind == "shuffle"
                and eventPlan[3].kind == "refill"
                and eventPlan[4].kind == "merge",
            "Event must visibly apply, shuffle, then restock"
        )
        local session = { run = eventRun, profile = Profile.clean(nil) }
        Chests.observe(session)
        Chests.observe(session)
        assert(session.profile.restockCredits == 0, "Free event restock cannot mint saved currency")
        local final = Board.copy(eventReceipt.nextShotValues)
        assert(
            not eventRun:action("continue", { receiptId = eventReceipt.id - 1 }),
            "Stale playback completion must not advance"
        )
        assert(eventRun:action("continue", { receiptId = eventReceipt.id }))
        if eventIndex == 3 then
            assert(eventRun.phase == "shop", "Event must preserve the next route")
            assert(
                not eventRun:action("continue", { receiptId = eventReceipt.id }),
                "Repeated playback completion must not skip the shop"
            )
            assert(eventRun:action("continue"))
        end
        assert(
            eventRun.phase == "aim"
                and eventRun.round == round
                and eventRun.highestClearedRound == highest,
            "Completing event playback must not clear another round"
        )
        same(eventRun.values, final)
        assert(not eventRun:action("continue"), "Duplicate playback completion cannot advance aim")
    end

    for _, definition in pairs(Catalog.Items) do
        assert(
            not string.find(definition.triggerText or "", "unscored", 1, true),
            "Item triggers use player-readable halving copy"
        )
    end
    assert(
        Catalog.Perks.recovery.triggerText == "Every 3 pegs halved by items",
        "Perk halving copy explains its source"
    )
    print(
        "PASS drain/event: durable ordered drain cues, Last Word twice, clear/manual guards, growth-shuffle-free-restock order, capped rewards and replay safety"
    )
end
