-- Two native runs using ordinary client actions and visible first-hit aiming.
-- No scores, items, currency or run state are injected. A shot is manually ended
-- only after 45 simulated seconds, exactly as the ordinary End Shot action allows.
local Shared = game.ReplicatedStorage.Shared
local Board, Simulation, Catalog =
    require(Shared.Board), require(Shared.Simulation), require(Shared.Catalog)
local remotes = game.ReplicatedStorage:WaitForChild("PegRemotes")
local report = { running = true, runs = {} }
-- selene: allow(global_usage)
_G.RestockPlay = report
local state
local connection = remotes.State.OnClientEvent:Connect(function(s)
    state = s
end)
local function send(kind, payload)
    remotes.Action:FireServer(kind, payload)
    task.wait(0.2)
end
local function waitFor(predicate)
    local start = os.clock()
    repeat
        if predicate() then
            return
        end
        task.wait(0.1)
    until os.clock() - start > 20
    error("Native restock play condition timed out")
end
local function aim(s)
    local best, chosen = -1, 0
    for i = 0, 46 do
        local angle = -1.15 + i * 0.05
        local points = Simulation.preview(angle, s.values)
        local last = points[#points]
        for id, slot in Board.Slots do
            local distance = ((last.x - slot.x) ^ 2 + (last.y - slot.y) ^ 2) ^ 0.5
            if
                s.values[id] > best
                and distance < Board.Geometry.pegRadius + Board.Geometry.ballRadius + 0.001
            then
                best, chosen = s.values[id], angle
            end
        end
    end
    return chosen
end
task.spawn(function()
    local ok, err = xpcall(function()
        send("ready")
        waitFor(function()
            return state ~= nil
        end)
        assert(
            state.sessionView == "hub" and not state.hub.canResume,
            "Begin in a fresh isolated hub"
        )
        for index = 1, 2 do
            local runReport = { shots = 0, extras = 0, maxRestocks = 0, manualEnds = 0 }
            table.insert(report.runs, runReport)
            local before = state.hub.chests.restockCredits
            send("startRun")
            waitFor(function()
                return state.sessionView == "run"
            end)
            local started, seen = os.clock(), {}
            local shop, perk, event
            while os.clock() - started < 240 do
                runReport.phase = state.phase
                runReport.cleared = state.highestClearedRound
                local receipt = state.settlementReceipt
                if receipt and not seen[receipt.id] then
                    seen[receipt.id] = true
                    runReport.extras += math.max(0, receipt.earnedRestocks - 1)
                    runReport.maxRestocks = math.max(runReport.maxRestocks, receipt.earnedRestocks)
                    assert(#receipt.cycles <= 5, "Native receipt exceeds five full visual cycles")
                end
                if state.phase == "gameover" then
                    break
                elseif state.phase == "aim" then
                    if state.speed ~= 4 then
                        send("speed", { value = 4 })
                    end
                    if state.canJumble and state.lastResult and not state.lastResult.success then
                        send("jumble")
                    end
                    runReport.shots += 1
                    send("launch", { angle = aim(state) })
                elseif state.phase == "flight" and state.elapsed >= 45 then
                    runReport.manualEnds += 1
                    send("endShot")
                elseif state.phase == "shop" and shop ~= state.round then
                    shop = state.round
                    for offerIndex, offer in state.shopOffers do
                        if
                            Catalog.purchaseState(state.inventory, state.slots, offer, state.coins).allowed
                        then
                            send("buy", { offer = offerIndex, expectedId = offer.id })
                        end
                    end
                    send("continue")
                elseif state.phase == "perk" and perk ~= state.round then
                    perk = state.round
                    send("choosePerk", { index = 1 })
                elseif state.phase == "event" and event ~= state.round then
                    event = state.round
                    send("chooseEvent", { index = 1 })
                else
                    task.wait(0.1)
                end
            end
            assert(state.phase == "gameover", "Ordinary run must finish within native test budget")
            send("enterHub")
            waitFor(function()
                return state.sessionView == "hub"
            end)
            runReport.wallet = state.hub.chests.restockCredits
            assert(
                runReport.wallet - before == runReport.extras,
                "Native wallet agrees with settled extras"
            )
            runReport.seconds = os.clock() - started
            runReport.index = index
        end
    end, debug.traceback)
    report.ok, report.error, report.running = ok, if ok then nil else tostring(err), false
    connection:Disconnect()
end)
return "Two native ordinary restock runs started"
