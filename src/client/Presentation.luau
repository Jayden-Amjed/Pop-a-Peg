--!nonstrict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Board = require(Shared:WaitForChild("Board"))
local Catalog = require(Shared:WaitForChild("Catalog"))
local Format = require(Shared:WaitForChild("Format"))
local Simulation = require(Shared:WaitForChild("Simulation"))

local Presentation = {}
Presentation.__index = Presentation

local C = {
    ink = Color3.fromRGB(15, 24, 38),
    board = Color3.fromRGB(24, 40, 57),
    panel = Color3.fromRGB(29, 46, 63),
    edge = Color3.fromRGB(65, 89, 106),
    muted = Color3.fromRGB(151, 174, 186),
    paper = Color3.fromRGB(247, 241, 222),
    mint = Color3.fromRGB(121, 230, 187),
    coral = Color3.fromRGB(255, 132, 105),
    gold = Color3.fromRGB(255, 213, 113),
    blue = Color3.fromRGB(129, 201, 242),
}

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

local function make(className, properties, parent)
    local instance = Instance.new(className)
    for key, value in properties do
        instance[key] = value
    end
    instance.Parent = parent
    return instance
end

local function corner(parent, radius)
    return make("UICorner", { CornerRadius = UDim.new(0, radius or 12) }, parent)
end

local function stroke(parent, color, thickness)
    return make("UIStroke", {
        Color = color or C.edge,
        Thickness = thickness or 1,
        Transparency = 0.15,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
    }, parent)
end

local function frame(parent, name, color, z)
    local result = make("Frame", {
        Name = name,
        BackgroundColor3 = color or C.panel,
        BorderSizePixel = 0,
        ZIndex = z or 2,
    }, parent)
    return result
end

local function label(parent, name, value, size, color, z)
    return make("TextLabel", {
        Name = name,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Font = Enum.Font.Gotham,
        Text = value or "",
        TextSize = size or 16,
        TextColor3 = color or C.paper,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Center,
        ZIndex = z or 3,
    }, parent)
end

local function button(parent, name, value, color, callback, z)
    local result = make("TextButton", {
        Name = name,
        BackgroundColor3 = color or C.mint,
        BorderSizePixel = 0,
        AutoButtonColor = true,
        Font = Enum.Font.GothamBold,
        Text = value,
        TextColor3 = C.ink,
        TextSize = 15,
        ZIndex = z or 6,
    }, parent)
    corner(result, 9)
    result.Activated:Connect(callback)
    return result
end

local function blockAim(gui)
    gui:SetAttribute("BlocksAim", true)
end

local function setRect(gui, x, y, width, height)
    gui.Position = UDim2.fromOffset(x, y)
    gui.Size = UDim2.fromOffset(width, height)
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

local function initials(value)
    local result = ""
    for word in string.gmatch(value, "%S+") do
        result ..= string.sub(word, 1, 1)
        if #result >= 2 then
            break
        end
    end
    return string.upper(result)
end

local function formatTime(seconds)
    seconds = math.max(0, seconds or 0)
    return string.format("%02d:%05.2f", math.floor(seconds / 60), seconds % 60)
end

