-- Client-only feedback follows authoritative values and settlement receipts.
local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Board = require(Shared.Board)
local Format = require(Shared.Format)
local Timeline = require(Shared.RewardTimeline)
local Signatures = require(Shared.ItemFeedback)
local ItemModels = require(script.Parent.ItemModels)
local SoundEffects = require(script.Parent.SoundEffects)
local Theme = require(script.Parent.UiTheme)

local Feedback = {}
Feedback.__index = Feedback
local GREEN = Color3.fromRGB(155, 225, 96)
local GOLD = Color3.fromRGB(255, 205, 92)
local WHITE = Color3.fromRGB(249, 254, 255)
local INK = Color3.fromRGB(24, 72, 106)
local MAX_FX = 100

local function smooth(t)
    return t * t * (3 - 2 * t)
end

local function text(parent, value, color, size)
    local label = Instance.new("TextLabel")
    label.BackgroundTransparency = 1
    label.Font = Theme.font or Enum.Font.GothamBold
    label.Text = value
    label.TextColor3 = color or WHITE
    label.TextStrokeColor3 = INK
    label.TextStrokeTransparency = 0
    label.TextSize = size or 26
    label.AnchorPoint = Vector2.new(0.5, 0.5)
    label.Size = UDim2.fromOffset(160, 40)
    label.ZIndex = 215
    label.Parent = parent
    return label
end

function Feedback.new(host, onAdvance)
    return setmetatable({
        host = host,
        onAdvance = onAdvance,
        sounds = SoundEffects.new(),
        fx = {},
        lastEvent = 0,
        completedReceipt = -1,
        generation = 0,
        displayScore = 0,
        queuedScore = 0,
        displayCoins = 0,
        earned = 0,
        elapsed = 0,
        busy = false,
        walletRevision = 0,
        itemFxTimes = {},
    }, Feedback)
end

function Feedback:isBusy()
    return self.busy
end

function Feedback:setMuted(value)
    self.sounds:setMuted(value)
end

function Feedback:playCue(name)
    self.sounds:play(name)
end

function Feedback:_anchor(kind, index)
    return self.host:getAnchor(kind, index) or Vector2.new(0, 0)
end

function Feedback:_remove(index, arrive)
    local effect = table.remove(self.fx, index)
    if effect.view then
        effect.view:destroy()
    end
    effect.gui:Destroy()
    if arrive and effect.onArrival and effect.generation == self.generation then
        effect.onArrival()
    end
end

function Feedback:_clearFx()
    for index = #self.fx, 1, -1 do
        self:_remove(index, false)
    end
end

function Feedback:_ring(point, color, size)
    if #self.fx >= MAX_FX then
        return
    end
    local ring = Instance.new("Frame")
    ring.BackgroundTransparency = 1
    ring.AnchorPoint = Vector2.new(0.5, 0.5)
    ring.Position = UDim2.fromOffset(point.X, point.Y)
    ring.ZIndex = 205
    local round = Instance.new("UICorner")
    round.CornerRadius = UDim.new(1, 0)
    round.Parent = ring
    local border = Instance.new("UIStroke")
    border.Color = color
    border.Thickness = 4
    border.Parent = ring
    ring.Parent = self.host.fxLayer
    table.insert(self.fx, {
        kind = "ring",
        gui = ring,
        border = border,
        age = 0,
        duration = 0.3,
        start = point,
        size = size or 32,
        generation = self.generation,
    })
end

function Feedback:_label(value, point, color, size)
    if #self.fx >= MAX_FX then
        return
    end
    table.insert(self.fx, {
        kind = "float",
        gui = text(self.host.fxLayer, value, color, size),
        age = 0,
        duration = 0.65,
        start = point,
        generation = self.generation,
    })
end

function Feedback:_line(startPoint, endPoint, color)
    if #self.fx >= MAX_FX then
        return
    end
    local line = Instance.new("Frame")
    line.AnchorPoint = Vector2.new(0.5, 0.5)
    line.BorderSizePixel = 0
    line.BackgroundColor3 = color
    line.ZIndex = 202
    local delta = endPoint - startPoint
    line.Size = UDim2.fromOffset(delta.Magnitude, 4)
    line.Position =
        UDim2.fromOffset((startPoint.X + endPoint.X) / 2, (startPoint.Y + endPoint.Y) / 2)
    line.Rotation = math.deg(math.atan2(delta.Y, delta.X))
    line.Parent = self.host.fxLayer
    table.insert(
        self.fx,
        { kind = "line", gui = line, age = 0, duration = 0.22, generation = self.generation }
    )
