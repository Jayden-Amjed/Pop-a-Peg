--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local PhysicsService = game:GetService("PhysicsService")
local ArcadeSessions = require(script.Parent.ArcadeSessions)
local HubWorld = require(script.Parent.HubWorld)
local ProfileStore = require(script.Parent.ProfileStore)
local LeaderboardService = require(script.Parent.LeaderboardService)

Players.CharacterAutoLoads = false
pcall(function()
    PhysicsService:RegisterCollisionGroup("ArcadePlayers")
end)
PhysicsService:CollisionGroupSetCollidable("ArcadePlayers", "ArcadePlayers", false)

local remotes = Instance.new("Folder")
remotes.Name = "PegRemotes"
local actionRemote = Instance.new("RemoteEvent")
actionRemote.Name, actionRemote.Parent = "Action", remotes
local stateRemote = Instance.new("RemoteEvent")
stateRemote.Name, stateRemote.Parent = "State", remotes
remotes.Parent = ReplicatedStorage

local arcade = ArcadeSessions.new()
local leaderboards = LeaderboardService.new()
local sessions, leaving = {}, {}
local world, requestAction, loadCharacter
local allowed = {
    startRun = true,
    enterHub = true,
    launch = true,
    jumble = true,
    endShot = true,
    continue = true,
    buy = true,
    cycleEvolution = true,
    reroll = true,
    freeze = true,
    buySlot = true,
    sell = true,
    move = true,
    choosePerk = true,
    skipPerk = true,
    chooseEvent = true,
    restart = true,
    endless = true,
    speed = true,
    openChest = true,
    researchItem = true,
}

local function seedFor(player)
    return (os.time() + player.UserId * 31 + math.floor(os.clock() * 1000)) % 2147483647
end

local function save(player, session, release)
    if session.saving or session.loading then
        return
    end
    session.saving = true
    local profile = arcade:capture(session)
    local saved, status = ProfileStore.save(player.UserId, profile, release)
    session.profileStatus = status
    session.lastSave, session.saving = os.clock(), false
    if saved then
        task.spawn(function()
            leaderboards:publish(player.UserId, session.name, profile)
        end)
    end
    if status == "locked" and player.Parent == Players then
        player:Kick("Your profile opened in another server. Rejoin to continue safely.")
    end
    return saved
end

local function setCharacterMode(player, session, reposition)
    local character = player.Character
    if not character then
        return
    end
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    local root = character:FindFirstChild("HumanoidRootPart")
    if not humanoid or not root then
        return
    end
    local inHub = session.view == "hub"
    root.Anchored = not inHub
    root.AssemblyLinearVelocity, root.AssemblyAngularVelocity = Vector3.zero, Vector3.zero
    humanoid.WalkSpeed = if inHub then 16 else 0
    humanoid.JumpPower = if inHub then 50 else 0
    humanoid.JumpHeight = if inHub then 7.2 else 0
    humanoid.AutoRotate = inHub
    if reposition then
        character:PivotTo(world:spawnCFrame(session.station))
    end
end

local function sendState(player, session, notice)
    if player.Parent ~= Players or session.loading then
        return
    end
    local snapshot = arcade:snapshot(player.UserId)
    if not snapshot then
        return
    end
    if snapshot.sessionView == "run" then
        local events = {}
        for _, event in snapshot.events or {} do
            if event.id > session.lastEvent then
                table.insert(events, event)
                session.lastEvent = event.id
            end
        end
        snapshot.events = events
    end
    snapshot.profileStatus, snapshot.notice = session.profileStatus, notice
    if snapshot.hub then
        snapshot.hub.leaderboards = leaderboards:snapshot(arcade.players)
        snapshot.hub.progressionPending = session.progressionBusy == true
    end
    session.sequence += 1
    snapshot.sequence = session.sequence
    session.phase = if session.run then session.run.phase else "hub"
    player:SetAttribute("PegView", session.view)
    player:SetAttribute("PegStation", session.station)
    player:SetAttribute("PegPhase", if session.view == "hub" then "hub" else session.phase)
    player:SetAttribute("PegRound", if session.run then session.run.round else 1)
    player:SetAttribute("PegScore", if session.run then session.run.score else 0)
    player:SetAttribute("PegQuota", if session.run then session.run.quota else 0)
    player:SetAttribute("PegRecordsMode", session.profileStatus)
    stateRemote:FireClient(player, snapshot)
