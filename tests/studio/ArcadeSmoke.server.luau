-- Opt-in isolated Studio test; not mapped into any game build.
local Players = game:GetService("Players")
local service = game:GetService("StudioTestService")
local remote = Instance.new("RemoteEvent")
remote.Name = "ArcadeQARemote"
remote.Parent = game.ReplicatedStorage
local received = {}
local report = { steps = {}, maxPlayers = 0 }
remote.OnServerEvent:Connect(function(player, command, result)
    received[command] = received[command] or {}
    received[command][player.UserId] = result
end)
local function waitFor(fn, seconds)
    local started = os.clock()
    repeat
        if fn() then
            return
        end
        task.wait(0.1)
    until os.clock() - started > (seconds or 35)
    error("Timed out waiting for server condition")
end
local function complete(stage, count)
    waitFor(function()
        local n = 0
        for _ in received[stage] or {} do
            n += 1
        end
        return n >= count
    end, 50)
    local entries = {}
    for id, value in received[stage] do
        assert(value.ok, stage .. " client " .. id .. ": " .. tostring(value.result))
        entries[tostring(id)] = value.result
    end
    report.steps[stage] = entries
end
task.spawn(function()
    local ok, err = xpcall(function()
        complete("ready", 8)
        assert(#Players:GetPlayers() == 8, "eight actual connected players")
        report.maxPlayers = #Players:GetPlayers()
        local stations = {}
        for _, p in Players:GetPlayers() do
            local station = p:GetAttribute("PegStation")
            assert(station and not stations[station], "unique station")
            stations[station] = true
        end
        for _, stage in { "start", "launch", "hub", "resume" } do
            remote:FireAllClients(stage)
            complete(stage, 8)
        end
        local ordered = Players:GetPlayers()
        table.sort(ordered, function(a, b)
            return a.UserId < b.UserId
        end)
        local departing = ordered[1]
        local station = departing:GetAttribute("PegStation")
        departing:Kick("Arcade QA: verifying station cleanup")
        waitFor(function()
            return #Players:GetPlayers() == 7
        end)
        task.wait(0.5)
        assert(
            workspace.AquariumArcade
                :FindFirstChild("ArcadeStation" .. station, true)
                :GetAttribute("OccupantUserId") == nil,
            "departed pod cleared"
        )
        report.departure = { remaining = 7, freedStation = station }
        remote:FireAllClients("idle")
        complete("idle", 7)
    end, debug.traceback)
    report.ok = ok
    report.error = if ok then nil else tostring(err)
    service:EndTest(report)
end)
