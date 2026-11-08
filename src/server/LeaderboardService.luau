local DataStoreService = game:GetService("DataStoreService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local Boards = require(game:GetService("ReplicatedStorage").Shared.Leaderboards)
local LeaderboardService = {}
LeaderboardService.__index = LeaderboardService

function LeaderboardService.new()
    local self = setmetatable(
        { stores = {}, cache = nil, refreshing = false, names = {}, nextRefresh = 0 },
        LeaderboardService
    )
    self.enabled = game.GameId > 0 and not RunService:IsStudio()
    if self.enabled then
        for _, category in Boards.Categories do
            self.stores[category.id] =
                DataStoreService:GetOrderedDataStore("PopAPeg_Leaderboard_v1_" .. category.id)
        end
    end
    return self
end

function LeaderboardService:publish(userId, name, profile)
    self.names[userId] = name
    if not self.enabled or userId <= 0 then
        return
    end
    for _, category in Boards.Categories do
        local value = Boards.value(profile, category.field)
        if value > 0 then
            local ok = pcall(function()
                self.stores[category.id]:UpdateAsync(tostring(userId), function(previous)
                    return math.max(tonumber(previous) or 0, value)
                end)
            end)
            if not ok then
                self.nextRefresh = 0
            end
        end
    end
end

function LeaderboardService:_refresh()
    if self.refreshing or not self.enabled or os.clock() < self.nextRefresh then
        return
    end
    self.refreshing = true
    self.nextRefresh = os.clock() + 60
    local result = { mode = "global", updatedAt = os.time(), categories = {} }
    local complete = true
    for _, category in Boards.Categories do
        local ok, page = pcall(function()
            return self.stores[category.id]:GetSortedAsync(false, 10, 1):GetCurrentPage()
        end)
        if not ok then
            complete = false
            break
        end
        local entries = {}
        for _, entry in page do
            local id = tonumber(entry.key)
            if id then
                local name = self.names[id]
                if not name then
                    local found, username = pcall(function()
                        return Players:GetNameFromUserIdAsync(id)
                    end)
                    name = if found then username else "Player " .. tostring(id)
                    self.names[id] = name
                end
                table.insert(entries, { userId = id, name = name, value = entry.value })
            end
        end
        result.categories[category.id] = { entries = entries, title = category.title }
    end
    if complete then
        self.cache = result
    end
    self.failed = not complete
    self.refreshing = false
end

function LeaderboardService:snapshot(sessions)
    if not self.enabled then
        return Boards.session(sessions)
    end
    if not self.refreshing and os.clock() >= self.nextRefresh then
        task.spawn(function()
            self:_refresh()
        end)
    end
    if self.cache then
        -- Keep last verified rows during an outage and explicitly mark them stale.
        self.cache.stale = self.failed == true
        return self.cache
    end
    local fallback = Boards.session(sessions)
    fallback.mode = "unavailable"
    return fallback
end

return LeaderboardService
