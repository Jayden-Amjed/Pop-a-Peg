local Board = if script then require(script.Parent.Board) else require("./Board")
local Rng = if script then require(script.Parent.Rng) else require("./Rng")
local Simulation = if script then require(script.Parent.Simulation) else require("./Simulation")
local Catalog = if script then require(script.Parent.Catalog) else require("./Catalog")
local Stages = if script then require(script.Parent.Stages) else require("./Stages")

local Run = {}
Run.__index = Run
Run.Config = {
    startingReserves = 5,
    maxReserves = 5,
    startingCoins = 3,
    maxCoins = 999999,
    maxScore = 1e300,
    maxPeg = 2 ^ 996,
    maxRestocks = 10000,
    effectsPerStep = 32,
    maxActivationsPerShot = 4096,
    restocksPerStep = 32,
    slotPrice = 5,
    rerollPrice = 1,
    eventHistory = 128,
    suppliesRound = 11,
    suppliesOffers = 2,
    perkSkipCoins = 5,
}

local function finite(value)
    return type(value) == "number" and value == value and math.abs(value) < math.huge
end

local function integer(value, low, high)
    return finite(value) and value % 1 == 0 and value >= low and value <= high
end

local function copy(value)
    if type(value) ~= "table" then
        return value
    end
    local result = {}
    for key, child in pairs(value) do
        result[key] = copy(child)
    end
    return result
end

local function emptySlot()
    return { id = "", level = 0 }
end

local function unlockList(unlocks)
    local ids = {}
    for id, unlocked in pairs(unlocks) do
        if unlocked then
            table.insert(ids, id)
        end
    end
    table.sort(ids)
    return ids
end

function Run:_event(kind, data)
    self.eventSerial += 1
    local entry = data or {}
    entry.id = self.eventSerial
    entry.kind = kind
    table.insert(self.events, entry)
    if #self.events > Run.Config.eventHistory then
        table.remove(self.events, 1)
    end
end

function Run:_phase(phase)
    self.phase = phase
    self:_event("phase", { text = phase })
end

function Run:_coins(amount, reason)
    local before = self.coins
    self.coins = math.clamp(self.coins + amount, 0, Run.Config.maxCoins)
    if self.coins ~= before then
        self:_event(
            "coins",
            { amount = self.coins - before, balance = self.coins, reason = reason }
        )
    end
end

function Run:_life(amount, reason)
    local before = self.reserves
    self.reserves = math.clamp(self.reserves + amount, 0, self.maxReserves)
    if self.reserves ~= before then
        self:_event("life", {
            amount = self.reserves - before,
            from = before,
            to = self.reserves,
            balance = self.reserves,
            reason = reason,
        })
    end
end

function Run:_occupied()
    local slots = {}
    for index, item in ipairs(self.inventory) do
        if item.id ~= "" then
            table.insert(slots, index)
        end
    end
    return slots
end

function Run:_livePegs()
    local ids = {}
    for index, value in ipairs(self.values) do
        if value > 0 then
            table.insert(ids, index)
        end
    end
    return ids
end

function Run:_randomPeg()
    local ids = self:_livePegs()
    return if #ids > 0 then ids[self.rng:integer(1, #ids)] else nil
end

function Run:_extremePeg(highest)
    local target, best = nil, if highest then 0 else math.huge
    for id, value in ipairs(self.values) do
        if value > 0 and (if highest then value > best else value < best) then
            target, best = id, value
        end
    end
    return target
end

function Run:_itemOrigin(slot)
    local item = slot and self.inventory[slot]
    local definition = item and Catalog.Items[item.id]
    return {
        slot = slot,
        sourceSlot = slot,
        itemId = definition and definition.id,
        effect = definition and definition.effect,
    }
end

function Run:_itemEvent(slot, action, pegId, data)
    local event = self:_itemOrigin(slot)
    event.action = action
    event.pegId, event.targetPegId = pegId, pegId
    for key, value in pairs(data or {}) do
        event[key] = value
    end
    self:_event("trigger", event)
end

function Run:_shotStats()
    return {
        shotId = self.shotSerial,
        round = self.round,
        pops = self.pops,
        walls = self.wallHits,
        doubles = self.doubles,
        halves = self.halves,
        quotas = self.goalCrossings,
        time = self.elapsed,
        first = if self.pops > 0 then 1 else 0,
        drain = self.drainCount,
        clear = if self.clearBonus then 1 else 0,
        itemTriggers = self.itemTriggers,
        perkTriggers = self.perkTriggers,
    }
end

function Run:_queue(kind, index, amount, relayDepth, channel)
    if self.activationCount >= Run.Config.maxActivationsPerShot then
        return
    end
    local depth = relayDepth or 0
    -- Keep each direct relay depth separate so coalescing cannot renew its budget.
    local key = kind .. ":" .. index .. ":" .. depth .. ":" .. (channel or 0)
    local existing = self.pending[key]
    if existing then
        existing.count += amount or 1
    else
        local entry = {
            kind = kind,
            index = index,
            count = amount or 1,
            key = key,
            relayDepth = depth,
            channel = channel,
        }
        self.pending[key] = entry
        table.insert(self.queue, entry)
    end
end

