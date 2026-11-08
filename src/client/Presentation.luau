--!nonstrict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Board = require(Shared:WaitForChild("Board"))
local Catalog = require(Shared:WaitForChild("Catalog"))
local Format = require(Shared:WaitForChild("Format"))
local Simulation = require(Shared:WaitForChild("Simulation"))
local Theme = require(script.Parent.UiTheme)
local ItemModels = require(script.Parent.ItemModels)
local Feedback = require(script.Parent.Feedback)

local Presentation = {}
Presentation.__index = Presentation

local C = Theme.colors

local PEG_COLORS = {
    Color3.fromRGB(255, 143, 117),
    Color3.fromRGB(255, 183, 111),
    Color3.fromRGB(250, 220, 116),
    Color3.fromRGB(169, 227, 137),
    Color3.fromRGB(114, 224, 184),
    Color3.fromRGB(122, 213, 239),
    Color3.fromRGB(149, 179, 248),
    Color3.fromRGB(191, 159, 241),
    Color3.fromRGB(236, 161, 218),
}

local make = Theme.make
local corner = Theme.corner
local stroke = Theme.stroke
local frame = Theme.frame
local label = Theme.label
local button = Theme.button
local setRect = Theme.rect
local plate = Theme.plate

local function blockAim(gui)
    gui:SetAttribute("BlocksAim", true)
end
local function part(parent, name, size, position, color, material, shape)
    local result = make("Part", {
        Name = name,
        Anchored = true,
        CanCollide = false,
        CanTouch = false,
        CanQuery = false,
        CastShadow = true,
        Size = size,
        Position = position,
        Color = color,
        Material = material or Enum.Material.SmoothPlastic,
        TopSurface = Enum.SurfaceType.Smooth,
        BottomSurface = Enum.SurfaceType.Smooth,
    }, parent)
    if shape then
        result.Shape = shape
    end
    return result
end

local function disc(parent, name, radius, thickness, position, color, material)
    local result = part(
        parent,
        name,
        Vector3.new(thickness, radius * 2, radius * 2),
        position,
        color,
        material,
        Enum.PartType.Cylinder
    )
    result.CFrame = CFrame.new(position) * CFrame.Angles(0, math.pi / 2, 0)
    return result
end

local function itemDefinition(item)
    if not item then
        return nil
    end
    return Catalog.Items[item.id or item]
end

local function itemColor(definition)
    local color = definition and definition.color
    if typeof(color) == "Color3" then
        return color
    elseif type(color) == "table" then
        return Color3.fromRGB(
            color[1] or color.r or 121,
            color[2] or color.g or 230,
            color[3] or color.b or 187
        )
    end
    return C.mint
end

local function formatTime(seconds)
    seconds = math.max(0, seconds or 0)
    return string.format("%02d:%05.2f", math.floor(seconds / 60), seconds % 60)
end

function Presentation:_send(kind, payload)
    if self.destroyed then
        return
    end
    if self.feedback and self.feedback.playCue and kind ~= "continue" then
        self.feedback:playCue("click")
    end
    self.onAction(kind, payload or {})
end

function Presentation:_buildBoard()
    self.model = make("Model", { Name = "PopAPegLocalBoard" }, workspace)
    part(self.model, "StageBackdrop", Vector3.new(300, 200, 1), Vector3.new(0, 11, -8), C.ink)
    part(
        self.model,
        "CabinetShadow",
        Vector3.new(24.4, 32.4, 0.3),
        Vector3.new(0.45, 10.45, -3),
        Color3.fromRGB(7, 18, 10)
    )
    for _, side in { -1, 1 } do
        part(
            self.model,
            "StagePanel",
            Vector3.new(8, 39, 0.2),
            Vector3.new(side * 17.5, 11, -7.25),
            Color3.fromRGB(19, 40, 22)
        )
        part(
            self.model,
            "StageTrim",
            Vector3.new(0.035, 35, 0.1),
            Vector3.new(side * 13.25, 11, -7),
            C.edge
        )
        for y = -6, 30, 6 do
            local mark = part(
                self.model,
                "StageMark",
                Vector3.new(0.55, 0.04, 0.1),
                Vector3.new(side * 14, y, -6.9),
                C.edge
            )
            mark.Transparency = 0.4
        end
    end
    part(self.model, "CabinetBack", Vector3.new(22, 30, 1.2), Vector3.new(0, 10.9, -1), C.ink)
    for _, side in { -1, 1 } do
        for _, y in { -3.5, 25.2 } do
            part(
                self.model,
                "CornerHousing",
                Vector3.new(1.45, 1.45, 1.9),
                Vector3.new(side * 10.5, y, -0.05),
                C.mint
            )
            disc(
                self.model,
                "CornerBolt",
                0.23,
                0.12,
                Vector3.new(side * 10.5, y, 0.98),
                C.paper,
                Enum.Material.Metal
            )
        end
        part(
            self.model,
            "FactoryBrace",
            Vector3.new(0.7, 18, 0.8),
            Vector3.new(side * 11.5, 8, -0.8),
            C.panel
        )
        local housing = part(
            self.model,
            "RefillFeeder",
            Vector3.new(1.8, 3.4, 1.5),
            Vector3.new(side * 11.7, 19.8, -0.55),
            C.mint
        )
        housing.Material = Enum.Material.SmoothPlastic
        for index = 1, 3 do
            part(
                self.model,
                "FeederVent",
                Vector3.new(1.15, 0.12, 0.1),
                Vector3.new(side * 11.7, 18.8 + index * 0.5, 0.24),
                C.ink
            )
        end
    end
    part(
        self.model,
        "Playfield",
        Vector3.new(20.15, 28.9, 0.45),
        Vector3.new(0, 10.95, -0.25),
        C.board
    )
    for _, side in { -1, 1 } do
        part(
            self.model,
            "SideRail",
            Vector3.new(0.55, 30, 1.5),
            Vector3.new(side * 10.55, 10.9, 0),
            C.edge,
            Enum.Material.Metal
        )
        part(
            self.model,
            "RailLight",
            Vector3.new(0.09, 28.5, 0.13),
            Vector3.new(side * 10.12, 10.9, 0.79),
            side < 0 and C.coral or C.mint,
            Enum.Material.Neon
        )
        part(
            self.model,
            "OuterPipe",
            Vector3.new(0.5, 20, 0.5),
            Vector3.new(side * 11.45, 7.8, -0.3),
            C.edge,
            Enum.Material.Metal,
            Enum.PartType.Cylinder
        )
        for y = -1, 23, 4 do
            disc(
                self.model,
                "RailFastener",
                0.13,
                0.12,
                Vector3.new(side * 10.55, y, 0.85),
                C.paper,
                Enum.Material.Metal
            )
        end
        for y = 1, 18, 8 do
            part(
                self.model,
                "PipeBracket",
                Vector3.new(0.8, 0.32, 0.8),
                Vector3.new(side * 11.45, y, -0.2),
                C.board,
                Enum.Material.Metal
            )
        end
    end
    part(
        self.model,
        "TopRail",
        Vector3.new(21.6, 0.65, 1.5),
        Vector3.new(0, 25.6, 0),
        C.edge,
        Enum.Material.Metal
    )
    part(
        self.model,
        "DrainLip",
        Vector3.new(21.6, 0.5, 1.5),
        Vector3.new(0, -3.8, 0),
        C.edge,
        Enum.Material.Metal
    )
    part(
        self.model,
        "DrainGlow",
        Vector3.new(19.8, 0.12, 0.2),
        Vector3.new(0, -3.48, 0.6),
        C.coral,
        Enum.Material.Neon
    )
    for x = -8.5, 8.5, 1 do
        part(
            self.model,
            "DrainVent",
            Vector3.new(0.38, 0.8, 0.1),
            Vector3.new(x, -3.1, 0.05),
            C.ink
        )
    end
    for y = 0, 21, 1.7 do
        local line =
            part(self.model, "Inlay", Vector3.new(19.3, 0.025, 0.025), Vector3.new(0, y, 0), C.edge)
        line.Transparency = 0.8
    end
    local launcher = disc(
        self.model,
        "LauncherSocket",
        0.9,
        0.15,
        Vector3.new(0, 22, 0.2),
        C.edge,
        Enum.Material.Metal
    )
    make("PointLight", { Color = C.blue, Brightness = 0.65, Range = 19, Shadows = false }, launcher)
    self.pegs = {}
    for _, slot in Board.Slots do
        disc(
            self.model,
            "SocketRim" .. slot.id,
            1.02,
            0.12,
            Vector3.new(slot.x, slot.y, 0.15),
            C.edge,
            Enum.Material.Metal
        )
        disc(self.model, "Socket" .. slot.id, 0.91, 0.15, Vector3.new(slot.x, slot.y, 0.25), C.ink)
        local peg = part(
            self.model,
            "Peg" .. slot.id,
            Vector3.one * Board.Geometry.pegRadius * 2,
            Vector3.new(slot.x, slot.y, 0.62),
            C.gold,
            nil,
            Enum.PartType.Ball
        )
        local billboard = make("BillboardGui", {
            Name = "Value",
            Adornee = peg,
            Size = UDim2.fromScale(1.65, 1.25),
            StudsOffsetWorldSpace = Vector3.new(0, 0, 1),
            AlwaysOnTop = true,
            LightInfluence = 0,
        }, peg)
        local number = label(billboard, "Number", "1", 30, C.ink)
        number.Size = UDim2.fromScale(1, 1)
        number.Font = Enum.Font.FredokaOne
        number.TextScaled = true
        number.TextXAlignment = Enum.TextXAlignment.Center
        self.pegs[slot.id] =
            { part = peg, number = number, billboard = billboard, pulse = 0, value = -1 }
    end
    self.ball = part(
        self.model,
        "Ball",
        Vector3.one * Board.Geometry.ballRadius * 2,
        Vector3.new(0, 22, 1.15),
        C.paper,
        nil,
        Enum.PartType.Ball
    )
    local a = make("Attachment", { Position = Vector3.new(-0.14, 0, 0) }, self.ball)
    local b = make("Attachment", { Position = Vector3.new(0.14, 0, 0) }, self.ball)
    self.trail = make("Trail", {
        Attachment0 = a,
        Attachment1 = b,
        Color = ColorSequence.new(C.paper, C.mint),
        Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0.2),
            NumberSequenceKeypoint.new(1, 1),
        }),
        Lifetime = 0.22,
        MinLength = 0.08,
        FaceCamera = true,
        Enabled = false,
    }, self.ball)
    self.guide = {}
    for index = 1, 28 do
        local dot = part(
            self.model,
            "AimDot" .. index,
            Vector3.one * 0.15,
            Vector3.new(0, 21 - index, 1),
            C.mint,
            Enum.Material.Neon,
            Enum.PartType.Ball
        )
        self.guide[index] = dot
    end
    self.aimArrow = {}
    for index = 1, 2 do
        self.aimArrow[index] = part(
            self.model,
            "AimArrow" .. index,
            Vector3.new(0.12, 0.6, 0.12),
            Vector3.new(0, 20, 1.1),
            C.mint,
            Enum.Material.Neon
        )
    end