end

local function updateStations()
    local occupied = {}
    for _, entry in arcade:roster() do
        occupied[entry.station] = true
        world:setStation(entry.station, entry)
    end
    for station = 1, ArcadeSessions.Capacity do
        if not occupied[station] then
            world:setStation(station, nil)
        end
    end
    if world.setLeaderboards then
        world:setLeaderboards(leaderboards:snapshot(arcade.players))
    end
end

requestAction = function(player, kind, payload)
    local session = sessions[player]
    if
        not session
        or session.loading
        or session.progressionBusy
        or type(kind) ~= "string"
        or #kind > 24
    then
        return
    end
    local now = os.clock()
    session.tokens = math.min(20, session.tokens + (now - session.lastAction) * 10)
    session.lastAction = now
    if session.tokens < 1 then
        return
    end
    session.tokens -= 1
    if kind == "ready" then
        sendState(player, session)
        return
    end
    if not allowed[kind] or (payload ~= nil and type(payload) ~= "table") then
        return
    end
    local before = session.view
    local progression = kind == "openChest" or kind == "researchItem"
    if progression and session.saving then
        sendState(player, session, "Finishing your save. Try again in a moment.")
        return
    end
    local ok, accepted, message = pcall(function()
        return arcade:action(player.UserId, kind, payload or {}, seedFor(player))
    end)
    if not ok then
        warn("[Pop a Peg] Rejected malformed action: " .. kind)
        sendState(player, session, "That action could not be applied.")
        return
    end
    if accepted and before ~= session.view then
        setCharacterMode(player, session, session.view == "hub")
        updateStations()
        if session.view == "hub" then
            task.spawn(save, player, session)
            if not player.Character or not player.Character:FindFirstChild("HumanoidRootPart") then
                task.spawn(loadCharacter, player, session)
            end
        end
    end
    if accepted and progression then
        session.progressionBusy = true
        local saved = save(player, session)
        session.progressionBusy = false
        if not saved then
            sendState(
                player,
                session,
                "Unlock received here; saving is retrying. Stay connected to keep progress."
            )
            return
        end
    end
    sendState(player, session, if accepted then nil else message)
end

world = HubWorld.new(function(player, station)
    local session = sessions[player]
    if not session or session.loading or session.view ~= "hub" then
        return
    end
    if session.station ~= station then
        sendState(
            player,
            session,
            "Your arcade is pod " .. session.station .. ". Or press Play below."
        )
        return
    end
    local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
    if not root or (root.Position - world:spawnCFrame(station).Position).Magnitude > 18 then
        return
    end
    requestAction(player, "startRun")
end)

loadCharacter = function(player, session, attempt)
    if player.Parent ~= Players or sessions[player] ~= session or session.spawning then
        return
    end
    session.spawning = true
    attempt = attempt or 1
    local ok = pcall(function()
        player:LoadCharacterAsync()
    end)
    session.spawning = false
    if ok and player.Parent == Players and sessions[player] == session then
        setCharacterMode(player, session, true)
        if not session.hasSpawned and session.view == "hub" and player.Character then
            player.Character:PivotTo(world:spawnCFrame(0))
        end
        session.hasSpawned = true
    end
    if not ok and player.Parent == Players then
        sendState(player, session, "Avatar is loading. You can still press Play.")
        if attempt < 3 then
            task.delay(attempt * 2, loadCharacter, player, session, attempt + 1)
        end
    end
end

