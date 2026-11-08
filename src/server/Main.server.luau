--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Run = require(ReplicatedStorage.Shared.Run)
local Profile = require(ReplicatedStorage.Shared.Profile)
local ProfileStore = require(script.Parent.ProfileStore)

Players.CharacterAutoLoads = false

local remotes = Instance.new("Folder")
remotes.Name = "PegRemotes"
local actionRemote = Instance.new("RemoteEvent")
actionRemote.Name = "Action"
actionRemote.Parent = remotes
local stateRemote = Instance.new("RemoteEvent")
stateRemote.Name = "State"
stateRemote.Parent = remotes
remotes.Parent = ReplicatedStorage

local sessions = {}
local leaving = {}
local allowed = {
    launch = true,
    jumble = true,
    endShot = true,
    continue = true,
    buy = true,
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
}

local function captureProfile(session)
    session.profile = Profile.merge(session.profile, session.run:profile())
    return session.profile
end

local function save(player, session)
    if session.saving then
        return
    end
    session.saving = true
    local _, status = ProfileStore.save(player.UserId, captureProfile(session))
    session.profileStatus = status
    session.lastSave = os.clock()
    session.saving = false
end

local function sendState(player, session, notice)
    if player.Parent ~= Players then
        return
    end
    local snapshot = session.run:snapshot()
    local events = {}
    for _, event in snapshot.events or {} do
        if event.id > session.lastEvent then
            table.insert(events, event)
            session.lastEvent = event.id
        end
    end
    snapshot.events = events
    snapshot.profileStatus = session.profileStatus
    snapshot.notice = notice
    session.sequence += 1
    snapshot.sequence = session.sequence
    session.phase = snapshot.phase
    player:SetAttribute("PegPhase", snapshot.phase)
    player:SetAttribute("PegRound", snapshot.round)
    player:SetAttribute("PegScore", snapshot.score)
    player:SetAttribute("PegQuota", snapshot.quota)
    player:SetAttribute("PegRecordsMode", session.profileStatus)
    stateRemote:FireClient(player, snapshot)
end

local function added(player)
    local profile, status = ProfileStore.load(player.UserId)
    if player.Parent ~= Players then
        return
    end
    local seed = (os.time() + player.UserId * 31 + math.floor(os.clock() * 1000)) % 2147483647
    local session = {
        run = Run.new(seed, profile),
        profile = profile,
        profileStatus = status,
        tokens = 20,
        lastAction = os.clock(),
        lastEvent = 0,
        sequence = 0,
        sendElapsed = 0,
        lastSave = os.clock(),
        saving = false,
        phase = "aim",
    }
    sessions[player] = session
    sendState(player, session)
end

Players.PlayerAdded:Connect(added)
for _, player in Players:GetPlayers() do
    task.spawn(added, player)
end

actionRemote.OnServerEvent:Connect(function(player, kind, payload)
    local session = sessions[player]
    if not session or type(kind) ~= "string" or #kind > 24 then
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
    -- The server owns all scores, RNG, offers and inventory. Clients only request actions.
    local ok, accepted, message = pcall(function()
        return session.run:action(kind, payload or {})
    end)
    if not ok then
        warn("[Pop a Peg] Rejected malformed action: " .. kind)
        sendState(player, session, "That action could not be applied.")
        return
    end
    sendState(player, session, if accepted then nil else message)
end)

RunService.Heartbeat:Connect(function(dt)
    local elapsed = math.min(dt, 0.25)
    for player, session in sessions do
        session.run:step(elapsed)
        session.sendElapsed += elapsed
        local interval = if session.phase == "flight" then 1 / 20 else 0.5
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
    if session then
        leaving[player] = true
        -- A concurrent save only stores monotonic fields; merge this final snapshot afterward.
        while session.saving do
            task.wait(0.05)
        end
        save(player, session)
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
            save(player, session)
            remaining -= 1
        end)
    end
    local started = os.clock()
    while (remaining > 0 or next(leaving) ~= nil) and os.clock() - started < 25 do
        task.wait(0.1)
    end
end)

print("[Pop a Peg] Independent run service ready")
