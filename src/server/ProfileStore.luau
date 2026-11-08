local DataStoreService = game:GetService("DataStoreService")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local Shared = game:GetService("ReplicatedStorage").Shared
local Profile = require(Shared.Profile)
local Lease = require(Shared.ProfileLease)
local ProfileStore = {}
local enabled = game.GameId > 0 and not RunService:IsStudio()
-- Keep the existing keyspace so v1 records migrate in place atomically.
local store = if enabled then DataStoreService:GetDataStore("PopAPeg_Records_v1") else nil
local tokens, sessionProfiles = {}, {}

function ProfileStore.load(userId)
    if not store then
        return Profile.clean(sessionProfiles[userId]), "session"
    end
    local token = game.JobId .. ":" .. HttpService:GenerateGUID(false)
    local blocked = false
    for attempt = 1, 3 do
        local ok, data = pcall(function()
            return store:UpdateAsync("player_" .. userId, function(previous)
                local acquired = Lease.acquire(previous, token, os.time())
                blocked = acquired == nil
                return acquired
            end)
        end)
        if ok and data and data._session and data._session.token == token then
            tokens[userId] = token
            return Profile.clean(data), "saved"
        end
        if ok and blocked then
            return nil, "locked"
        end
        if attempt < 3 then
            task.wait(attempt)
        end
    end
    return nil, "unavailable"
end

function ProfileStore.save(userId, profile, release)
    if not store then
        sessionProfiles[userId] = Profile.clean(profile)
        return true, "session"
    end
    local token = tokens[userId]
    if not token then
        return false, "unavailable"
    end
    local clean = Profile.clean(profile)
    local lost = false
    for attempt = 1, 3 do
        local ok, result = pcall(function()
            return store:UpdateAsync("player_" .. userId, function(previous)
                local updated = Lease.write(previous, clean, token, os.time(), release)
                lost = updated == nil
                return updated
            end)
        end)
        if ok and result and not lost then
            if release then
                tokens[userId] = nil
            end
            return true, "saved"
        end
        if ok and lost then
            tokens[userId] = nil
            return false, "locked"
        end
        if attempt < 3 then
            task.wait(attempt)
        end
    end
    return false, "unavailable"
end

return ProfileStore