function Presentation:_send(kind, payload)
    if self.destroyed then
        return
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
        Color3.fromRGB(9, 17, 27)
    )
    for _, side in { -1, 1 } do
        part(
            self.model,
            "StagePanel",
            Vector3.new(8, 39, 0.2),
            Vector3.new(side * 17.5, 11, -7.25),
            Color3.fromRGB(18, 30, 44)
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
        number.Font = Enum.Font.GothamBlack
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

function Presentation:_buildHud()
    self.gui = make("ScreenGui", {
        Name = "PopAPeg",
        IgnoreGuiInset = true,
        ResetOnSpawn = false,
        ZIndexBehavior = Enum.ZIndexBehavior.Global,
        DisplayOrder = 20,
    }, Players.LocalPlayer:WaitForChild("PlayerGui"))
    self.root = frame(self.gui, "Root")
    self.root.Size = UDim2.fromScale(1, 1)
    self.root.BackgroundTransparency = 1
    self.brand = label(self.root, "Brand", "POP A PEG", 26, C.paper)
    self.brand.Font = Enum.Font.GothamBlack
    self.tag = label(self.root, "Tag", "ONE SHOT. BIG POSSIBILITIES.", 10, C.mint)
    self.phaseLabel = label(self.root, "Phase", "CONNECTING", 12, C.muted)
    self.phaseLabel.TextXAlignment = Enum.TextXAlignment.Right

    self.inventory = frame(self.root, "Inventory", C.ink, 30)
    corner(self.inventory, 13)
    stroke(self.inventory)
    blockAim(self.inventory)
    self.itemSlots = {}
    for index = 1, 7 do
        local cell = button(self.inventory, "Slot" .. index, "", C.panel, function()
            local state = self.snapshot
            if not state then
                return
            end
            if index > state.slots then
                if state.phase == "shop" then
                    self:_send("buySlot")
                else
                    self:setNotice("Extra slots are available in the shop.")
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
        end, 31)
        local border = stroke(cell, C.edge, 1)
        local n = label(cell, "Index", tostring(index), 10, C.muted, 32)
        local icon = label(cell, "Icon", "+", 22, C.muted, 32)
        icon.Font = Enum.Font.GothamBlack
        icon.TextXAlignment = Enum.TextXAlignment.Center
        local name = label(cell, "Name", "EMPTY", 10, C.muted, 32)
        name.TextXAlignment = Enum.TextXAlignment.Center
        name.TextTruncate = Enum.TextTruncate.AtEnd
        self.itemSlots[index] =
            { button = cell, border = border, index = n, icon = icon, name = name, flash = 0 }
    end

    self.left = frame(self.root, "RunResources")
    corner(self.left, 14)
    stroke(self.left)
    blockAim(self.left)
    self.coinCaption = label(self.left, "CoinsCaption", "RUN COINS", 11, C.muted)
    self.coins = label(self.left, "Coins", "0", 36, C.gold)
    self.coins.Font = Enum.Font.GothamBold
    self.reserveCaption = label(self.left, "ReservesCaption", "RESERVE BALLS", 11, C.muted)
    self.reserves = label(self.left, "Reserves", "5 / 5", 22, C.paper)
    self.reserveDots = {}
    for index = 1, 5 do
        local dot = frame(self.left, "Reserve" .. index, C.mint, 4)
        corner(dot, 100)
        self.reserveDots[index] = dot
    end
    self.counterCaption = label(self.left, "CounterCaption", "POPS   /   WALLS", 11, C.muted)
    self.counters = label(self.left, "Counters", "0    /    0", 20, C.paper)
    self.timer = label(self.left, "Timer", "00:00.00", 15, C.muted)
    self.speed = button(self.root, "Speed", "1× SPEED", C.panel, function()
        local state = self.snapshot
        if state and (state.phase == "aim" or state.phase == "flight") then
            local current = state.speed or 1
            self:_send("speed", { value = current == 1 and 2 or (current == 2 and 4 or 1) })
        end
    end, 7)
    self.speed.TextColor3 = C.mint
    self.speed.TextSize = 11
    stroke(self.speed)

    self.right = frame(self.root, "ScorePanel")
    corner(self.right, 14)
    stroke(self.right)
    blockAim(self.right)
    self.roundLabel = label(self.right, "Round", "ROUND 01", 13, C.mint)
    self.roundLabel.Font = Enum.Font.GothamBold
    self.scoreCaption = label(self.right, "ScoreCaption", "SHOT SCORE", 11, C.muted)
    self.score = label(self.right, "Score", "0", 40, C.paper)
    self.score.Font = Enum.Font.GothamBlack
    self.quota = label(self.right, "Quota", "TARGET 10", 16, C.paper)
    self.progress = frame(self.right, "ProgressTrack", C.ink, 3)
    corner(self.progress, 100)
    self.progressFill = frame(self.progress, "Progress", C.mint, 4)
    self.progressFill.Size = UDim2.fromScale(0, 1)
    corner(self.progressFill, 100)
    self.restock = label(self.right, "Restock", "Fill the target to restock", 12, C.muted)
    self.restock.TextWrapped = true
    self.best = label(self.right, "Best", "BEST ROUND 0", 12, C.muted)
    self.perkSummary = label(self.right, "Perks", "No perks yet", 11, C.muted)
    self.perkSummary.TextWrapped = true
    self.profile = label(self.right, "Profile", "", 10, C.muted)
    self.profile.TextWrapped = true

    self.detail = frame(self.root, "ItemDetail")
    corner(self.detail, 12)
    stroke(self.detail)
    blockAim(self.detail)
    self.detailTitle = label(self.detail, "Title", "BUILD YOUR COMBO", 13, C.paper)
    self.detailTitle.Font = Enum.Font.GothamBold
    self.detailTitle.TextWrapped = true
    self.detailTrigger = label(self.detail, "Trigger", "Select an inventory item", 11, C.mint)
    self.detailTrigger.TextWrapped = true
    self.detailBody =
        label(self.detail, "Body", "Combine upgrades. Let every bounce count.", 12, C.muted)
    self.detailBody.TextWrapped = true
    self.detailBody.TextYAlignment = Enum.TextYAlignment.Top

    self.controls = frame(self.root, "Controls", C.ink, 6)
    corner(self.controls, 13)
    stroke(self.controls)
    blockAim(self.controls)
    self.jumbleButton = button(self.controls, "Jumble", "JUMBLE  [Q]", C.panel, function()
        self:_send("jumble")
    end, 7)
    self.jumbleButton.TextColor3 = C.paper
    self.primary = button(self.controls, "Primary", "LAUNCH  [SPACE]", C.mint, function()
        self:_primaryAction()
    end, 7)
    self.help = label(
        self.root,
        "Help",
        "Aim with your pointer. Click or tap the board to launch.",
        11,
        C.muted,
        7
    )
    self.help.TextXAlignment = Enum.TextXAlignment.Center
    self.help.TextWrapped = true
    self.notice = label(self.root, "Notice", "", 13, C.gold, 60)
    self.notice.TextXAlignment = Enum.TextXAlignment.Center
    self.notice.TextWrapped = true
    self.overlay = frame(self.root, "Overlay", C.ink, 10)
    self.overlay.Size = UDim2.fromScale(1, 1)
    self.overlay.BackgroundTransparency = 0.28
    self.overlay.Visible = false
    blockAim(self.overlay)
    self.fxLayer = frame(self.root, "Feedback", nil, 40)
    self.fxLayer.Size = UDim2.fromScale(1, 1)
    self.fxLayer.BackgroundTransparency = 1
    self.loading = frame(self.root, "Connecting", C.ink, 80)
    self.loading.Size = UDim2.fromScale(1, 1)
    blockAim(self.loading)
    local connecting = label(self.loading, "Message", "Connecting…", 23, C.paper, 81)
    connecting.Size = UDim2.fromScale(1, 1)
    connecting.TextXAlignment = Enum.TextXAlignment.Center
end

function Presentation:_layout()
    local camera = workspace.CurrentCamera
    if not camera then
        return
    end
    local size = camera.ViewportSize
    if size.X < 1 or size.Y < 1 then
        return
    end
    self.viewport = size
    self.mobile = size.X < 850
    local w, h = size.X, size.Y
    local scale = math.clamp(math.min(w / 1440, h / 900), 0.76, 1.15)
    self.uiScale = scale
    local s = scale
    setRect(self.brand, 24 * s, 14 * s, 250 * s, 32 * s)
    self.brand.TextSize = 26 * s
    setRect(self.tag, 25 * s, 47 * s, 280 * s, 16 * s)
    setRect(self.phaseLabel, w - 275 * s, 22 * s, 250 * s, 22 * s)
    self.phaseLabel.TextSize = 12 * s
    local inventoryWidth = math.min(770 * s, w - 32)
    local inventoryHeight = self.mobile and 66 or 80 * s
    local inventoryTop = self.mobile and 143 or 76 * s
    setRect(self.inventory, (w - inventoryWidth) / 2, inventoryTop, inventoryWidth, inventoryHeight)
    local cellWidth = (inventoryWidth - 16) / 7
    for index, slot in self.itemSlots do
        setRect(
            slot.button,
            8 + (index - 1) * cellWidth + 3,
            6,
            cellWidth - 6,
            inventoryHeight - 12
        )
        setRect(slot.index, 6, 2, 12, 14)
        setRect(slot.icon, 4, 10, cellWidth - 14, self.mobile and 23 or 31 * s)
        setRect(slot.name, 4, inventoryHeight - 37, cellWidth - 14, 17)
        slot.name.TextSize = self.mobile and 8 or 10 * s
        slot.icon.TextSize = self.mobile and 17 or 23 * s
    end
    if self.mobile then
        self.tag.Visible = false
        self.phaseLabel.Visible = false
        setRect(self.brand, 16, 12, w - 32, 32)
        self.brand.TextSize = 25
        setRect(self.speed, w - 104, 12, 88, 30)
        local half = (w - 44) / 2
        setRect(self.left, 16, 54, half, 80)
        setRect(self.right, 28 + half, 54, half, 80)
        setRect(self.coinCaption, 12, 6, half * 0.5, 15)
        setRect(self.coins, 12, 25, half * 0.5, 29)
        self.coins.TextSize = 27
        setRect(self.reserveCaption, half * 0.51, 6, half * 0.49 - 8, 15)
        self.reserveCaption.Text = "RESERVES"
        self.reserveCaption.TextSize = 9
        setRect(self.reserves, half * 0.51, 25, half * 0.49 - 8, 29)
        self.reserves.TextSize = 20
        for index, dot in self.reserveDots do
            setRect(dot, half * 0.51 + (index - 1) * 11, 62, 6, 6)
        end
        setRect(self.roundLabel, 10, 6, half - 20, 17)
        self.roundLabel.TextSize = 11
        setRect(self.score, 10, 24, half - 20, 27)
        self.score.TextSize = 24
        setRect(self.quota, 10, 52, half - 20, 15)
        self.quota.TextSize = 10
        setRect(self.progress, 10, 71, half - 20, 4)
        for _, gui in
            {
                self.counterCaption,
                self.counters,
                self.timer,
                self.scoreCaption,
                self.restock,
                self.best,
                self.perkSummary,
                self.profile,
                self.detail,
            }
        do
            gui.Visible = false
        end
    else
        self.tag.Visible = true
        self.phaseLabel.Visible = true
        local leftWidth, rightWidth = 214 * s, 232 * s
        setRect(self.left, 24 * s, 184 * s, leftWidth, 276 * s)
        setRect(self.coinCaption, 18 * s, 17 * s, leftWidth - 36 * s, 18 * s)
        setRect(self.coins, 18 * s, 38 * s, leftWidth - 36 * s, 43 * s)
        self.coins.TextSize = 36 * s
        setRect(self.reserveCaption, 18 * s, 97 * s, leftWidth - 36 * s, 18 * s)
        self.reserveCaption.Text = "RESERVE BALLS"
        self.reserveCaption.TextSize = 11 * s
        setRect(self.reserves, 18 * s, 119 * s, leftWidth - 36 * s, 28 * s)
        self.reserves.TextSize = 23 * s
        for index, dot in self.reserveDots do
            setRect(dot, (18 + (index - 1) * 22) * s, 157 * s, 12 * s, 12 * s)
        end
        setRect(self.counterCaption, 18 * s, 190 * s, leftWidth - 36 * s, 16 * s)
        setRect(self.counters, 18 * s, 210 * s, leftWidth - 36 * s, 25 * s)
        setRect(self.timer, 18 * s, 242 * s, 92 * s, 20 * s)
        self.timer.TextSize = 12 * s
        setRect(self.speed, 24 * s + leftWidth - 91 * s, 422 * s, 76 * s, 27 * s)
        setRect(self.right, w - rightWidth - 24 * s, 184 * s, rightWidth, 315 * s)
        setRect(self.roundLabel, 18 * s, 17 * s, rightWidth - 36 * s, 22 * s)
        self.roundLabel.TextSize = 14 * s
        setRect(self.scoreCaption, 18 * s, 58 * s, rightWidth - 36 * s, 16 * s)
        setRect(self.score, 18 * s, 80 * s, rightWidth - 36 * s, 48 * s)
        self.score.TextSize = 39 * s
        setRect(self.quota, 18 * s, 134 * s, rightWidth - 36 * s, 24 * s)
        self.quota.TextSize = 16 * s
        setRect(self.progress, 18 * s, 172 * s, rightWidth - 36 * s, 9 * s)
        setRect(self.restock, 18 * s, 189 * s, rightWidth - 36 * s, 36 * s)
        setRect(self.best, 18 * s, 237 * s, rightWidth - 36 * s, 20 * s)
        setRect(self.perkSummary, 18 * s, 263 * s, rightWidth - 36 * s, 23 * s)
        setRect(self.profile, 18 * s, 288 * s, rightWidth - 36 * s, 18 * s)
        setRect(self.detail, 24 * s, 478 * s, leftWidth, 155 * s)
        setRect(self.detailTitle, 15 * s, 12 * s, leftWidth - 30 * s, 35 * s)
        setRect(self.detailTrigger, 15 * s, 49 * s, leftWidth - 30 * s, 31 * s)
        setRect(self.detailBody, 15 * s, 87 * s, leftWidth - 30 * s, 59 * s)
        for _, gui in
            {
                self.counterCaption,
                self.counters,
                self.timer,
                self.scoreCaption,
                self.restock,
                self.best,
                self.perkSummary,
                self.profile,
                self.detail,
            }
        do
            gui.Visible = true
        end
    end
    local controlsWidth = math.min(450 * s, w - 32)
    setRect(self.controls, (w - controlsWidth) / 2, h - 83, controlsWidth, 51)
    setRect(self.jumbleButton, 7, 7, controlsWidth * 0.41 - 11, 37)
    setRect(self.primary, controlsWidth * 0.41 + 3, 7, controlsWidth * 0.59 - 10, 37)
    self.jumbleButton.TextSize = self.mobile and 12 or 14
    self.primary.TextSize = self.mobile and 12 or 14
    setRect(self.help, math.max(8, (w - 700) / 2), h - 29, math.min(700, w - 16), 24)
    setRect(self.notice, math.max(12, (w - 620) / 2), h - 120, math.min(620, w - 24), 30)
    self.modalKey = nil

    local topSpace = self.mobile and 220 or 171 * s
    local bottomSpace = 100
    local availableHeight = math.max(150, h - topSpace - bottomSpace)
    local availableWidth = self.mobile and (w - 24) or math.max(260, w - 540 * s)
    local visibleHeight = math.max(31.5 * h / availableHeight, 24.5 * h / availableWidth)
    local distance = visibleHeight / (2 * math.tan(math.rad(35 / 2)))
    local targetY = 11 + ((topSpace - bottomSpace) / (2 * h)) * visibleHeight
    self.cameraCFrame = CFrame.lookAt(Vector3.new(0, targetY, distance), Vector3.new(0, targetY, 0))
    camera.CameraType = Enum.CameraType.Scriptable
    camera.FieldOfView = 35
    camera.CFrame = self.cameraCFrame
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
    if not camera or not self.snapshot or self.snapshot.phase ~= "aim" then
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
    if not self.snapshot then
        return
    end
    local phase = self.snapshot.phase
    if phase == "aim" then
        self:_send("launch", { angle = self.aim })
    elseif phase == "flight" then
        self:_send("endShot")
    elseif phase == "gameover" then
        self:_send("restart")
    elseif phase == "result" or phase == "shop" then
        self:_send("continue")
    end
end

function Presentation:_bindInput()
    table.insert(
        self.connections,
        UserInputService.InputBegan:Connect(function(input, processed)
            if processed then
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
            elseif
                input.KeyCode == Enum.KeyCode.R
                and self.snapshot
                and self.snapshot.phase == "gameover"
            then
                self:_send("restart")
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
                    self.snapshot
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

function Presentation:_updateInventory()
    local state = self.snapshot
    if not state then
        return
    end
    for index, cell in self.itemSlots do
        local item = state.inventory[index]
        local definition = itemDefinition(item)
        local locked = index > state.slots
        cell.button.BackgroundColor3 = definition and itemColor(definition):Lerp(C.ink, 0.75)
            or C.panel
        cell.border.Color = self.selectedSlot == index and C.paper or C.edge
        cell.border.Thickness = self.selectedSlot == index and 2 or 1
        cell.icon.Text = locked and "+" or (definition and initials(definition.name) or "—")
        cell.icon.TextColor3 = definition and itemColor(definition) or C.muted
        cell.name.Text = locked and "5 COINS"
            or (
                definition
                    and (definition.name .. ((item.level or 1) > 1 and ("  ↑" .. item.level) or ""))
                or "EMPTY"
            )
        cell.name.TextColor3 = definition and C.paper or C.muted
    end
    local item = self.selectedSlot and state.inventory[self.selectedSlot]
    local definition = itemDefinition(item)
    if definition then
        self.detailTitle.Text = definition.name .. "  •  LV " .. tostring(item.level or 1)
        self.detailTrigger.Text = definition.triggerText or "Passive effect"
        self.detailBody.Text = definition.description or ""
    else
        self.detailTitle.Text = "BUILD YOUR COMBO"
        self.detailTrigger.Text = "Select an item to inspect it"
        self.detailBody.Text =
            "Select two slots to reorder. Buy matching items to upgrade their effects."
        if state.boss then
            self.detailTitle.Text = state.boss.name
            self.detailTrigger.Text = "BOSS ROUND"
            self.detailBody.Text = state.boss.description
        end
    end
    if self.mobile and self.selectedSlot and definition and state.phase == "aim" then
        self.help.Text = definition.name .. ": " .. (definition.triggerText or "")
    end
end

function Presentation:_modalButton(parent, name, value, x, y, width, color, callback)
    local result = button(parent, name, value, color, callback, 14)
    setRect(result, x, y, width, 38)
    result.TextSize = width < 125 and 11 or 14
    return result
end

function Presentation:_updateModal()
    local state = self.snapshot
    if not state then
        return
    end
    local phase = state.phase
    local visible = phase ~= "aim" and phase ~= "flight"
    self.overlay.Visible = visible
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
        tostring(state.score),
    }
    for _, offer in state.shopOffers or {} do
        table.insert(parts, offer.id .. tostring(offer.frozen) .. tostring(offer.sold))
    end
    for _, item in state.inventory or {} do
        table.insert(parts, item.id .. tostring(item.level))
    end
    local key = table.concat(parts, "/")
    if self.modalKey == key then
        return
    end
    self.modalKey = key
    if self.modal then
        self.modal:Destroy()
    end
    local viewport = self.viewport or Vector2.new(1280, 720)
    local w = math.min(760, viewport.X - 32)
    local top = self.inventory.AbsolutePosition.Y
        + self.inventory.AbsoluteSize.Y
        - self.overlay.AbsolutePosition.Y
        + 12
    local h = math.min(570, math.max(240, viewport.Y - top - 18))
    local modal = frame(self.overlay, "ChoicePanel", C.panel, 11)
    self.modal = modal
    modal.AnchorPoint = Vector2.new(0.5, 0)
    modal.Position = UDim2.fromOffset(viewport.X / 2, top)
    modal.Size = UDim2.fromOffset(w, h)
    corner(modal, 17)
    stroke(modal, C.edge, 2)
    local title = label(modal, "Title", "", 25, C.paper, 12)
    title.Font = Enum.Font.GothamBlack
    title.TextSize = w < 500 and 19 or 25
    title.TextTruncate = Enum.TextTruncate.AtEnd
    setRect(title, 22, 17, w - 44, 34)
    local subtitle = label(modal, "Subtitle", "", 12, C.muted, 12)
    subtitle.TextWrapped = true
    setRect(subtitle, 22, 52, w - 44, 30)
    local footerY = h - 53
    local function scrollBody(height)
        local body = make("ScrollingFrame", {
            Name = "Choices",
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            ScrollBarThickness = 4,
            ScrollBarImageColor3 = C.edge,
            ScrollingDirection = Enum.ScrollingDirection.Y,
            CanvasSize = UDim2.fromOffset(0, height),
            ZIndex = 12,
        }, modal)
        setRect(body, 22, 90, w - 44, math.max(70, h - 156))
        return body
    end
    if phase == "shop" then
        title.Text = "THE UPGRADE COUNTER"
        subtitle.Text = "Coins "
            .. Format.integer(state.coins)
            .. "  •  Matching purchases upgrade your items. Select two slots above to reorder."
        local selectedDefinition = self.selectedSlot
            and itemDefinition(state.inventory[self.selectedSlot])
        if selectedDefinition then
            subtitle.Text = selectedDefinition.name .. "  •  " .. selectedDefinition.description
        end
        local gap = 10
        local cardWidth = (w - 52 - gap) / 2
        local cardHeight = w < 500 and 156 or 130
        local offers = state.shopOffers or {}
        local hasConsumables = #offers > 4
        local compact = w < 500
        local body =
            scrollBody(cardHeight * 2 + gap + (hasConsumables and (compact and 346 or 152) or 0))
        for index, offer in state.shopOffers or {} do
            local definition = Catalog.Items[offer.id]
            local consumable = offer.consumable or (definition and definition.consumable)
            local width = consumable and (compact and w - 52 or (w - 72) / 3) or cardWidth
            local height = consumable and (compact and 96 or 116) or cardHeight
            local x = consumable and (compact and 0 or (index - 5) * (width + 10))
                or ((index - 1) % 2) * (cardWidth + gap)
            local y = consumable
                    and cardHeight * 2 + gap + 28 + (compact and (index - 5) * 106 or 0)
                or math.floor((index - 1) / 2) * (cardHeight + gap)
            local card = frame(body, "Offer" .. index, C.ink, 12)
            setRect(card, x, y, width, height)
            corner(card, 10)
            local name =
                label(card, "Name", definition and definition.name or offer.id, 14, C.paper, 13)
            name.Font = Enum.Font.GothamBold
            name.TextWrapped = true
            name.TextSize = consumable and 11 or 14
            setRect(name, 11, 6, width - 22, consumable and 30 or 23)
            local description =
                label(card, "Effect", definition and definition.description or "", 10, C.muted, 13)
            description.TextWrapped = true
            description.TextYAlignment = Enum.TextYAlignment.Top
            setRect(description, 11, consumable and 37 or 31, width - 22, height - 73)
            local buy = button(
                card,
                "Buy",
                offer.sold and "SOLD" or ((consumable and "USE " or "BUY  ") .. offer.price),
                C.mint,
                function()
                    self:_send("buy", { offer = index })
                end,
                14
            )
            setRect(buy, 10, height - 40, consumable and width - 20 or width * 0.62 - 13, 32)
            buy.TextSize = 11
            buy.Active = not offer.sold and state.coins >= offer.price
            buy.AutoButtonColor = buy.Active
            if not buy.Active then
                buy.BackgroundColor3 = C.edge
            end
            if not consumable then
                local freeze = button(
                    card,
                    "Freeze",
                    offer.frozen and "HELD" or "HOLD",
                    offer.frozen and C.blue or C.panel,
                    function()
                        self:_send("freeze", { offer = index })
                    end,
                    14
                )
                setRect(freeze, width * 0.62 + 2, height - 40, width * 0.38 - 12, 32)
                freeze.TextSize = 10
                freeze.TextColor3 = offer.frozen and C.ink or C.paper
                freeze.Active = not offer.sold
            end
        end
        if hasConsumables then
            local caption =
                label(body, "Consumables", "USE NOW  •  ONE-SHOT BOOSTS", 10, C.mint, 13)
            setRect(caption, 0, cardHeight * 2 + gap + 6, w - 52, 18)
        end
        local footerWidth = (w - 64) / 3
        local reroll = self:_modalButton(
            modal,
            "Reroll",
            "REROLL 1  •  " .. tostring(state.rerollsLeft or 0),
            22,
            footerY,
            footerWidth,
            C.gold,
            function()
                self:_send("reroll")
            end
        )
        reroll.Active = (state.rerollsLeft or 0) > 0 and state.coins >= 1
        reroll.AutoButtonColor = reroll.Active
        if not reroll.Active then
            reroll.BackgroundColor3 = C.edge
        end
        local selected = self.selectedSlot and state.inventory[self.selectedSlot]
        local hasSelected = selected and selected.id ~= ""
        local sell = self:_modalButton(
            modal,
            "Sell",
            hasSelected and ("SELL SLOT " .. self.selectedSlot)
                or (state.slots < 7 and "+ SLOT  5" or "SELECT TO SELL"),
            32 + footerWidth,
            footerY,
            footerWidth,
            C.coral,
            function()
                if hasSelected then
                    self:_send("sell", { slot = self.selectedSlot })
                    self.selectedSlot = nil
                elseif state.slots < 7 then
                    self:_send("buySlot")
                end
            end
        )
        sell.Active = hasSelected or state.slots < 7
        sell.AutoButtonColor = sell.Active
        if not sell.Active then
            sell.BackgroundColor3 = C.edge
        end
        self:_modalButton(
            modal,
            "Continue",
            "CONTINUE",
            42 + footerWidth * 2,
            footerY,
            footerWidth,
            C.mint,
            function()
                self:_send("continue")
            end
        )
    elseif phase == "perk" or phase == "event" then
        title.Text = phase == "perk" and "CHOOSE YOUR EDGE"
            or (state.eventTitle or "A NEW OPPORTUNITY")
        subtitle.Text = phase == "perk"
                and "One permanent advantage for this run. Make it work with your items."
            or "Your choice changes this run."
        local choices = state.perkOffers or {}
        if phase == "event" then
            choices = state.eventChoices or {}
        end
        local count = math.max(1, #choices)
        local stacked = w < 500
        local cardWidth = stacked and w - 52 or (w - 52 - (count - 1) * 12) / count
        local cardHeight = stacked and 218 or 302
        local body = scrollBody(stacked and count * (cardHeight + 12) or cardHeight)
        body.Size = UDim2.fromOffset(w - 44, h - 112)
        for index, choice in choices do
            local definition = phase == "perk"
                    and Catalog.Perks[type(choice) == "table" and choice.id or choice]
                or choice
            definition = definition or { name = tostring(choice), description = "" }
            local card = frame(body, "Choice" .. index, C.ink, 12)
            setRect(
                card,
                stacked and 0 or (index - 1) * (cardWidth + 12),
                stacked and (index - 1) * (cardHeight + 12) or 0,
                cardWidth,
                cardHeight
            )
            corner(card, 12)
            local number = label(
                card,
                "Number",
                string.format("0%d", index),
                34,
                index == 1 and C.mint or C.gold,
                13
            )
            number.Font = Enum.Font.GothamBlack
            setRect(number, 17, 12, cardWidth - 34, 38)
            local name = label(card, "Name", definition.name, 17, C.paper, 13)
            name.Font = Enum.Font.GothamBold
            name.TextWrapped = true
            setRect(name, 17, stacked and 52 or 68, cardWidth - 34, stacked and 38 or 50)
            local description =
                label(card, "Description", definition.description or "", 12, C.muted, 13)
            description.TextWrapped = true
            description.TextYAlignment = Enum.TextYAlignment.Top
            setRect(description, 17, stacked and 94 or 126, cardWidth - 34, stacked and 64 or 98)
            self:_modalButton(
                card,
                "Choose",
                "CHOOSE",
                14,
                cardHeight - 52,
                cardWidth - 28,
                index == 1 and C.mint or C.gold,
                function()
                    self:_send(phase == "perk" and "choosePerk" or "chooseEvent", { index = index })
                end
            )
        end
    else
        local result = state.lastResult or {}
        local terminal = phase == "gameover" or phase == "victory"
        title.Text = phase == "victory" and "THE RUN IS YOURS"
            or (
                phase == "gameover" and "EVERY RUN TEACHES YOU"
                or (result.success and "TARGET CLEARED" or "TAKE ANOTHER SHOT")
            )
        subtitle.Text = phase == "victory"
                and "Eighty rounds complete. Keep building in endless, or start fresh."
            or (
                phase == "gameover"
                    and "Your records and unlocks remain. Your next combo starts from a clean slate."
                or (
                    result.reason == "clear" and "Board clear! Your shot score was doubled."
                    or "Your shot is settled. Here is what you earned."
                )
            )
        local resultBody = scrollBody(terminal and 258 or 203)
        local total = label(
            resultBody,
            "FinalScore",
            Format.number(result.score or state.score or 0),
            54,
            C.paper,
            12
        )
        total.Font = Enum.Font.GothamBlack
        total.TextXAlignment = Enum.TextXAlignment.Center
        total.TextSize = w < 500 and 40 or 54
        setRect(total, 0, 10, w - 52, 68)
        local target = label(
            resultBody,
            "Target",
            "TARGET  " .. Format.number(result.quota or state.quota or 0),
            16,
            C.muted,
            12
        )
        target.TextXAlignment = Enum.TextXAlignment.Center
        setRect(target, 0, 81, w - 52, 26)
        local earned = label(
            resultBody,
            "Earned",
            terminal
                    and ("BEST ROUND " .. tostring(state.bestRound or state.round) .. "    •    BEST SCORE " .. Format.number(
                        state.bestScore or 0
                    ))
                or (
                    tostring(result.restocks or 0)
                    .. " RESTOCKS    •    "
                    .. tostring(result.restocks or 0)
                    .. " COINS EARNED"
                ),
            15,
            C.mint,
            12
        )
        earned.TextXAlignment = Enum.TextXAlignment.Center
        earned.TextWrapped = true
        setRect(earned, 0, 123, w - 52, 65)
        if terminal then
            local names = {}
            for _, id in state.unlocks or {} do
                local definition = Catalog.Unlocks and Catalog.Unlocks[id]
                table.insert(names, definition and definition.name or id)
            end
            local unlocks = label(
                resultBody,
                "Unlocks",
                #names > 0 and ("UNLOCKS  •  " .. table.concat(names, " / "))
                    or "Unlock new items by reaching deeper rounds.",
                12,
                C.gold,
                13
            )
            unlocks.TextWrapped = true
            unlocks.TextXAlignment = Enum.TextXAlignment.Center
            setRect(unlocks, 0, 191, w - 52, 60)
        end
        if phase == "victory" then
            self:_modalButton(
                modal,
                "Restart",
                "NEW RUN",
                22,
                footerY,
                (w - 56) / 2,
                C.paper,
                function()
                    self:_send("restart")
                end
            )
            self:_modalButton(
                modal,
                "Endless",
                "GO ENDLESS",
                34 + (w - 56) / 2,
                footerY,
                (w - 56) / 2,
                C.mint,
                function()
                    self:_send("endless")
                end
            )
        else
            self:_modalButton(
                modal,
                "Continue",
                phase == "gameover" and "START A NEW RUN"
                    or (result.success and "CONTINUE" or "TRY AGAIN"),
                22,
                footerY,
                w - 44,
                C.mint,
                function()
                    self:_send(phase == "gameover" and "restart" or "continue")
                end
            )
        end
    end
end

function Presentation:_feedback(event)
    if event.kind == "trigger" and event.slot and self.itemSlots[event.slot] then
        self.itemSlots[event.slot].flash = 0.45
    end
    if event.kind == "pop" and event.pegId then
        local peg = self.pegs[event.pegId]
        if peg then
            peg.pulse = 0.18
        end
        local slot = Board.Slots[event.pegId]
        if slot and event.value then
            local text =
                label(self.fxLayer, "PopValue", "+" .. Format.number(event.value), 22, C.paper, 41)
            text.Font = Enum.Font.GothamBold
            text.TextStrokeColor3 = C.ink
            text.TextStrokeTransparency = 0.35
            text.TextXAlignment = Enum.TextXAlignment.Center
            text.AnchorPoint = Vector2.new(0.5, 0.5)
            text.Size = UDim2.fromOffset(150, 35)
            table.insert(self.effects, {
                gui = text,
                position = Vector3.new(slot.x, slot.y + 0.5, 1.2),
                age = 0,
                duration = 0.85,
            })
            local ring = frame(self.fxLayer, "PopRing", nil, 40)
            ring.BackgroundTransparency = 1
            ring.AnchorPoint = Vector2.new(0.5, 0.5)
            corner(ring, 100)
            local border = stroke(ring, peg and peg.part.Color or C.mint, 2)
            table.insert(self.effects, {
                gui = ring,
                ring = border,
                position = Vector3.new(slot.x, slot.y, 1.2),
                age = 0,
                duration = 0.4,
            })
        end
    elseif event.kind == "clear" or event.kind == "restock" then
        self:setNotice(
            event.text
                or (event.kind == "clear" and "BOARD CLEAR  •  DOUBLE SCORE" or "RESTOCK EARNED")
        )
    end
end

function Presentation:update(snapshot)
    if self.destroyed then
        return
    end
    if
        self.snapshot
        and snapshot.phase == "aim"
        and (
            self.snapshot.phase == "gameover"
            or self.snapshot.phase == "victory"
            or snapshot.round < self.snapshot.round
        )
    then
        self.lastEvent = 0
        self.selectedSlot = nil
    end
    if
        self.snapshot
        and (snapshot.round < self.snapshot.round or snapshot.score < self.snapshot.score)
    then
        self.displayScore = snapshot.score
    end
    local newBoss = snapshot.boss and (not self.snapshot or self.snapshot.round ~= snapshot.round)
    self.snapshot = snapshot
    self.loading.Visible = false
    self.receivedAt = os.clock()
    self.coins.Text = Format.integer(snapshot.coins or 0)
    self.reserves.Text = tostring(snapshot.reserves or 0)
        .. " / "
        .. tostring(snapshot.maxReserves or 5)
    for index, dot in self.reserveDots do
        dot.BackgroundColor3 = index <= (snapshot.reserves or 0) and C.mint or C.edge
    end
    self.roundLabel.Text =
        string.format("ROUND %02d  /  ZONE %d", snapshot.round or 1, snapshot.zone or 1)
    self.quota.Text = "TARGET  " .. Format.number(snapshot.quota or 0)
    self.counters.Text = tostring(snapshot.pops or 0)
        .. "    /    "
        .. tostring(snapshot.wallHits or 0)
    self.timer.Text = formatTime(snapshot.elapsed)
    self.best.Text = "BEST ROUND " .. tostring(snapshot.bestRound or 0)
    self.perkSummary.Text = tostring(#(snapshot.perks or {}))
        .. " PERKS  •  "
        .. tostring(snapshot.doubles or 0)
        .. " DOUBLES"
    self.profile.Text = ({
        session = "Records: this Studio session",
        saved = "Cloud records enabled",
        unavailable = "Cloud save unavailable • session records",
    })[snapshot.profileStatus] or "Records: current session"
    self.speed.Text = tostring(snapshot.speed or 1) .. "× SPEED"
    self.speed.Visible = snapshot.phase == "aim" or snapshot.phase == "flight"
    local ratio = (snapshot.score or 0) / math.max(1, snapshot.quota or 1)
    self.progressFill.Size = UDim2.fromScale(math.clamp(ratio < 1 and ratio or ratio % 1, 0, 1), 1)
    self.progressFill.BackgroundColor3 = ratio >= 1 and C.gold or C.mint
    local restocks = snapshot.restocks or math.floor(ratio)
    self.restock.Text = ratio >= 1
            and (Format.integer(restocks) .. " RESTOCKS EARNED\nNext at " .. Format.number(
                (restocks + 1) * snapshot.quota
            ))
        or "Fill the target to earn a restock"
    if restocks >= (snapshot.maxRestocks or 10000) then
        self.restock.Text = "MAX RESTOCKS EARNED"
        self.progressFill.Size = UDim2.fromScale(1, 1)
    end
    if snapshot.settling then
        self.restock.Text = "SETTLING RESTOCKS…"
    end
    if snapshot.boss then
        self.perkSummary.Text = "BOSS  •  " .. snapshot.boss.name
        if newBoss then
            self:setNotice(snapshot.boss.name .. " • " .. snapshot.boss.description)
        end
    end
    local phaseNames = {
        aim = "READY TO LAUNCH",
        flight = "SHOT IN PLAY",
        result = "SHOT COMPLETE",
        shop = "UPGRADE COUNTER",
        perk = "CHOOSE A PERK",
        event = "MAKE YOUR CHOICE",
        gameover = "RUN COMPLETE",
        victory = "VICTORY",
    }
    self.phaseLabel.Text = phaseNames[snapshot.phase] or string.upper(snapshot.phase)
    self.jumbleButton.Visible = snapshot.phase == "aim"
    self.jumbleButton.BackgroundColor3 = snapshot.canJumble and C.panel or C.ink
    self.jumbleButton.TextColor3 = snapshot.canJumble and C.paper or C.muted
    self.jumbleButton.Active = snapshot.canJumble == true
    self.jumbleButton.AutoButtonColor = self.jumbleButton.Active
    self.primary.Text = snapshot.phase == "flight" and "END SHOT  [E]" or "LAUNCH  [SPACE]"
    if self.mobile then
        self.primary.Text = snapshot.phase == "flight" and "END SHOT" or "LAUNCH"
        self.jumbleButton.Text = "JUMBLE"
    end
    self.controls.Visible = snapshot.phase == "aim" or snapshot.phase == "flight"
    self.help.Text = snapshot.phase == "flight"
            and "Let the combo play out. End Shot settles the current score."
        or (
            self.mobile and "Drag to aim, release to launch. Tap a slot to inspect."
            or "Aim with your pointer. Click the board or press Space to launch."
        )
    for id, value in snapshot.values or {} do
        local peg = self.pegs[id]
        if peg and peg.value ~= value then
            self.previewDirty = true
            peg.value = value
            peg.part.Transparency = value > 0 and 0 or 1
            peg.billboard.Enabled = value > 0
            peg.number.Text = Format.number(value)
            if value > 0 then
                local exponent = math.max(0, math.floor(math.log(value) / math.log(2) + 0.001))
                peg.part.Color = PEG_COLORS[(exponent % #PEG_COLORS) + 1]
            end
            peg.pulse = 0.18
        end
    end
    self:_updateInventory()
    for _, event in snapshot.events or {} do
        if event.id > self.lastEvent then
            self.lastEvent = event.id
            self:_feedback(event)
        end
    end
    self:_updateModal()
end

function Presentation:setNotice(message)
    self.notice.Text = message or ""
    self.noticeUntil = os.clock() + 3
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
    local state = self.snapshot
    if not state then
        return
    end
    self.displayScore += ((state.score or 0) - self.displayScore) * math.min(1, dt * 15)
    if math.abs(self.displayScore - (state.score or 0)) < 0.5 then
        self.displayScore = state.score or 0
    end
    self.score.Text = Format.number(math.floor(self.displayScore + 0.5))
    if os.clock() > self.noticeUntil then
        self.notice.Text = ""
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
    local guideVisible = state.phase == "aim"
    if guideVisible and (self.previewDirty or self.previewAim ~= self.aim) then
        self.preview = Simulation.preview(self.aim, state.values)
        self.previewAim = self.aim
        self.previewDirty = false
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
    for _, peg in self.pegs do
        peg.pulse = math.max(0, peg.pulse - dt)
        local scale = 1 + math.sin((peg.pulse / 0.18) * math.pi) * 0.14
        peg.part.Size = Vector3.one * Board.Geometry.pegRadius * 2 * scale
    end
    for index, cell in self.itemSlots do
        if cell.flash > 0 then
            cell.flash = math.max(0, cell.flash - dt)
            cell.border.Color = C.gold
            cell.border.Thickness = 1 + cell.flash * 5
        else
            cell.border.Color = self.selectedSlot == index and C.paper or C.edge
            cell.border.Thickness = self.selectedSlot == index and 2 or 1
        end
    end
    for index = #self.effects, 1, -1 do
        local effect = self.effects[index]
        effect.age += dt
        if effect.age >= effect.duration then
            effect.gui:Destroy()
            table.remove(self.effects, index)
        else
            local position, visible = camera:WorldToViewportPoint(
                effect.position + Vector3.new(0, effect.ring and 0 or effect.age * 2.2, 0)
            )
            effect.gui.Visible = visible
            effect.gui.Position = UDim2.fromOffset(position.X, position.Y)
            if effect.ring then
                local size = 12 + effect.age * 75
                effect.gui.Size = UDim2.fromOffset(size, size)
                effect.ring.Transparency = effect.age / effect.duration
            else
                effect.gui.TextTransparency =
                    math.clamp((effect.age / effect.duration - 0.45) / 0.55, 0, 1)
            end
        end
    end
end

function Presentation.new(onAction)
    local camera = workspace.CurrentCamera
    local self = setmetatable({
        onAction = onAction,
        connections = {},
        effects = {},
        aim = 0.15,
        lastEvent = 0,
        displayScore = 0,
        noticeUntil = 0,
        receivedAt = os.clock(),
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
    self.gui:Destroy()
    self.model:Destroy()
    if self.oldCamera and workspace.CurrentCamera == self.oldCamera.camera then
        workspace.CurrentCamera.CameraType = self.oldCamera.cameraType
        workspace.CurrentCamera.CFrame = self.oldCamera.cframe
        workspace.CurrentCamera.FieldOfView = self.oldCamera.fov
    end
end

return Presentation
