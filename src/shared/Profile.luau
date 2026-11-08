-- Persistent ownership and records. Consumable balances are replaced under a
-- session lease by ProfileStore; merge is only for run record capture.
local Shared = if script then game:GetService("ReplicatedStorage").Shared else nil
local Catalog = if Shared then require(Shared.Catalog) else require("./Catalog")
local Profile = {}
local fallbackStarters = {
    "tap_driver",
    "split_prism",
    "wall_meter",
    "landing_fund",
    "survey_lens",
    "resonator",
    "compass",
    "seed_bank",
}
local tiers = { "common", "uncommon", "rare", "legendary" }

local function record(value, limit)
    if type(value) ~= "number" or value ~= value or math.abs(value) == math.huge then
        return 0
    end
    return math.clamp(value, 0, limit)
end

local function identifiers(raw)
    local seen, result = {}, {}
    if type(raw) == "table" then
        for _, id in raw do
            if type(id) == "string" and #id <= 48 and id:match("^[%w_%-]+$") and not seen[id] then
                seen[id] = true
                table.insert(result, id)
                if #result >= 256 then
                    break
                end
            end
        end
    end
    table.sort(result)
    return result
end

function Profile.clean(raw)
    raw = if type(raw) == "table" then raw else {}
    local unlocks = identifiers(raw.unlocks)
    local owned = {}
    for _, id in identifiers(raw.itemUnlocks) do
        owned[id] = true
    end
    for _, id in Catalog.StarterIds or fallbackStarters do
        owned[id] = true
    end
    if raw.version ~= 2 then
        for _, id in unlocks do
            owned[id] = true
        end
        local migrations = {
            workshop_access = { "gain_dial" },
            growth_kit = { "growth_array", "fishbowl" },
            relay_kit = { "echo_plate", "encore" },
        }
        for token, ids in migrations do
            if table.find(unlocks, token) then
                for _, id in ids do
                    owned[id] = true
                end
            end
        end
    end
    local itemUnlocks = {}
    for _, id in Catalog.ItemIds do
        if owned[id] then
            table.insert(itemUnlocks, id)
        end
    end
    table.sort(itemUnlocks)
    local chests = {}
    for _, tier in tiers do
        chests[tier] = math.floor(record(type(raw.chests) == "table" and raw.chests[tier], 10000))
    end
    local opened
    if type(raw.lastOpened) == "table" and type(raw.lastOpened.requestId) == "string" then
        local source = raw.lastOpened
        opened = {
            serial = math.floor(record(source.serial, 1e12)),
            requestId = source.requestId:sub(1, 96),
            tier = if table.find(tiers, source.tier) then source.tier else "common",
            itemId = if table.find(Catalog.ItemIds, source.itemId) then source.itemId else nil,
            research = math.floor(record(source.research, 100)),
            allCollected = source.allCollected == true,
            kind = source.kind == "research" and "research" or "chest",
        }
    end
    return {
        version = 2,
        bestScore = record(raw.bestScore, 1e300),
        bestRound = math.floor(record(raw.bestRound, 1000000)),
        bestEndlessRound = math.floor(record(raw.bestEndlessRound, 1000000)),
        playSeconds = math.floor(record(raw.playSeconds, 1e12)),
        robuxSpent = math.floor(record(raw.robuxSpent, 1e12)),
        unlocks = unlocks,
        itemUnlocks = itemUnlocks,
        chests = chests,
        research = math.floor(record(raw.research, 100000)),
        chestSerial = math.floor(record(raw.chestSerial, 1e12)),
        lastOpened = opened,
    }
end

function Profile.merge(first, second)
    local incoming = if type(second) == "table" then table.clone(second) else {}
    incoming.version = 2
    local a, b = Profile.clean(first), Profile.clean(incoming)
    for _, id in b.unlocks do
        table.insert(a.unlocks, id)
    end
    for _, id in b.itemUnlocks do
        table.insert(a.itemUnlocks, id)
    end
    a.bestScore = math.max(a.bestScore, b.bestScore)
    a.bestRound = math.max(a.bestRound, b.bestRound)
    a.bestEndlessRound = math.max(a.bestEndlessRound, b.bestEndlessRound)
    -- Do not import consumable balances or play time from a run snapshot.
    return Profile.clean(a)
end

return Profile