function Run:_signal(event, amount)
    if self.ending or self.phase ~= "flight" then
        return
    end
    local delta = amount or 1
    if event == "drain" then
        self.drainCount += delta
    end
    for index, item in ipairs(self.inventory) do
        local definition = Catalog.Items[item.id]
        if definition then
            for channelIndex, channel in ipairs(definition.channels or { definition }) do
                if channel.trigger and channel.trigger.event == event then
                    local counter = if definition.channels
                        then index .. ":" .. channelIndex
                        else index
                    local count = (self.itemCounts[counter] or 0) + delta
                    local times = math.floor((count + 1e-8) / channel.trigger.every)
                    self.itemCounts[counter] = count - times * channel.trigger.every
                    if times > 0 then
                        self:_queue("item", index, times, nil, definition.channels and channelIndex)
                    end
                end
            end
        end
    end
    for index, id in ipairs(self.perks) do
        local definition = Catalog.Perks[id]
        if definition.trigger.event == event then
            local count = (self.perkCounts[index] or 0) + delta
            local times = math.floor((count + 1e-8) / definition.trigger.every)
            self.perkCounts[index] = count - times * definition.trigger.every
            if times > 0 then
                self:_queue("perk", index, times)
            end
        end
    end
end

function Run:_addScore(amount, origin)
    if not finite(amount) or amount <= 0 then
        return
    end
    local before = self.score
    self.score = math.min(Run.Config.maxScore, self.score + amount)
    if self.score > before then
        local event = self:_itemOrigin(origin and origin.slot)
        event.value, event.fromScore, event.toScore = self.score - before, before, self.score
        event.pegId = origin and origin.pegId
        event.targetPegId = event.pegId
        event.action = "score"
        self:_event("score", event)
    end
    local crossings = math.min(Run.Config.maxRestocks, math.floor(self.score / self.quota))
    if crossings > self.goalCrossings then
        local delta = crossings - self.goalCrossings
        self:_event("goal", { count = delta, from = self.goalCrossings, to = crossings })
        self.goalCrossings = crossings
        self:_signal("goal", delta)
    end
    self.restocks = crossings
    self.bestScore = math.max(self.bestScore, self.score)
end

function Run:_clear()
    if self.clearBonus then
        return
    end
    self.clearBonus = true
    self:_addScore(self.score)
    self:_event("clear", { value = self.score, text = "Board clear: score doubled" })
    self:_endShot("clear")
end

function Run:_pop(id, slot)
    if self.ending or not id or self.values[id] <= 0 then
        return
    end
    local points, old, new = Board.pop(self.values, id)
    self.pops += 1
    self:_addScore(points, { pegId = id, slot = slot })
    self:_event("pop", {
        pegId = id,
        value = points,
        old = old,
        new = new,
        oldValue = old,
        newValue = new,
        slot = slot,
    })
    if slot then
        self:_itemEvent(slot, "pop", id, { value = points, old = old, new = new })
    end
    if self.pops == 1 then
        self:_signal("first")
    end
    self:_signal("pop")
    if Board.isClear(self.values) then
        self:_clear()
    end
end

function Run:_double(id, slot)
    if self.ending or not id or self.values[id] <= 0 then
        return
    end
    local before = self.values[id]
    self.values[id] = math.min(Run.Config.maxPeg, before * 2)
    if self.values[id] > before then
        self.doubles += 1
        self:_itemEvent(slot, "double", id, {
            value = self.values[id],
            old = before,
            new = self.values[id],
            text = "Double",
        })
        self:_signal("double")
    end
end

function Run:_halve(id, slot)
    if self.ending or not id or self.values[id] <= 1 then
        return
    end
    local before = self.values[id]
    self.values[id] = math.max(1, self.values[id] / 2)
    self.halves += 1
    self:_itemEvent(
        slot,
        "halve",
        id,
        { value = self.values[id], old = before, new = self.values[id], text = "Halve" }
    )
    self:_signal("halve")
end

function Run:_allowActivation()
    if self.activationCount >= Run.Config.maxActivationsPerShot then
        if not self.activationCapped then
            self.activationCapped = true
            self:_event(
                "chainLimit",
                { limit = Run.Config.maxActivationsPerShot, text = "OVERDRIVE COMPLETE" }
            )
        end
        return false
    end
    self.activationCount += 1
    return true
end

function Run:_activateItem(index, relayDepth, selectedChannel)
    local item = self.inventory[index]
    local definition = item and Catalog.Items[item.id]
    if
        not definition
        or self.ending
        or (self.boss and self.boss.disabledLast and index == self.slots)
    then
        return
    end
    if not self:_allowActivation() then
        return
    end
    self.itemTriggers += 1
    self:_itemEvent(index, "activate", nil, { text = definition.name })
    for channelIndex, channel in ipairs(definition.channels or { definition }) do
        if not selectedChannel or selectedChannel == channelIndex then
            local context = {}
            for _, operation in ipairs(channel.operations or { { effect = channel.effect } }) do
                if self.ending then
                    break
                end
                self:_applyEffect(
                    operation.effect,
                    index,
                    if operation.fixed
                        then 1
                        elseif definition.evolved then Catalog.MaxLevel
                        else item.level,
                    relayDepth,
                    context
                )
            end
        end
    end
