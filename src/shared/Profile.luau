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
Profile.ReceiptLimit = 64

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

local function receipt(source)
    if
        type(source) ~= "table"
        or type(source.requestId) ~= "string"
        or #source.requestId < 1
        or #source.requestId > 96
    then
        return nil
    end
    if not table.find(tiers, source.tier) then
        return nil
    end
    if source.kind ~= nil and source.kind ~= "chest" and source.kind ~= "research" then
        return nil
    end
    local kind = source.kind == "research" and "research" or "chest"
    local itemId = if table.find(Catalog.ItemIds, source.itemId) then source.itemId else nil
    if kind == "research" and not itemId then
        return nil
    end
    return {
        serial = math.floor(record(source.serial, 1e12)),
        requestId = source.requestId,
        tier = source.tier,
        itemId = itemId,
        research = math.floor(record(source.research, 100)),
        allCollected = source.allCollected == true,
        kind = kind,
    }
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
    local opened = receipt(raw.lastOpened)
    local receipts, seen = {}, {}
    if type(raw.chestReceipts) == "table" then
        -- Prefer the newest stored occurrence, then restore oldest-to-newest order.
        for index = #raw.chestReceipts, 1, -1 do
            local entry = receipt(raw.chestReceipts[index])
            if entry and not seen[entry.requestId] then
                seen[entry.requestId] = entry
                table.insert(receipts, 1, entry)
                if #receipts == Profile.ReceiptLimit then
                    break
                end
            end
        end
    elseif opened then
        -- Migrate the previous v2 single-receipt format without losing retry safety.
        table.insert(receipts, opened)
        seen[opened.requestId] = opened
    end
    opened = if opened then seen[opened.requestId] else nil
    local serial = math.floor(record(raw.chestSerial, 1e12))
    for _, entry in receipts do
        serial = math.max(serial, entry.serial)
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
        chestSerial = serial,
        chestReceipts = receipts,
        lastOpened = if opened then table.clone(opened) else nil,
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
