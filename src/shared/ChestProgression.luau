local Shared = if script then game:GetService("ReplicatedStorage").Shared else nil
local Catalog = if Shared then require(Shared.Catalog) else require("./Catalog")
local Profile = if Shared then require(Shared.Profile) else require("./Profile")
local Rng = if Shared then require(Shared.Rng) else require("./Rng")
local Chests = {}
Chests.Tiers = {
    { id = "common", name = "Meadow Chest", researchValue = 1, cost = 6, restockCost = 100 },
    { id = "uncommon", name = "Lagoon Chest", researchValue = 3, cost = 12, restockCost = 250 },
    { id = "rare", name = "Aurora Chest", researchValue = 6, cost = 24, restockCost = 500 },
    {
        id = "legendary",
        name = "Celestial Chest",
        researchValue = 10,
        cost = 40,
        restockCost = 1000,
    },
}

local function tierInfo(tier)
    for _, info in Chests.Tiers do
        if info.id == tier then
            return info
        end
    end
    return nil
end

function Chests.tierFor(id)
    local definition = Catalog.Items[id]
    local tier = definition and (definition.tier or definition.rarity)
    return if tierInfo(tier) then tier else "common"
end

function Chests.pool(profile, tier)
    local candidates, total = {}, 0
    for _, id in Catalog.ItemIds do
        if Chests.tierFor(id) == tier then
            total += 1
            if not table.find(profile.itemUnlocks, id) then
                table.insert(candidates, id)
            end
        end
    end
    return candidates, total
end

function Chests.award(profile, tier)
    if not tierInfo(tier) then
        return false
    end
    -- Storage capacity never wraps and is visible in the chest inventory.
    profile.chests[tier] = math.min(10000, (profile.chests[tier] or 0) + 1)
    return true
end

function Chests.rewardTier(completed)
    if completed >= 100 then
        return "legendary"
    end
    if completed >= 40 then
        return "rare"
    end
    if completed >= 15 then
        return "uncommon"
    end
    return "common"
end

function Chests.observe(session)
    local run = session.run
    if not run then
        return
    end
    local receipt = run.settlementReceipt
    if receipt and receipt.id > (session.rewardedRestockReceipt or 0) then
        -- Only finalized authoritative receipts mint currency. Animation, captures,
        -- hub visits and repeated result snapshots cannot mint it a second time.
        local extra = if receipt.kind == "event" then 0 else math.max(0, receipt.earnedRestocks - 1)
        session.profile.restockCredits =
            math.min(Profile.RestockCreditLimit, session.profile.restockCredits + extra)
        session.rewardedRestockReceipt = receipt.id
    end
    local completed = run.highestClearedRound or 0
    session.rewardedMilestones = session.rewardedMilestones or {}
    for _, milestone in { 15, 40, 65, 100 } do
        if completed >= milestone and not session.rewardedMilestones[milestone] then
            Chests.award(session.profile, Chests.rewardTier(milestone))
            session.rewardedMilestones[milestone] = true
        end
    end
    -- Bound to one current highest marker: the server cannot skip ordinary rounds.
    local current = 150 + (session.rewardedEndless or 0) * 50
    while run.endlessMode and completed >= current do
        Chests.award(session.profile, "legendary")
        session.rewardedEndless = (session.rewardedEndless or 0) + 1
        current += 50
    end
    if run.phase == "gameover" and not session.terminalRewarded then
        session.terminalRewarded = true
        if completed >= 3 then
            Chests.award(session.profile, Chests.rewardTier(completed))
        end
    end
end

local function requestValid(requestId)
    return type(requestId) == "string" and #requestId >= 1 and #requestId <= 96
end

local function replay(profile, requestId, kind, target)
    for _, previous in profile.chestReceipts or {} do
        if previous.requestId == requestId then
            local previousTarget = if previous.kind == "research"
                then previous.itemId
                else previous.tier
            if previous.kind ~= kind or previousTarget ~= target then
                return false, "This request already belongs to a different action."
            end
            -- Re-acknowledge the original result; do not generate a new serial.
            profile.lastOpened = table.clone(previous)
            return true
        end
    end
    return nil
end

