--!strict
-- Only records and unlock identifiers cross run boundaries.
local Profile = {}

local function record(value: any, limit: number): number
    if type(value) ~= "number" or value ~= value or math.abs(value) == math.huge then
        return 0
    end
    return math.clamp(value, 0, limit)
end

function Profile.clean(raw: any)
    raw = if type(raw) == "table" then raw else {}
    local seen = {}
    local unlocks = {}
    if type(raw.unlocks) == "table" then
        for _, id in raw.unlocks do
            if type(id) == "string" and #id <= 48 and id:match("^[%w_%-]+$") and not seen[id] then
                seen[id] = true
                table.insert(unlocks, id)
                if #unlocks >= 128 then
                    break
                end
            end
        end
    end
    table.sort(unlocks)
    return {
        version = 1,
        bestScore = record(raw.bestScore, 1e300),
        bestRound = math.floor(record(raw.bestRound, 1000000)),
        unlocks = unlocks,
    }
end

function Profile.merge(first: any, second: any)
    local a = Profile.clean(first)
    local b = Profile.clean(second)
    for _, id in b.unlocks do
        table.insert(a.unlocks, id)
    end
    a.bestScore = math.max(a.bestScore, b.bestScore)
    a.bestRound = math.max(a.bestRound, b.bestRound)
    return Profile.clean(a)
end

return Profile
