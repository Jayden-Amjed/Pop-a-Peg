-- Server-owned station allocation and hub/run lifecycle; no Roblox instances here.
local Shared = if script then game:GetService("ReplicatedStorage").Shared else nil
local Run = if Shared then require(Shared.Run) else require("../shared/Run")
local Profile = if Shared then require(Shared.Profile) else require("../shared/Profile")

local ArcadeSessions = { Capacity = 8 }
ArcadeSessions.__index = ArcadeSessions

function ArcadeSessions.new()
    return setmetatable({ players = {}, stations = {} }, ArcadeSessions)
end

function ArcadeSessions:add(userId, name, profile)
    if self.players[userId] then
        return nil, "Already in the arcade."
    end
    local station
    for index = 1, ArcadeSessions.Capacity do
        if not self.stations[index] then
            station = index
            break
        end
    end
    if not station then
        return nil, "This arcade is full. Please join another server."
    end
    local session = {
        userId = userId,
        name = name,
        station = station,
        view = "hub",
        profile = Profile.clean(profile),
        run = nil,
        runId = 0,
    }
    self.players[userId] = session
    self.stations[station] = userId
    return session
end

function ArcadeSessions:capture(session)
    if session.run then
        session.profile = Profile.merge(session.profile, session.run:profile())
    end
    return Profile.clean(session.profile)
end

function ArcadeSessions:remove(userId)
    local session = self.players[userId]
    if session then
        self:capture(session)
        self.players[userId] = nil
        self.stations[session.station] = nil
    end
    return session
end

function ArcadeSessions:canResume(session)
    return session.run ~= nil and session.run.phase ~= "gameover"
end

function ArcadeSessions:action(userId, kind, payload, seed)
    local session = self.players[userId]
    if not session then
        return false, "Join the arcade first."
    end
    if kind == "startRun" then
        if session.view ~= "hub" then
            return false, "Your run is already open."
        end
        if not self:canResume(session) then
            self:capture(session)
            session.run = Run.new(seed or 1, session.profile)
            session.runId += 1
            session.lastEvent = 0
        end
        session.view = "run"
        return true
    elseif kind == "enterHub" then
        if session.view ~= "run" then
            return false, "You are already in the arcade."
        end
        if session.run.phase == "flight" or session.run.phase == "settling" then
            return false, "Finish this shot before returning to the arcade."
        end
        self:capture(session)
        session.view = "hub"
        return true
    end
    if session.view ~= "run" or not session.run then
        return false, "Start or resume your run first."
    end
    return session.run:action(kind, payload)
end

function ArcadeSessions:step(dt)
    for _, session in self.players do
        if session.view == "run" and session.run then
            session.run:step(dt)
        end
    end
end

function ArcadeSessions:roster()
    local roster = {}
    for station = 1, ArcadeSessions.Capacity do
        local userId = self.stations[station]
        local session = userId and self.players[userId]
        if session then
            table.insert(roster, {
                userId = userId,
                name = session.name,
                station = station,
                view = session.view,
                round = if session.run then session.run.round else 1,
                bestRound = math.max(
                    session.profile.bestRound,
                    if session.run then session.run.bestRound else 0
                ),
            })
        end
    end
    return roster
end

function ArcadeSessions:snapshot(userId)
    local session = self.players[userId]
    if not session then
        return nil
    end
    if session.view == "run" then
        local snapshot = session.run:snapshot()
        snapshot.sessionView = "run"
        snapshot.runId = session.runId
        return snapshot
    end
    return {
        sessionView = "hub",
        hub = {
            capacity = ArcadeSessions.Capacity,
            station = session.station,
            players = self:roster(),
            profile = self:capture(session),
            canResume = self:canResume(session),
        },
    }
end

return ArcadeSessions