end

function Feedback:_beam(slot, pegId, color, style, action)
    local key = tostring(slot) .. ":" .. tostring(pegId) .. ":" .. tostring(action)
    if self.elapsed - (self.itemFxTimes[key] or -10) < 0.07 then
        return
    end
    self.itemFxTimes[key] = self.elapsed
    local startPoint = self:_anchor("inventory", slot)
    local target = self:_anchor("peg", pegId)
    self.host:pulseItem(slot, 0.7, { effect = style, direction = target - startPoint })
    local rays = style == "prism" and 3 or 1
    for ray = 1, rays do
        if #self.fx >= MAX_FX then
            break
        end
        local beam = Instance.new("Frame")
        beam.Name = "ItemBeam"
        beam.AnchorPoint = Vector2.new(0.5, 0.5)
        beam.BorderSizePixel = 0
        beam.BackgroundColor3 = if rays == 3
            then ({ Color3.fromRGB(113, 229, 255), WHITE, Color3.fromRGB(205, 177, 255) })[ray]
            else color
        beam.ZIndex = 203
        local rounding = Instance.new("UICorner")
        rounding.CornerRadius = UDim.new(1, 0)
        rounding.Parent = beam
        beam.Parent = self.host.fxLayer
        table.insert(self.fx, {
            kind = "beam",
            gui = beam,
            age = 0,
            duration = 0.32,
            slot = slot,
            pegId = pegId,
            offset = (ray - (rays + 1) / 2) * 4,
            width = if style == "trim" then 3 else 5,
            generation = self.generation,
        })
    end
end

function Feedback:_itemSpark(slot, profile)
    local source = self:_anchor("inventory", slot)
    local color = Color3.fromRGB(table.unpack(profile.color))
    local style = profile.style
    local count = if style == "burst" or style == "chorus" then 7 else 4
    for index = 1, count do
        if #self.fx >= MAX_FX then
            break
        end
        local spark = Instance.new("Frame")
        spark.Name = "ItemSpark"
        spark.AnchorPoint = Vector2.new(0.5, 0.5)
        spark.BorderSizePixel = 0
        spark.BackgroundColor3 = color
        spark.ZIndex = 208
        local round = Instance.new("UICorner")
        round.CornerRadius = UDim.new(style == "clock" and 0 or 1, 0)
        round.Parent = spark
        spark.Parent = self.host.fxLayer
        local angle = index * math.pi * 2 / count
        local distance = style == "bubbles" and 37 or 23
        table.insert(self.fx, {
            kind = "spark",
            gui = spark,
            age = 0,
            duration = 0.34,
            start = source,
            delta = Vector2.new(math.cos(angle), math.sin(angle)) * distance,
            size = style == "seed" and 9 or 6,
            generation = self.generation,
        })
    end
end

function Feedback:_activateVisual(id, slot)
    local profile = Signatures.Profiles[id]
    if not profile then
        return
    end
    self.sounds:playItem(id)
    if slot then
        self.host:pulseItem(slot, 1, { effect = profile.style })
        local key = "slot:" .. slot
        if self.elapsed - (self.itemFxTimes[key] or -10) >= 0.12 then
            self.itemFxTimes[key] = self.elapsed
            self:_itemSpark(slot, profile)
        end
    end
end

