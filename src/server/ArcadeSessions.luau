-- Server-owned station allocation and hub/run lifecycle; no Roblox instances here.
local Shared = if script then game:GetService("ReplicatedStorage").Shared else nil
local Run = if Shared then require(Shared.Run) else require("../shared/Run")
local Profile = if Shared then require(Shared.Profile) else require("../shared/Profile")
local Chests = if Shared
    then require(Shared.ChestProgression)
    else require("../shared/ChestProgression")
local PlaytestAccess = if script
    then require(script.Parent.PlaytestAccess)
    else require("./PlaytestAccess")

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
        playRemainder = 0,
    }
    self.players[userId] = session
    self.stations[station] = userId
    return session
end

function ArcadeSessions:capture(session)
    if session.run then
        Chests.observe(session)
        session.profile = Profile.merge(
            session.profile,
            PlaytestAccess.captureProfile(session.run:profile(), session.temporaryRunAccess)
        )
    end
    return Profile.clean(session.profile)
end

function ArcadeSessions:_newRun(session, seed)
    self:capture(session)
    session.temporaryRunAccess = PlaytestAccess.active(session.userId)
    session.run = Run.new(seed or 1, PlaytestAccess.runProfile(session.userId, session.profile))
    session.runId += 1
    session.lastEvent = 0
    session.rewardedMilestones = {}
    session.rewardedEndless = 0
    session.terminalRewarded = false
    session.rewardedRestockReceipt = 0
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
    payload = payload or {}
    if kind == "openChest" or kind == "researchItem" or kind == "buyChest" then
        if session.view ~= "hub" then
            return false, "Buy or open chests and research in the arcade."
        end
        if session.profileStatus == "unavailable" or session.profileStatus == "locked" then
            return false, "Saving is unavailable. Your chests are safe; try again shortly."
        end
        if kind == "researchItem" and PlaytestAccess.active(userId) then
            return false, "All equipment is available during your temporary playtest."
        end
        if type(payload.requestId) ~= "string" or #payload.requestId > 96 then
            return false, "Request a chest action again."
        end
        local accepted, message
        if kind == "openChest" then
            accepted, message = Chests.open(session.profile, payload.tier, payload.requestId, seed)
        elseif kind == "buyChest" then
            accepted, message = Chests.buy(session.profile, payload.tier, payload.requestId)
        else
            accepted, message = Chests.research(session.profile, payload.id, payload.requestId)
        end
        return accepted, message
    end
    if kind == "startRun" then
        if session.view ~= "hub" then
            return false, "Your run is already open."
        end
        if not self:canResume(session) then
            self:_newRun(session, seed)
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
    self:capture(session)
    if kind == "restart" then
        if session.run.phase ~= "gameover" and session.run.phase ~= "victory" then
            return false, "Restart is available after a run ends."
        end
        local speed = session.run.speed
        self:_newRun(session, seed)
        session.run.speed = speed
        return true
    end
    local accepted, message = session.run:action(kind, payload)
    self:capture(session)
    return accepted, message
end

function ArcadeSessions:step(dt, realSeconds)
    for _, session in self.players do
        if not session.loading then
            local seconds = realSeconds or dt
            if
                type(seconds) == "number"
                and seconds == seconds
                and seconds > 0
                and seconds < math.huge
            then
                session.playRemainder += seconds
                local whole = math.floor(session.playRemainder)
                session.playRemainder -= whole
                session.profile.playSeconds = math.min(1e12, session.profile.playSeconds + whole)
            end
        end
        if session.view == "run" and session.run then
            session.run:step(dt)
            Chests.observe(session)
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
        snapshot.chestsEarned = table.clone(session.profile.chests)
        snapshot.restockCredits = session.profile.restockCredits
        snapshot.temporaryAccess = session.temporaryRunAccess == true
        return snapshot
    end
    local profile = PlaytestAccess.viewProfile(userId, self:capture(session))
    profile.chestReceipts = nil -- The private retry ledger is not needed by the UI.
    local chests = Chests.snapshot(session.profile)
    if PlaytestAccess.active(userId) then
        for _, entry in chests.unlocks do
            entry.owned = true
        end
    end
    return {
        sessionView = "hub",
        temporaryAccess = PlaytestAccess.active(userId),
        hub = {
            capacity = ArcadeSessions.Capacity,
            station = session.station,
            players = self:roster(),
            profile = profile,
            canResume = self:canResume(session),
            chests = chests,
        },
    }
end

return ArcadeSessions
