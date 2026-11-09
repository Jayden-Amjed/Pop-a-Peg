--!nonstrict
-- Opt-in unpublished UI preview runtime check; observes actual model/board playback.
local Http = game:GetService("HttpService")
local Board = require(game:GetService("ReplicatedStorage").Shared.Board)
local started = os.clock()
local report = { ok = false, checks = {}, drains = {}, eventStages = {} }
script:SetAttribute("Result", Http:JSONEncode({ running = true }))
local controller

local function waitFor(predicate, label, seconds)
    local deadline = os.clock() + (seconds or 20)
    repeat
        if predicate() then
            return
        end
        task.wait()
    until os.clock() >= deadline
    error("Drain/event timeout: " .. label)
end

local function sameBoard(host, values)
    for id, value in ipairs(values) do
        assert(host.pegs[id].value == value, "Displayed peg differs at " .. id)
    end
end

local function readyModels(host)
    waitFor(function()
        for _, entry in host.models do
            local info = entry.handle:inspect()
            assert(info.backend == "Blender", "Expected real Blender models")
            assert(info.loadState ~= "Failed", "Model load failed")
            if info.loadState ~= "Ready" then
                return false
            end
        end
        return true
    end, "Blender model loading")
end

local function beginDrain(speed)
    controller.select("Aim")
    local run, host = controller.run, controller.view
    run.inventory[1] = { id = "landing_fund", level = 1 }
    run.inventory[2] = { id = "seed_bank", level = 1 }
    run.inventory[3] = { id = "tap_driver", level = 1 }
    run.perks = { "last_word" }
    run:_resetShot()
    run.speed = speed
    controller.send("speed", { value = speed })
    waitFor(function()
        return host.snapshot.inventory[1].id == "landing_fund"
            and host.snapshot.perks[1] == "last_word"
    end, "scenario refresh")
    readyModels(host)
    local cues = {}
    local pulseItem, pulsePerk = host.pulseItem, host.pulsePerk
    host.pulseItem = function(self, slot, strength, params)
        table.insert(cues, {
            kind = "item",
            id = self.snapshot.inventory[slot].id,
            slot = slot,
            time = os.clock(),
            overlapping = self:hasActiveItemAnimations(),
        })
        pulseItem(self, slot, strength, params)
    end
    host.pulsePerk = function(self, id)
        table.insert(cues, {
            kind = "perk",
            id = id,
            time = os.clock(),
            overlapping = self:hasActiveItemAnimations(),
        })
        pulsePerk(self, id)
    end
    controller.send("launch", { angle = 0 })
    waitFor(function()
        return run.phase == "flight" and run.ball and run.ball.active
    end, "launch")
    run.ball.y = Board.Geometry.bottom + 0.001
    run.ball.vx, run.ball.vy = 0, -10
    waitFor(function()
        return host.feedback.timeline
            and host.feedback.timeline[host.feedback.timelineIndex].kind == "drain"
    end, "first queued drain")
    assert(not host.primary.Active, "Launch/End Shot must be blocked during drain playback")
    return run, host, cues, run.settlementReceipt
end