function Feedback:_flight(kind, value, startPoint, target, targetIndex, onArrival)
    if #self.fx >= MAX_FX then
        if onArrival then
            onArrival()
        end
        return nil
    end
    local gui, view, caption
    if kind == "score" then
        gui = text(self.host.fxLayer, "+" .. Format.number(value), WHITE, 28)
    else
        gui = Instance.new("ViewportFrame")
        gui.BackgroundTransparency = 1
        gui.Size = UDim2.fromOffset(68, 68)
        gui.AnchorPoint = Vector2.new(0.5, 0.5)
        gui.ZIndex = 212
        gui.Parent = self.host.fxLayer
        view = ItemModels.mount(gui, kind, 1, { animate = true })
        if value > 1 then
            caption = text(gui, "×" .. Format.integer(value), GOLD, 22)
            caption.Position = UDim2.new(0.5, 0, 1, 2)
            caption.Size = UDim2.fromOffset(120, 28)
        end
    end
    local effect = {
        kind = "flight",
        reward = kind,
        value = value,
        gui = gui,
        view = view,
        caption = caption,
        age = 0,
        duration = if kind == "score"
            then 0.42
            else 0.56 / math.sqrt(self.snapshot and self.snapshot.speed or 1),
        start = startPoint,
        target = target,
        targetIndex = targetIndex,
        onArrival = onArrival,
        generation = self.generation,
    }
    table.insert(self.fx, effect)
    return effect
end

function Feedback:_pulseCounter(kind, strength)
    if self.host.pulseCounter then
        self.host:pulseCounter(kind, strength or 0.55)
    elseif kind == "score" and self.host.pulseScore then
        self.host:pulseScore(strength or 0.55)
    end
end

function Feedback:_pulsePerk(id)
    if self.host.pulsePerk and id then
        self.host:pulsePerk(id)
    end
end

function Feedback:_arriveScore(value)
    if not self.snapshot or self.busy and self.timeline then
        return
    end
    self.displayScore = math.max(self.displayScore, math.min(value, self.snapshot.score))
    self.host:setCounterDisplay("score", self.displayScore)
    self:_pulseCounter("score")
    local earned = math.min(
        self.snapshot.maxRestocks or 10000,
        math.floor(self.displayScore / math.max(1, self.snapshot.quota))
    )
    if earned > self.earned then
        local count = earned - self.earned
        self.earned = earned
        self.host:setCounterDisplay("restocks", earned)
        self:_flight("restock", count, self:_anchor("meter"), "restocks", nil, function()
            self:_pulseCounter("restocks")
            self:_ring(self:_anchor("restocks"), GOLD, 52)
        end)
        self:_label(
            "+" .. Format.integer(count) .. " RESTOCK",
            self:_anchor("meter") + Vector2.new(0, -35),
            GOLD,
            28
        )
        self.sounds:play("goal", 1 + math.min(5, earned) * 0.035)
    end
end

function Feedback:_score(toScore, source)
    if toScore <= self.queuedScore or self.timeline then
        return
    end
    local amount = toScore - self.queuedScore
    self.queuedScore = toScore
    local active = 0
    local latest
    local sameOrigin
    for _, effect in ipairs(self.fx) do
        if effect.reward == "score" then
            active += 1
            latest = effect
            if effect.age < 0.08 and (effect.start - source).Magnitude < 2 then
                sameOrigin = effect
            end
        end
    end
    latest = sameOrigin or latest
    if (sameOrigin or active >= 24) and latest then
        latest.value += amount
        latest.gui.Text = "+" .. Format.number(latest.value)
        latest.onArrival = function()
            self:_arriveScore(toScore)
        end
        return
    end
    self:_flight("score", amount, source, "score", nil, function()
        self:_arriveScore(toScore)
        self:_ring(self:_anchor("score"), GREEN, 26)
    end)
end