end

function Presentation:_viewport(parent, name, id, level, z)
    local viewport = make("ViewportFrame", {
        Name = name,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ZIndex = z or 5,
        Ambient = Color3.new(1, 1, 1),
        LightColor = Color3.new(1, 1, 1),
        LightDirection = Vector3.new(-1, -1, -1),
    }, parent)
    self:_mount(viewport, id, level)
    return viewport
end

function Presentation:_mount(viewport, id, level)
    local key = tostring(id) .. ":" .. tostring(level or 1)
    local current = self.models[viewport]
    if current and current.key == key then
        return
    end
    if current then
        current.handle:destroy()
    end
    self.models[viewport] =
        { key = key, handle = ItemModels.mount(viewport, id, level or 1, { animate = false }) }
end

function Presentation:_dropModels(parent)
    for viewport, mounted in self.models do
        if viewport:IsDescendantOf(parent) then
            mounted.handle:destroy()
            self.models[viewport] = nil
        end
    end
end

function Presentation:_buildHud()
    self.gui = make("ScreenGui", {
        Name = "PopAPeg",
        IgnoreGuiInset = true,
        ResetOnSpawn = false,
        ScreenInsets = Enum.ScreenInsets.None,
        ZIndexBehavior = Enum.ZIndexBehavior.Global,
        DisplayOrder = 20,
    }, Players.LocalPlayer:WaitForChild("PlayerGui"))
    self.root = frame(self.gui, "Root", nil, 1)
    self.root.Size = UDim2.fromScale(1, 1)
    self.root.BackgroundTransparency = 1
    self.brand = label(self.root, "Brand", "POP A PEG", 37, C.paper, 5)
    self.tag = label(self.root, "Tag", "BUILD A BIGGER BOUNCE!", 18, C.gold, 5)
    self.roundPlate = plate(self.root, "RoundPlate", C.panel, 3)
    blockAim(self.roundPlate)
    self.roundLabel = label(self.roundPlate, "Round", "ROUND 1", 30, C.paper, 5)
    self.phaseLabel = label(self.roundPlate, "Phase", "READY TO LAUNCH", 17, C.muted, 5)

    self.inventory = plate(self.root, "EquipmentRack", C.panel, 30)
    blockAim(self.inventory)
    self.itemSlots = {}
    for index = 1, 7 do
        local cell = button(self.inventory, "Slot" .. index, "", C.panel, function()
            local state = self.snapshot
            if not state or self.busy then
                return
            end
            if index > state.slots then
                if state.phase == "shop" then
                    self:_send("buySlot")
                else
                    self:setNotice("Unlock another slot for 5 coins in the shop.")
                end
            elseif self.selectedSlot and self.selectedSlot ~= index then
                if state.phase == "aim" or state.phase == "shop" then
                    self:_send("move", { from = self.selectedSlot, to = index })
                end
                self.selectedSlot = index
            else
                self.selectedSlot = self.selectedSlot == index and nil or index
            end
            self.modalKey = nil
            self:_updateInventory()
            self:_updateModal()
        end, 32)
        local border = cell:FindFirstChildWhichIsA("UIStroke")
        local model = self:_viewport(cell, "Equipment", index <= 4 and "restock" or "lock", 1, 34)
        local number = label(cell, "Position", tostring(index), 18, C.paper, 36)
        local level = label(cell, "Level", "", 18, C.gold, 36)
        level.TextXAlignment = Enum.TextXAlignment.Right
        local name = label(cell, "Name", index <= 4 and "EMPTY" or "5 COINS", 18, C.paper, 36)
        name.TextXAlignment = Enum.TextXAlignment.Center
        name.TextTruncate = Enum.TextTruncate.AtEnd
        self.itemSlots[index] = {
            button = cell,
            border = border,
            viewport = model,
            number = number,
            level = level,
            name = name,
        }
    end

    self.left = frame(self.root, "Resources", nil, 2)
    self.left.BackgroundTransparency = 1
    self.wallet = plate(self.left, "Wallet", C.panel, 3)
    blockAim(self.wallet)
    self.coinModel = self:_viewport(self.wallet, "Coin", "coin", 1, 5)
    self.coinCaption = label(self.wallet, "Caption", "COINS", 22, C.gold, 5)
    self.coins = label(self.wallet, "Amount", "0", 56, C.paper, 5)
    self.reservePlate = plate(self.left, "ReserveRack", C.panel, 3)
    blockAim(self.reservePlate)
    self.reserveCaption = label(self.reservePlate, "Caption", "BALLS LEFT", 22, C.paper, 5)
    self.reserves = label(self.reservePlate, "Count", "5 / 5", 28, C.paper, 5)
    self.reserves.TextXAlignment = Enum.TextXAlignment.Right
    self.reserveIcons = {}
    for index = 1, 5 do
        self.reserveIcons[index] = self:_viewport(self.reservePlate, "Ball" .. index, "ball", 1, 5)
    end
    self.detail = plate(self.left, "EquipmentDetail", C.panel, 3)
    blockAim(self.detail)
    self.detailTitle = label(self.detail, "Name", "YOUR COMBO STARTS HERE", 23, C.paper, 5)
    self.detailTitle.TextWrapped = true
    self.detailTrigger = label(self.detail, "Trigger", "TAP AN EQUIPMENT SLOT", 18, C.gold, 5)
    self.detailTrigger.TextWrapped = true
    self.detailBody = label(
        self.detail,
        "Effect",
        "Shop for gadgets. Match them to upgrade. Every bounce builds your run.",
        18,
        C.paper,
        5
    )
    self.detailBody.TextWrapped = true
    self.detailBody.TextYAlignment = Enum.TextYAlignment.Top
    self.detailClose = button(self.detail, "CloseDetail", "×", C.coral, function()
        self.selectedSlot = nil
        self.modalKey = nil
        self:_updateInventory()
        self:_updateModal()
    end, 6)
    self.detailClose.Visible = false
    self.stats = label(self.left, "ShotStats", "0 POPS   0 WALLS", 19, C.paper, 5)
    self.timer = label(self.left, "Time", "00:00.00", 18, C.muted, 5)

    self.right = frame(self.root, "ScoreTower", nil, 2)
    self.right.BackgroundTransparency = 1
    self.scorePlate = plate(self.right, "Score", C.panel, 3)
    blockAim(self.scorePlate)
    self.scoreCaption = label(self.scorePlate, "Caption", "SHOT SCORE", 23, C.paper, 5)
    self.score = label(self.scorePlate, "Total", "0", 60, C.paper, 5)
    self.quota = label(self.scorePlate, "Quota", "TARGET 10", 23, C.paper, 5)
    self.quotaConstraint =
        make("UITextSizeConstraint", { MinTextSize = 16, MaxTextSize = 25 }, self.quota)
    self.progressCaption = label(self.scorePlate, "Next", "NEXT RESTOCK", 18, C.muted, 5)
    self.progress = frame(self.scorePlate, "RepeatMeter", C.ink, 4)
    stroke(self.progress, C.ink, 4)
    corner(self.progress, 3)
    self.progressFill = frame(self.progress, "CurrentFill", C.mint, 5)
    corner(self.progressFill, 2)
    self.fraction = label(self.progress, "Fraction", "0 / 10", 29, C.paper, 7)
    self.fraction.TextXAlignment = Enum.TextXAlignment.Center
    self.fraction.Size = UDim2.fromScale(1, 1)
    self.restockPlate = plate(self.right, "EarnedRestocks", C.panel, 3)
    blockAim(self.restockPlate)
    self.restockModel = self:_viewport(self.restockPlate, "Restock", "restock", 1, 5)
    self.restockCaption = label(self.restockPlate, "Caption", "RESTOCKS EARNED", 20, C.gold, 5)
    self.restockCount = label(self.restockPlate, "Count", "×0", 55, C.paper, 5)
    self.restockHint =
        label(self.restockPlate, "Hint", "Fill the meter to grow your board", 17, C.paper, 5)
    self.restockHint.TextWrapped = true
    self.stackIcons = {}
    for index = 1, 8 do
        self.stackIcons[index] =
            self:_viewport(self.restockPlate, "Stack" .. index, "restock", 1, 5)
        self.stackIcons[index].Visible = false
    end
    self.best = label(self.right, "Best", "BEST ROUND 0", 18, C.muted, 5)
    self.profile = label(self.right, "Profile", "SESSION RECORDS", 14, C.muted, 5)

    self.controls = frame(self.root, "Controls", nil, 10)
    self.controls.BackgroundTransparency = 1
    blockAim(self.controls)
    self.jumbleButton = button(self.controls, "Jumble", "JUMBLE", C.blue, function()
        self:_send("jumble")
    end, 12)
    self.primary = button(self.controls, "Launch", "LAUNCH!", C.mint, function()
        self:_primaryAction()
    end, 12)
    self.speedButtons = {}
    for index, speed in { 1, 2, 4 } do
        self.speedButtons[index] = button(
            self.root,
            "Speed" .. speed,
            speed .. "×",
            C.panel,
            function()
                if not self.busy then
                    self:_send("speed", { value = speed })
                end
            end,
            12
        )
    end
    self.soundButton = button(self.root, "Sound", "SOUND ON", C.panel, function()
        self.muted = not self.muted
        self.soundButton.Text = (self.shortWide and "SFX " or "SOUND ")
            .. (self.muted and "OFF" or "ON")
        if self.feedback then
            self.feedback:setMuted(self.muted)
        end
    end, 12)
    self.soundButton.TextSize = 17
    self.help = label(self.root, "Help", "AIM • CLICK THE BOARD OR PRESS SPACE", 18, C.paper, 12)
    self.help.TextXAlignment = Enum.TextXAlignment.Center
    self.notice = label(self.root, "Notice", "", 24, C.gold, 70)
    self.notice.TextXAlignment = Enum.TextXAlignment.Center
    self.notice.TextWrapped = true
    self.settlement = plate(self.root, "Settlement", C.panel, 55)
    self.settlement.Visible = false
    blockAim(self.settlement)
    self.settlementText = label(self.settlement, "Text", "", 26, C.paper, 57)
    self.settlementText.TextXAlignment = Enum.TextXAlignment.Center
    self.settlementText.TextWrapped = true
    self.settlementProgress = frame(self.settlement, "Progress", C.mint, 57)
    self.skipButton = button(self.settlement, "Skip", "SKIP", C.mint, function()
        if self.feedback then
            self.feedback:skip()
        end
    end, 58)
    self.skipButton.TextSize = 19
    self.overlay = frame(self.root, "Overlay", C.ink, 20)
    self.overlay.Size = UDim2.fromScale(1, 1)
    self.overlay.BackgroundTransparency = 0.18
    self.overlay.Visible = false
    blockAim(self.overlay)
    self.fxLayer = frame(self.root, "Feedback", nil, 60)
    self.fxLayer.Size = UDim2.fromScale(1, 1)
    self.fxLayer.BackgroundTransparency = 1
    self.loading = frame(self.root, "Connecting", C.ink, 90)
    self.loading.Size = UDim2.fromScale(1, 1)
    blockAim(self.loading)
    local connecting = label(self.loading, "Text", "CONNECTING…", 32, C.paper, 91)
    connecting.Size = UDim2.fromScale(1, 1)
    connecting.TextXAlignment = Enum.TextXAlignment.Center
