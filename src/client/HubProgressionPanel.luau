-- Hub-only earned rewards, collection research and leaderboard presentation.
local HttpService = game:GetService("HttpService")
local Shared = game:GetService("ReplicatedStorage").Shared
local Catalog = require(Shared.Catalog)
local Format = require(Shared.Format)
local Theme = require(script.Parent.UiTheme)
local Layout = require(script.Parent.HubProgressionLayout)
local C = Theme.colors
local Panel = {}
Panel.__index = Panel
local tiers = { "common", "uncommon", "rare", "legendary" }
local colors = { common = C.mint, uncommon = C.blue, rare = C.aqua or C.edge, legendary = C.gold }
local names = { common = "MEADOW", uncommon = "LAGOON", rare = "AURORA", legendary = "CELESTIAL" }
local categories = { "time", "endless", "robux" }
local categoryNames =
    { time = "MOST TIME PLAYED", endless = "HIGHEST ENDLESS ROUND", robux = "MOST ROBUX SPENT" }

local function place(object, area)
    Theme.rect(object, area.x, area.y, area.w, area.h)
end
local function label(parent, name, value, area, color, maxSize)
    local text = Theme.label(parent, name, value, maxSize or 22, color or C.ink, 34)
    text.TextStrokeTransparency = 1
    text.TextWrapped, text.TextScaled = true, true
    Theme.make("UITextSizeConstraint", { MinTextSize = 11, MaxTextSize = maxSize or 22 }, text)
    place(text, area)
    return text
end
local function button(parent, name, value, area, color, callback, z)
    local result = Theme.button(parent, name, value, color or C.mint, callback, z or 35)
    result.TextColor3, result.TextStrokeTransparency = C.ink, 1
    result.TextScaled = true
    Theme.make("UITextSizeConstraint", { MinTextSize = 11, MaxTextSize = 23 }, result)
    place(result, area)
    return result
end
local function metric(kind, value)
    value = math.max(0, math.floor(tonumber(value) or 0))
    if kind == "time" then
        if value < 3600 then
            return string.format("%dm %02ds", math.floor(value / 60), value % 60)
        end
        return string.format("%dh %02dm", math.floor(value / 3600), math.floor(value / 60) % 60)
    end
    return kind == "endless" and ("R" .. value) or (tostring(value) .. " R$")
end

function Panel.new(host)
    return setmetatable({
        host = host,
        tier = "common",
        mode = "chests",
        page = 1,
        category = "time",
        leaderboardPage = 1,
    }, Panel)
end

function Panel:data()
    return (self.host.snapshot and self.host.snapshot.hub and self.host.snapshot.hub.chests) or {}
end

function Panel:footer(previous, nextText, summary)
    local h = self.host
    h.back.Visible = false
    h.previous.Visible, h.nextPage.Visible = previous ~= nil, nextText ~= nil
    h.previous.Text, h.nextPage.Text = previous or "", nextText or ""
    Theme.setEnabled(h.previous, true, C.muted)
    Theme.setEnabled(h.nextPage, true, C.muted)
    h.footer.Text = summary or ""
end

function Panel:request(kind, payload, handle)
    if self.pending then
        return
    end
    local target = payload.tier or payload.id
    local retry = self.retry and self.retry.kind == kind and self.retry.target == target
    payload.requestId = retry and self.retry.id or HttpService:GenerateGUID(false)
    self.pending = { id = payload.requestId, since = os.clock(), kind = kind, target = target }
    self.retry = self.pending
    if handle then
        handle:pulse(1.5)
    end
    self.host.onAction(kind, payload)
    if self.actionButton then
        Theme.setEnabled(self.actionButton, false, C.mint)
        if kind ~= "buyChest" then
            self.actionButton.Text = kind == "openChest" and "OPENING…" or "UNLOCKING…"
        end
    end
    if self.buyButton and self.buyButton.Parent then
        Theme.setEnabled(self.buyButton, false, C.mint)
        if kind == "buyChest" then
            self.buyButton.Text = "BUYING…"
        end
    end
end