function Feedback:_event(event)
    if event.kind == "score" then
        local source = if event.pegId
            then self:_anchor("peg", event.pegId)
            elseif event.slot then self:_anchor("inventory", event.slot)
            else self:_anchor("ball")
        self:_score(event.toScore or self.snapshot.score, source)
    elseif event.kind == "pop" then
        local source = self:_anchor("peg", event.pegId)
        self:_ring(source, if (event.oldValue or 1) <= 1 then WHITE else GREEN, 28)
        self.sounds:play("pop", 0.92 + ((event.pegId or 0) % 7) * 0.045)
    elseif event.kind == "trigger" then
        local slot = event.sourceSlot or event.slot
        local id = event.itemId
            or (slot and self.snapshot.inventory[slot] and self.snapshot.inventory[slot].id)
        local profile = id and Signatures.Profiles[id]
        if event.action == "activate" or not event.action and slot then
            self:_activateVisual(id, slot)
        elseif event.action == "perk" then
            self:_pulsePerk(event.perkId)
            self:_activateVisual(event.perkId, event.targetSlot or slot)
        end
        local pegId = event.targetPegId or event.pegId
        if pegId then
            local point = self:_anchor("peg", pegId)
            local color = if event.action == "halve"
                then Color3.fromRGB(255, 165, 112)
                elseif profile then Color3.fromRGB(table.unpack(profile.color))
                else GOLD
            if slot then
                self:_beam(slot, pegId, color, profile and profile.style or "tap", event.action)
            end
            self:_ring(point, color, 38)
            if event.action == "double" or event.action == "halve" then
                self:_label(
                    event.action == "double" and "×2" or "÷2",
                    point + Vector2.new(0, event.action == "double" and -24 or 15),
                    color,
                    24
                )
            end
        end
    elseif event.kind == "perkTrigger" then
        self:_pulsePerk(event.perkId)
        self:_activateVisual(event.perkId, event.targetSlot)
    elseif event.kind == "purchase" then
        self:_activateVisual(event.itemId, event.slot)
    elseif event.kind == "perkChoice" then
        if event.perkId then
            self:_pulsePerk(event.perkId)
            self:_activateVisual(event.perkId)
        end
    elseif event.kind == "clear" then
        self:_label("BOARD CLEAR!  ×2", self:_anchor("meter") + Vector2.new(0, -70), GOLD, 36)
        self.sounds:play("clear")
    end
end

function Feedback:_reset(snapshot)
    self.generation += 1
    self:_clearFx()
    self.sounds:clearItems()
    table.clear(self.itemFxTimes)
    self.timeline = nil
    self.pendingReceipt = nil
    self.awaitingFinish = false
    self.advanceWait = nil
    self.receipt = nil
    self.busy = false
    self.displayScore = snapshot.score
    self.queuedScore = snapshot.score
    self.displayCoins = snapshot.coins
    self.earned = snapshot.restocks or 0
    self.host:setBusy(false)
    self.host:setSettlement(nil)
    self.host:finishBoardOverride(snapshot)
    for kind, value in pairs({
        score = self.displayScore,
        coins = self.displayCoins,
        restocks = self.earned,
        reserves = snapshot.reserves,
    }) do
        self.host:setCounterDisplay(kind, value)
    end
end

function Feedback:update(snapshot)
    if self.destroyed then
        return
    end
    local previous = self.snapshot
    self.snapshot = snapshot
    if not previous or snapshot.coins ~= previous.coins then
        self.walletRevision += 1
    end
    if
        not previous
        or snapshot.phase == "aim"
            and (previous.phase ~= "aim" or snapshot.round ~= previous.round)
    then
        self:_reset(snapshot)
    end
    if previous and previous.phase == "aim" and snapshot.phase == "flight" then
        self.host:setCounterDisplay("reserves", snapshot.reserves)
        self.sounds:play("launch")
    end
    for _, event in ipairs(snapshot.events or {}) do
        if event.id > self.lastEvent then
            self.lastEvent = event.id
            if previous and not self.timeline then
                self:_event(event)
            end
        end
    end
    if snapshot.phase == "flight" or snapshot.phase == "result" or snapshot.phase == "gameover" then
        self:_score(snapshot.score, self:_anchor("ball"))
    end
    local receipt = snapshot.settlementReceipt
    if
        receipt
        and receipt.id ~= self.completedReceipt
        and not self.timeline
        and not self.pendingReceipt
    then
        self.pendingReceipt = receipt
        self.pendingWait = 0
        self.busy = true
        self.host:setBusy(true)
        self.host:setSettlement("COUNTING YOUR SHOT…", 0, false)
    elseif
        previous
        and not self.busy
        and not snapshot.settling
        and snapshot.phase ~= "flight"
        and snapshot.coins ~= previous.coins
    then
        if snapshot.coins > previous.coins then
            local balance = snapshot.coins
            local revision = self.walletRevision
            self.displayCoins = previous.coins
            self.host:setCounterDisplay("coins", self.displayCoins)
            self:_flight(
                "coin",
                balance - previous.coins,
                self:_anchor("inventory", 1),
                "coins",
                nil,
                function()
                    if revision ~= self.walletRevision then
                        return
                    end
                    self.displayCoins = balance
                    self.host:setCounterDisplay("coins", balance)
                    self:_pulseCounter("coins")
                    self.sounds:play("coin")
                end
            )
        else
            self.displayCoins = snapshot.coins
            self.host:setCounterDisplay("coins", snapshot.coins)
            self:_pulseCounter("coins", 0.4)
            self:_ring(self:_anchor("coins"), GOLD, 52)
            self.sounds:play("purchase")
        end
    end
    if not self.busy and snapshot.phase ~= "flight" then
        self.host:setCounterDisplay("reserves", snapshot.reserves)
    end