end

function Presentation:_layout()
    local camera = workspace.CurrentCamera
    if not camera or camera.ViewportSize.X < 1 then
        return
    end
    local size = camera.ViewportSize
    self.viewport = size
    local w, h = size.X, size.Y
    local inset = game:GetService("GuiService"):GetGuiInset()
    local top = math.max(12, inset.Y + 8)
    self.mobile = w < 850 and h > w * 0.8
    self.shortWide = (h < 620 or w < 1100) and not self.mobile
    local compact = self.mobile or self.shortWide
    self.compact = compact
    local boardRect, invWidth, invHeight
    self.brand.Visible = not compact
    self.tag.Visible = not compact
    self.roundPlate.Visible = true
    self.phaseLabel.Visible = not compact
    self.detail.Visible = not compact
    self.stats.Visible = not compact
    self.timer.Visible = not compact
    self.coinCaption.Visible = not compact
    self.scoreCaption.Visible = true
    self.progressCaption.Visible = not compact
    self.restockCaption.Visible = true
    self.restockCaption.Text = compact and "RESTOCKS" or "RESTOCKS EARNED"
    self.restockCaption.TextXAlignment = Enum.TextXAlignment.Left
    self.detailClose.Visible = false
    self.detailPopup = compact
    self.inlineDetail = false
    self.restockHint.Visible = not compact
    self.restockModel.Visible = not compact
    self.best.Visible = not compact
    self.profile.Visible = not compact
    self.help.Visible = not compact
    if compact then
        local uiX = self.shortWide and math.floor(w * 0.43) or 12
        local uiW = self.shortWide and w - uiX - 12 or w - 24
        local resourceTop = self.shortWide and top + 72 or top
        local scoreTop = resourceTop + 50
        local invTop = self.shortWide and top or top + 188
        invWidth, invHeight = uiW, 64
        setRect(self.inventory, uiX, invTop, uiW, invHeight)
        setRect(self.left, uiX, resourceTop, uiW, 42)
        local half = (uiW - 10) / 2
        setRect(self.wallet, 0, 0, half, 42)
        setRect(self.coinModel, 0, -4, 48, 48)
        setRect(self.coins, 47, 0, half - 53, 42)
        self.coins.TextSize = 31
        setRect(self.reservePlate, half + 10, 0, half, 42)
        setRect(self.reserveCaption, 8, 0, 65, 42)
        self.reserveCaption.Text = "BALLS"
        self.reserveCaption.TextSize = 18
        setRect(self.reserves, 71, 0, half - 79, 42)
        self.reserves.TextSize = 25
        setRect(self.right, uiX, scoreTop, uiW, 88)
        setRect(self.scorePlate, 0, 0, uiW, 88)
        setRect(self.scoreCaption, 10, 3, 58, 34)
        self.scoreCaption.Text = "SCORE"
        self.scoreCaption.TextSize = 18
        setRect(self.score, 72, 1, uiW - 205, 37)
        self.score.TextSize = 31
        setRect(self.quota, uiW - 127, 3, 117, 34)
        self.quota.TextSize = 19
        self.quota.TextScaled = true
        self.quotaConstraint.MaxTextSize = 19
        self.quota.TextXAlignment = Enum.TextXAlignment.Right
        setRect(self.progress, 10, 45, uiW - 132, 32)
        self.fraction.TextSize = 25
        setRect(self.restockPlate, uiW - 111, 39, 101, 42)
        setRect(self.restockCaption, 4, 0, 93, 17)
        self.restockCaption.TextSize = 15
        self.restockCaption.TextXAlignment = Enum.TextXAlignment.Center
        setRect(self.restockCount, 4, 15, 93, 27)
        self.restockCount.TextSize = 27
        self.restockCount.TextXAlignment = Enum.TextXAlignment.Center
        for _, icon in self.reserveIcons do
            icon.Visible = false
        end
        for _, icon in self.stackIcons do
            icon.Visible = false
        end
        if self.shortWide then
            setRect(self.roundPlate, 12, top + 1, uiX - 32, 34)
            setRect(self.roundLabel, 8, 0, uiX - 48, 32)
            self.roundLabel.TextSize = 23
            self.roundLabel.TextXAlignment = Enum.TextXAlignment.Center
            boardRect = { x = 12, y = top + 47, w = uiX - 32, h = h - top - 63 }
            setRect(self.controls, uiX, h - 70, math.max(235, uiW - 168), 54)
            local cw = self.controls.Size.X.Offset
            setRect(self.jumbleButton, 0, 0, cw * 0.40 - 5, 52)
            setRect(self.primary, cw * 0.40 + 5, 0, cw * 0.60 - 5, 52)
            for index, speedButton in self.speedButtons do
                setRect(speedButton, w - 164 + (index - 1) * 52, h - 69, 46, 50)
            end
            setRect(self.soundButton, 14, h - 61, 65, 43)
            self.soundButton.TextSize = 15
            local detailTop = scoreTop + 105
            local detailHeight = math.min(200, h - 86 - detailTop)
            if detailHeight >= 125 then
                self.inlineDetail = true
                self.detailPopup = false
                self.detail.Visible = true
                self.restockModel.Visible = true
                local rewardWidth = 154
                setRect(self.restockPlate, 0, 105, rewardWidth, detailHeight)
                setRect(self.restockCaption, 8, 4, rewardWidth - 16, 27)
                self.restockCaption.TextSize = 20
                setRect(self.restockModel, 0, 33, 74, 78)
                setRect(self.restockCount, 72, 39, rewardWidth - 78, 64)
                self.restockCount.TextSize = 37
                setRect(self.progress, 10, 45, uiW - 20, 32)
                setRect(
                    self.detail,
                    rewardWidth + 15,
                    detailTop - resourceTop,
                    uiW - rewardWidth - 15,
                    detailHeight
                )
                local detailW = uiW - rewardWidth - 15
                setRect(self.detailTitle, 12, 6, detailW - 24, 31)
                self.detailTitle.TextSize = 23
                setRect(self.detailTrigger, 12, 41, detailW - 24, 26)
                setRect(self.detailBody, 12, 76, detailW - 24, detailHeight - 83)
            end
        else
            setRect(self.roundPlate, 12, top + 148, uiW, 30)
            setRect(self.roundLabel, 8, 0, uiW - 16, 29)
            self.roundLabel.TextSize = 22
            self.roundLabel.TextXAlignment = Enum.TextXAlignment.Center
            boardRect = { x = 14, y = top + 266, w = w - 28, h = h - top - 408 }
            setRect(self.controls, 12, h - 126, uiW, 54)
            setRect(self.jumbleButton, 0, 0, uiW * 0.36 - 5, 54)
            setRect(self.primary, uiW * 0.36 + 5, 0, uiW * 0.64 - 5, 54)
            local unit = (uiW - 24) / 4
            for index, speedButton in self.speedButtons do
                setRect(speedButton, 12 + (index - 1) * (unit + 8), h - 61, unit, 47)
            end
            setRect(self.soundButton, 12 + 3 * (unit + 8), h - 61, unit, 47)
            self.soundButton.TextSize = 15
        end
        self.primary.TextSize = 25
        self.jumbleButton.TextSize = 20
        if self.detailPopup then
            local detailW = math.min(520, w - 28)
            local detailY = self.mobile and (invTop + invHeight + 12) or math.max(top + 82, h - 230)
            setRect(self.detail, (w - detailW) / 2 - uiX, detailY - resourceTop, detailW, 208)
            setRect(self.detailTitle, 13, 9, detailW - 80, 47)
            self.detailTitle.TextSize = 24
            setRect(self.detailClose, detailW - 58, 9, 44, 44)
            setRect(self.detailTrigger, 13, 65, detailW - 26, 43)
            setRect(self.detailBody, 13, 117, detailW - 26, 80)
        end
    else
        local leftW = math.clamp(w * 0.19, 225, 290)
        local rightW = math.clamp(w * 0.215, 265, 330)
        local rackSpace = w - leftW - rightW - 64
        invWidth, invHeight = math.min(760, rackSpace), 110
        setRect(self.brand, 22, top + 12, leftW, 45)
        self.brand.TextSize = w < 1200 and 30 or 37
        setRect(self.tag, 24, top + 59, leftW, 26)
        self.tag.TextSize = w < 1200 and 15 or 18
        setRect(self.inventory, leftW + 32 + (rackSpace - invWidth) / 2, top, invWidth, invHeight)
        setRect(self.roundPlate, w - rightW - 22, top + 7, rightW, 87)
        setRect(self.roundLabel, 14, 7, rightW - 28, 40)
        self.roundLabel.TextSize = 30
        self.roundLabel.TextXAlignment = Enum.TextXAlignment.Left
        setRect(self.phaseLabel, 14, 49, rightW - 28, 27)
        setRect(self.left, 22, top + 139, leftW, 570)
        setRect(self.wallet, 0, 0, leftW, 114)
        setRect(self.coinModel, 8, 24, 89, 78)
        setRect(self.coinCaption, 102, 11, leftW - 110, 29)
        setRect(self.coins, 102, 41, leftW - 110, 64)
        self.coins.TextSize = 54
        setRect(self.reservePlate, 0, 136, leftW, 114)
        setRect(self.reserveCaption, 13, 10, leftW - 95, 31)
        self.reserveCaption.Text = "BALLS LEFT"
        self.reserveCaption.TextSize = 21
        setRect(self.reserves, leftW - 82, 10, 69, 31)
        self.reserves.TextSize = 25
        for index, icon in self.reserveIcons do
            icon.Visible = true
            setRect(icon, 8 + (index - 1) * ((leftW - 16) / 5), 47, (leftW - 16) / 5, 56)
        end
        setRect(self.detail, 0, 273, leftW, 220)
        setRect(self.detailTitle, 14, 10, leftW - 28, 57)
        self.detailTitle.TextSize = 23
        setRect(self.detailTrigger, 14, 75, leftW - 28, 42)
        setRect(self.detailBody, 14, 126, leftW - 28, 84)
        setRect(self.stats, 4, 511, leftW - 8, 26)
        setRect(self.timer, 4, 543, leftW - 8, 27)
        setRect(self.right, w - rightW - 22, top + 139, rightW, 570)
        setRect(self.scorePlate, 0, 0, rightW, 259)
        setRect(self.scoreCaption, 16, 12, rightW - 32, 31)
        self.scoreCaption.Text = "SHOT SCORE"
        self.scoreCaption.TextSize = 23
        setRect(self.score, 16, 46, rightW - 32, 70)
        self.score.TextSize = 60
        setRect(self.quota, 16, 120, rightW - 32, 32)
        self.quota.TextSize = 25
        self.quota.TextScaled = false
        self.quotaConstraint.MaxTextSize = 25
        self.quota.TextXAlignment = Enum.TextXAlignment.Left
        setRect(self.progressCaption, 16, 161, rightW - 32, 26)
        setRect(self.progress, 15, 194, rightW - 30, 48)
        self.fraction.TextSize = 29
        setRect(self.restockPlate, 0, 281, rightW, 218)
        setRect(self.restockCaption, 14, 10, rightW - 28, 31)
        self.restockCaption.TextSize = 20
        setRect(self.restockModel, 4, 43, 106, 92)
        setRect(self.restockCount, 114, 44, rightW - 125, 78)
        self.restockCount.TextSize = 55
        self.restockCount.TextXAlignment = Enum.TextXAlignment.Left
        setRect(self.restockHint, 14, 169, rightW - 28, 38)
        for index, icon in self.stackIcons do
            setRect(icon, 12 + (index - 1) * ((rightW - 24) / 8), 130, (rightW - 24) / 8, 35)
        end
        setRect(self.best, 4, 516, rightW - 8, 27)
        setRect(self.profile, 4, 547, rightW - 8, 21)
        if h < 860 then
            setRect(self.wallet, 0, 0, leftW, 104)
            setRect(self.reservePlate, 0, 124, leftW, 96)
            for index, icon in self.reserveIcons do
                setRect(icon, 8 + (index - 1) * ((leftW - 16) / 5), 43, (leftW - 16) / 5, 43)
            end
            setRect(self.detail, 0, 241, leftW, 177)
            setRect(self.detailTitle, 14, 7, leftW - 28, 43)
            setRect(self.detailTrigger, 14, 56, leftW - 28, 37)
            setRect(self.detailBody, 14, 99, leftW - 28, 69)
            self.stats.Visible = false
            self.timer.Visible = false
            setRect(self.restockPlate, 0, 281, rightW, 140)
            setRect(self.restockModel, 4, 40, 95, 79)
            setRect(self.restockCount, 108, 42, rightW - 119, 70)
            for index, icon in self.stackIcons do
                setRect(icon, 12 + (index - 1) * ((rightW - 24) / 8), 110, (rightW - 24) / 8, 26)
            end
            self.restockHint.Visible = false
            self.best.Visible = false
            self.profile.Visible = false
        end
        boardRect =
            { x = leftW + 47, y = top + 127, w = w - leftW - rightW - 94, h = h - top - 232 }
        local cw = math.min(440, boardRect.w)
        setRect(self.controls, boardRect.x + (boardRect.w - cw) / 2, h - 91, cw, 60)
        setRect(self.jumbleButton, 0, 0, 154, 58)
        setRect(self.primary, 168, 0, cw - 168, 58)
        self.primary.TextSize = 28
        self.jumbleButton.TextSize = 24
        for index, speedButton in self.speedButtons do
            setRect(speedButton, w - rightW - 22 + (index - 1) * 66, h - 85, 58, 52)
        end
        setRect(self.soundButton, 24, h - 85, 148, 52)
        self.soundButton.TextSize = 18
        setRect(self.help, boardRect.x - 40, h - 26, boardRect.w + 80, 22)
    end
    local cellW = (invWidth - 14) / 7
    for index, slot in self.itemSlots do
        setRect(slot.button, 7 + (index - 1) * cellW + 2, 6, cellW - 4, invHeight - 12)
        setRect(slot.viewport, 3, compact and 5 or 10, cellW - 10, compact and 42 or 63)
        setRect(slot.number, 4, 1, 18, 21)
        slot.number.TextSize = compact and 14 or 18
        setRect(slot.level, cellW - 36, 1, 26, 21)
        slot.level.TextSize = compact and 14 or 18
        setRect(slot.name, 3, invHeight - 41, cellW - 10, 24)
        slot.name.Visible = not compact
        slot.name.TextSize = 18
    end
    self.boardRect = boardRect
    local noticeY = self.mobile and h - 177 or h - 139
    setRect(self.notice, math.max(12, (w - 710) / 2), noticeY, math.min(710, w - 24), 42)
    self.notice.TextSize = compact and 20 or 24
    local settleW = math.min(compact and 460 or 600, w - 32, boardRect.w)
    setRect(
        self.settlement,
        boardRect.x + (boardRect.w - settleW) / 2,
        math.min(h - 170, boardRect.y + boardRect.h * 0.68),
        settleW,
        83
    )
    setRect(self.settlementText, 10, 4, settleW - 110, 59)
    self.settlementText.TextSize = compact and 21 or 26
    setRect(self.skipButton, settleW - 93, 16, 79, 45)
    self.settlementProgress.Position = UDim2.fromOffset(7, 72)
    self.settlementProgress.Size =
        UDim2.new(self.settlementFraction or 0, -14 * (self.settlementFraction or 0), 0, 5)
    self.modalKey = nil
    local vh =
        math.max(31.5 * h / math.max(140, boardRect.h), 26.8 * h / math.max(170, boardRect.w))
    local distance = vh / (2 * math.tan(math.rad(17.5)))
    local cameraX = (w / 2 - boardRect.x - boardRect.w / 2) * vh / h
    local cameraY = 11 + (boardRect.y + boardRect.h / 2 - h / 2) * vh / h
    self.cameraCFrame =
        CFrame.lookAt(Vector3.new(cameraX, cameraY, distance), Vector3.new(cameraX, cameraY, 0))
    camera.CameraType = Enum.CameraType.Scriptable
    camera.FieldOfView = 35
    camera.CFrame = self.cameraCFrame
    self:_renderCounters()
    self:_renderControls()
    self:_updateInventory()
