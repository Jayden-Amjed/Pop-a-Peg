--!nonstrict

local Players = game:GetService("Players")
local ProximityPromptService = game:GetService("ProximityPromptService")
local UserInputService = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")
local Shared = game:GetService("ReplicatedStorage").Shared
local Catalog = require(Shared.Catalog)
local Format = require(Shared.Format)
local Theme = require(script.Parent.UiTheme)
local ItemModels = require(script.Parent.GameItemModels)
local Layout = require(script.Parent.HubLayout)
local HubAmbience = require(script.Parent.HubAmbience)
local HubProgressionPanel = require(script.Parent.HubProgressionPanel)
local C = Theme.colors
local Hub = {}
Hub.__index = Hub

local function text(parent, name, value, size, color, z)
    local label = Theme.label(parent, name, value, size, color or C.ink, z or 7)
    label.TextStrokeTransparency = 1
    return label
end

local function fitText(label, maxSize, minSize)
    label.TextScaled = true
    Theme.make(
        "UITextSizeConstraint",
        { MinTextSize = minSize or 12, MaxTextSize = maxSize },
        label
    )
end

local function setRect(object, area)
    Theme.rect(object, area.x, area.y, area.w, area.h)
end

local function button(parent, name, value, color, callback, z)
    local result = Theme.button(parent, name, value, color, callback, z or 8)
    result.TextColor3 = C.ink
    result.TextStrokeTransparency = 1
    fitText(result, 22, 12)
    local hovered, focused = false, false
    local function highlight()
        local border = result:FindFirstChildWhichIsA("UIStroke")
        if border then
            local active = result.Active and (hovered or focused)
            border.Color = active and C.gold or C.edge
            border.Thickness = active and 4 or 2
        end
    end
    result.MouseEnter:Connect(function()
        hovered = true
        highlight()
    end)
    result.MouseLeave:Connect(function()
        hovered = false
        highlight()
    end)
    result.SelectionGained:Connect(function()
        focused = true
        highlight()
    end)
    result.SelectionLost:Connect(function()
        focused = false
        highlight()
    end)
    result:GetPropertyChangedSignal("Active"):Connect(highlight)
    return result
end

function Hub:_clearBody()
    for _, entry in self.models do
        entry.handle:destroy()
    end
    self.models = {}
    self.body:ClearAllChildren()
    self.rosterRows = nil
end

function Hub:_model(parent, id, area, discovered)
    local viewport = Theme.make("ViewportFrame", {
        Name = "Model_" .. id,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ZIndex = 32,
    }, parent)
    viewport:SetAttribute("NoOutline", true)
    setRect(viewport, area)
    local handle = ItemModels.mount(viewport, id, Catalog.MaxLevel, {
        outline = false,
        reducedMotion = GuiService.ReducedMotionEnabled,
    })
    if discovered == false then
        for _, part in handle.model:GetDescendants() do
            if part:IsA("BasePart") then
                part.Color = Color3.fromRGB(48, 94, 116)
                part.Material = Enum.Material.SmoothPlastic
                part.Transparency = 0
                part.Reflectance = 0
            end
        end
    end
    table.insert(self.models, { viewport = viewport, handle = handle })
    return viewport, handle
end

function Hub:_discovered(id)
    return self.unlocks[id] == true
end

