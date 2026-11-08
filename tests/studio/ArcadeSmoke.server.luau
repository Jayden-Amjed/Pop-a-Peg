-- Opt-in isolated Studio test; not mapped into any game build.
-- Before running, disable ServerScriptService.Server.Main in EDIT. This harness
-- seeds only Studio's in-memory repository, then enables Main in the test server.
-- Afterward restore Edit Main.Disabled=false and remove both ArcadeMultiQA scripts.
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local service = game:GetService("StudioTestService")
local remote = Instance.new("RemoteEvent")
remote.Name = "ArcadeQARemote"
remote.Parent = game.ReplicatedStorage
local received = {}
local report = {
    steps = {},
    maxPlayers = 0,
    fixture = "isolated Studio session profiles",
    persistedChecks = {},
}
local fixtures = {}
local profileStore
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

local function verifyProgression(expectedSerial, expectedOwned, requestSuffix)
    for _, player in Players:GetPlayers() do
        local saved, mode = profileStore.load(player.UserId)
        local fixture = fixtures[player.UserId]
        assert(mode == "session", "Fixture must never access production storage")
        assert(saved.chests.common == fixture.chests - 2, "Chest consumption remains player-owned")
        assert(#saved.itemUnlocks == expectedOwned, "Only expected blueprint unlocks persisted")
        assert(saved.chestSerial == expectedSerial, "Replay cannot increase award serial")
        assert(
            #saved.chestReceipts == expectedSerial,
            "Retry ledger stores distinct operations only"
        )
        assert(
            saved.lastOpened.requestId == "ArcadeQA_" .. player.UserId .. requestSuffix,
            "Correct original acknowledgement persisted"
        )
        assert(
            saved.bestEndlessRound == 0 and saved.robuxSpent == 0,
            "Campaign/coins do not populate unrelated rankings"
        )
        assert(saved.playSeconds >= 1, "Actual session time is persisted")
        local spent = if expectedSerial == 3 then 12 else 0
        assert(saved.research == fixture.research - spent, "Research debit is isolated per player")
    end
end
task.spawn(function()
    local ok, err = xpcall(function()
        assert(RunService:IsStudio(), "Never install this fixture outside Studio")
        local mainScript = game.ServerScriptService.Server.Main
        assert(
            mainScript.Disabled,
            "Disable ServerScriptService.Server.Main in Edit before this fixture"
        )
        Players.CharacterAutoLoads = false
        waitFor(function()
            return #Players:GetPlayers() == 8
        end, 50)
        local Profile = require(game.ReplicatedStorage.Shared.Profile)
        profileStore = require(game.ServerScriptService.Server.ProfileStore)
        local fixturePlayers = Players:GetPlayers()
        table.sort(fixturePlayers, function(a, b)
            return a.UserId < b.UserId
        end)
        for index, player in fixturePlayers do
            local profile = Profile.clean({
                version = 2,
                chests = { common = index + 2 },
                research = index + 12,
                restockCredits = index + 250,
            })
            assert(#profile.itemUnlocks == 8, "Fixture begins with the real starter pool")
            local saved, mode = profileStore.save(player.UserId, profile)
            assert(saved and mode == "session", "Fixture uses isolated in-memory profiles only")
            fixtures[player.UserId] = { chests = index + 2, research = index + 12 }
            player:SetAttribute("ArcadeQAChests", index + 2)
            player:SetAttribute("ArcadeQAResearch", index + 12)
            player:SetAttribute("ArcadeQARestocks", index + 250)
        end
        mainScript.Disabled = false
        complete("ready", 8)
        assert(#Players:GetPlayers() == 8, "eight actual connected players")
        report.maxPlayers = #Players:GetPlayers()
        local stations = {}
        for _, p in Players:GetPlayers() do
            local station = p:GetAttribute("PegStation")
            assert(station and not stations[station], "unique station")
            stations[station] = true
        end
        for _, stage in
            {
                "chestA",
                "chestB",
                "replayA",
                "wrongReplay",
                "research",
                "market",
                "start",
                "runChestReject",
                "launch",
                "hub",
                "resume",
            }
        do
            remote:FireAllClients(stage)
            complete(stage, 8)
            if stage == "replayA" or stage == "wrongReplay" then
                verifyProgression(2, 10, "_A")
                report.persistedChecks[stage] = 8
            elseif stage == "research" then
                verifyProgression(3, 11, "_R")
                report.persistedChecks[stage] = 8
            elseif stage == "market" then
                for _, player in Players:GetPlayers() do
                    local saved, mode = profileStore.load(player.UserId)
                    assert(mode == "session", "Market fixtures stay in Studio memory")
                    assert(
                        saved.restockCredits == player:GetAttribute("ArcadeQARestocks") - 250,
                        "Private wallet debit persisted once"
                    )
                    assert(
                        saved.chests.uncommon == 1 and saved.chestSerial == 4,
                        "One purchase survived retries and rejections"
                    )
                end
                report.persistedChecks[stage] = 8
            end
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