local function remember(profile, result)
    profile.chestReceipts = profile.chestReceipts or {}
    table.insert(profile.chestReceipts, table.clone(result))
    while #profile.chestReceipts > Profile.ReceiptLimit do
        table.remove(profile.chestReceipts, 1)
    end
    profile.lastOpened = result
end

function Chests.buy(profile, tier, requestId)
    local info = tierInfo(tier)
    if not info or not requestValid(requestId) then
        return false, "Choose a chest to buy."
    end
    local acknowledged, message = replay(profile, requestId, "purchase", tier)
    if acknowledged ~= nil then
        return acknowledged, message
    end
    if (profile.chests[tier] or 0) >= 10000 then
        return false, "Open a chest of this tier before buying another."
    end
    if profile.restockCredits < info.restockCost then
        return false, "Earn more extra restocks to buy this chest."
    end
    profile.restockCredits -= info.restockCost
    Chests.award(profile, tier)
    profile.chestSerial += 1
    remember(profile, {
        serial = profile.chestSerial,
        requestId = requestId,
        tier = tier,
        kind = "purchase",
        restockCost = info.restockCost,
        research = 0,
    })
    return true
end

function Chests.open(profile, tier, requestId, seed)
    local info = tierInfo(tier)
    if not info or not requestValid(requestId) then
        return false, "Choose a chest to open."
    end
    local acknowledged, message = replay(profile, requestId, "chest", tier)
    if acknowledged ~= nil then
        return acknowledged, message
    end
    if (profile.chests[tier] or 0) < 1 then
        return false, "Earn this chest by completing runs."
    end
    local pool = Chests.pool(profile, tier)
    local result = { tier = tier, requestId = requestId, kind = "chest", research = 0 }
    if #pool > 0 then
        local rng = Rng.new(seed or 1)
        result.itemId = pool[rng:integer(1, #pool)]
        table.insert(profile.itemUnlocks, result.itemId)
        table.sort(profile.itemUnlocks)
    else
        local before = profile.research
        profile.research = math.min(100000, before + info.researchValue)
        result.research = profile.research - before
        result.allCollected = #profile.itemUnlocks == #Catalog.ItemIds
    end
    profile.chests[tier] -= 1
    profile.chestSerial += 1
    result.serial = profile.chestSerial
    remember(profile, result)
    return true
end

function Chests.research(profile, id, requestId)
    if not requestValid(requestId) or not table.find(Catalog.ItemIds, id) then
        return false, "Choose an equipment blueprint."
    end
    local acknowledged, message = replay(profile, requestId, "research", id)
    if acknowledged ~= nil then
        return acknowledged, message
    end
    if table.find(profile.itemUnlocks, id) then
        return false, "You already own that blueprint."
    end
    local tier = Chests.tierFor(id)
    local info = tierInfo(tier)
    if profile.research < info.cost then
        return false, "Open completed-tier chests to earn research."
    end
    profile.research -= info.cost
    table.insert(profile.itemUnlocks, id)
    table.sort(profile.itemUnlocks)
    profile.chestSerial += 1
    remember(profile, {
        serial = profile.chestSerial,
        requestId = requestId,
        tier = tier,
        itemId = id,
        kind = "research",
        research = 0,
    })
    return true
end

function Chests.snapshot(profile)
    local clean = Profile.clean(profile)
    local result = {
        tiers = {},
        research = clean.research,
        restockCredits = clean.restockCredits,
        unlocks = {},
        lastOpened = clean.lastOpened,
    }
    for _, tier in Chests.Tiers do
        local pool, total = Chests.pool(clean, tier.id)
        table.insert(result.tiers, {
            id = tier.id,
            name = tier.name,
            count = clean.chests[tier.id],
            remaining = #pool,
            total = total,
            researchValue = tier.researchValue,
            restockCost = tier.restockCost,
        })
    end
    for _, id in Catalog.ItemIds do
        local tier = Chests.tierFor(id)
        table.insert(result.unlocks, {
            id = id,
            tier = tier,
            owned = table.find(clean.itemUnlocks, id) ~= nil,
            cost = tierInfo(tier).cost,
        })
    end
    return result
end

return Chests
