local DataStoreService = game:GetService("DataStoreService")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local Repository = require(script.Parent.ProfileRepository)
local enabled = game.GameId > 0 and not RunService:IsStudio()
-- Keep the existing keyspace so v1 records migrate in place atomically.
local repository = Repository.new({
    store = if enabled then DataStoreService:GetDataStore("PopAPeg_Records_v1") else nil,
    clock = os.time,
    wait = task.wait,
    newToken = function()
        return game.JobId .. ":" .. HttpService:GenerateGUID(false)
    end,
})

local ProfileStore = {}

function ProfileStore.load(userId)
    return repository:load(userId)
end

function ProfileStore.save(userId, profile, release)
    return repository:save(userId, profile, release)
end

return ProfileStore