local function characterAdded(player, session, character)
    local humanoid = character:WaitForChild("Humanoid", 10)
    local root = character:WaitForChild("HumanoidRootPart", 10)
    if not humanoid or not root or sessions[player] ~= session then
        return
    end
    for _, object in character:GetDescendants() do
        if object:IsA("BasePart") then
            object.CollisionGroup = "ArcadePlayers"
        end
    end
    local forceField = character:FindFirstChildOfClass("ForceField")
    if forceField then
        forceField.Visible = false
    end
    setCharacterMode(player, session, true)
    humanoid.Died:Once(function()
        task.delay(1, loadCharacter, player, session)
    end)
end

local function added(player)
    local session, message = arcade:add(player.UserId, player.DisplayName)
    if not session then
        player:Kick(message)
        return
    end
    -- Reserve the station before the first yielding profile/avatar operation.
    sessions[player] = session
    session.loading, session.saving, session.spawning = true, false, false
    session.tokens, session.lastAction, session.lastEvent = 20, os.clock(), 0
    session.sequence, session.sendElapsed, session.lastSave = 0, 0, os.clock()
    session.characterConnection = player.CharacterAdded:Connect(function(character)
        characterAdded(player, session, character)
    end)
    local profile, status = ProfileStore.load(player.UserId)
    if player.Parent ~= Players or sessions[player] ~= session then
        if profile then
            ProfileStore.save(player.UserId, profile, true)
        end
        return
    end
    if not profile then
        player:Kick(
            if status == "locked"
                then "Your profile is still open in another server. Please rejoin shortly."
                else "Your progress could not be loaded safely. Please rejoin shortly."
        )
        return
    end
    session.profile, session.profileStatus, session.loading = profile, status, false
    task.spawn(function()
        leaderboards:publish(player.UserId, session.name, profile)
    end)
    updateStations()
    sendState(player, session)
    task.spawn(loadCharacter, player, session)
end

Players.PlayerAdded:Connect(added)
for _, player in Players:GetPlayers() do
    task.spawn(added, player)
end
actionRemote.OnServerEvent:Connect(requestAction)

local hubElapsed = 0
RunService.Heartbeat:Connect(function(dt)
    local elapsed = math.min(dt, 0.25)
    arcade:step(elapsed, dt)
    hubElapsed += elapsed
    if hubElapsed >= 1 then
        hubElapsed = 0
        updateStations()
        for player, session in sessions do
            local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
            if session.view == "hub" and root then
                local home = world:spawnCFrame(session.station).Position
                if root.Position.Y < home.Y - 30 or (root.Position - home).Magnitude > 200 then
                    setCharacterMode(player, session, true)
                end
            end
        end
    end
    for player, session in sessions do
        session.sendElapsed += elapsed
        local interval = if session.view == "run" and session.run.phase == "flight"
            then 1 / 20
            else 0.5
        if session.sendElapsed >= interval then
            session.sendElapsed = 0
            sendState(player, session)
        end
        if os.clock() - session.lastSave >= 60 and not session.saving then
            task.spawn(save, player, session)
        end
    end
end)

Players.PlayerRemoving:Connect(function(player)
    local session = sessions[player]
    sessions[player] = nil
    arcade:remove(player.UserId)
    if session then
        if session.characterConnection then
            session.characterConnection:Disconnect()
        end
        updateStations()
        leaving[player] = true
        while session.saving do
            task.wait(0.05)
        end
        save(player, session, true)
        leaving[player] = nil
    end
end)

game:BindToClose(function()
    local remaining = 0
    for player, session in sessions do
        remaining += 1
        task.spawn(function()
            while session.saving do
                task.wait(0.05)
            end
            save(player, session, true)
            remaining -= 1
        end)
    end
    local started = os.clock()
    while (remaining > 0 or next(leaving) ~= nil) and os.clock() - started < 25 do
        task.wait(0.1)
    end
end)

print("[Pop a Peg] Eight-player aquarium arcade ready")