end

function Feedback:_board(values, scale)
    for id, value in ipairs(values or {}) do
        self.host:setPeg(id, value, nil, scale or 1)
    end
end

function Feedback:_reward(count)
    local receipt = self.receipt
    local receiptId = receipt.id
    self.credited = math.min(receipt.earnedRestocks, self.credited + count)
    local expectedCoins = math.min(receipt.coinsAfter, receipt.coinsBefore + self.credited)
    local expectedReserves = math.min(receipt.reservesAfter, receipt.reservesBefore + self.credited)
    self.host:setCounterDisplay("restocks", math.max(0, receipt.earnedRestocks - self.credited))
    self:_pulseCounter("restocks", 0.4)
    self:_flight("coin", count, self:_anchor("restocks"), "coins", nil, function()
        if not self.receipt or self.receipt.id ~= receiptId then
            return
        end
        self.displayCoins = math.max(self.displayCoins, expectedCoins)
        self.host:setCounterDisplay("coins", self.displayCoins)
        self:_pulseCounter("coins")
        self:_ring(self:_anchor("coins"), GOLD, 54)
        self.sounds:play("coin")
    end)
    if expectedReserves > self.displayReserves then
        local restoredLives = expectedReserves - self.displayReserves
        self.displayReserves = expectedReserves
        self:_flight("life", restoredLives, self:_anchor("restocks"), "reserve", nil, function()
            if not self.receipt or self.receipt.id ~= receiptId then
                return
            end
            self.host:setCounterDisplay("reserves", expectedReserves)
            self:_ring(self:_anchor("reserve"), GREEN, 40)
        end)
    end
end

function Feedback:_startTimeline(receipt)
    self.pendingReceipt = nil
    self.receipt = receipt
    self.timeline = Timeline.plan(receipt)
    self.timelineIndex = 0
    self.stepTime = 0
    self.credited = 0
    self.displayCoins = receipt.coinsBefore
    self.displayReserves = receipt.reservesBefore
    self.host:setCounterDisplay("coins", self.displayCoins)
    self.host:setCounterDisplay("reserves", self.displayReserves)
    self.host:setCounterDisplay("restocks", receipt.earnedRestocks)
    self.host:setBoardOverride(true)
    self:_board(receipt.shotValues)
    self:_nextStep()
end

function Feedback:_nextStep()
    self.timelineIndex += 1
    self.stepTime = 0
    local step = self.timeline[self.timelineIndex]
    if not step then
        self.awaitingFinish = true
        return
    end
    local receipt = self.receipt
    if step.beforeValues then
        self:_board(step.beforeValues)
    end
    if step.kind == "restore" then
        self.host:setSettlement(
            if receipt.earnedRestocks > 0
                then "RESTOCK ×" .. Format.integer(receipt.earnedRestocks)
                else "RESETTING THE BOARD",
            0,
            true
        )
        self.host:setCounterDisplay("score", 0)
    elseif step.kind == "refill" or step.kind == "batch" then
        local prefix = if step.kind == "batch"
            then "RESTOCK ×" .. Format.integer(step.count)
            else "RESTOCK " .. step.index .. " / " .. receipt.earnedRestocks
        self.host:setSettlement(
            prefix,
            (step.index - 1) / math.max(1, receipt.earnedRestocks),
            true
        )
        self:_reward(step.count)
        self.sounds:play("restock", 0.94 + (step.index % 4) * 0.05)
        if step.kind == "refill" then
            for _, refill in ipairs(step.refills) do
                local slot = Board.Slots[refill.to]
                self.host:setPeg(
                    refill.to,
                    refill.value,
                    { x = slot.x, y = Board.Geometry.top + 4 },
                    0.75
                )
            end
        end
    elseif step.kind == "merge" then
        self.host:setSettlement(
            "MERGING MATCHES",
            (step.index - 0.35) / math.max(1, receipt.earnedRestocks),
            true
        )
        for _, merge in ipairs(step.merges) do
            self:_line(self:_anchor("peg", merge.from), self:_anchor("peg", merge.to), GOLD)
        end
        if #step.merges > 0 then
            self.sounds:play("merge")
        end
    else
        self:_board(step.afterValues)
        self.host:setSettlement(
            if receipt.success
                then "READY FOR THE NEXT ROUND!"
                elseif receipt.reservesAfter <= 0 then "OUT OF BALLS — RUN COMPLETE"
                else "AIM AGAIN — " .. receipt.reservesAfter .. " BALLS LEFT",
            1,
            true
        )
    end