function Panel:renderChests()
    local h, data = self.host, self:data()
    h:_clearBody()
    self.leaderRows = nil
    local balance = data.restockCredits or 0
    h.title.Text = "CHEST MARKET · " .. Format.integer(balance) .. " RESTOCKS"
    h.subtitle.Text = "Extra restocks saved across runs · Choose your chest · Open when ready"
    local g = Layout.chest(h.geometry.body.w, h.geometry.body.h)
    for i, tier in tiers do
        local cost = 0
        for _, entry in data.tiers or {} do
            if entry.id == tier then
                cost = entry.restockCost or 0
            end
        end
        local tab = button(
            h.body,
            "Tier_" .. tier,
            string.upper(tier) .. "\n" .. Format.integer(cost) .. " RS",
            g.tabs[i],
            colors[tier],
            function()
                self.tier, self.reveal = tier, nil
                self:renderChests()
            end
        )
        Theme.select(tab, self.tier == tier, colors[tier])
        tab.TextColor3, tab.TextStrokeTransparency = C.ink, 1
    end
    local tierData
    for _, entry in data.tiers or {} do
        if entry.id == self.tier then
            tierData = entry
        end
    end
    tierData = tierData
        or { count = 0, remaining = 0, total = 0, researchValue = 0, restockCost = 0 }
    local reveal = self.reveal
    local rewardId = reveal and reveal.itemId
    local modelId = rewardId or ("chest_" .. self.tier)
    local _, handle = h:_model(h.body, modelId, g.model, true)
    local heading, detail, actionText
    if reveal then
        heading = rewardId and ("UNLOCKED · " .. Catalog.Items[rewardId].name)
            or "RESEARCH COLLECTED"
        detail = rewardId and "Added to your collection. This item can roll in your next new run."
            or (
                "+"
                .. tostring(reveal.research or 0)
                .. " research. Choose a locked item in the workshop."
            )
        actionText = "CONTINUE"
    else
        heading = names[self.tier] .. " CHEST · " .. tostring(tierData.count) .. " READY"
        detail = tierData.remaining > 0
                and (tostring(tierData.remaining) .. " new discoveries in this chest pool. Every opening finds an unowned item.")
            or (
                "Pool complete. Opening grants "
                .. tostring(tierData.researchValue)
                .. " research for the workshop."
            )
        detail ..= " Extra restocks beyond the first each shot become saved currency. Milestones also award chests."
        actionText = tierData.count > 0 and ("OPEN · " .. tierData.count .. " OWNED")
            or "NO CHESTS OWNED"
    end
    label(h.body, "ChestName", heading, g.title, C.ink, 30).Font = Enum.Font.SourceSansBold
    local description = label(h.body, "ChestDetail", detail, g.detail, C.board, 21)
    description.Visible = g.showDetail
    self.actionButton = button(
        h.body,
        "OpenChest",
        actionText,
        g.action,
        colors[self.tier],
        function()
            if self.reveal then
                self.reveal = nil
                self:renderChests()
            else
                self:request("openChest", { tier = self.tier }, handle)
            end
        end
    )
    Theme.setEnabled(
        self.actionButton,
        reveal ~= nil or (tierData.count > 0 and not self.pending),
        colors[self.tier]
    )
    local price = tierData.restockCost or 0
    self.buyButton = button(
        h.body,
        "BuyChest",
        "BUY · " .. Format.integer(price) .. " RESTOCKS",
        g.buy,
        C.mint,
        function()
            self:request("buyChest", { tier = self.tier }, handle)
        end
    )
    self.buyButton.Visible = reveal == nil
    Theme.setEnabled(
        self.buyButton,
        not self.pending and price > 0 and balance >= price and tierData.count < 10000,
        C.mint
    )
    if reveal then
        place(self.actionButton, { x = 0, y = g.action.y, w = h.geometry.body.w, h = g.action.h })
    end
    local summary = balance < price and (Format.integer(price - balance) .. " MORE RESTOCKS TO BUY")
        or "BUY TO STORE · OPEN TO DISCOVER"
    self:footer(nil, "WORKSHOP ›", summary)
end