end

function Presentation:_updateInventory()
    local state = self.snapshot
    if not state then
        return
    end
    for index, cell in self.itemSlots do
        local item = state.inventory[index]
        local definition = itemDefinition(item)
        local locked = index > state.slots
        cell.border.Color = self.selectedSlot == index and C.gold or C.ink
        cell.border.Thickness = self.selectedSlot == index and 5 or 3
        cell.button.BackgroundColor3 = definition and itemColor(definition):Lerp(C.panel, 0.42)
            or C.panel
        self:_mount(
            cell.viewport,
            locked and "lock" or (definition and item.id or "restock"),
            definition and item.level or 1
        )
        cell.viewport.ImageTransparency = not definition and not locked and 0.65 or 0
        cell.name.Text = locked and "5 COINS" or (definition and definition.name or "EMPTY")
        cell.level.Text = definition and ("L" .. tostring(item.level or 1)) or ""
    end
    local item = self.selectedSlot and state.inventory[self.selectedSlot]
    local definition = itemDefinition(item)
    if definition then
        self.detailTitle.Text = definition.name
        self.detailTrigger.Text = definition.triggerText or "PASSIVE EFFECT"
        self.detailBody.Text = definition.description
    elseif state.boss then
        self.detailTitle.Text = state.boss.name
        self.detailTrigger.Text = "BOSS ROUND"
        self.detailBody.Text = state.boss.description
    else
        self.detailTitle.Text = "YOUR COMBO STARTS HERE"
        self.detailTrigger.Text = "SELECT TWO SLOTS TO REORDER"
        self.detailBody.Text =
            "Shop for gadgets. Buy a matching gadget to upgrade it. Let every bounce count!"
    end
    local showPopup = self.detailPopup
        and definition ~= nil
        and not self.busy
        and (state.phase == "aim" or state.phase == "shop")
    self.detail.Visible = not self.compact or self.inlineDetail or showPopup
    self.detailClose.Visible = showPopup
    local detailObjects = self.detail:GetDescendants()
    table.insert(detailObjects, self.detail)
    for _, object in detailObjects do
        if object:IsA("GuiObject") then
            local original = object:GetAttribute("DetailZ")
            if not original then
                original = object.ZIndex
                object:SetAttribute("DetailZ", original)
            end
            object.ZIndex = original + (showPopup and 42 or 0)
        end
    end
