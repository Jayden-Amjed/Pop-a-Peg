--!strict
local DataStoreService = game:GetService("DataStoreService")
local RunService = game:GetService("RunService")
local Profile = require(game:GetService("ReplicatedStorage").Shared.Profile)

local ProfileStore = {}
local enabled = game.GameId > 0 and not RunService:IsStudio()
local store = if enabled then DataStoreService:GetDataStore("PopAPeg_Records_v1") else nil

function ProfileStore.load(userId: number)
    if not store then
        return Profile.clean(nil), "session"
    end
    for attempt = 1, 3 do
        local ok, data = pcall(function()
            return store:GetAsync("player_" .. userId)
        end)
        if ok then
            return Profile.clean(data), "saved"
        end
        if attempt < 3 then
            task.wait(attempt)
        end
    end
    return Profile.clean(nil), "unavailable"
end

function ProfileStore.save(userId: number, profile: any)
    if not store then
        return true, "session"
    end
    local clean = Profile.clean(profile)
    for attempt = 1, 3 do
        local ok = pcall(function()
            store:UpdateAsync("player_" .. userId, function(previous)
                return Profile.merge(previous, clean)
            end)
        end)
        if ok then
            return true, "saved"
        end
        if attempt < 3 then
            task.wait(attempt)
        end
    end
    return false, "unavailable"
end

return ProfileStore