end

function Feedback:_sampleStep(step, t)
    if step.kind == "restore" or step.kind == "batch" then
        local eased = smooth(t)
        local values = if t < 0.4 then step.beforeValues else step.afterValues
        local scale = if t < 0.4 then 1 - eased * 0.65 else 0.7 + smooth((t - 0.4) / 0.6) * 0.3
        self:_board(values, scale)
    elseif step.kind == "refill" then
        for order, refill in ipairs(step.refills) do
            local slot = Board.Slots[refill.to]
            local delay = (order - 1) * 0.009
            local p = math.clamp((t - delay) / (1 - delay), 0, 1)
            local fall = math.min(1, p / 0.82)
            local y = (Board.Geometry.top + 4) + (slot.y - Board.Geometry.top - 4) * fall * fall
            local bounce = if p > 0.82 then math.sin((p - 0.82) / 0.18 * math.pi) * 0.3 else 0
            self.host:setPeg(
                refill.to,
                refill.value,
                { x = slot.x, y = y + bounce },
                0.8 + 0.2 * fall
            )
        end
    elseif step.kind == "merge" then
        local p = smooth(t)
        for _, merge in ipairs(step.merges) do
            local from, to = Board.Slots[merge.from], Board.Slots[merge.to]
            local x = from.x + (to.x - from.x) * p
            local y = from.y + (to.y - from.y) * p + math.sin(math.pi * p) * 0.8
            self.host:setPeg(
                merge.from,
                if p < 0.98 then step.beforeValues[merge.from] else 0,
                { x = x, y = y },
                1 - p * 0.4
            )
            local targetValue = if p > 0.8 then merge.value else step.beforeValues[merge.to]
            local scale = if p > 0.8 then 1 + math.sin((p - 0.8) / 0.2 * math.pi) * 0.3 else 1
            self.host:setPeg(merge.to, targetValue, nil, scale)
        end
    end
end

function Feedback:_finish()
    local receipt = self.receipt
    if not receipt then
        return
    end
    self.completedReceipt = receipt.id
    self.timeline = nil
    self.awaitingFinish = false
    self.receipt = nil
    self.busy = false
    self.displayCoins = receipt.coinsAfter
    self.host:setCounterDisplay("coins", receipt.coinsAfter)
    self.host:setCounterDisplay("reserves", receipt.reservesAfter)
    self.host:setCounterDisplay("restocks", 0)
    -- Shop and choice snapshots still contain the spent shot's values. Keep the
    -- restored board visible until the next aim snapshot releases this override.
    self:_board(receipt.finalValues)
    self.host:setBoardOverride(true)
    self.host:setSettlement(nil)
    self.host:setBusy(false)
    if self.snapshot.phase == "result" and self.onAdvance then
        self.advanceWait = 0
        self.onAdvance()
    end
end

function Feedback:skip()
    if self.timeline then
        self:_clearFx()
        self:_finish()
    end
end