function Panel:renderWorkshop()
    local h, data = self.host, self:data()
    h:_clearBody()
    self.leaderRows = nil
    h.title.Text = "ITEM WORKSHOP"
    h.subtitle.Text = "Unlock new possibilities · Item levels still reset each run"
    local g = Layout.catalog(h.geometry.body.w, h.geometry.body.h)
    local entries = data.unlocks or {}
    local pages = math.max(1, math.ceil(#entries / g.pageSize))
    self.page = math.clamp(self.page, 1, pages)
    button(h.body, "ToChests", "‹ CHESTS", g.back, C.muted, function()
        self.mode = "chests"
        self:renderChests()
    end)
    local currency = label(
        h.body,
        "Research",
        tostring(data.research or 0) .. " RESEARCH",
        g.currency,
        C.board,
        20
    )
    currency.TextXAlignment = Enum.TextXAlignment.Right
    for i, area in g.cells do
        local entry = entries[(self.page - 1) * g.pageSize + i]
        if entry and Catalog.Items[entry.id] then
            local card = button(h.body, "Unlock_" .. entry.id, "", area, C.paper, function()
                self.itemId, self.mode = entry.id, "item"
                self:renderItem()
            end, 30)
            local badgeH = math.min(22, area.h * 0.18)
            label(
                card,
                "Tier",
                string.upper(entry.tier) .. (entry.owned and " · OWNED" or " · LOCKED"),
                { x = 5, y = 3, w = area.w - 10, h = badgeH },
                entry.owned and C.positive or C.board,
                14
            ).TextXAlignment =
                Enum.TextXAlignment.Center
            h:_model(
                card,
                entry.id,
                { x = 6, y = badgeH + 5, w = area.w - 12, h = math.max(16, area.h - badgeH - 40) },
                entry.owned
            )
            local name = label(
                card,
                "Name",
                Catalog.Items[entry.id].name,
                { x = 4, y = area.h - 31, w = area.w - 8, h = 28 },
                C.ink,
                22
            )
            name.TextXAlignment = Enum.TextXAlignment.Center
        end
    end
    self:footer("‹ PREV", "NEXT ›", self.page .. " / " .. pages)
    Theme.setEnabled(h.previous, self.page > 1, C.muted)
    Theme.setEnabled(h.nextPage, self.page < pages, C.muted)
end

function Panel:renderItem()
    local h, data = self.host, self:data()
    local entry
    for _, item in data.unlocks or {} do
        if item.id == self.itemId then
            entry = item
        end
    end
    if not entry then
        self.mode = "workshop"
        self:renderWorkshop()
        return
    end
    h:_clearBody()
    local definition, detail = Catalog.Items[entry.id], Catalog.detail(entry.id, 1)
    h.title.Text = definition.name
    h.subtitle.Text = string.upper(entry.tier)
        .. (
            entry.owned and " · OWNED · Available in new runs"
            or " · Discover in chests or spend research"
        )
    local g = Layout.item(h.geometry.body.w, h.geometry.body.h)
    h:_model(h.body, entry.id, g.model, true)
    local rows = { { text = detail.trigger, tone = "trigger" } }
    for _, effect in detail.effects do
        table.insert(rows, effect)
    end
    local rowH = math.min(48, g.stats.h / #rows)
    for i, row in rows do
        label(
            h.body,
            "Effect" .. i,
            row.text,
            { x = g.stats.x, y = g.stats.y + (i - 1) * rowH, w = g.stats.w, h = rowH },
            C[row.tone] or C.ink,
            21
        )
    end
    self.actionButton = button(
        h.body,
        "ResearchUnlock",
        entry.owned and "OWNED" or ("UNLOCK · " .. tostring(entry.cost) .. " RESEARCH"),
        g.action,
        C.mint,
        function()
            self:request("researchItem", { id = entry.id })
        end
    )
    Theme.setEnabled(
        self.actionButton,
        not entry.owned and (data.research or 0) >= entry.cost and not self.pending,
        C.mint
    )
    self:footer("‹ ITEMS", nil, tostring(data.research or 0) .. " RESEARCH")
end

function Panel:renderLeaders()
    local h = self.host
    h:_clearBody()
    h.title.Text = "ARCADE LEADERBOARDS"
    local g = Layout.leaders(h.geometry.body.w, h.geometry.body.h)
    for i, kind in categories do
        local tab = button(
            h.body,
            "Board_" .. kind,
            ({ time = "TIME", endless = "ENDLESS", robux = "ROBUX" })[kind],
            g.tabs[i],
            C.muted,
            function()
                self.category, self.leaderboardPage = kind, 1
                self:renderLeaders()
            end
        )
        Theme.select(tab, self.category == kind, C.muted)
        tab.TextColor3, tab.TextStrokeTransparency = C.ink, 1
    end
    self.leaderRows = {}
    for i, area in g.rows do
        local row = Theme.plate(h.body, "Rank" .. i, i % 2 == 0 and C.muted or C.paper, 30)
        place(row, area)
        local rank = label(row, "Rank", "", { x = 5, y = 2, w = 35, h = area.h - 4 }, C.board, 20)
        local valueW = math.min(160, area.w * 0.32)
        local name = label(
            row,
            "Player",
            "",
            { x = 43, y = 2, w = area.w - valueW - 49, h = area.h - 4 },
            C.ink,
            22
        )
        local value = label(
            row,
            "Value",
            "",
            { x = area.w - valueW - 6, y = 2, w = valueW, h = area.h - 4 },
            C.board,
            21
        )
        value.TextXAlignment = Enum.TextXAlignment.Right
        self.leaderRows[i] = { frame = row, rank = rank, name = name, value = value }
    end
    self.emptyLabel = label(
        h.body,
        "EmptyBoard",
        "",
        { x = 12, y = 60, w = h.geometry.body.w - 24, h = math.max(40, h.geometry.body.h - 66) },
        C.board,
        22
    )
    self:refreshLeaders()
end

function Panel:refreshLeaders()
    if not self.leaderRows then
        return
    end
    local h = self.host
    local boards = h.snapshot.hub.leaderboards or { mode = "unavailable" }
    local mode = boards.mode == "global" and (boards.stale and "GLOBAL · LAST SAVED" or "GLOBAL")
        or boards.mode == "session" and "THIS SERVER · STUDIO SESSION"
        or "OFFLINE"
    h.subtitle.Text = mode .. " · " .. categoryNames[self.category]
    local category = boards.categories and boards.categories[self.category] or {}
    local entries = category.entries or {}
    local pages = math.max(1, math.ceil(#entries / #self.leaderRows))
    self.leaderboardPage = math.clamp(self.leaderboardPage, 1, pages)
    for i, row in self.leaderRows do
        local index = (self.leaderboardPage - 1) * #self.leaderRows + i
        local entry = entries[index]
        row.frame.Visible = entry ~= nil
        if entry then
            row.rank.Text = tostring(index)
            row.name.Text = entry.name or ("Player " .. entry.userId)
            row.value.Text = metric(self.category, entry.value)
        end
    end
    self.emptyLabel.Visible = #entries == 0
    self.emptyLabel.Text = boards.mode == "unavailable"
            and "Leaderboards are temporarily unavailable."
        or self.category == "robux" and "No recorded purchases in this experience. Purchases are not enabled."
        or self.category == "endless" and "Clear round 100, enter Endless, then set the first record!"
        or "Play a little longer to set the first time record."
    self:footer("‹ PREV", "NEXT ›", self.leaderboardPage .. " / " .. pages)
    Theme.setEnabled(h.previous, self.leaderboardPage > 1, C.muted)
    Theme.setEnabled(h.nextPage, self.leaderboardPage < pages, C.muted)
end

function Panel:render()
    if self.host.openPanel == "leaderboards" then
        self:renderLeaders()
    elseif self.mode == "workshop" then
        self:renderWorkshop()
    elseif self.mode == "item" then
        self:renderItem()
    else
        self:renderChests()
    end
end

function Panel:pageBy(delta)
    if self.host.openPanel == "leaderboards" then
        self.leaderboardPage += delta
    elseif self.mode == "chests" or self.mode == "item" then
        self.mode = "workshop"
    else
        self.page += delta
    end
    self:render()
end

function Panel:update(snapshot)
    local data = snapshot.hub and snapshot.hub.chests or {}
    local key = HttpService:JSONEncode(data)
    local changed = self.key ~= key
    self.key = key
    local opened = data.lastOpened
    if opened and self.retry and opened.requestId == self.retry.id then
        self.lastSerial = opened.serial
        self.pendingResult = opened
        self.pending = self.pending or self.retry
        self.retry = nil
    end
    local rejected = snapshot.notice and self.pending and not self.pendingResult
    if snapshot.notice and not self.pendingResult then
        self.pending, self.retry = nil, nil
    end
    if self.host.openPanel == "leaderboards" then
        self:refreshLeaders()
    elseif self.host.openPanel == "chests" and (changed or rejected) and not self.pending then
        self:render()
    end
end

function Panel:step()
    if self.pending and self.pendingResult and self.pendingResult.kind == "purchase" then
        local result = self.pendingResult
        self.pending, self.pendingResult, self.reveal = nil, nil, nil
        self.tier, self.mode = result.tier, "chests"
        self.host:setNotice(names[result.tier] .. " CHEST STORED · Open it whenever you're ready")
        if self.host.openPanel == "chests" then
            self:render()
        end
    elseif self.pending and self.pendingResult and os.clock() - self.pending.since >= 1.6 then
        self.reveal, self.pendingResult, self.pending = self.pendingResult, nil, nil
        self.tier, self.mode = self.reveal.tier, "chests"
        if self.host.openPanel == "chests" then
            self:render()
        end
    elseif self.pending and os.clock() - self.pending.since > 8 then
        self.pending = nil
        self.host:setNotice(
            "Still waiting for the reward response. Check your chest balance before retrying."
        )
        if self.host.openPanel == "chests" then
            self:render()
        end
    end
end

return Panel