end

function Presentation:_renderCounters()
    local state = self.snapshot
    if not state then
        return
    end
    local overrides = self.counterOverrides
    local score = overrides.score or state.score or 0
    local quota = math.max(1, state.quota or 1)
    local completed = math.floor(score / quota)
    local restocks = overrides.restocks or state.restocks or completed
    local coins = overrides.coins or state.coins or 0
    local reserves = overrides.reserves or state.reserves or 0
    self.score.Text = Format.number(math.floor(score + 0.5))
    self.coins.Text = coins >= 1000 and Format.number(coins) or Format.integer(coins)
    self.reserves.Text = tostring(math.floor(reserves + 0.5))
        .. "/"
        .. tostring(state.maxReserves or 5)
    self.restockCount.Text = "×"
        .. (restocks >= 1000 and Format.number(restocks) or Format.integer(restocks))
    self.quota.Text = "TARGET " .. Format.number(quota)
    local remainder = score % quota
    self.fraction.Text = Format.number(math.floor(remainder + 0.5)) .. " / " .. Format.number(quota)
    local layers =
        { C.mint, C.gold, C.blue, Color3.fromRGB(215, 132, 255), Color3.fromRGB(255, 141, 65) }
    self.progress.BackgroundColor3 = completed > 0 and layers[((completed - 1) % #layers) + 1]
        or C.ink
    self.progressFill.BackgroundColor3 = layers[(completed % #layers) + 1]
    self.progressFill.Size = UDim2.fromScale(math.clamp(remainder / quota, 0, 1), 1)
    self.scorePlate.BackgroundColor3 = completed > 0 and Color3.fromRGB(137, 120, 35) or C.panel
    self.restockPlate.BackgroundColor3 = restocks > 0 and Color3.fromRGB(87, 133, 41) or C.panel
    self.restockHint.Text = restocks > 0 and "Ready to refill + merge your board!"
        or "Fill the meter to grow your board"
    for index, viewport in self.reserveIcons do
        viewport.ImageTransparency = index <= reserves and 0 or 0.78
    end
    for index, viewport in self.stackIcons do
        viewport.Visible = not self.compact and index <= restocks
    end
    self.roundLabel.Text = "ROUND " .. tostring(state.round) .. "  •  Z" .. tostring(state.zone)
    self.best.Text = "BEST ROUND " .. tostring(state.bestRound or 0)
    self.profile.Text = ({
        session = "RECORDS: STUDIO SESSION",
        saved = "CLOUD RECORDS ENABLED",
        unavailable = "SESSION RECORDS • CLOUD UNAVAILABLE",
    })[state.profileStatus] or "SESSION RECORDS"
    self.timer.Text = formatTime(state.elapsed)
    self.stats.Text = Format.integer(state.pops or 0)
        .. " POPS   "
        .. Format.integer(state.wallHits or 0)
        .. " WALLS"
end

function Presentation:_renderControls()
    local state = self.snapshot
    if not state then
        return
    end
    local phase = state.phase
    self.soundButton.Text = (self.shortWide and "SFX " or "SOUND ")
        .. (self.muted and "OFF" or "ON")
    local playable = (phase == "aim" or phase == "flight") and not self.busy
    self.controls.Visible = playable
    self.jumbleButton.Visible = phase == "aim"
    Theme.setEnabled(self.jumbleButton, state.canJumble == true and playable, C.blue)
    self.primary.Text = phase == "flight" and "END SHOT" or "LAUNCH!"
    Theme.setEnabled(self.primary, playable, phase == "flight" and C.gold or C.mint)
    self.phaseLabel.Text = ({
        aim = "READY TO LAUNCH",
        flight = "KEEP THE COMBO GOING",
        result = "GROWING YOUR BOARD",
        shop = "UPGRADE YOUR COMBO",
        perk = "CHOOSE A PERK",
        event = "YOUR NEXT OPPORTUNITY",
        gameover = "RUN COMPLETE",
        victory = "VICTORY!",
    })[phase] or ""
    self.help.Text = phase == "flight" and "LET THE COMBO PLAY • [E] END SHOT"
        or "AIM • CLICK THE BOARD OR PRESS SPACE"
    self.help.Visible = not self.compact and playable
    for index, speedButton in self.speedButtons do
        local value = ({ 1, 2, 4 })[index]
        speedButton.Visible = phase == "aim" or phase == "flight"
        Theme.setEnabled(
            speedButton,
            not self.busy,
            (state.speed or 1) == value and C.mint or C.panel
        )
    end
end

function Presentation:_updateModal()
    local state = self.snapshot
    if not state then
        return
    end
    local phase = state.phase
    local visible = ({ shop = true, perk = true, event = true, gameover = true, victory = true })[phase]
        and not self.busy
    self.overlay.Visible = visible == true
    if not visible then
        return
    end
    local parts = {
        phase,
        tostring(state.round),
        tostring(state.coins),
        tostring(state.slots),
        tostring(state.rerollsLeft),
        tostring(self.selectedSlot),
        tostring(state.bestScore),
    }
    for _, offer in state.shopOffers or {} do
        table.insert(parts, offer.id .. tostring(offer.sold) .. tostring(offer.frozen))
    end
    for _, item in state.inventory or {} do
        table.insert(parts, item.id .. tostring(item.level))
    end
    local key = table.concat(parts, "/")
    if key == self.modalKey then
        return
    end
    self.modalKey = key
    if self.modal then
        self:_dropModels(self.modal)
        self.modal:Destroy()
    end
    local size = self.viewport or Vector2.new(1440, 900)
    local width = math.min(940, size.X - 28)
    local top = self.inventory.AbsolutePosition.Y
        + self.inventory.AbsoluteSize.Y
        - self.overlay.AbsolutePosition.Y
        + 14
    local height = math.min(680, size.Y - top - 18)
    local modal = plate(self.overlay, "Choices", C.panel, 22)
    self.modal = modal
    setRect(modal, (size.X - width) / 2, top, width, height)
    local title = label(modal, "Title", "", width < 500 and 26 or 34, C.paper, 25)
    if self.shortWide then
        title.TextSize = 28
    end
    setRect(title, 16, self.shortWide and 8 or 9, width - 32, self.shortWide and 32 or 43)
    local subtitle = label(modal, "Subtitle", "", 18, C.paper, 25)
    subtitle.TextWrapped = true
    setRect(subtitle, 16, self.shortWide and 44 or 55, width - 32, self.shortWide and 20 or 47)
    local bodyTop = self.shortWide and 70 or 112
    local footerY = height - (self.shortWide and 54 or 67)
    local body = make("ScrollingFrame", {
        Name = "Content",
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ScrollBarThickness = 6,
        ScrollBarImageColor3 = C.mint,
        CanvasSize = UDim2.fromOffset(0, 0),
        ScrollingDirection = Enum.ScrollingDirection.Y,
        ZIndex = 24,
    }, modal)
    setRect(
        body,
        14,
        bodyTop,
        width - 28,
        math.max(50, footerY - bodyTop - (self.shortWide and 10 or 13))
    )
    local function action(name, text, x, buttonWidth, color, callback)
        local result = button(modal, name, text, color, callback, 27)
        setRect(result, x, footerY, buttonWidth, self.shortWide and 42 or 51)
        result.TextSize = width < 650 and 18 or 24
        result.TextWrapped = true
        return result
    end
    if phase == "shop" then
        title.Text = "UPGRADE SHOP"
        local selected = self.selectedSlot and state.inventory[self.selectedSlot]
        local definition = itemDefinition(selected)
        subtitle.Text = definition
                and (Format.integer(state.coins) .. " COINS • " .. definition.name .. ": " .. definition.description)
            or (
                Format.integer(state.coins)
                .. " COINS • Matching equipment upgrades it. Select two slots to reorder."
            )
        if self.shortWide and definition then
            setRect(subtitle, 16, 44, width - 32, 38)
            setRect(body, 14, 86, width - 28, math.max(50, footerY - 96))
        end
        local columns = width >= 650 and 2 or 1
        local cw = (width - 42 - (columns - 1) * 16) / columns
        local cardHeight = self.shortWide and 216 or 248
        for index, offer in state.shopOffers or {} do
            local data = Catalog.Items[offer.id]
            if data then
                local consumable = data.consumable == true
                local card = plate(body, "Offer" .. index, C.board, 25)
                setRect(
                    card,
                    ((index - 1) % columns) * (cw + 16) + 3,
                    math.floor((index - 1) / columns) * (cardHeight + 16) + 4,
                    cw,
                    cardHeight
                )
                local model = self:_viewport(card, "Item", offer.id, 1, 27)
                setRect(model, 6, 8, 98, 96)
                local name = label(card, "Name", data.name, 24, C.paper, 28)
                name.TextWrapped = true
                setRect(name, 110, 10, cw - 122, 54)
                local trigger = label(
                    card,
                    "Trigger",
                    consumable and "USE IMMEDIATELY" or data.triggerText,
                    18,
                    C.gold,
                    28
                )
                trigger.TextWrapped = true
                setRect(trigger, 110, 67, cw - 122, 43)
                local description = label(card, "Effect", data.description, 18, C.paper, 28)
                description.TextWrapped = true
                description.TextYAlignment = Enum.TextYAlignment.Top
                setRect(description, 13, 113, cw - 26, cardHeight - 178)
                local matching
                for _, owned in state.inventory do
                    if owned.id == offer.id then
                        matching = owned
                        break
                    end
                end
                local verb = consumable and "USE" or (matching and "UPGRADE" or "BUY")
                local buy = button(
                    card,
                    "Buy",
                    offer.sold and "SOLD" or (verb .. "  " .. offer.price),
                    C.mint,
                    function()
                        self:_send("buy", { offer = index })
                    end,
                    29
                )
                setRect(buy, 12, cardHeight - 57, cw - (consumable and 24 or 91), 44)
                buy.TextSize = 23
                Theme.setEnabled(buy, not offer.sold and state.coins >= offer.price, C.mint)
                if not consumable then
                    local hold = button(
                        card,
                        "Hold",
                        offer.frozen and "HELD" or "HOLD",
                        offer.frozen and C.blue or C.panel,
                        function()
                            self:_send("freeze", { offer = index })
                        end,
                        29
                    )
                    setRect(hold, cw - 69, cardHeight - 57, 57, 44)
                    hold.TextSize = 17
                    Theme.setEnabled(hold, not offer.sold, offer.frozen and C.blue or C.panel)
                end
            end
        end
        body.CanvasSize = UDim2.fromOffset(
            0,
            math.ceil(#(state.shopOffers or {}) / columns) * (cardHeight + 16) + 5
        )
        local fw = (width - 60) / 3
        local reroll = action("Reroll", "REROLL 1 COIN", 14, fw, C.gold, function()
            self:_send("reroll")
        end)
        Theme.setEnabled(reroll, (state.rerollsLeft or 0) > 0 and state.coins >= 1, C.gold)
        local occupied = selected and selected.id ~= ""
        local sell = action(
            "Sell",
            occupied and "SELL ITEM" or (state.slots < 7 and "+ SLOT 5" or "SELECT TO SELL"),
            30 + fw,
            fw,
            C.coral,
            function()
                if occupied then
                    self:_send("sell", { slot = self.selectedSlot })
                    self.selectedSlot = nil
                elseif state.slots < 7 then
                    self:_send("buySlot")
                end
            end
        )
        Theme.setEnabled(sell, occupied or state.slots < 7, C.coral)
        action("Continue", "NEXT ROUND", 46 + fw * 2, fw, C.mint, function()
            self:_send("continue")
        end)
    elseif phase == "perk" or phase == "event" then
        title.Text = phase == "perk" and "CHOOSE YOUR PERK"
            or (state.eventTitle or "CHOOSE YOUR REWARD")
        subtitle.Text = "Make your next combo even stronger. Pick one."
        local choices = phase == "perk" and state.perkOffers or state.eventChoices
        local columns = width >= 650 and 2 or 1
        local cw = (width - 42 - (columns - 1) * 16) / columns
        local ch = phase == "perk" and 368 or 320
        body.Size = UDim2.fromOffset(width - 28, height - bodyTop - 16)
        for index, choice in choices or {} do
            local id = type(choice) == "table" and choice.id or choice
            local data = phase == "perk" and Catalog.Perks[id] or choice
            local card = plate(body, "Choice" .. index, C.board, 25)
            setRect(
                card,
                ((index - 1) % columns) * (cw + 16) + 3,
                math.floor((index - 1) / columns) * (ch + 16) + 4,
                cw,
                ch
            )
            local model = self:_viewport(card, "Reward", id, 1, 27)
            setRect(model, (cw - 130) / 2, 4, 130, 115)
            local name = label(card, "Name", data.name, 27, C.paper, 28)
            name.TextXAlignment = Enum.TextXAlignment.Center
            name.TextWrapped = true
            setRect(name, 12, 123, cw - 24, 48)
            if phase == "perk" then
                local trigger =
                    label(card, "Trigger", data.triggerText or "PASSIVE EFFECT", 18, C.gold, 28)
                trigger.TextWrapped = true
                trigger.TextXAlignment = Enum.TextXAlignment.Center
                setRect(trigger, 15, 177, cw - 30, 36)
            end
            local description = label(card, "Effect", data.description, 19, C.paper, 28)
            description.TextWrapped = true
            description.TextYAlignment = Enum.TextYAlignment.Top
            setRect(
                description,
                15,
                phase == "perk" and 219 or 181,
                cw - 30,
                phase == "perk" and 80 or 71
            )
            local choose = button(card, "Choose", "CHOOSE", C.mint, function()
                self:_send(phase == "perk" and "choosePerk" or "chooseEvent", { index = index })
            end, 29)
            setRect(choose, 14, ch - 58, cw - 28, 44)
        end
        body.CanvasSize = UDim2.fromOffset(0, math.ceil(#(choices or {}) / columns) * (ch + 16) + 5)
    else
        title.Text = phase == "victory" and "WHAT A RUN!" or "READY FOR ANOTHER RUN?"
        subtitle.Text = "Keep your records and unlocks. Build a new combo next time."
        local model = self:_viewport(body, "RunReward", "restock", 2, 26)
        setRect(model, (width - 160) / 2, 0, 130, 115)
        local result = label(body, "Result", "ROUND " .. state.round, 38, C.gold, 27)
        result.TextXAlignment = Enum.TextXAlignment.Center
        setRect(result, 0, 122, width - 42, 55)
        local records = label(
            body,
            "Records",
            "BEST SCORE "
                .. Format.number(state.bestScore or 0)
                .. "\nBEST ROUND "
                .. tostring(state.bestRound or 0),
            24,
            C.paper,
            27
        )
        records.TextXAlignment = Enum.TextXAlignment.Center
        records.TextWrapped = true
        setRect(records, 8, 185, width - 58, 78)
        local names = {}
        for _, id in state.unlocks or {} do
            local definition = Catalog.Unlocks and Catalog.Unlocks[id]
            table.insert(names, definition and definition.name or id)
        end
        local unlocks = label(
            body,
            "Unlocks",
            #names > 0 and ("UNLOCKED: " .. table.concat(names, " • "))
                or "Reach deeper rounds to unlock new equipment.",
            18,
            C.paper,
            27
        )
        unlocks.TextWrapped = true
        unlocks.TextXAlignment = Enum.TextXAlignment.Center
        setRect(unlocks, 12, 274, width - 66, 86)
        body.CanvasSize = UDim2.fromOffset(0, 370)
        if phase == "victory" then
            action("Restart", "NEW RUN", 14, (width - 44) / 2, C.gold, function()
                self:_send("restart")
            end)
            action(
                "Endless",
                "GO ENDLESS!",
                30 + (width - 44) / 2,
                (width - 44) / 2,
                C.mint,
                function()
                    self:_send("endless")
                end
            )
        else
            action("Restart", "START A NEW RUN", 14, width - 28, C.mint, function()
                self:_send("restart")
            end)
        end
    end
end

function Presentation:setBoardOverride(active)
    self.boardOverride = active == true
end

function Presentation:setPeg(id, value, position, scale)
    local peg, slot = self.pegs[id], Board.Slots[id]
    if not peg or not slot then
        return
    end
    peg.value = value
    peg.part.Transparency = value > 0 and 0 or 1
    peg.billboard.Enabled = value > 0
    peg.number.Text = Format.number(value)
    if value > 0 then
        local exponent = math.max(0, math.floor(math.log(value) / math.log(2) + 0.001))
        peg.part.Color = PEG_COLORS[(exponent % #PEG_COLORS) + 1]
    end
    peg.part.Position =
        Vector3.new(position and position.x or slot.x, position and position.y or slot.y, 0.62)
    peg.part.Size = Vector3.one * Board.Geometry.pegRadius * 2 * (scale or 1)
    self.previewDirty = true
end

function Presentation:finishBoardOverride(snapshot)
    self.boardOverride = false
    local state = snapshot or self.snapshot
    if state then
        for id, value in state.values or {} do
            self:setPeg(id, value)
        end
    end
end

function Presentation:getAnchor(kind, index)
    local layerOrigin = self.fxLayer.AbsolutePosition
    if kind == "peg" or kind == "ball" then
        local object = kind == "ball" and self.ball or (self.pegs[index] and self.pegs[index].part)
        local camera = workspace.CurrentCamera
        if object and camera then
            local point = camera:WorldToViewportPoint(object.Position)
            return Vector2.new(point.X, point.Y)
        end
    end
    local object = ({
        score = self.score,
        meter = self.progress,
        restocks = self.restockModel.Visible and self.restockModel or self.restockPlate,
        coins = self.coinModel,
        reserve = self.reserveIcons[index or 1],
        inventory = self.itemSlots[index or 1] and self.itemSlots[index or 1].viewport,
    })[kind]
    if kind == "reserve" and (not object or not object.Visible) then
        object = self.reserves
    end
    if object then
        return object.AbsolutePosition + object.AbsoluteSize / 2 - layerOrigin
    end
    return (self.viewport or Vector2.new(1440, 900)) / 2
end

function Presentation:setCounterDisplay(kind, value)
    self.counterOverrides[kind] = value
    self:_renderCounters()
end

function Presentation:setSettlement(text, progress, canSkip)
    self.settlement.Visible = type(text) == "string" and text ~= ""
    self.settlementText.Text = text or ""
    self.settlementFraction = math.clamp(progress or 0, 0, 1)
    self.settlementProgress.Size =
        UDim2.new(self.settlementFraction, -14 * self.settlementFraction, 0, 5)
    self.skipButton.Visible = canSkip == true
end

function Presentation:pulseItem(slot, strength)
    local cell = self.itemSlots[slot]
    if cell then
        local mounted = self.models[cell.viewport]
        if mounted then
            mounted.handle:pulse(strength or 1)
        end
        cell.flash = 0.3
    end
end

function Presentation:setBusy(active)
    local changed = self.busy ~= (active == true)
    self.busy = active == true
    if changed then
        self:_renderControls()
        self.modalKey = nil
        self:_updateModal()
    end
end

function Presentation:_overInterface(point)
    for _, object in Players.LocalPlayer.PlayerGui:GetGuiObjectsAtPosition(point.X, point.Y) do
        local current = object
        while current and current ~= self.root do
            if current:IsA("GuiButton") or current:GetAttribute("BlocksAim") then
                return true
            end
            current = current.Parent
        end
    end
    return false
end

function Presentation:_aimAt(point)
    local camera = workspace.CurrentCamera
    if self.busy or not camera or not self.snapshot or self.snapshot.phase ~= "aim" then
        return
    end
    local ray = camera:ViewportPointToRay(point.X, point.Y)
    if math.abs(ray.Direction.Z) < 0.0001 then
        return
    end
    local world = ray.Origin + ray.Direction * ((1.15 - ray.Origin.Z) / ray.Direction.Z)
    if world.Y < Board.Geometry.launchY - 0.4 then
        self.aim = math.clamp(
            math.atan2(world.X - Board.Geometry.launchX, Board.Geometry.launchY - world.Y),
            -1.25,
            1.25
        )
    end
end

function Presentation:_primaryAction()
    if not self.snapshot or self.busy then
        return
    end
    if self.snapshot.phase == "aim" then
        self:_send("launch", { angle = self.aim })
    elseif self.snapshot.phase == "flight" then
        self:_send("endShot")
    end
end

function Presentation:_bindInput()
    table.insert(
        self.connections,
        UserInputService.InputBegan:Connect(function(input, processed)
            if processed or self.busy then
                return
            end
            if
                input.UserInputType == Enum.UserInputType.MouseButton1
                or input.UserInputType == Enum.UserInputType.Touch
            then
                local point = Vector2.new(input.Position.X, input.Position.Y)
                if
                    self.snapshot
                    and self.snapshot.phase == "aim"
                    and not self:_overInterface(point)
                then
                    self.aimHeld = input
                    self:_aimAt(point)
                end
            elseif input.KeyCode == Enum.KeyCode.Space then
                self:_primaryAction()
            elseif
                input.KeyCode == Enum.KeyCode.Q
                and self.snapshot
                and self.snapshot.phase == "aim"
            then
                self:_send("jumble")
            elseif
                input.KeyCode == Enum.KeyCode.E
                and self.snapshot
                and self.snapshot.phase == "flight"
            then
                self:_send("endShot")
            end
        end)
    )
    table.insert(
        self.connections,
        UserInputService.InputChanged:Connect(function(input)
            if
                input.UserInputType == Enum.UserInputType.MouseMovement
                or (input.UserInputType == Enum.UserInputType.Touch and input == self.aimHeld)
            then
                local point = Vector2.new(input.Position.X, input.Position.Y)
                if not self:_overInterface(point) then
                    self:_aimAt(point)
                end
            end
        end)
    )
    table.insert(
        self.connections,
        UserInputService.InputEnded:Connect(function(input)
            if input == self.aimHeld then
                self.aimHeld = nil
                local point = Vector2.new(input.Position.X, input.Position.Y)
                if
                    not self.busy
                    and self.snapshot
                    and self.snapshot.phase == "aim"
                    and not self:_overInterface(point)
                then
                    self:_aimAt(point)
                    self:_send("launch", { angle = self.aim })
                end
            end
        end)
    )
end

function Presentation:update(snapshot)
    if self.destroyed then
        return
    end
    local previous = self.snapshot
    if previous and (snapshot.round < previous.round or snapshot.seed ~= previous.seed) then
        self.selectedSlot = nil
        self.counterOverrides = {}
    end
    self.snapshot = snapshot
    self.receivedAt = os.clock()
    self.loading.Visible = false
    self.feedback:update(snapshot)
    if not self.boardOverride then
        for id, value in snapshot.values or {} do
            if self.pegs[id] and self.pegs[id].value ~= value then
                self:setPeg(id, value)
            end
        end
    end
    self:_renderCounters()
    self:_renderControls()
    self:_updateInventory()
    self:_updateModal()
end

function Presentation:setNotice(message)
    self.notice.Text = message or ""
    self.noticeUntil = os.clock() + 3.5
end

function Presentation:step(dt)
    if self.destroyed then
        return
    end
    local camera = workspace.CurrentCamera
    if not camera then
        return
    end
    if not self.viewport or self.viewport ~= camera.ViewportSize then
        self:_layout()
        self:_updateModal()
    end
    camera.CameraType = Enum.CameraType.Scriptable
    camera.CFrame = self.cameraCFrame or camera.CFrame
    self.feedback:step(dt)
    for viewport, mounted in self.models do
        if viewport.Visible then
            mounted.handle:step(dt)
        end
    end
    for index, cell in self.itemSlots do
        cell.flash = math.max(0, (cell.flash or 0) - dt)
        if cell.flash > 0 then
            cell.border.Color = C.gold
            cell.border.Thickness = 5
        else
            cell.border.Color = self.selectedSlot == index and C.gold or C.ink
            cell.border.Thickness = self.selectedSlot == index and 5 or 3
        end
    end
    if os.clock() > self.noticeUntil then
        self.notice.Text = ""
    end
    local state = self.snapshot
    if not state then
        return
    end
    local ball = state.ball
    local flying = state.phase == "flight" and ball and ball.active
    self.ball.Transparency = (flying or state.phase == "aim") and 0 or 1
    self.trail.Enabled = flying == true
    if flying then
        local lag = math.min(0.05, os.clock() - self.receivedAt) * (state.speed or 1)
        local target =
            Vector3.new(ball.x + (ball.vx or 0) * lag, ball.y + (ball.vy or 0) * lag, 1.15)
        if not self.wasFlying then
            self.ball.Position = target
            self.trail:Clear()
        else
            self.ball.Position = self.ball.Position:Lerp(target, 1 - math.exp(-dt * 38))
        end
    elseif state.phase == "aim" then
        self.ball.Position = Vector3.new(Board.Geometry.launchX, Board.Geometry.launchY, 1.15)
    end
    self.wasFlying = flying
    local guideVisible = state.phase == "aim" and not self.busy
    if guideVisible and (self.previewDirty or self.previewAim ~= self.aim) then
        self.preview = Simulation.preview(self.aim, state.values)
        self.previewAim, self.previewDirty = self.aim, false
    end
    for index, arrow in self.aimArrow do
        local side = index == 1 and -1 or 1
        local direction = Vector3.new(math.sin(self.aim), -math.cos(self.aim), 0)
        local perpendicular = Vector3.new(math.cos(self.aim), math.sin(self.aim), 0)
        local tip = Vector3.new(Board.Geometry.launchX, Board.Geometry.launchY, 1.1)
            + direction * 2.3
        local tail = tip - direction * 0.5 + perpendicular * 0.3 * side
        arrow.Size = Vector3.new(0.1, (tip - tail).Magnitude, 0.1)
        arrow.CFrame = CFrame.lookAt((tip + tail) / 2, tip) * CFrame.Angles(math.pi / 2, 0, 0)
        arrow.Transparency = guideVisible and 0.1 or 1
    end
    for index, dot in self.guide do
        local point = self.preview and self.preview[index + 1]
        dot.Transparency = guideVisible and point and (0.1 + index * 0.02) or 1
        if point then
            dot.Position = Vector3.new(point.x, point.y, 1.1)
        end
    end
end

function Presentation.new(onAction)
    local camera = workspace.CurrentCamera
    local self = setmetatable({
        onAction = onAction,
        connections = {},
        models = {},
        counterOverrides = {},
        aim = 0.15,
        noticeUntil = 0,
        receivedAt = os.clock(),
        busy = false,
        boardOverride = false,
        oldCamera = camera and {
            camera = camera,
            cframe = camera.CFrame,
            cameraType = camera.CameraType,
            fov = camera.FieldOfView,
        },
    }, Presentation)
    self:_buildBoard()
    self:_buildHud()
    self:_layout()
    self.feedback = Feedback.new(self, function()
        self:_send("continue")
    end)
    self:_bindInput()
    return self
end

function Presentation:destroy()
    if self.destroyed then
        return
    end
    self.destroyed = true
    for _, connection in self.connections do
        connection:Disconnect()
    end
    self.feedback:destroy()
    for _, mounted in self.models do
        mounted.handle:destroy()
    end
    self.gui:Destroy()
    self.model:Destroy()
    if self.oldCamera and workspace.CurrentCamera == self.oldCamera.camera then
        workspace.CurrentCamera.CameraType = self.oldCamera.cameraType
        workspace.CurrentCamera.CFrame = self.oldCamera.cframe
        workspace.CurrentCamera.FieldOfView = self.oldCamera.fov
    end
end

return Presentation