function Hub:_gallery()
    self:_clearBody()
    local layout = self.geometry
    local pageSize = layout.pageSize
    self.page = math.clamp(self.page, 1, math.ceil(#Catalog.Evolutions / pageSize))
    self.title.Text = "EVOLUTION AQUARIUM"
    self.subtitle.Text = self.discoveries
        .. " / "
        .. #Catalog.Evolutions
        .. " discovered · Select a model to see its recipe"
    for index, area in layout.cells do
        local recipe = Catalog.Evolutions[(self.page - 1) * pageSize + index]
        if recipe then
            local owned = self:_discovered(recipe.id)
            local card = button(
                self.body,
                "Evolution_" .. recipe.id,
                "",
                owned and C.muted or C.paper,
                function()
                    self.selected = recipe.id
                    self.recipePage = 1
                    self:_renderPanel()
                end,
                30
            )
            setRect(card, area)
            local badge = text(
                card,
                "Discovery",
                owned and "DISCOVERED" or "UNDISCOVERED",
                14,
                owned and C.positive or C.board,
                33
            )
            badge.Font = Enum.Font.SourceSansBold
            badge.TextXAlignment = Enum.TextXAlignment.Center
            Theme.rect(badge, 8, 6, area.w - 16, 20)
            local modelY, modelH = 27, math.max(22, area.h - 68)
            self:_model(card, recipe.id, { x = 8, y = modelY, w = area.w - 16, h = modelH }, owned)
            local name = text(card, "Name", Catalog.Items[recipe.id].name, 22, C.ink, 33)
            name.Font = Enum.Font.SourceSansBold
            name.TextXAlignment = Enum.TextXAlignment.Center
            name.TextWrapped = true
            fitText(name, 22, 12)
            Theme.rect(name, 8, area.h - 38, area.w - 16, 32)
        end
    end
    self.previous.Visible, self.nextPage.Visible = true, true
    self.previous.Text, self.nextPage.Text = "‹ PREV", "NEXT ›"
    Theme.setEnabled(self.previous, self.page > 1, C.muted)
    Theme.setEnabled(self.nextPage, self.page < math.ceil(#Catalog.Evolutions / pageSize), C.muted)
    self.footer.Text = "PAGE " .. self.page .. " / " .. math.ceil(#Catalog.Evolutions / pageSize)
    self.back.Visible = false
end

function Hub:_recipe()
    self:_clearBody()
    local recipe
    for _, candidate in Catalog.Evolutions do
        if candidate.id == self.selected then
            recipe = candidate
            break
        end
    end
    if not recipe then
        self.selected = nil
        self:_gallery()
        return
    end
    local w, h = self.geometry.body.w, self.geometry.body.h
    local compact = self.geometry.compact
    local owned = self:_discovered(recipe.id)
    self.title.Text = string.upper(Catalog.Items[recipe.id].name)
    self.subtitle.Text = owned and "DISCOVERED · This display stays with you between runs"
        or "UNDISCOVERED · Evolve these two items during a run"
    local showModels = not compact or self.recipePage ~= 2
    local recipeH = if compact then h else math.min(280, h * 0.6)
    local tileW = (w - 60) / 3
    local ids = { recipe.ingredients[1], recipe.ingredients[2], recipe.id }
    if showModels then
        for index, id in ids do
            local x = (index - 1) * (tileW + 30)
            local tile = Theme.plate(self.body, "RecipePart" .. index, C.muted, 30)
            Theme.rect(tile, x, 0, tileW, recipeH)
            local status = text(
                tile,
                "Status",
                index == 3 and "EVOLVED" or "LEVEL 5",
                16,
                index == 3 and C.positive or C.board,
                33
            )
            status.TextXAlignment = Enum.TextXAlignment.Center
            Theme.rect(status, 4, 4, tileW - 8, 18)
            self:_model(
                tile,
                id,
                { x = 6, y = 23, w = tileW - 12, h = math.max(22, recipeH - 60) },
                index < 3 or owned
            )
            local name = text(tile, "Name", Catalog.Items[id].name, 20, C.ink, 33)
            name.Font = Enum.Font.SourceSansBold
            name.TextWrapped = true
            name.TextXAlignment = Enum.TextXAlignment.Center
            fitText(name, 20, 11)
            Theme.rect(name, 5, recipeH - 36, tileW - 10, 31)
            if index < 3 then
                local symbol =
                    text(self.body, "Operator" .. index, index == 1 and "+" or "=", 32, C.ink, 33)
                symbol.TextXAlignment = Enum.TextXAlignment.Center
                Theme.rect(symbol, x + tileW, recipeH * 0.42, 30, 40)
            end
        end
    end
    if not compact or not showModels then
        local details = Catalog.detail(recipe.id, Catalog.MaxLevel)
        local effects = Theme.plate(self.body, "Abilities", C.paper, 30)
        local effectsY = compact and 0 or recipeH + 12
        Theme.rect(effects, 0, effectsY, w, h - effectsY)
        local availableH = h - effectsY - 16
        local rowH = math.min(28, availableH / math.max(1, #details.effects))
        for index, effect in details.effects do
            local line = text(
                effects,
                "Effect" .. index,
                (effect.tone == "trigger" and "" or "• ") .. effect.text,
                19,
                C[effect.tone] or C.ink,
                33
            )
            line.Font = effect.tone == "trigger" and Enum.Font.SourceSansBold
                or Enum.Font.SourceSansSemibold
            fitText(line, 19, 11)
            Theme.rect(line, 12, 8 + (index - 1) * rowH, w - 24, rowH)
        end
    end
    self.previous.Visible, self.nextPage.Visible, self.back.Visible = false, compact, true
    self.nextPage.Text = showModels and "STATS ›" or "MODELS ›"
    Theme.setEnabled(self.nextPage, true, C.muted)
    self.footer.Text = compact and (showModels and "L5 + L5" or "MAX LEVEL")
        or "Collection is permanent · Equipment power resets each run"
end

function Hub:_records()
    self:_clearBody()
    self.title.Text = "YOUR ARCADE RECORDS"
    self.subtitle.Text = "Every new run is a fresh build. Your milestones stay with you."
    local profile = self.snapshot.hub.profile or {}
    local w, h = self.geometry.body.w, self.geometry.body.h
    local compact = self.geometry.compact
    local showStats = not compact or self.recordsPage ~= 2
    local topH = compact and math.min(120, h) or 100
    local stats = {
        { name = "BEST ROUND", value = tostring(profile.bestRound or 0) },
        { name = "BEST SHOT", value = Format.number(profile.bestScore or 0) },
        { name = "DISCOVERIES", value = self.discoveries .. " / " .. #Catalog.Evolutions },
    }
    if showStats then
        for index, stat in stats do
            local card = Theme.plate(self.body, "Record" .. index, C.muted, 30)
            local cardW = (w - 20) / 3
            Theme.rect(card, (index - 1) * (cardW + 10), 0, cardW, topH)
            local caption = text(card, "Caption", stat.name, 16, C.board, 32)
            caption.Font = Enum.Font.SourceSansBold
            caption.TextXAlignment = Enum.TextXAlignment.Center
            fitText(caption, 16, 10)
            Theme.rect(caption, 4, 5, cardW - 8, 22)
            local value = text(card, "Value", stat.value, compact and 28 or 42, C.ink, 32)
            value.Font = Enum.Font.SourceSansBold
            value.TextXAlignment = Enum.TextXAlignment.Center
            fitText(value, compact and 28 or 42, 15)
            Theme.rect(value, 4, 26, cardW - 8, topH - 30)
        end
    end
    local milestones = {
        { "Meadow Shore", 15 },
        { "Glass Lagoon", 40 },
        { "Sunlit Reef", 65 },
        { "Aurora Ocean", 100 },
    }
    local rowTop = compact and 0 or topH + 12
    local rowH = (h - rowTop - 18) / 4
    if not compact or not showStats then
        for index, milestone in milestones do
            local earned = self.unlocks["level_" .. index]
            local card =
                Theme.plate(self.body, "Milestone" .. index, earned and C.muted or C.paper, 30)
            Theme.rect(card, 0, rowTop + (index - 1) * (rowH + 6), w, rowH)
            local badge = text(
                card,
                "Badge",
                earned and "CLEARED" or "GOAL",
                16,
                earned and C.positive or C.board,
                32
            )
            badge.Font = Enum.Font.SourceSansBold
            Theme.rect(badge, 12, 0, 80, rowH)
            local name = text(card, "Name", milestone[1], 22, C.ink, 32)
            fitText(name, 22, 11)
            Theme.rect(name, 92, 0, math.max(50, w - 210), rowH)
            local target = text(card, "Target", "ROUND " .. milestone[2], 18, C.board, 32)
            target.TextXAlignment = Enum.TextXAlignment.Right
            fitText(target, 18, 10)
            Theme.rect(target, w - 108, 0, 96, rowH)
        end
    end
    self.previous.Visible, self.nextPage.Visible, self.back.Visible = false, compact, false
    self.nextPage.Text = showStats and "LEVELS ›" or "BESTS ›"
    Theme.setEnabled(self.nextPage, true, C.muted)
    self.footer.Text = self.snapshot.profileStatus == "session"
            and "SESSION RECORDS · Studio preview"
        or (
            self.snapshot.profileStatus == "unavailable"
                and "Saving unavailable · Session records only"
            or "Records stay with your profile when saving is available"
        )
    if compact then
        self.footer.Text = self.snapshot.profileStatus == "session" and "SESSION"
            or (self.snapshot.profileStatus == "unavailable" and "UNAVAILABLE" or "RECORDS")
    end
end

function Hub:_help()
    self:_clearBody()
    local steps = {
        {
            title = "AIM YOUR BOUNCE",
            model = "ball",
            lines = {
                "Drag on the board, then release to launch.",
                "Every peg hit scores its current number, then halves it.",
                "One-point pegs pop away. Clear the board to double your score.",
            },
        },
        {
            title = "EARN A RESTOCK",
            model = "restock",
            lines = {
                "Reach the shot target to clear the round and earn a restock.",
                "Extra restocks beyond the first each shot also become saved hub currency.",
                "After the shot, restocks refill and merge pegs, add coins and restore balls.",
            },
        },
        {
            title = "SHAPE YOUR BUILD",
            model = "goldfish",
            lines = {
                "Use coins in the shop. Read each item's trigger and effects.",
                "Raise two recipe ingredients to level 5, then evolve them in a shop.",
                "Spend saved restocks on chests in the hub. Milestones award bonus chests too.",
            },
        },
    }
    self.helpPage = math.clamp(self.helpPage or 1, 1, #steps)
    local step = steps[self.helpPage]
    self.title.Text = "HOW TO PLAY"
    self.subtitle.Text = string.format("%02d / 03 · %s", self.helpPage, step.title)
    local w, h = self.geometry.body.w, self.geometry.body.h
    local modelW = self.geometry.narrow and math.min(110, w * 0.28) or w * 0.32
    local model = Theme.plate(self.body, "LessonModel", C.muted, 30)
    Theme.rect(model, 0, 0, modelW, h)
    self:_model(model, step.model, { x = 4, y = 4, w = modelW - 8, h = h - 8 }, true)
    local x, rowW = modelW + 12, w - modelW - 12
    local rowH = (h - 16) / 3
    for index, value in step.lines do
        local card = Theme.plate(self.body, "Lesson" .. index, C.paper, 30)
        Theme.rect(card, x, (index - 1) * (rowH + 8), rowW, rowH)
        local line = text(card, "Instruction", value, 23, C.ink, 33)
        line.TextWrapped = true
        fitText(line, 23, 11)
        Theme.rect(line, 10, 5, rowW - 20, rowH - 10)
    end
    self.previous.Visible, self.nextPage.Visible, self.back.Visible = true, true, false
    self.previous.Text, self.nextPage.Text = "‹ PREV", "NEXT ›"
    Theme.setEnabled(self.previous, self.helpPage > 1, C.muted)
    Theme.setEnabled(self.nextPage, self.helpPage < #steps, C.muted)
    self.footer.Text = "STEP " .. self.helpPage .. " / " .. #steps
end

function Hub:_roster()
    self:_clearBody()
    self.title.Text = "ARCADE CREW"
    self.subtitle.Text = "Eight personal stations · Everyone plays their own board"
    local w, h = self.geometry.body.w, self.geometry.body.h
    local columns = self.geometry.narrow and not self.geometry.compact and 1 or 2
    local rows = 8 / columns
    local rowH = (h - (rows - 1) * 6) / rows
    local rowW = (w - (columns - 1) * 12) / columns
    self.rosterRows = {}
    for index = 1, 8 do
        local column, row = math.floor((index - 1) / rows), (index - 1) % rows
        local card = Theme.plate(self.body, "Station" .. index, C.paper, 30)
        Theme.rect(card, column * (rowW + 12), row * (rowH + 6), rowW, rowH)
        local number = text(card, "Number", string.format("%02d", index), 26, C.board, 32)
        number.Font = Enum.Font.SourceSansBold
        Theme.rect(number, 10, 0, 35, rowH)
        local name = text(card, "Player", "OPEN STATION", 21, C.ink, 32)
        name.TextTruncate = Enum.TextTruncate.AtEnd
        fitText(name, 21, 11)
        Theme.rect(name, 50, 2, rowW - 64, rowH * 0.52)
        local status = text(card, "Status", "Ready for a player", 15, C.board, 32)
        fitText(status, 15, 9)
        Theme.rect(status, 50, rowH * 0.48, rowW - 64, rowH * 0.46)
        self.rosterRows[index] = { card = card, name = name, status = status }
    end
    self:_refreshRoster()
    self.previous.Visible, self.nextPage.Visible, self.back.Visible = false, false, false
    self.footer.Text = "Walk to your station or press Play from anywhere in the arcade"
end

function Hub:_refreshRoster()
    if not self.rosterRows or not self.snapshot then
        return
    end
    local occupants = {}
    for _, player in self.snapshot.hub.players or {} do
        occupants[player.station] = player
    end
    for index, row in self.rosterRows do
        local player = occupants[index]
        row.name.Text = player and player.name or "OPEN STATION"
        row.status.Text = player
                and (player.view == "run" and ("IN RUN · ROUND " .. tostring(player.round or 1)) or "EXPLORING THE ARCADE")
            or "Ready for a player"
        row.card.BackgroundColor3 = index == self.snapshot.hub.station and C.muted or C.paper
        if index == self.snapshot.hub.station then
            row.name.Text ..= " · YOU"
        end
    end
end

function Hub:_renderPanel()
    if not self.snapshot or not self.openPanel then
        return
    end
    local focusedBody = GuiService.SelectedObject
        and GuiService.SelectedObject:IsDescendantOf(self.body)
    if self.openPanel == "collection" then
        if self.selected then
            self:_recipe()
        else
            self:_gallery()
        end
    elseif self.openPanel == "records" then
        self:_records()
    elseif self.openPanel == "help" then
        self:_help()
    elseif self.openPanel == "chests" or self.openPanel == "leaderboards" then
        self.progression:render()
    else
        self:_roster()
    end
    self.progressTrack.Visible = self.openPanel == "collection" and self.selected == nil
    self.progressFill.Size = UDim2.fromScale(self.discoveries / #Catalog.Evolutions, 1)
    if focusedBody then
        GuiService.SelectedObject = self.back.Visible and self.back or self.closeButton
    end
end

function Hub:open(kind)
    if self.destroyed or not self.snapshot then
        return
    end
    self.openPanel = kind
    self.returnSelection = GuiService.SelectedObject
    self.selected = nil
    self.panel.Visible, self.shade.Visible = true, true
    self.dock.Visible = false
    self:_renderPanel()
    if UserInputService:GetLastInputType() == Enum.UserInputType.Gamepad1 then
        GuiService.SelectedObject = self.closeButton
    end
end

function Hub:close()
    self.openPanel, self.selected = nil, nil
    self.panel.Visible, self.shade.Visible = false, false
    self.dock.Visible = true
    if GuiService.SelectedObject and GuiService.SelectedObject:IsDescendantOf(self.panel) then
        GuiService.SelectedObject = self.returnSelection
                and self.returnSelection.Parent
                and self.returnSelection
            or self.play
    end
    self:_clearBody()
end

function Hub:isModalOpen()
    return self.openPanel ~= nil
end

function Hub:_page(delta)
    if self.openPanel == "chests" or self.openPanel == "leaderboards" then
        self.progression:pageBy(delta)
        return
    elseif self.openPanel == "help" then
        self.helpPage = math.clamp((self.helpPage or 1) + delta, 1, 3)
    elseif self.openPanel == "records" then
        self.recordsPage = self.recordsPage == 2 and 1 or 2
    elseif self.selected then
        self.recipePage = self.recipePage == 2 and 1 or 2
    else
        self.page += delta
    end
    self:_renderPanel()
end

function Hub:_layout()
    local size = self.root.AbsoluteSize
    if size.X < 32 or size.Y < 32 then
        return
    end
    self.size = size
    local geometry = Layout.compute(size.X, size.Y)
    self.geometry = geometry
    setRect(self.panel, geometry.panel)
    setRect(self.body, geometry.body)
    local w, h = geometry.panel.w, geometry.panel.h
    Theme.rect(self.title, 18, 10, w - 84, 32)
    Theme.rect(self.subtitle, 18, 44, w - 36, 25)
    Theme.rect(self.progressTrack, 18, 71, w - 36, 4)
    Theme.rect(self.closeButton, w - 60, 8, 44, 44)
    Theme.rect(self.previous, 16, h - 59, 84, 44)
    Theme.rect(self.nextPage, w - 100, h - 59, 84, 44)
    Theme.rect(self.back, 16, h - 59, 100, 44)
    Theme.rect(self.footer, 120, h - 59, w - 240, 44)
    if w < 500 then
        Theme.rect(self.footer, 106, h - 59, w - 212, 44)
    end
    setRect(self.dock, geometry.dock)
    setRect(self.collectionButton, geometry.controls.collection)
    setRect(self.recordsButton, geometry.controls.records)
    setRect(self.helpButton, geometry.controls.help)
    setRect(self.chestsButton, geometry.controls.chests)
    setRect(self.leadersButton, geometry.controls.leaderboards)
    setRect(self.play, geometry.controls.play)
    setRect(self.hint, geometry.hint)
    setRect(self.brand, geometry.brand)
    setRect(self.wallet, geometry.wallet)
    Theme.rect(self.walletLabel, 12, 4, geometry.wallet.w - 24, 17)
    Theme.rect(self.walletValue, 12, 21, geometry.wallet.w - 24, 29)
    Theme.rect(self.brandTitle, 12, 5, geometry.brand.w - 24, 28)
    Theme.rect(self.brandSubtitle, 12, 34, geometry.brand.w - 24, 20)
    setRect(self.crewPlate, geometry.crew)
    Theme.rect(self.crew, 5, 4, geometry.crew.w - 10, 31)
    Theme.rect(self.stationLabel, 6, 36, geometry.crew.w - 12, 20)
    setRect(self.notice, geometry.notice)
    self:_renderPanel()
end

function Hub.new(onAction)
    local self = setmetatable({
        onAction = onAction,
        models = {},
        connections = {},
        page = 1,
        discoveries = 0,
        unlocks = {},
    }, Hub)
    self.progression = HubProgressionPanel.new(self)
    self.gui = Theme.make("ScreenGui", {
        Name = "PopAPegHub",
        ResetOnSpawn = false,
        IgnoreGuiInset = false,
        DisplayOrder = 10,
        ZIndexBehavior = Enum.ZIndexBehavior.Global,
    }, Players.LocalPlayer:WaitForChild("PlayerGui"))
    self.root = Theme.frame(self.gui, "Root", C.paper, 1)
    self.root.Size = UDim2.fromScale(1, 1)
    self.root.BackgroundTransparency = 1
    self.brand = Theme.plate(self.root, "Brand", C.paper, 3)
    self.brandTitle = text(self.brand, "Title", "AQUARIUM ARCADE", 26, C.ink)
    self.brandTitle.Font = Enum.Font.SourceSansBold
    fitText(self.brandTitle, 26, 15)
    self.brandSubtitle =
        text(self.brand, "Subtitle", "POP A PEG · BUILD A BIGGER BOUNCE", 13, C.board)
    fitText(self.brandSubtitle, 13, 9)
    self.wallet = button(self.root, "RestockWallet", "", C.paper, function()
        self.progression.mode = "chests"
        self:open("chests")
    end, 4)
    self.walletLabel = text(self.wallet, "Label", "RESTOCKS · CHEST MARKET", 14, C.board)
    fitText(self.walletLabel, 14, 9)
    self.walletValue = text(self.wallet, "Balance", "0", 30, C.ink)
    self.walletValue.Font = Enum.Font.SourceSansBold
    fitText(self.walletValue, 30, 15)
    self.crewPlate = Theme.plate(self.root, "CrewPlate", C.paper, 3)
    self.crew = button(self.crewPlate, "Crew", "PLAYERS · 0 / 8", C.muted, function()
        self:open("crew")
    end)
    self.stationLabel =
        text(self.crewPlate, "AssignedStation", "FINDING YOUR STATION…", 16, C.board)
    self.stationLabel.TextXAlignment = Enum.TextXAlignment.Center
    fitText(self.stationLabel, 16, 10)
    self.dock = Theme.plate(self.root, "PlayDock", C.paper, 4)
    self.collectionButton = button(self.dock, "Collection", "EVOLUTIONS", C.muted, function()
        self:open("collection")
    end)
    self.recordsButton = button(self.dock, "Records", "RECORDS", C.muted, function()
        self:open("records")
    end)
    self.helpButton = button(self.dock, "Help", "HOW TO PLAY", C.muted, function()
        self:open("help")
    end)
    self.chestsButton = button(self.dock, "Chests", "CHESTS", C.gold, function()
        self.progression.mode = "chests"
        self:open("chests")
    end)
    self.leadersButton = button(self.dock, "Leaderboards", "RANKINGS", C.muted, function()
        self:open("leaderboards")
    end)
    self.play = button(self.dock, "Play", "PLAY", C.mint, function()
        if self.startPending or self.transitionPending then
            return
        end
        self.startPending = os.clock()
        self:_refreshPlay()
        self.onAction("startRun", {})
    end)
    self.hint = text(self.dock, "Hint", "Walk around the arcade or start from here", 15, C.board)
    self.hint.TextXAlignment = Enum.TextXAlignment.Center
    fitText(self.hint, 15, 10)
    self.notice = text(self.root, "Notice", "", 20, C.ink, 12)
    self.notice.BackgroundColor3 = C.paper
    self.notice.BackgroundTransparency = 0.05
    self.notice.Visible = false
    Theme.corner(self.notice, 8)
    Theme.stroke(self.notice, C.edge, 2)
    self.notice.TextXAlignment = Enum.TextXAlignment.Center
    fitText(self.notice, 20, 12)
    self.shade = Theme.make("TextButton", {
        Name = "PanelBackdrop",
        Text = "",
        AutoButtonColor = false,
        Active = true,
        BackgroundColor3 = C.ink,
        BackgroundTransparency = 0.25,
        BorderSizePixel = 0,
        Size = UDim2.fromScale(1, 1),
        ZIndex = 20,
        Visible = false,
    }, self.root)
    self.shade.Activated:Connect(function()
        self:close()
    end)
    self.panel = Theme.plate(self.root, "Panel", C.paper, 25)
    self.panel.Active = true
    self.panel.Visible = false
    self.title = text(self.panel, "Title", "", 29, C.ink, 28)
    self.title.Font = Enum.Font.SourceSansBold
    fitText(self.title, 29, 16)
    self.subtitle = text(self.panel, "Subtitle", "", 17, C.board, 28)
    fitText(self.subtitle, 17, 10)
    self.progressTrack = Theme.frame(self.panel, "CollectionProgress", C.muted, 29)
    Theme.corner(self.progressTrack, 2)
    self.progressFill = Theme.frame(self.progressTrack, "Fill", C.gold, 30)
    Theme.corner(self.progressFill, 2)
    self.closeButton = button(self.panel, "Close", "×", C.muted, function()
        self:close()
    end, 30)
    self.body = Theme.frame(self.panel, "Body", C.paper, 29)
    self.body.BackgroundTransparency = 1
    self.previous = button(self.panel, "Previous", "‹ PREV", C.muted, function()
        self:_page(-1)
    end, 30)
    self.nextPage = button(self.panel, "Next", "NEXT ›", C.muted, function()
        self:_page(1)
    end, 30)
    self.back = button(self.panel, "Back", "‹ GALLERY", C.muted, function()
        self.selected = nil
        self:_renderPanel()
    end, 30)
    self.footer = text(self.panel, "Footer", "", 16, C.board, 29)
    self.footer.TextXAlignment = Enum.TextXAlignment.Center
    self.footer.TextWrapped = true
    fitText(self.footer, 16, 10)
    table.insert(
        self.connections,
        ProximityPromptService.PromptTriggered:Connect(function(prompt, player)
            if player and player ~= Players.LocalPlayer then
                return
            end
            if prompt.Name == "CollectionPrompt" then
                self:open("collection")
            elseif prompt.Name == "RecordsPrompt" then
                self:open("records")
            elseif prompt.Name == "OpenChests" then
                self.progression.mode = "chests"
                self:open("chests")
            elseif prompt.Name == "OpenLeaderboards" then
                self:open("leaderboards")
            end
        end)
    )
    table.insert(
        self.connections,
        UserInputService.InputBegan:Connect(function(input, processed)
            if
                not processed
                and self.openPanel
                and (
                    input.KeyCode == Enum.KeyCode.ButtonB
                    or input.KeyCode == Enum.KeyCode.Backspace
                )
            then
                if self.selected then
                    self.selected = nil
                    self:_renderPanel()
                else
                    self:close()
                end
            end
        end)
    )
    self:_layout()
    return self
end

function Hub:update(snapshot)
    self.snapshot = snapshot
    local hub = snapshot.hub or {}
    self.unlocks, self.discoveries = {}, 0
    for _, id in (hub.profile and hub.profile.unlocks) or {} do
        self.unlocks[id] = true
    end
    for _, id in Catalog.EvolvedIds do
        if self.unlocks[id] then
            self.discoveries += 1
        end
    end
    self:_refreshPlay()
    self.crew.Text = "PLAYERS · " .. #(hub.players or {}) .. " / " .. tostring(hub.capacity or 8)
    self.brandSubtitle.Text = "POP A PEG · "
        .. self.discoveries
        .. " / "
        .. #Catalog.Evolutions
        .. " DISCOVERIES"
    self.stationLabel.Text = hub.station
            and string.format(
                "%02d · %s WING",
                hub.station,
                hub.station <= 4 and "LEFT" or "RIGHT"
            )
        or "FINDING YOUR STATION…"
    local round = 1
    for _, player in hub.players or {} do
        if player.station == hub.station then
            round = player.round or 1
            break
        end
    end
    self.hint.Text = hub.canResume and ("ROUND " .. round .. " · Your build is waiting")
        or (
            hub.station
                and string.format(
                    "Station %02d · %s wing · Or press Play",
                    hub.station,
                    hub.station <= 4 and "Left" or "Right"
                )
            or "Explore the arcade, or press Play to begin"
        )
    self:_refreshRoster()
    local chestCount = 0
    for _, tier in (hub.chests and hub.chests.tiers) or {} do
        chestCount += tier.count
    end
    self.chestsButton.Text = chestCount > 0 and ("CHESTS · " .. chestCount) or "CHESTS"
    self.walletValue.Text = Format.integer(hub.chests and hub.chests.restockCredits or 0)
    self.progression:update(snapshot)
    if snapshot.notice then
        self:setNotice(snapshot.notice)
    end
end

function Hub:_refreshPlay()
    local pending = self.startPending ~= nil or self.transitionPending == true
    local canResume = self.snapshot and self.snapshot.hub and self.snapshot.hub.canResume
    self.play.Text = pending and "ENTERING…" or (canResume and "RESUME RUN" or "PLAY")
    Theme.setEnabled(self.play, not pending, C.mint)
end

function Hub:setTransitionPending(pending)
    self.transitionPending = pending == true
    if not pending then
        self.startPending = nil
    end
    self:_refreshPlay()
end

function Hub:setNotice(message)
    self.notice.Text = tostring(message)
    self.notice.Visible = true
    self.noticeUntil = os.clock() + 5
    self.startPending = nil
    self.transitionPending = false
    self:_refreshPlay()
end

function Hub:step(dt)
    if self.destroyed then
        return
    end
    self.progression:step()
    if
        not GuiService.ReducedMotionEnabled
        and Players.LocalPlayer:GetAttribute("ReducedMotionEnabled") ~= true
    then
        if not self.ambience then
            self.ambienceRetry = (self.ambienceRetry or 0) + dt
            if self.ambienceRetry >= 0.5 then
                self.ambienceRetry = 0
                local world = workspace:FindFirstChild("AquariumArcade")
                if world then
                    local ambience = HubAmbience.new(world)
                    if #ambience.groups == 10 then
                        self.ambience = ambience
                    else
                        ambience:destroy()
                    end
                end
            end
        else
            self.ambience:step(dt)
        end
    elseif self.ambience then
        self.ambience:destroy()
        self.ambience = nil
    end
    if self.root.AbsoluteSize ~= self.size then
        self:_layout()
    end
    if self.openPanel then
        for _, entry in self.models do
            entry.handle:step(dt)
        end
    end
    if self.startPending and os.clock() - self.startPending > 4 then
        self.startPending = nil
        self:_refreshPlay()
    end
    if self.noticeUntil and os.clock() > self.noticeUntil then
        self.notice.Text = ""
        self.notice.Visible = false
        self.noticeUntil = nil
    end
end

function Hub:destroy()
    if self.destroyed then
        return
    end
    self.destroyed = true
    if self.ambience then
        self.ambience:destroy()
    end
    for _, connection in self.connections do
        connection:Disconnect()
    end
    self:_clearBody()
    self.gui:Destroy()
end

return Hub