function Feedback:step(dt)
    if self.destroyed then
        return
    end
    self.elapsed += dt
    for index = #self.fx, 1, -1 do
        local effect = self.fx[index]
        effect.age += dt
        local t = math.clamp(effect.age / effect.duration, 0, 1)
        if effect.kind == "flight" then
            local target = self:_anchor(effect.target, effect.targetIndex)
            local p = smooth(t)
            local point = effect.start:Lerp(target, p) + Vector2.new(0, -math.sin(t * math.pi) * 55)
            effect.gui.Position = UDim2.fromOffset(point.X, point.Y)
            if effect.reward == "score" then
                effect.gui.TextTransparency = math.max(0, (t - 0.8) * 3)
                effect.gui.Rotation = math.sin(t * math.pi) * 7
            elseif effect.view then
                effect.view:step(dt)
            end
        elseif effect.kind == "ring" then
            local size = effect.size * (0.6 + t * 1.6)
            effect.gui.Size = UDim2.fromOffset(size, size)
            effect.border.Transparency = t
            effect.border.Thickness = 4 * (1 - t)
        elseif effect.kind == "float" then
            effect.gui.Position = UDim2.fromOffset(effect.start.X, effect.start.Y - t * 48)
            effect.gui.TextTransparency = math.max(0, (t - 0.55) / 0.45)
            effect.gui.TextStrokeTransparency = effect.gui.TextTransparency
        elseif effect.kind == "line" then
            effect.gui.BackgroundTransparency = t
        elseif effect.kind == "beam" then
            local from = self:_anchor("inventory", effect.slot)
            local to = self:_anchor("peg", effect.pegId)
            local delta = to - from
            local direction = delta.Magnitude > 0 and delta.Unit or Vector2.new(0, 1)
            local normal = Vector2.new(-direction.Y, direction.X) * effect.offset
            local reach = smooth(math.min(1, t / 0.38))
            local center = from:Lerp(to, reach / 2) + normal
            effect.gui.Position = UDim2.fromOffset(center.X, center.Y)
            effect.gui.Size =
                UDim2.fromOffset(math.max(1, delta.Magnitude * reach), effect.width * (1 - t * 0.7))
            effect.gui.Rotation = math.deg(math.atan2(delta.Y, delta.X))
            effect.gui.BackgroundTransparency = 0.05 + math.max(0, (t - 0.5) * 1.9)
        elseif effect.kind == "spark" then
            local point = effect.start + effect.delta * smooth(t)
            effect.gui.Position = UDim2.fromOffset(point.X, point.Y)
            effect.gui.Size =
                UDim2.fromOffset(effect.size * (1 - t * 0.8), effect.size * (1 - t * 0.8))
            effect.gui.BackgroundTransparency = t
        end
        if t >= 1 then
            self:_remove(index, true)
        end
    end
    if self.pendingReceipt then
        self.pendingWait += dt
        local pointsInFlight = false
        for _, effect in ipairs(self.fx) do
            if effect.reward == "score" or effect.reward == "restock" then
                pointsInFlight = true
                break
            end
        end
        if self.pendingWait >= 0.5 and not pointsInFlight then
            self:_startTimeline(self.pendingReceipt)
        end
    end
    if self.timeline and not self.awaitingFinish then
        local speed = math.sqrt(self.snapshot.speed or 1)
        local step = self.timeline[self.timelineIndex]
        self.stepTime += dt * speed
        self:_sampleStep(step, math.clamp(self.stepTime / step.duration, 0, 1))
        if self.stepTime >= step.duration then
            self:_board(step.afterValues)
            self:_nextStep()
        end
    end
    if self.awaitingFinish then
        local inFlight = false
        for _, effect in ipairs(self.fx) do
            if effect.reward == "coin" or effect.reward == "life" then
                inFlight = true
                break
            end
        end
        if not inFlight then
            self:_finish()
        end
    end
    if self.advanceWait then
        local receipt = self.snapshot and self.snapshot.settlementReceipt
        if
            self.snapshot.phase ~= "result"
            or not receipt
            or receipt.id ~= self.completedReceipt
        then
            self.advanceWait = nil
        else
            self.advanceWait += dt
            if self.advanceWait >= 1 then
                self.advanceWait = 0
                self.onAdvance()
            end
        end
    end
end

function Feedback:destroy()
    if self.destroyed then
        return
    end
    self.destroyed = true
    self:_clearFx()
    self.sounds:destroy()
end

return Feedback
