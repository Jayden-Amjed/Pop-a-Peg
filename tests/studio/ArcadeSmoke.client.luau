-- Opt-in isolated Studio test; not mapped into any game build.
local Players = game:GetService("Players")
local p = Players.LocalPlayer
local remote = game.ReplicatedStorage:WaitForChild("ArcadeQARemote", 30)
if not remote then
    return
end
local actions = game.ReplicatedStorage:WaitForChild("PegRemotes", 60)
assert(actions, "Fixture must enable the normal server after seeding session profiles")
local state
local seenFlight = false
local firstReceipt, startingTime
local expectedChests, expectedResearch
local starterIds = {
    "tap_driver",
    "split_prism",
    "wall_meter",
    "landing_fund",
    "survey_lens",
    "resonator",
    "compass",
    "seed_bank",
}
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
local function requestId(suffix)
    return "ArcadeQA_" .. p.UserId .. suffix
end
local function chestCount()
    for _, tier in state.hub.chests.tiers do
        if tier.id == "common" then
            return tier.count
        end
    end
    error("Missing common chest tier")
end
local function checkProfile(expectedOwned, chestBalance, researchBalance)
    local profile = state.hub.profile
    assert(profile.version == 2, "New profile format reached this client")
    assert(#profile.itemUnlocks == expectedOwned, "Private owned count")
    for _, id in starterIds do
        assert(table.find(profile.itemUnlocks, id), "Starter retained: " .. id)
    end
    assert(
        profile.chests.common == chestBalance and chestCount() == chestBalance,
        "Private chest counts agree"
    )
    assert(
        profile.research == researchBalance and state.hub.chests.research == researchBalance,
        "Private research counts agree"
    )
    assert(
        profile.bestEndlessRound == 0 and profile.robuxSpent == 0,
        "No fabricated Endless/spending record"
    )
    assert(profile.chestReceipts == nil, "Private retry ledger is not replicated")
    local boards = state.hub.leaderboards
    assert(boards and boards.mode == "session", "Studio rankings are explicitly session-scoped")
    for _, category in { "time", "endless", "robux" } do
        assert(
            boards.categories[category] and type(boards.categories[category].entries) == "table",
            "Leaderboard category exists: " .. category
        )
    end
    assert(
        #boards.categories.endless.entries == 0 and #boards.categories.robux.entries == 0,
        "Zero-record boards stay empty"
    )
    assert(profile.playSeconds >= 1, "Time accrues without simulation-speed inflation")
end
local function progression(kind, payload, expectedId)
    local before = state.sequence
    actions.Action:FireServer(kind, payload)
    waitFor(function()
        return state.sequence > before
            and state.hub
            and not state.hub.progressionPending
            and state.hub.chests.lastOpened
            and state.hub.chests.lastOpened.requestId == expectedId
    end)
    return state.hub.chests.lastOpened
end
local function rejection(kind, payload)
    local before = state.sequence
    actions.Action:FireServer(kind, payload)
    waitFor(function()
        return state.sequence > before and state.notice ~= nil
    end)
end
remote.OnClientEvent:Connect(function(command)
    local ok, result = xpcall(function()
        if command == "chestA" then
            local opened = progression(
                "openChest",
                { tier = "common", requestId = requestId("_A") },
                requestId("_A")
            )
            firstReceipt = { serial = opened.serial, itemId = opened.itemId }
            assert(
                opened.kind == "chest" and opened.tier == "common" and opened.itemId,
                "Chest A returns a real equipment unlock"
            )
            checkProfile(9, expectedChests - 1, expectedResearch)
            return {
                owned = 9,
                chests = chestCount(),
                itemId = opened.itemId,
                serial = opened.serial,
            }
        elseif command == "chestB" then
            local opened = progression(
                "openChest",
                { tier = "common", requestId = requestId("_B") },
                requestId("_B")
            )
            assert(
                opened.itemId
                    and opened.itemId ~= firstReceipt.itemId
                    and opened.serial == firstReceipt.serial + 1,
                "Second chest finds a different locked blueprint"
            )
            checkProfile(10, expectedChests - 2, expectedResearch)
            return {
                owned = 10,
                chests = chestCount(),
                itemId = opened.itemId,
                serial = opened.serial,
            }
        elseif command == "replayA" then
            local opened = progression(
                "openChest",
                { tier = "common", requestId = requestId("_A") },
                requestId("_A")
            )
            assert(
                opened.serial == firstReceipt.serial and opened.itemId == firstReceipt.itemId,
                "Replay reacknowledges A exactly"
            )
            assert(
                state.hub.profile.chestSerial == 2,
                "Replay does not increment global award serial"
            )
            checkProfile(10, expectedChests - 2, expectedResearch)
            return {
                owned = 10,
                chests = chestCount(),
                serial = opened.serial,
                latestSerial = state.hub.profile.chestSerial,
            }
        elseif command == "wrongReplay" then
            rejection("openChest", { tier = "rare", requestId = requestId("_A") })
            rejection("researchItem", { id = "clockwork", requestId = requestId("_A") })
            checkProfile(10, expectedChests - 2, expectedResearch)
            assert(
                state.hub.chests.lastOpened.requestId == requestId("_A"),
                "Rejected rebinding keeps original receipt"
            )
            return {
                changedTierRejected = true,
                changedOperationRejected = true,
                chests = chestCount(),
            }
        elseif command == "research" then
            assert(
                not table.find(state.hub.profile.itemUnlocks, "clockwork"),
                "Common chests did not grant uncommon Tide Clock"
            )
            local opened = progression(
                "researchItem",
                { id = "clockwork", requestId = requestId("_R") },
                requestId("_R")
            )
            assert(
                opened.kind == "research" and opened.itemId == "clockwork" and opened.serial == 3,
                "Research returns selected blueprint"
            )
            checkProfile(11, expectedChests - 2, expectedResearch - 12)
            return {
                owned = 11,
                research = state.hub.profile.research,
                itemId = opened.itemId,
                serial = opened.serial,
            }
        elseif command == "start" then
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
                #state.itemUnlocks == 11 and table.find(state.itemUnlocks, "clockwork"),
                "New run receives this player's expanded pool"
            )
            assert(
                state.bestEndlessRound == 0 and not state.endlessMode,
                "Campaign start is not an Endless record"
            )
            assert(
                value.board and not value.hub and value.camera == "Scriptable" and value.anchored,
                "run presentation"
            )
            return value
        elseif command == "runChestReject" then
            rejection("openChest", { tier = "common", requestId = requestId("_RUN") })
            assert(
                state.sessionView == "run" and state.chestsEarned.common == expectedChests - 2,
                "Run view cannot open or spend chests"
            )
            assert(#state.itemUnlocks == 11, "Rejected request leaves run pool unchanged")
            return { rejected = true, chests = state.chestsEarned.common }
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
            checkProfile(11, expectedChests - 2, expectedResearch - 12)
            assert(
                state.hub.profile.playSeconds > startingTime,
                "Actual time advances across run and hub views"
            )
            assert(
                #state.hub.leaderboards.categories.time.entries == 8,
                "All eight native players appear in time rankings"
            )
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
    waitFor(function()
        return state.hub.profile.playSeconds >= 1
    end)
    expectedChests = p:GetAttribute("ArcadeQAChests")
    expectedResearch = p:GetAttribute("ArcadeQAResearch")
    assert(expectedChests and expectedResearch, "Server-owned test fixture identifiers replicated")
    startingTime = state.hub.profile.playSeconds
    checkProfile(8, expectedChests, expectedResearch)
    return inspect()
end, debug.traceback)
remote:FireServer("ready", { ok = ok, result = result })
