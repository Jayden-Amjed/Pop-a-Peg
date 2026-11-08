-- Opt-in ordinary-action smoke test. No run/profile values are granted or changed.
local Shared = game.ReplicatedStorage.Shared
local Board = require(Shared.Board)
local Simulation = require(Shared.Simulation)
local Catalog = require(Shared.Catalog)
local remotes = game.ReplicatedStorage:WaitForChild("PegRemotes")
local report = { running = true, shots = 0, maxCleared = 0, actions = 0 }
-- MCP reads this opt-in test report after the asynchronous play loop finishes.
-- selene: allow(global_usage)
_G.ProgressionPlay = report
local state
local connection = remotes.State.OnClientEvent:Connect(function(snapshot)
    state = snapshot
    report.phase = state.phase
    report.maxCleared = math.max(report.maxCleared, state.highestClearedRound or 0)
end)
local function action(kind, payload)
    report.actions += 1
    remotes.Action:FireServer(kind, payload)
    task.wait(0.25)
end
local function waitFor(predicate, limit)
    local start = os.clock()
    repeat
        if predicate() then
            return
        end
        task.wait(0.1)
    until os.clock() - start > (limit or 15)
    error("Progression play condition timed out")
end
local function aim(snapshot)
    local best, chosen = -1, 0
    for i = 0, 46 do
        local angle = -1.15 + i * 0.05
        local points = Simulation.preview(angle, snapshot.values)
        local last = points[#points]
        for id, slot in Board.Slots do
            local distance = ((last.x - slot.x) ^ 2 + (last.y - slot.y) ^ 2) ^ 0.5
            if
                snapshot.values[id] > best
                and distance < Board.Geometry.pegRadius + Board.Geometry.ballRadius + 0.001
            then
                best, chosen = snapshot.values[id], angle
            end
        end
    end
    return chosen
end
task.spawn(function()
    local started = os.clock()
    local ok, err = xpcall(function()
        action("ready")
        waitFor(function()
            return state ~= nil
        end)
        if state.sessionView == "hub" then
            action("startRun")
        end
        waitFor(function()
            return state.sessionView == "run"
        end)
        local initialRun = state.runId
        local initialPool = #state.itemUnlocks
        local lastShop, lastPerk, lastEvent
        while os.clock() - started < 240 do
            if state.phase == "aim" then
                if state.speed ~= 4 then
                    action("speed", { value = 4 })
                end
                if
                    report.maxCleared < 3
                    and state.canJumble
                    and state.lastResult
                    and not state.lastResult.success
                then
                    action("jumble")
                end
                report.shots += 1
                action("launch", { angle = aim(state) })
                if report.maxCleared >= 3 then
                    action("endShot")
                end
            elseif state.phase == "shop" and lastShop ~= state.round then
                lastShop = state.round
                for index, offer in state.shopOffers do
                    if
                        Catalog.purchaseState(state.inventory, state.slots, offer, state.coins).allowed
                    then
                        action("buy", { offer = index, expectedId = offer.id })
                    end
                end
                action("continue")
            elseif state.phase == "perk" and lastPerk ~= state.round then
                lastPerk = state.round
                action("choosePerk", { index = 1 })
            elseif state.phase == "event" and lastEvent ~= state.round then
                lastEvent = state.round
                action("chooseEvent", { index = 1 })
            elseif state.phase == "gameover" then
                assert(report.maxCleared >= 3, "Run ended before chest eligibility")
                break
            else
                task.wait(0.1)
            end
        end
        assert(state.phase == "gameover", "Normal run reached defeat in time")
        action("enterHub")
        waitFor(function()
            return state.sessionView == "hub"
        end)
        local chests = state.hub.chests
        local tier, count
        for _, entry in chests.tiers do
            if entry.count > 0 then
                tier, count = entry.id, entry.count
                break
            end
        end
        assert(tier, "Earned chest is present in hub")
        report.earnedTier, report.beforeCount = tier, count
        local requestId = "ordinary-play-" .. game:GetService("HttpService"):GenerateGUID(false)
        action("openChest", { tier = tier, requestId = requestId })
        waitFor(function()
            return state.hub.chests.lastOpened
                and state.hub.chests.lastOpened.requestId == requestId
        end)
        local opened = state.hub.chests.lastOpened
        assert(opened.itemId, "Starter collection receives an unowned item")
        report.unlocked = opened.itemId
        for _, entry in state.hub.chests.tiers do
            if entry.id == tier then
                assert(entry.count == count - 1, "Exactly one chest consumed")
            end
        end
        action("startRun")
        waitFor(function()
            return state.sessionView == "run" and state.runId ~= initialRun
        end)
        assert(table.find(state.itemUnlocks, opened.itemId), "New run receives the new blueprint")
        assert(#state.itemUnlocks == initialPool + 1, "Only the earned item expands the pool")
        report.newPoolSize = #state.itemUnlocks
        action("enterHub")
        waitFor(function()
            return state.sessionView == "hub"
        end)
    end, debug.traceback)
    report.ok, report.error = ok, if ok then nil else tostring(err)
    report.elapsed, report.running = os.clock() - started, false
    connection:Disconnect()
end)
return "Ordinary-action progression play started"