local ok, failure = xpcall(function()
    assert(game:GetService("RunService"):IsStudio() and game.GameId == 0, "Local preview only")
    waitFor(function()
        -- selene: allow(global_usage)
        controller = shared.RBX031UiPreview
        return controller and controller.view
    end, "UI preview")
    controller.toolbar.Enabled = false

    for _, speed in { 1, 4 } do
        local run, host, cues, receipt = beginDrain(speed)
        assert(#receipt.drainSteps == 5, "Expected five durable drain activation groups")
        local seen = {}
        waitFor(function()
            local feedback = host.feedback
            if feedback.timeline then
                local step = feedback.timeline[feedback.timelineIndex]
                if step then
                    seen[feedback.timelineIndex] = step.kind
                    if step.kind == "restore" then
                        assert(#cues == 5, "Restoration began before all five activations")
                        assert(
                            not host:hasActiveItemAnimations(),
                            "Restoration overlaps model activation"
                        )
                    end
                end
            end
            return feedback.completedReceipt == receipt.id and not feedback:isBusy()
        end, "ordered playback completion at " .. speed .. "x", 45)
        local order = {}
        for _, cue in cues do
            assert(not cue.overlapping, "Drain activations overlapped")
            table.insert(order, cue.id)
        end
        assert(
            table.concat(order, ",") == "landing_fund,seed_bank,last_word,tap_driver,tap_driver",
            "Last Word must animate the target exactly twice in order"
        )
        for index = 1, 5 do
            assert(seen[index] == "drain", "Skipped a drain activation group")
        end
        sameBoard(host, receipt.nextShotValues or receipt.finalValues)
        table.insert(report.drains, {
            speed = speed,
            order = order,
            seconds = cues[#cues].time - cues[1].time,
            groups = #receipt.drainSteps,
        })
        assert(
            run.coins == receipt.coinsAfter and run.reserves == receipt.reservesAfter,
            "Presentation altered authoritative rewards"
        )
    end
    table.insert(
        report.checks,
        "Natural drain plays all five real model activations before settlement at1x/4x"
    )

    local _, skipHost, skipCues, skipReceipt = beginDrain(1)
    skipHost.feedback:skip()
    assert(skipHost.feedback.completedReceipt == skipReceipt.id, "Skip did not finish receipt")
    assert(not skipHost:hasActiveItemAnimations(), "Skip left model work queued")
    sameBoard(skipHost, skipReceipt.nextShotValues or skipReceipt.finalValues)
    local cueCount = #skipCues
    task.wait(0.2)
    assert(#skipCues == cueCount, "Skipped activation replayed")
    table.insert(
        report.checks,
        "Skip clears remaining drain models/FX and applies exact final board"
    )

    controller.select("Event")
    local run, host = controller.run, controller.view
    run.reserves = 3
    local beforeCoins, beforeCredits, round =
        run.coins, controller.session.profile.restockCredits, run.round
    local choice
    for index, entry in run.eventChoices do
        if entry.id == "grow" then
            choice = index
        end
    end
    assert(choice, "Missing growth event")
    readyModels(host)
    controller.send("chooseEvent", { index = choice })
    waitFor(function()
        return host.feedback.timeline
            and run.settlementReceipt
            and run.settlementReceipt.kind == "event"
    end, "growth event timeline")
    local receipt = run.settlementReceipt
    local stages, applied, moving = {}, false, false
    waitFor(function()
        local feedback = host.feedback
        if feedback.timeline then
            local step = feedback.timeline[feedback.timelineIndex]
            if step then
                if stages[#stages] ~= step.kind then
                    table.insert(stages, step.kind)
                end
                if step.kind == "eventChange" and feedback.stepTime / step.duration > 0.4 then
                    sameBoard(host, receipt.eventValues)
                    applied = true
                elseif step.kind == "shuffle" and feedback.stepTime / step.duration > 0.2 then
                    assert(applied, "Shuffle began before visible growth")
                    for id, peg in host.pegs do
                        local slot = Board.Slots[id]
                        if
                            peg.value > 0
                            and (peg.part.Position - Vector3.new(slot.x, slot.y, 0.62)).Magnitude
                                > 0.05
                        then
                            moving = true
                        end
                    end
                end
            end
        end
        return feedback.completedReceipt == receipt.id and not feedback:isBusy()
    end, "growth event completion")
    assert(
        stages[1] == "eventChange" and stages[2] == "shuffle" and stages[3] == "refill",
        "Event must apply, shuffle, then restock"
    )
    assert(applied and moving, "Growth or physical peg shuffle was not shown")
    assert(run.coins == beforeCoins + 1 and run.reserves == 4, "Free restock coin/ball missing")
    assert(
        controller.session.profile.restockCredits == beforeCredits,
        "Free event farmed saved credits"
    )
    sameBoard(host, receipt.nextShotValues or receipt.finalValues)
    waitFor(function()
        return run.phase == "aim"
    end, "event route resumes")
    assert(run.round == round, "Free restock advanced an extra round")
    report.eventStages = stages
    table.insert(
        report.checks,
        "Growth is visible before physical shuffle, free restock and capped rewards"
    )
    report.ok = true
end, debug.traceback)

if controller then
    controller.select("Aim")
    controller.toolbar.Enabled = true
    report.restored = true
end
report.elapsedSeconds = os.clock() - started
if not ok then
    report.failure = tostring(failure)
end
script:SetAttribute("Result", Http:JSONEncode(report))
print("[RBX-031 Drain/Event audit] " .. Http:JSONEncode(report))
if not ok then
    error(failure)
end