end

function Run:_applyEffect(effect, index, level, relayDepth, context)
    if effect == "pop" then
        for _ = 1, level do
            self:_pop(self:_randomPeg(), index)
        end
    elseif effect == "double" or effect == "doubleMany" then
        for _ = 1, level * (if effect == "doubleMany" then 4 else 1) do
            self:_double(self:_randomPeg(), index)
        end
    elseif effect == "lowestDouble" then
        for _ = 1, level do
            self:_double(self:_extremePeg(false), index)
        end
    elseif effect == "halve" then
        for _ = 1, level * 2 do
            self:_halve(self:_randomPeg(), index)
        end
    elseif effect == "halveHighest" then
        self:_halve(self:_extremePeg(true), index)
    elseif effect == "lowestPop" then
        self:_pop(self:_extremePeg(false), index)
    elseif effect == "primeBurst" then
        context.center = self:_randomPeg()
        self:_double(context.center, index)
    elseif effect == "halveCenter" then
        self:_halve(context.center, index)
    elseif effect == "popNeighbors" then
        if context.center then
            local ids = self:_livePegs()
            local center = Board.Slots[context.center]
            table.sort(ids, function(a, b)
                local pa, pb = Board.Slots[a], Board.Slots[b]
                return (pa.x - center.x) ^ 2 + (pa.y - center.y) ^ 2
                    < (pb.x - center.x) ^ 2 + (pb.y - center.y) ^ 2
            end)
            local popped = 0
            for _, id in ipairs(ids) do
                if id ~= context.center then
                    self:_pop(id, index)
                    popped += 1
                    if popped >= level * 2 then
                        break
                    end
                end
            end
        end
    elseif effect == "highestPop" or effect == "firstScore" then
        local highest, id = 0, nil
        for pegId, value in ipairs(self.values) do
            if value > highest then
                highest, id = value, pegId
            end
        end
        if effect == "firstScore" then
            self:_addScore(highest * 2 * level, { slot = index })
        else
            for _ = 1, level do
                self:_pop(id, index)
            end
        end
    elseif effect == "halfScore" then
        local lowest = math.huge
        for _, value in ipairs(self.values) do
            if value > 0 then
                lowest = math.min(lowest, value)
            end
        end
        if lowest < math.huge then
            self:_addScore(lowest * 4 * level, { slot = index })
        end
    elseif effect == "multiply" then
        self:_addScore(self.score * 0.15 * level, { slot = index })
    elseif effect == "wallScore" then
        self:_addScore(45 * level, { slot = index })
    elseif effect == "drainScore" then
        self:_addScore(150 * level, { slot = index })
    elseif effect == "pulseScore" then
        self:_addScore(25 * level, { slot = index })
    elseif effect == "goalScore" then
        self:_addScore(40 * level, { slot = index })
    elseif effect == "left" or effect == "right" then
        if (relayDepth or 0) >= self.slots - 1 then
            return
        end
        local direction = if effect == "left" then -1 else 1
        local target = index + direction
        while target >= 1 and target <= self.slots do
            if self.inventory[target].id ~= "" then
                self:_itemEvent(index, "relay", nil, { targetSlot = target })
                self:_queue("item", target, level, (relayDepth or 0) + 1)
                break
            end
            target += direction
        end
    elseif effect == "all" then
        if (relayDepth or 0) >= self.slots - 1 then
            return
        end
        for _, target in ipairs(self:_occupied()) do
            if target ~= index then
                self:_itemEvent(index, "relay", nil, { targetSlot = target })
                self:_queue("item", target, level, (relayDepth or 0) + 1)
            end
        end
    end
end

