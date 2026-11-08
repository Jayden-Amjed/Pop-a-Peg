-- DataStore adapter with injectable clock, delay and token generation. Production
-- uses Roblox UpdateAsync; CLI tests execute this same retry/ownership path.
local Shared = if script then game:GetService("ReplicatedStorage").Shared else nil
local Profile = if Shared then require(Shared.Profile) else require("../shared/Profile")
local Lease = if Shared then require(Shared.ProfileLease) else require("../shared/ProfileLease")
local Repository = {}
Repository.__index = Repository

function Repository.new(dependencies)
    assert(type(dependencies.clock) == "function", "Profile clock required")
    assert(type(dependencies.wait) == "function", "Profile retry delay required")
    assert(type(dependencies.newToken) == "function", "Profile token generator required")
    return setmetatable({
        store = dependencies.store,
        clock = dependencies.clock,
        wait = dependencies.wait,
        newToken = dependencies.newToken,
        tokens = {},
        sessionProfiles = {},
    }, Repository)
end

function Repository:load(userId)
    if not self.store then
        return Profile.clean(self.sessionProfiles[userId]), "session"
    end
    if self.tokens[userId] then
        return nil, "locked"
    end
    local token = self.newToken()
    for attempt = 1, 3 do
        local blocked = false
        local ok, data = pcall(function()
            return self.store:UpdateAsync("player_" .. userId, function(previous)
                local acquired = Lease.acquire(previous, token, self.clock())
                blocked = acquired == nil
                return acquired
            end)
        end)
        if ok and data and data._session and data._session.token == token then
            self.tokens[userId] = token
            return Profile.clean(data), "saved"
        end
        if ok and blocked then
            return nil, "locked"
        end
        if attempt < 3 then
            self.wait(attempt)
        end
    end
    return nil, "unavailable"
end

function Repository:save(userId, profile, release)
    if not self.store then
        self.sessionProfiles[userId] = Profile.clean(profile)
        return true, "session"
    end
    local token = self.tokens[userId]
    if not token then
        return false, "unavailable"
    end
    local clean = Profile.clean(profile)
    local writeId = self.newToken()
    for attempt = 1, 3 do
        local lost = false
        local ok, result = pcall(function()
            return self.store:UpdateAsync("player_" .. userId, function(previous)
                local updated = Lease.write(previous, clean, token, self.clock(), release, writeId)
                lost = updated == nil
                return updated
            end)
        end)
        if ok and result and not lost then
            if release then
                self.tokens[userId] = nil
            end
            return true, "saved"
        end
        if ok and lost then
            self.tokens[userId] = nil
            return false, "locked"
        end
        if attempt < 3 then
            self.wait(attempt)
        end
    end
    return false, "unavailable"
end

return Repository
