-- Opt-in isolated Studio test; not mapped into any game build.
local Players = game:GetService("Players")
local p = Players.LocalPlayer
local remote = game.ReplicatedStorage:WaitForChild("ArcadeQARemote", 30)
if not remote then
    return
end
local actions = game.ReplicatedStorage:WaitForChild("PegRemotes")
local state
local seenFlight = false
actions.State.OnClientEvent:Connect(function(s)
    state = s
    if s.phase == "flight" then
        seenFlight = true
    end
end)
local function waitFor(fn, seconds)
    local start = os.clock()
    repeat
        if fn() then
            return
        end
        task.wait(0.1)
    until os.clock() - start > (seconds or 20)
    error("Timed out waiting for client condition")
end
local function inspect()
    return {
        view = p:GetAttribute("PegView"),
        station = p:GetAttribute("PegStation"),
        -- EnumItem.Name is valid at runtime; Selene's generated enum type omits it.
        -- selene: allow(incorrect_standard_library_use)
        camera = workspace.CurrentCamera.CameraType.Name,
        board = p.PlayerGui:FindFirstChild("PopAPeg") ~= nil,
        hub = p.PlayerGui:FindFirstChild("PopAPegHub") ~= nil,
        anchored = p.Character
            and p.Character:FindFirstChild("HumanoidRootPart")
            and p.Character.HumanoidRootPart.Anchored,
        runId = state and state.runId,
        round = state and state.round,
        coins = state and state.coins,
    }
end
local function checkGuide()
    local marker = p.PlayerGui:FindFirstChild("PopAPegStationGuide")
    if not marker or not marker.Enabled or not marker.Adornee then
        return false
    end
    local station = p:GetAttribute("PegStation")
    assert(
        marker.Adornee.Parent:GetAttribute("Station") == station,
        "Beacon belongs to this player"
    )
    local total, enabled = 0, 0
    for _, object in workspace.AquariumArcade:GetDescendants() do
        if object:IsA("ProximityPrompt") and object.Name == "PlayArcade" then
            total += 1
            if object.Enabled then
                enabled += 1
                assert(
                    object.Parent.Parent:GetAttribute("Station") == station,
                    "Only own cabinet can prompt"
                )
            end
        end
    end
    return total == 8 and enabled == 1
end
remote.OnClientEvent:Connect(function(command)
    local ok, result = xpcall(function()
        if command == "start" then
            actions.Action:FireServer("startRun")
            waitFor(function()
                return state
                    and state.sessionView == "run"
                    and p.PlayerGui:FindFirstChild("PopAPeg")
            end)
            waitFor(function()
                local value = inspect()
                return value.board
                    and not value.hub
                    and value.camera == "Scriptable"
                    and value.anchored
            end, 10)
            local value = inspect()
            assert(
                value.board and not value.hub and value.camera == "Scriptable" and value.anchored,
                "run presentation"
            )
            return value
        elseif command == "launch" then
            seenFlight = false
            actions.Action:FireServer("launch", { angle = (math.abs(p.UserId) % 7 - 3) * 0.1 })
            waitFor(function()
                return seenFlight
            end)
            actions.Action:FireServer("enterHub")
            task.wait(0.1)
            assert(p:GetAttribute("PegView") == "run", "cannot escape flight")
            actions.Action:FireServer("endShot")
            waitFor(function()
                return state.phase ~= "flight" and state.phase ~= "settling"
            end)
            return { flight = seenFlight, phase = state.phase, score = state.score }
        elseif command == "hub" then
            waitFor(function()
                return state.phase ~= "flight" and state.phase ~= "settling"
            end)
            -- Give the normal reward presentation time to finish before parking.
            task.wait(2)
            actions.Action:FireServer("enterHub")
            waitFor(function()
                return state.sessionView == "hub" and p.PlayerGui:FindFirstChild("PopAPegHub")
            end)
            task.wait(0.3)
            local value = inspect()
            assert(
                value.hub and not value.board and value.camera == "Custom" and not value.anchored,
                "hub restoration"
            )
            assert(#state.hub.players == 8, "all eight roster entries")
            waitFor(checkGuide)
            return value
        elseif command == "resume" then
            actions.Action:FireServer("startRun")
            waitFor(function()
                return state.sessionView == "run" and p.PlayerGui:FindFirstChild("PopAPeg")
            end)
            task.wait(0.2)
            return inspect()
        elseif command == "idle" then
            return inspect()
        end
    end, debug.traceback)
    remote:FireServer(command, { ok = ok, result = result })
end)
actions.Action:FireServer("ready")
local ok, result = xpcall(function()
    waitFor(function()
        return state
            and state.sessionView == "hub"
            and p.Character
            and p.Character:FindFirstChild("HumanoidRootPart")
            and p.PlayerGui:FindFirstChild("PopAPegHub")
    end, 45)
    task.wait(0.3)
    waitFor(checkGuide)
    return inspect()
end, debug.traceback)
remote:FireServer("ready", { ok = ok, result = result })