function Run:_activatePerk(index)
    local definition = Catalog.Perks[self.perks[index]]
    if not definition then
        return
    end
    if not self:_allowActivation() then
        return
    end
    local occupied = self:_occupied()
    local target
    if definition.effect == "first" then
        target = 1
    elseif definition.effect == "third" then
        target = 3
    elseif #occupied > 0 then
        target = if definition.effect == "last"
            then occupied[#occupied]
            else occupied[self.rng:integer(1, #occupied)]
    end
    if target and self.inventory[target] and self.inventory[target].id ~= "" then
        self.perkTriggers += 1
        self:_itemEvent(
            target,
            "perk",
            nil,
            { perkId = definition.id, targetSlot = target, text = definition.name }
        )
        self:_queue("item", target, if definition.effect == "third" then 2 else 1)
    end
end

function Run:_processQueue()
    for _ = 1, Run.Config.effectsPerStep do
        if self.activationCount >= Run.Config.maxActivationsPerShot then
            self:_allowActivation()
            self.queue, self.pending = {}, {}
            break
        end
        if self.ending or #self.queue == 0 then
            break
        end
        local entry = table.remove(self.queue, 1)
        entry.count -= 1
        if entry.count == 0 then
            self.pending[entry.key] = nil
        else
            table.insert(self.queue, entry)
        end
        if entry.kind == "item" then
            self:_activateItem(entry.index, entry.relayDepth, entry.channel)
        else
            self:_activatePerk(entry.index)
        end
    end
end

function Run:_resetShot()
    self.values = Board.copy(self.baseline)
    self.score = 0
    self.restocks = 0
    self.goalCrossings = 0
    self.elapsed = 0
    self.pops = 0
    self.wallHits = 0
    self.doubles = 0
    self.halves = 0
    self.drainCount = 0
    self.itemTriggers = 0
    self.perkTriggers = 0
    self.clearBonus = false
    self.canJumble = true
    self.ball = nil
    self.ending = false
    self.settlement = nil
    self.settlementReceipt = nil
    self.queue = {}
    self.pending = {}
    self.itemCounts = {}
    self.activationCount, self.activationCapped = 0, false
    self.evolutionCounts = {}
    self.stageCleared = nil
    self.perkCounts = {}
    self.boss = if self.round <= Stages.CampaignEnd and Stages.completed(self.round) ~= nil
        then Catalog.Bosses[Stages.forRound(self.round).index]
        else nil
    self.quota = math.max(1, Board.quota(self.baseline, self.shopsVisited))
    if self.boss and self.boss.multiplier then
        self.quota = math.ceil(self.quota * self.boss.multiplier)
    end
    if self.round > Stages.CampaignEnd then
        self.quota = math.min(
            Run.Config.maxScore,
            self.quota * 1.3 ^ math.min(self.round - Stages.CampaignEnd, 500)
        )
    end
    self:_phase("aim")
end

function Run.new(seed, profile)
    local self = setmetatable({}, Run)
    self.seed = if finite(seed) then math.floor(seed) else 1
    self.speed = 1
    self.rng = Rng.new(self.seed)
    self.round = 1
    self.zone = 1
    self.coins = Run.Config.startingCoins
    self.reserves = Run.Config.startingReserves
    self.maxReserves = Run.Config.maxReserves
    self.slots = 4
    self.inventory = {}
    for _ = 1, self.slots do
        table.insert(self.inventory, emptySlot())
    end
    self.perks = {}
    self.shopOffers = {}
    self.perkOffers = {}
    self.eventChoices = {}
    self.eventTitle = ""
    self.rerollsLeft = 0
    self.frozenOffer = nil
    self.shopsVisited = 0
    self.routes = {}
    self.events = {}
    self.eventSerial = 0
    self.settlementSerial = 0
    self.shotSerial = 0
    self.bestScore = 0
    self.bestRound = 0
    self.unlocks = {}
    if type(profile) == "table" then
        if finite(profile.bestScore) then
            self.bestScore = math.clamp(profile.bestScore, 0, Run.Config.maxScore)
        end
        if finite(profile.bestRound) then
            self.bestRound = math.clamp(math.floor(profile.bestRound), 0, 1000000)
        end
        if type(profile.unlocks) == "table" then
            for key, value in pairs(profile.unlocks) do
                local id = if type(key) == "number" then value else key
                if
                    type(id) == "string"
                    and #id < 50
                    and (type(key) == "number" or value == true)
                then
                    self.unlocks[id] = true
                end
            end
        end
    end
    self.baseline = Board.new(self.rng)
    self:_resetShot()
    return self
end

function Run:_endShot(reason)
    if self.ending then
        return
    end
    self.ending = true
    if self.ball then
        self.ball.active = false
    end
    self.queue = {}
    self.pending = {}
    local restocks = math.min(Run.Config.maxRestocks, math.floor(self.score / self.quota))
    self.restocks = restocks
    local coinsBefore, reservesBefore = self.coins, self.reserves
    self:_life(restocks, "restock")
    self:_coins(restocks, "restock")
    self.lastResult = {
        success = restocks > 0,
        reason = reason,
        restocks = restocks,
        score = self.score,
        quota = self.quota,
    }
    self.bestScore = math.max(self.bestScore, self.score)
    self.bestRound = math.max(self.bestRound, self.round)
    self.lastShotStats = self:_shotStats()
    self.settlementSerial += 1
    self.settlement = {
        remaining = restocks,
        completed = 0,
        receipt = {
            id = self.settlementSerial,
            round = self.round,
            reason = reason,
            success = restocks > 0,
            score = self.score,
            quota = self.quota,
            earnedRestocks = restocks,
            coinsBefore = coinsBefore,
            coinsAfter = self.coins,
            reservesBefore = reservesBefore,
            reservesAfter = self.reserves,
            shotValues = Board.copy(self.values),
            restoredValues = Board.copy(self.baseline),
            cycles = {},
            stats = copy(self.lastShotStats),
        },
    }
    if restocks > 0 then
        for id, definition in pairs(Catalog.Unlocks) do
            if self.round >= definition.round then
                self.unlocks[id] = true
            end
        end
    end
    if restocks > 0 and self.round % 20 == 0 then
        self.unlocks["zone_" .. math.floor(self.round / 20 + 1)] = true
    end
    if restocks > 0 then
        self.stageCleared = Stages.completed(self.round)
        if self.stageCleared then
            self:_event("stage", copy(self.stageCleared))
            self.unlocks["level_" .. self.stageCleared.index] = true
            self.settlement.receipt.stageCleared = copy(self.stageCleared)
        end
    end
    if restocks > 0 and self.round == Stages.CampaignEnd then
        self.unlocks.endless = true
        self.unlocks.challenge = true
    end
    self:_settle()
end

function Run:_settle()
    local settlement = self.settlement
    if not settlement then
        return
    end
    for _ = 1, math.min(Run.Config.restocksPerStep, settlement.remaining) do
        local index = settlement.completed + 1
        local capture = self.restocks <= 8 or index <= 3 or index > self.restocks - 2
        local _, cycle = Board.restock(self.baseline, self.round, self.rng, capture)
        if cycle then
            cycle.index = index
            table.insert(settlement.receipt.cycles, cycle)
        end
        settlement.remaining -= 1
        settlement.completed += 1
    end
    if self.restocks > 0 then
        self:_event(
            "restock",
            { value = settlement.completed, text = "Restock " .. settlement.completed .. "x" }
        )
    end
    if settlement.remaining == 0 then
        settlement.receipt.finalValues = Board.copy(self.baseline)
        self.settlementReceipt = settlement.receipt
        self.settlement = nil
        self:_phase(if self.reserves <= 0 then "gameover" else "result")
    end
end

function Run:_step(dt)
    if not finite(dt) or dt <= 0 or self.phase ~= "flight" then
        return
    end
    if self.settlement then
        self:_settle()
        return
    end
    local stepTime = math.min(dt, 0.25)
    if self.ball and self.ball.active then
        local previousElapsed = self.ball.elapsed
        local result = Simulation.step(self.ball, stepTime, self.values, self.rng, function(id)
            self:_pop(id)
        end, function()
            self.wallHits += 1
            self:_signal("wall")
        end)
        self.elapsed = self.ball.elapsed
        if not (self.boss and self.boss.noTime) then
            self:_signal("time", self.elapsed - previousElapsed)
        end
        if result == "drain" and not self.ending then
            self.ball.active = false
            self:_signal("drain")
        end
    end
    if not self.ending then
        self:_processQueue()
        if self.ball and not self.ball.active and #self.queue == 0 then
            self:_endShot("drain")
        end
    end
end

function Run:step(dt)
    if not finite(dt) or dt <= 0 then
        return
    end
    local total = math.min(dt, 0.25) * self.speed
    local slices = math.max(1, math.ceil(total / (1 / 30)))
    for _ = 1, slices do
        self:_step(total / slices)
    end
end

function Run:_drawItem()
    local pool = {}
    local rare = self.rng:number() < 0.12
    for _, id in ipairs(Catalog.ItemIds) do
        local definition = Catalog.Items[id]
        if
            (definition.rarity == "rare") == rare
            and (not definition.unlock or self.unlocks[definition.unlock])
        then
            table.insert(pool, id)
        end
    end
    if #pool == 0 then
        for _, id in ipairs(Catalog.ItemIds) do
            if Catalog.Items[id].rarity ~= "rare" then
                table.insert(pool, id)
            end
        end
    end
    return pool[self.rng:integer(1, #pool)]
end

function Run:_rollConsumables()
    for index = #self.shopOffers, 5, -1 do
        self.shopOffers[index] = nil
    end
    if self.round >= Run.Config.suppliesRound then
        for index = 5, 4 + Run.Config.suppliesOffers do
            local id = Catalog.ConsumableIds[self.rng:integer(1, #Catalog.ConsumableIds)]
            self.shopOffers[index] = {
                id = id,
                price = Catalog.Items[id].price,
                frozen = false,
                sold = false,
                consumable = true,
            }
        end
    end
end

function Run:_refreshEvolutions()
    if #self.shopOffers == 0 then
        return
    end
    local present = {}
    for index = 1, 4 do
        local offer = self.shopOffers[index]
        local definition = offer and Catalog.Items[offer.id]
        if definition and definition.evolved and not offer.sold then
            if Catalog.evolutionState(self.inventory, self.slots, offer.id).ready then
                present[offer.id] = true
            else
                if self.frozenOffer and self.frozenOffer.index == index then
                    self.frozenOffer = nil
                end
                local id = self:_drawItem()
                self.shopOffers[index] =
                    { id = id, price = Catalog.Items[id].price, sold = false, frozen = false }
            end
        end
    end
    for _, recipe in ipairs(Catalog.Evolutions) do
        if
            not present[recipe.id]
            and Catalog.evolutionState(self.inventory, self.slots, recipe.id).ready
        then
            local destination
            for index = 4, 1, -1 do
                local offer = self.shopOffers[index]
                if
                    not offer
                    or (not offer.frozen and (offer.sold or not Catalog.Items[offer.id].evolved))
                then
                    destination = index
                    if not offer or offer.sold then
                        break
                    end
                end
            end
            if destination then
                self.shopOffers[destination] =
                    { id = recipe.id, price = 0, evolution = true, sold = false, frozen = false }
                present[recipe.id] = true
            end
        end
    end
end

function Run:_evolutionChoices()
    local choices = {}
    for _, recipe in ipairs(Catalog.Evolutions) do
        if Catalog.evolutionState(self.inventory, self.slots, recipe.id).ready then
            table.insert(choices, recipe.id)
        end
    end
    return choices
end

function Run:_rollShop()
    for index = 1, 4 do
        if self.frozenOffer and self.frozenOffer.index == index then
            self.shopOffers[index] = copy(self.frozenOffer.offer)
        else
            local id = self:_drawItem()
            local discount = if self.shopKind == "surplus" then 1 else 0
            self.shopOffers[index] = {
                id = id,
                price = math.max(1, Catalog.Items[id].price - discount),
                frozen = false,
                sold = false,
            }
        end
    end
    local upgradeIds, alreadyOffered = {}, false
    for _, entry in ipairs(self.inventory) do
        if entry.id ~= "" and entry.level < Catalog.MaxLevel then
            table.insert(upgradeIds, entry.id)
            for index = 1, 4 do
                if self.shopOffers[index].id == entry.id then
                    alreadyOffered = true
                end
            end
        end
    end
    if not alreadyOffered and #upgradeIds > 0 then
        for index = 4, 1, -1 do
            if not self.shopOffers[index].frozen then
                local id = upgradeIds[self.rng:integer(1, #upgradeIds)]
                self.shopOffers[index] = {
                    id = id,
                    price = math.max(
                        1,
                        Catalog.Items[id].price - (if self.shopKind == "surplus" then 1 else 0)
                    ),
                    frozen = false,
                    sold = false,
                }
                break
            end
        end
    end
    self:_rollConsumables()
    self:_refreshEvolutions()
end

function Run:_openShop(alternate)
    self.shopsVisited += 1
    self.shopKind = if alternate then "surplus" else "standard"
    self.rerollsLeft = 1
    self:_rollShop()
    self:_phase("shop")
end

function Run:_nextRoute()
    local route = table.remove(self.routes, 1)
    if not route then
        self:_resetShot()
    elseif route.kind == "shop" then
        self:_openShop(route.alternate)
    elseif route.kind == "perk" then
        local ids = copy(Catalog.PerkIds)
        self.rng:shuffle(ids)
        self.perkOffers = { ids[1], ids[2] }
        self:_phase("perk")
    elseif route.kind == "event" then
        local event = Catalog.Events[route.index]
        self.eventChoices = copy(event.choices)
        self.eventTitle = event.title
        self:_phase("event")
    elseif route.kind == "victory" then
        self:_phase("victory")
    end
end

function Run:_afterResult()
    if not self.lastResult.success then
        self:_resetShot()
        return
    end
    local completed = self.round
    self.round += 1
    self.zone = math.floor((self.round - 1) / 20) + 1
    local within = completed % 20
    if within == 5 or within == 10 or within == 15 or within == 19 then
        table.insert(self.routes, { kind = "shop", alternate = completed % 40 == 15 })
    end
    if
        completed == 9
        or (completed > 20 and completed < Stages.CampaignEnd and (within == 1 or within == 9))
        or (completed >= 161 and completed % 80 == 1)
    then
        table.insert(self.routes, { kind = "perk" })
    end
    if within == 7 or within == 12 or within == 17 then
        table.insert(
            self.routes,
            { kind = "event", index = if within == 7 then 1 elseif within == 12 then 2 else 3 }
        )
    end
    if completed == Stages.CampaignEnd then
        table.insert(self.routes, { kind = "victory" })
    end
    self:_nextRoute()
end

function Run:_purchase(index)
    local offer = self.shopOffers[index]
    local intent = Catalog.purchaseState(self.inventory, self.slots, offer, self.coins)
    if not intent.allowed then
        return false, intent.message
    end
    if intent.action == "use" then
        if
            self.round < Run.Config.suppliesRound
            or index < 5
            or index > 4 + Run.Config.suppliesOffers
        then
            return false, "Supplies unlock at round " .. Run.Config.suppliesRound .. "."
        end
        self:_coins(-offer.price)
        offer.sold = true
        self:_consume(Catalog.Items[offer.id].effect)
        self:_event("purchase", { itemId = offer.id, action = "use" })
        self:_refreshEvolutions()
        return true
    end
    self:_coins(-offer.price)
    if intent.action == "evolve" then
        for _, slot in ipairs(intent.removeSlots) do
            self.inventory[slot] = emptySlot()
        end
    end
    self.inventory[intent.slot] = { id = offer.id, level = intent.level }
    offer.sold = true
    offer.frozen = false
    if self.frozenOffer and self.frozenOffer.index == index then
        self.frozenOffer = nil
    end
    self:_event("purchase", {
        itemId = offer.id,
        action = if intent.action == "purchase" then "buy" else intent.action,
        level = intent.level,
        slot = intent.slot,
    })
    self:_refreshEvolutions()
    return true
end

function Run:_consume(effect)
    if effect == "repair" then
        self:_life(2, "consumable")
    elseif effect == "reserveCoins" then
        self:_coins(self.reserves)
    elseif effect == "upgrade" then
        local candidates = {}
        for slot, item in ipairs(self.inventory) do
            if item.id ~= "" and item.level < Catalog.MaxLevel then
                table.insert(candidates, slot)
            end
        end
        if #candidates == 0 then
            self:_coins(4)
        else
            self.inventory[candidates[self.rng:integer(1, #candidates)]].level += 1
        end
    end
end

function Run:_chooseEvent(index)
    local choice = self.eventChoices[index]
    if choice.id == "coins" then
        self:_coins(4)
    elseif choice.id == "repair" then
        self:_life(2, "event")
    elseif choice.id == "overtime" then
        if self.reserves <= 1 then
            return false, "Keep at least one ball for the next shot."
        end
        self:_life(-1, "event")
        self:_coins(8)
    elseif choice.id == "grow" then
        local ids = {}
        for pegId, value in ipairs(self.baseline) do
            if value > 0 then
                table.insert(ids, pegId)
            end
        end
        self.rng:shuffle(ids)
        for order = 1, math.min(4, #ids) do
            self.baseline[ids[order]] = math.min(Run.Config.maxPeg, self.baseline[ids[order]] * 2)
        end
    elseif choice.id == "upgrade" then
        local candidates = {}
        for slot, item in ipairs(self.inventory) do
            if item.id ~= "" and item.level < Catalog.MaxLevel then
                table.insert(candidates, slot)
            end
        end
        if #candidates == 0 then
            self:_coins(4)
        else
            self.inventory[candidates[self.rng:integer(1, #candidates)]].level += 1
        end
    end
    self:_nextRoute()
    return true
end

function Run:action(kind, payload)
    if type(kind) ~= "string" or (payload ~= nil and type(payload) ~= "table") then
        return false, "Invalid action."
    end
    local input = payload or {}
    if kind == "speed" then
        if input.value ~= 1 and input.value ~= 2 and input.value ~= 4 then
            return false, "Choose 1x, 2x, or 4x speed."
        end
        self.speed = input.value
        return true
    elseif kind == "launch" then
        if
            self.phase ~= "aim"
            or self.reserves <= 0
            or not finite(input.angle)
            or math.abs(input.angle) > 1.25
        then
            return false, "Aim within the board before launching."
        end
        self.ball = Simulation.new(input.angle)
        self.shotSerial += 1
        self.lastShotStats = nil
        self:_life(-1, "launch")
        self.canJumble = false
        self:_phase("flight")
        return true
    elseif kind == "cycleEvolution" then
        if self.phase ~= "shop" or not integer(input.offer, 1, 4) then
            return false, "Choose an evolution offer in the shop."
        end
        local offer = self.shopOffers[input.offer]
        if not offer or offer.sold or not Catalog.Items[offer.id].evolved then
            return false, "Choose an evolution offer in the shop."
        end
        if input.itemId ~= nil and input.itemId ~= offer.id then
            return false, "That offer changed. Review the current card."
        end
        local shown = {}
        for index = 1, 4 do
            local current = self.shopOffers[index]
            if current and not current.sold then
                shown[current.id] = true
            end
        end
        local choices, currentIndex = self:_evolutionChoices(), 0
        for index, id in ipairs(choices) do
            if id == offer.id then
                currentIndex = index
                break
            end
        end
        for offset = 1, #choices do
            local id = choices[(currentIndex + offset - 1) % #choices + 1]
            if not shown[id] then
                if self.frozenOffer and self.frozenOffer.index == input.offer then
                    self.frozenOffer = nil
                end
                self.shopOffers[input.offer] =
                    { id = id, price = 0, evolution = true, sold = false, frozen = false }
                return true
            end
        end
        return false, "All available evolutions are already shown."
    elseif kind == "jumble" then
        if self.phase ~= "aim" or not self.canJumble then
            return false, "One jumble is available before each shot."
        end
        Board.jumble(self.values, self.rng)
        self.canJumble = false
        return true
    elseif kind == "endShot" then
        if self.phase ~= "flight" or self.ending then
            return false, "No active shot."
        end
        self:_endShot("manual")
        return true
    elseif kind == "continue" then
        if self.phase == "result" then
            self:_afterResult()
        elseif self.phase == "shop" then
            self:_nextRoute()
        else
            return false, "Finish the current choice first."
        end
        return true
    elseif kind == "buy" then
        if self.phase ~= "shop" or not integer(input.offer, 1, #self.shopOffers) then
            return false, "Select a shop offer."
        end
        if input.itemId ~= nil and input.itemId ~= self.shopOffers[input.offer].id then
            return false, "That offer changed. Review the current card."
        end
        return self:_purchase(input.offer)
    elseif kind == "reroll" then
        if self.phase ~= "shop" or self.rerollsLeft <= 0 or self.coins < Run.Config.rerollPrice then
            return false, "Reroll unavailable."
        end
        self:_coins(-Run.Config.rerollPrice)
        self.rerollsLeft -= 1
        self:_rollShop()
        return true
    elseif kind == "freeze" then
        if
            self.phase ~= "shop"
            or not integer(input.offer, 1, 4)
            or self.shopOffers[input.offer].sold
        then
            return false, "Select an available offer."
        end
        local wasFrozen = self.shopOffers[input.offer].frozen
        for _, offer in ipairs(self.shopOffers) do
            offer.frozen = false
        end
        self.frozenOffer = nil
        if not wasFrozen then
            self.shopOffers[input.offer].frozen = true
            self.frozenOffer = { index = input.offer, offer = copy(self.shopOffers[input.offer]) }
        end
        return true
    elseif kind == "buySlot" then
        if self.phase ~= "shop" or self.slots >= 7 or self.coins < Run.Config.slotPrice then
            return false, "Slot purchase unavailable."
        end
        self:_coins(-Run.Config.slotPrice)
        self.slots += 1
        table.insert(self.inventory, emptySlot())
        return true
    elseif kind == "sell" then
        if self.phase ~= "shop" or not integer(input.slot, 1, self.slots) then
            return false, "Select an inventory slot in the shop."
        end
        local item = self.inventory[input.slot]
        if item.id == "" then
            return false, "That slot is empty."
        end
        self:_coins(
            math.max(
                1,
                math.floor(
                    Catalog.Items[item.id].price
                        * (if item.level == Catalog.MaxLevel then 0.8 else 0.5)
                )
            )
        )
        self.inventory[input.slot] = emptySlot()
        self:_refreshEvolutions()
        return true
    elseif kind == "move" then
        if
            (self.phase ~= "aim" and self.phase ~= "shop")
            or not integer(input.from, 1, self.slots)
            or not integer(input.to, 1, self.slots)
        then
            return false, "Move items before launching or in a shop."
        end
        local source, target = self.inventory[input.from], self.inventory[input.to]
        if source.id == "" or input.from == input.to then
            return false, "Choose a different destination."
        end
        if
            source.id == target.id
            and source.level == target.level
            and source.level < Catalog.MaxLevel
        then
            target.level += 1
            self.inventory[input.from] = emptySlot()
        else
            self.inventory[input.from], self.inventory[input.to] = target, source
        end
        if self.phase == "shop" then
            self:_refreshEvolutions()
        end
        return true
    elseif kind == "skipPerk" then
        if self.phase ~= "perk" or #self.perkOffers == 0 then
            return false, "Finish a perk choice to take coins."
        end
        self.perkOffers = {}
        self:_coins(Run.Config.perkSkipCoins, "perkSkip")
        self:_event("perkChoice", { action = "coins", amount = Run.Config.perkSkipCoins })
        self:_nextRoute()
        return true
    elseif kind == "choosePerk" then
        if self.phase ~= "perk" or not integer(input.index, 1, #self.perkOffers) then
            return false, "Select one perk."
        end
        table.insert(self.perks, self.perkOffers[input.index])
        self:_event("perkChoice", { action = "choose", perkId = self.perkOffers[input.index] })
        self.perkOffers = {}
        self:_nextRoute()
        return true
    elseif kind == "chooseEvent" then
        if self.phase ~= "event" or not integer(input.index, 1, #self.eventChoices) then
            return false, "Select one event option."
        end
        return self:_chooseEvent(input.index)
    elseif kind == "endless" then
        if self.phase ~= "victory" then
            return false, "Complete the run first."
        end
        self:_nextRoute()
        return true
    elseif kind == "restart" then
        if self.phase ~= "gameover" and self.phase ~= "victory" then
            return false, "Restart is available after a run ends."
        end
        local restarted = Run.new(self.rng:integer(1, 2147483646), self:profile())
        restarted.speed = self.speed
        local serial = self.eventSerial
        local receiptSerial = self.settlementSerial
        local shotSerial = self.shotSerial
        for key in pairs(self) do
            self[key] = nil
        end
        for key, value in pairs(restarted) do
            self[key] = value
        end
        self.eventSerial = serial
        self.settlementSerial = receiptSerial
        self.shotSerial = shotSerial
        self.events = {}
        self:_event("phase", { text = "aim" })
        return true
    end
    return false, "Unknown action."
end

function Run:profile()
    return {
        bestScore = self.bestScore,
        bestRound = self.bestRound,
        unlocks = unlockList(self.unlocks),
    }
end

function Run:snapshot()
    return copy({
        phase = self.phase,
        seed = self.seed,
        speed = self.speed,
        round = self.round,
        zone = self.zone,
        stage = Stages.forRound(self.round),
        stageCleared = self.stageCleared,
        score = self.score,
        quota = self.quota,
        coins = self.coins,
        reserves = math.max(0, self.reserves),
        maxReserves = self.maxReserves,
        restocks = self.restocks,
        maxRestocks = Run.Config.maxRestocks,
        elapsed = self.elapsed,
        values = self.values,
        ball = self.ball,
        inventory = self.inventory,
        slots = self.slots,
        shopOffers = self.shopOffers,
        evolutionChoices = self:_evolutionChoices(),
        shopKind = self.shopKind,
        perkOffers = self.perkOffers,
        perkSkipCoins = if self.phase == "perk" then Run.Config.perkSkipCoins else 0,
        perks = self.perks,
        eventChoices = self.eventChoices,
        eventTitle = self.eventTitle,
        rerollsLeft = self.rerollsLeft,
        canJumble = self.canJumble,
        pops = self.pops,
        wallHits = self.wallHits,
        doubles = self.doubles,
        halves = self.halves,
        clearBonus = self.clearBonus,
        shotStats = self:_shotStats(),
        lastShotStats = self.lastShotStats,
        lastResult = self.lastResult,
        bestScore = self.bestScore,
        bestRound = self.bestRound,
        unlocks = unlockList(self.unlocks),
        boss = self.boss,
        settling = self.settlement ~= nil,
        settlementReceipt = self.settlementReceipt,
        pendingEffects = #self.queue,
        events = self.events,
    })
end

return Run
