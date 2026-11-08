--!nonstrict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local TextService = game:GetService("TextService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Board = require(Shared:WaitForChild("Board"))
local Catalog = require(Shared:WaitForChild("Catalog"))
local Format = require(Shared:WaitForChild("Format"))
local Simulation = require(Shared:WaitForChild("Simulation"))
local Theme = require(script.Parent.UiTheme)
local ItemModels = require(script.Parent.ItemModels)
local Feedback = require(script.Parent.Feedback)
local Selection = require(script.Parent.InventorySelection)
local ShopLayout = require(script.Parent.ShopLayout)
local ChoiceLayout = require(script.Parent.ChoiceLayout)
local CounterProgress = require(script.Parent.CounterProgress)
local HoverInspector = require(script.Parent.HoverInspector)
local EvolutionDisplay = require(script.Parent.EvolutionDisplay)
local BoardArt = require(script.Parent.BoardArt)

local Presentation = {}
Presentation.__index = Presentation

local C = Theme.colors

local PEG_COLORS = {
    Color3.fromRGB(33, 160, 222),
    Color3.fromRGB(46, 188, 187),
    Color3.fromRGB(98, 177, 73),
    Color3.fromRGB(228, 164, 49),
    Color3.fromRGB(233, 127, 67),
    Color3.fromRGB(218, 110, 155),
    Color3.fromRGB(147, 120, 205),
    Color3.fromRGB(80, 141, 217),
    Color3.fromRGB(61, 183, 163),
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
        if shape == Enum.PartType.Ball and (size.X ~= size.Y or size.Y ~= size.Z) then
            result.Size = Vector3.one
            make("SpecialMesh", { MeshType = Enum.MeshType.Sphere, Scale = size }, result)
        else
            result.Shape = shape
        end
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

function Presentation:_send(kind, payload)
    if self.destroyed then
        return
    end
    if self.feedback and self.feedback.playCue and kind ~= "continue" then
        self.feedback:playCue("click")
    end
    if kind == "launch" then
        self.statsCleared = false
        self.selectedSlot = nil
    end
    self.onAction(kind, payload or {})
end

function Presentation:_buildBoard()
    self.model = make("Model", { Name = "PopAPegLocalBoard" }, workspace)
    part(
        self.model,
        "Sky",
        Vector3.new(420, 240, 1),
        Vector3.new(0, 40, -35),
        Color3.fromRGB(197, 244, 255):Lerp(Color3.fromRGB(66, 169, 229), 40 / 56),
        Enum.Material.Neon
    )
    for index = 1, 40 do
        local y = -35 + index * 2
        part(
            self.model,
            "Atmosphere",
            Vector3.new(420, 2, 0.2),
            Vector3.new(0, y, -34),
            Color3.fromRGB(197, 244, 255):Lerp(Color3.fromRGB(66, 169, 229), index / 56),
            Enum.Material.Neon
        )
    end
    part(
        self.model,
        "Water",
        Vector3.new(420, 100, 0.5),
        Vector3.new(0, -53, -27),
        Color3.fromRGB(28, 161, 212)
    )
    for index = 1, 14 do
        local shimmer = part(
            self.model,
            "WaterShimmer",
            Vector3.new(9 + index * 1.5, 0.1, 0.1),
            Vector3.new(math.sin(index * 2.2) * 34, -6 - index * 1.3, -26),
            C.paper
        )
        shimmer.Transparency = 0.75
    end
    for _, side in { -1, 1 } do
        part(
            self.model,
            "DistantHill",
            Vector3.new(62, 22, 6),
            Vector3.new(side * 40, -4, -31),
            Color3.fromRGB(112, 186, 70),
            nil,
            Enum.PartType.Ball
        )
        part(
            self.model,
            "Meadow",
            Vector3.new(45, 16, 5),
            Vector3.new(side * 47, -6, -30),
            Color3.fromRGB(152, 206, 75),
            nil,
            Enum.PartType.Ball
        )
        for index = 1, 4 do
            local x, y = side * (16 + index * 12), 25 + (index % 3) * 9
            for puff = -1, 1 do
                local cloud = part(
                    self.model,
                    "Cloud",
                    Vector3.new(11, 4.5 + (puff == 0 and 2 or 0), 3),
                    Vector3.new(
                        x + puff * 4,
                        y + (puff == 0 and 1 or 0),
                        -23 + (puff == 0 and 0.35 or 0)
                    ),
                    C.paper,
                    nil,
                    Enum.PartType.Ball
                )
                cloud.Transparency = 0
            end
        end
        for index = 1, 5 do
            local bubble = part(
                self.model,
                "AirBubble",
                Vector3.one * (1.3 + index * 0.5),
                Vector3.new(side * (14 + index * 4.6), 2 + index * 4, -16),
                C.edge,
                Enum.Material.Glass,
                Enum.PartType.Ball
            )
            bubble.Transparency = 0.68
            bubble.Reflectance = 0.15
            part(
                self.model,
                "BubbleGlint",
                Vector3.one * 0.17,
                bubble.Position + Vector3.new(-0.3, 0.5, 1),
                C.paper,
                Enum.Material.Neon,
                Enum.PartType.Ball
            )
        end
    end
    for _, scenery in self.model:GetDescendants() do
        if scenery:IsA("BasePart") then
            scenery.CastShadow = false
        end
    end
    self.boardArt = BoardArt.new(self.model)
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
        local number = label(billboard, "Number", "1", 30, C.paper)
        number.Size = UDim2.fromScale(1, 1)
        number.Font = Enum.Font.SourceSansBold
        number.TextStrokeTransparency = 0.35
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
        dot.CastShadow = false
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
        self.aimArrow[index].CastShadow = false
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
    local animate = Catalog.Items[id] ~= nil or Catalog.Perks[id] ~= nil
    local reduced = game:GetService("GuiService").ReducedMotionEnabled
    local outline = viewport:GetAttribute("NoOutline") ~= true
    local key = tostring(id)
        .. ":"
        .. tostring(level or 1)
        .. ":"
        .. tostring(animate)
        .. ":"
        .. tostring(reduced)
        .. ":"
        .. tostring(outline)
    local current = self.models[viewport]
    if current and current.key == key then
        return
    end
    if current then
        current.handle:destroy()
    end
    self.models[viewport] = {
        key = key,
        handle = ItemModels.mount(
            viewport,
            id,
            level or 1,
            { animate = animate, reducedMotion = reduced, outline = outline }
        ),
    }
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
    self.inspector = HoverInspector.new(self)
    self.brand = label(self.root, "Brand", "POP A PEG", 37, C.paper, 5)
    self.tag = label(self.root, "Tag", "BUILD A BIGGER BOUNCE!", 18, C.gold, 5)
    self.roundPlate = plate(self.root, "RoundPlate", C.paper, 3)
    blockAim(self.roundPlate)
    self.roundLabel = label(self.roundPlate, "Round", "ROUND 1", 30, C.ink, 5)
    self.phaseLabel = label(self.roundPlate, "Phase", "READY TO LAUNCH", 17, C.board, 5)
    self.stageLabel = label(self.roundPlate, "Stage", "LEVEL 1", 20, C.board, 5)
    self.stageLabel.Font = Enum.Font.SourceSansBold
    self.stageLabel.TextScaled = true
    make("UITextSizeConstraint", { MinTextSize = 13, MaxTextSize = 20 }, self.stageLabel)
    self.stageProgress = frame(self.roundPlate, "StageProgress", C.edge, 5)
    corner(self.stageProgress, 3)
    self.stageFill = frame(self.stageProgress, "Fill", C.mint, 6)
    corner(self.stageFill, 3)

    self.inventory = plate(self.root, "EquipmentRack", C.paper, 30)
    blockAim(self.inventory)
    self.swapHelp = label(
        self.root,
        "RackInstructions",
        "Click item: select / clear • Other slot: swap",
        18,
        C.paper,
        31
    )
    self.swapHelp.TextXAlignment = Enum.TextXAlignment.Center
    self.swapHelp.TextScaled = true
    self.swapHelp.BackgroundColor3 = C.ink
    self.swapHelp.BackgroundTransparency = 0.15
    corner(self.swapHelp, 6)
    make("UITextSizeConstraint", { MinTextSize = 14, MaxTextSize = 18 }, self.swapHelp)
    self.itemSlots = {}
    for index = 1, 7 do
        local cell = button(self.inventory, "Slot" .. index, "", C.panel, function()
            local state = self.snapshot
            if not state or self.busy then
                return
            end
            self.pendingMove = Selection.reconcileMove(self.pendingMove, state, os.clock())
            if self.pendingMove then
                return
            end
            if index > state.slots then
                if state.phase == "shop" then
                    self:_send("buySlot")
                else
                    self:setNotice("Unlock another slot for 5 coins in the shop.")
                end
            else
                local selected, move = Selection.click(
                    self.selectedSlot,
                    index,
                    state.inventory,
                    state.slots,
                    state.phase,
                    self.busy
                )
                self.selectedSlot = selected
                self.selectedOffer = nil
                self.selectedPerk = nil
                if move then
                    self.pendingMove =
                        Selection.beginMove(move, state, os.clock(), Catalog.MaxLevel)
                    self:_send("move", move)
                end
            end
            self.modalKey = nil
            self:_updateInventory()
            self:_updatePerks()
            self:_updateModal()
            local item = state.inventory[index]
            if self.selectedSlot == index and item and item.id ~= "" then
                self.inspector:show(item.id, item.level, self.itemSlots[index].button, true)
            else
                self.inspector:hide()
            end
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
        self.inspector:bind(cell, function()
            local item = self.snapshot and self.snapshot.inventory[index]
            return item and item.id ~= "" and item.id or nil, item and item.level or 1
        end)
    end

    self.left = frame(self.root, "Resources", nil, 2)
    self.left.BackgroundTransparency = 1
    self.wallet = plate(self.left, "Wallet", C.panel, 3)
    self.coinScale = make("UIScale", { Scale = 1 }, self.wallet)
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
    self.stats = label(self.left, "ShotStats", "0 POPS   0 WALLS", 19, C.paper, 5)
    self.timer = label(self.left, "Time", "00:00.00", 18, C.muted, 5)
    self.statsPanel = plate(self.root, "TriggerCounts", C.panel, 5)
    blockAim(self.statsPanel)
    self.statsTitle = label(self.statsPanel, "Title", "THIS SHOT", 18, C.paper, 7)
    self.statLabels = {}
    for _, field in
        {
            "pops",
            "walls",
            "doubles",
            "halves",
            "quotas",
            "time",
            "first",
            "drain",
            "clear",
            "itemTriggers",
            "perkTriggers",
        }
    do
        self.statLabels[field] = label(self.statsPanel, field, "", 18, C.paper, 7)
    end

    self.right = frame(self.root, "ScoreTower", nil, 2)
    self.right.BackgroundTransparency = 1
    self.scorePlate = plate(self.right, "Score", C.paper, 3)
    blockAim(self.scorePlate)
    self.scoreScale = make("UIScale", { Scale = 1 }, self.scorePlate)
    self.scoreCaption = label(self.scorePlate, "Caption", "SHOT SCORE", 23, C.ink, 5)
    self.score = label(self.scorePlate, "Total", "0", 60, C.ink, 5)
    self.score.Font = Enum.Font.SourceSansBold
    make("UITextSizeConstraint", { MinTextSize = 18, MaxTextSize = 60 }, self.score)
    self.quota = label(self.scorePlate, "Quota", "TARGET 10", 23, C.ink, 5)
    self.quotaConstraint =
        make("UITextSizeConstraint", { MinTextSize = 16, MaxTextSize = 25 }, self.quota)
    self.progressCaption = label(self.scorePlate, "Next", "NEXT RESTOCK", 18, C.board, 5)
    self.progress = frame(self.scorePlate, "RepeatMeter", C.ink, 4)
    stroke(self.progress, C.ink, 4)
    corner(self.progress, 3)
    self.progressFill = frame(self.progress, "CurrentFill", C.mint, 5)
    corner(self.progressFill, 2)
    self.fraction = label(self.progress, "Fraction", "0 / 10", 29, C.paper, 7)
    make("UITextSizeConstraint", { MinTextSize = 16, MaxTextSize = 29 }, self.fraction)
    self.fraction.TextXAlignment = Enum.TextXAlignment.Center
    self.fraction.Size = UDim2.fromScale(1, 1)
    self.restockPlate = plate(self.right, "EarnedRestocks", C.paper, 3)
    self.restockScale = make("UIScale", { Scale = 1 }, self.restockPlate)
    blockAim(self.restockPlate)
    self.restockModel = self:_viewport(self.restockPlate, "Restock", "restock", 1, 5)
    self.restockCaption = label(self.restockPlate, "Caption", "RESTOCKS EARNED", 20, C.ink, 5)
    self.restockCount = label(self.restockPlate, "Count", "×0", 55, C.ink, 5)
    self.restockHint =
        label(self.restockPlate, "Hint", "Fill the meter to grow your board", 17, C.board, 5)
    self.restockHint.TextWrapped = true
    self.stackIcons = {}
    for index = 1, 8 do
        self.stackIcons[index] =
            self:_viewport(self.restockPlate, "Stack" .. index, "restock", 1, 5)
        self.stackIcons[index].Visible = false
    end
    self.best = label(self.right, "Best", "BEST ROUND 0", 18, C.muted, 5)
    self.profile = label(self.right, "Profile", "SESSION RECORDS", 14, C.muted, 5)

    self.perksPanel = plate(self.root, "OwnedPerks", C.paper, 6)
    blockAim(self.perksPanel)
    self.perksTitle = label(self.perksPanel, "Title", "OWNED PERKS", 18, C.ink, 8)
    self.perksTitle.Font = Enum.Font.SourceSansBold
    self.perksStatus = label(self.perksPanel, "Status", "", 16, C.board, 8)
    self.perksStatus.TextScaled = true
    make("UITextSizeConstraint", { MinTextSize = 13, MaxTextSize = 16 }, self.perksStatus)
    self.perksEmpty =
        label(self.perksPanel, "Empty", "Choose perks as your run grows.", 16, C.board, 8)
    self.perksEmpty.TextWrapped = true
    self.perkCells, self.perkCounts = {}, {}
    for _, id in Catalog.PerkIds do
        local data = Catalog.Perks[id]
        local cell = button(self.perksPanel, id, "", C.muted, function()
            self.selectedPerk = if self.selectedPerk == id then nil else id
            self.selectedSlot, self.selectedOffer = nil, nil
            self:_updateInventory()
            self:_updatePerks()
            if self.selectedPerk then
                self.inspector:show(id, 1, self.perkCells[id].button, true)
            else
                self.inspector:hide()
            end
        end, 8)
        cell.Visible = false
        self.inspector:bind(cell, function()
            return id, 1
        end)
        local viewport = make(
            "ViewportFrame",
            { Name = "PerkModel", BackgroundTransparency = 1, BorderSizePixel = 0, ZIndex = 10 },
            cell
        )
        local name = label(cell, "Name", data.name, 15, C.ink, 11)
        name.TextTruncate = Enum.TextTruncate.AtEnd
        name.TextXAlignment = Enum.TextXAlignment.Center
        local count = label(cell, "Copies", "", 14, C.ink, 12)
        count.Font = Enum.Font.SourceSansBold
        count.TextXAlignment = Enum.TextXAlignment.Right
        self.perkCells[id] =
            { button = cell, viewport = viewport, name = name, count = count, flash = 0 }
    end

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
    self.settlement = frame(self.root, "Settlement", C.board, 55)
    self.settlement.BackgroundTransparency = 1
    self.settlementOutline = stroke(self.settlement, C.paper, 2)
    self.settlementOutline.Transparency = 1
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
    self.overlay.BackgroundTransparency = 0.38
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
    if not camera or camera.ViewportSize.X < 32 or camera.ViewportSize.Y < 48 then
        return
    end
    local size = camera.ViewportSize
    self.viewport = size
    local w, h = size.X, size.Y
    local inset = game:GetService("GuiService"):GetGuiInset()
    local top = math.max(12, inset.Y + 8)
    self.safeTop = top
    self.mobile = w < 850 and h > w * 0.8
    self.shortWide = (h < 620 or w < 1100) and not self.mobile
    self.compact = self.mobile or self.shortWide
    self.lowDesktop = not self.compact and h < 960
    local phase = self.snapshot and self.snapshot.phase
    local compact, shop = self.compact, phase == "shop"
    local choosing = shop
        or phase == "perk"
        or phase == "event"
        or phase == "gameover"
        or phase == "victory"
    local boardRect, invWidth, invHeight
    self.brand.Visible, self.tag.Visible = not compact, not compact
    self.roundPlate.Visible = not (shop and self.shortWide)
    self.phaseLabel.Visible = not compact
    self.stageLabel.Visible, self.stageProgress.Visible = not compact, not compact
    self.coinCaption.Visible = not compact
    self.progressCaption.Visible = not compact
    self.restockCaption.Text = compact and "RESTOCKS" or "RESTOCKS EARNED"
    self.restockHint.Visible, self.restockModel.Visible = not compact, not compact
    self.best.Visible, self.profile.Visible = not compact and h >= 1040, not compact and h >= 1040
    self.stats.Visible, self.timer.Visible = false, false
    self.statsPanel.Visible = true
    self.help.Visible = not compact
    self.soundButton.TextSize = compact and 15 or 18
    self.quota.TextScaled = true
    self.quotaConstraint.MaxTextSize = compact and 19 or 25
    self.score.TextScaled = true
    self.fraction.TextScaled = true
    if compact then
        local uiX = self.shortWide and math.floor(w * 0.43) or 12
        local uiW = w - uiX - 12
        local invTop = self.shortWide and top + 20 or top + 190
        invWidth, invHeight = uiW, 88
        if choosing then
            invHeight = self.shortWide and 60 or 64
        end
        if choosing and self.mobile then
            invTop = top + 20
        end
        local invX = shop and self.shortWide and 12 or uiX
        if shop and self.shortWide then
            invWidth = w - 24
        end
        setRect(self.inventory, invX, invTop, invWidth, invHeight)
        setRect(self.swapHelp, invX, invTop - 22, invWidth, 20)
        local resourceTop = self.shortWide and invTop + invHeight + 8 or top
        setRect(self.left, uiX, resourceTop, uiW, 42)
        local half = (uiW - 8) / 2
        setRect(self.wallet, 0, 0, half, 42)
        setRect(self.coinModel, 0, -3, 47, 47)
        setRect(self.coins, 45, 0, half - 51, 42)
        self.coins.TextSize = 31
        setRect(self.reservePlate, half + 8, 0, half, 42)
        setRect(self.reserveCaption, 8, 0, 60, 42)
        self.reserveCaption.Text, self.reserveCaption.TextSize = "BALLS", 18
        setRect(self.reserves, 70, 0, half - 78, 42)
        self.reserves.TextSize = 25
        setRect(self.right, uiX, resourceTop + 50, uiW, 88)
        setRect(self.scorePlate, 0, 0, uiW, 88)
        setRect(self.scoreCaption, 10, 3, 58, 34)
        self.scoreCaption.Text, self.scoreCaption.TextSize = "SCORE", 18
        setRect(self.score, 70, 3, uiW - 201, 34)
        setRect(self.quota, uiW - 127, 3, 117, 34)
        self.quota.TextXAlignment = Enum.TextXAlignment.Right
        setRect(self.progress, 10, 45, uiW - 125, 32)
        setRect(self.restockPlate, uiW - 106, 41, 96, 39)
        setRect(self.restockCaption, 3, 0, 90, 17)
        self.restockCaption.TextSize = 15
        self.restockCaption.TextXAlignment = Enum.TextXAlignment.Center
        setRect(self.restockCount, 3, 15, 90, 24)
        self.restockCount.TextSize = 26
        self.restockCount.TextXAlignment = Enum.TextXAlignment.Center
        for _, icon in self.reserveIcons do
            icon.Visible = false
        end
        for _, icon in self.stackIcons do
            icon.Visible = false
        end
        if self.shortWide then
            setRect(self.roundPlate, 12, top, uiX - 26, 32)
            setRect(self.roundLabel, 6, 0, uiX - 38, 31)
            self.roundLabel.TextSize = 22
            self.roundLabel.TextXAlignment = Enum.TextXAlignment.Center
            local statsY = h - 114
            boardRect = { x = 12, y = top + 40, w = uiX - 28, h = statsY - top - 48 }
            if h < 450 then
                setRect(self.perksPanel, 12, top + 38, uiX - 26, 50)
                boardRect.y, boardRect.h = top + 94, statsY - top - 102
            else
                setRect(
                    self.perksPanel,
                    uiX,
                    resourceTop + 150,
                    uiW,
                    math.min(88, h - 110 - resourceTop - 150)
                )
            end
            setRect(self.statsPanel, 12, statsY, uiX - 26, 100)
            local cw = math.max(235, uiW - 156)
            setRect(self.controls, uiX, h - 66, cw, 50)
            setRect(self.jumbleButton, 0, 0, cw * 0.4 - 4, 50)
            setRect(self.primary, cw * 0.4 + 4, 0, cw * 0.6 - 4, 50)
            for index, speedButton in self.speedButtons do
                setRect(speedButton, w - 152 + (index - 1) * 47, h - 66, 41, 50)
            end
            setRect(self.soundButton, uiX, h - 102, 68, 28)
        else
            setRect(self.roundPlate, 12, top + 146, uiW, 26)
            setRect(self.roundLabel, 6, 0, uiW - 12, 26)
            self.roundLabel.TextSize = 21
            self.roundLabel.TextXAlignment = Enum.TextXAlignment.Center
            local statsY = h - 212
            setRect(self.perksPanel, 12, top + 278, uiW, 68)
            boardRect = { x = 12, y = top + 354, w = uiW, h = statsY - top - 362 }
            setRect(self.statsPanel, 12, statsY, uiW, 96)
            setRect(self.controls, 12, h - 104, uiW, 46)
            setRect(self.jumbleButton, 0, 0, uiW * 0.36 - 4, 46)
            setRect(self.primary, uiW * 0.36 + 4, 0, uiW * 0.64 - 4, 46)
            local unit = (uiW - 24) / 4
            for index, speedButton in self.speedButtons do
                setRect(speedButton, 12 + (index - 1) * (unit + 8), h - 48, unit, 36)
            end
            setRect(self.soundButton, 12 + 3 * (unit + 8), h - 48, unit, 36)
        end
        self.primary.TextSize, self.jumbleButton.TextSize = 24, 20
    else
        local leftW = math.clamp(w * 0.185, 225, 290)
        local rightW = math.clamp(w * 0.205, 250, 315)
        local rackSpace = w - leftW - rightW - 64
        invWidth = math.min(shop and 1100 or 1320, rackSpace)
        invHeight = choosing and 94 or math.clamp(h * 0.17, 124, 180)
        setRect(self.brand, 22, top + 16, leftW, 42)
        self.brand.Font = Enum.Font.SourceSansBold
        self.brand.TextSize = 37
        setRect(self.tag, 24, top + 60, leftW, 24)
        self.tag.TextSize = 17
        setRect(
            self.inventory,
            leftW + 32 + (rackSpace - invWidth) / 2,
            top + 22,
            invWidth,
            invHeight
        )
        setRect(self.swapHelp, self.inventory.Position.X.Offset, top, invWidth, 20)
        setRect(self.roundPlate, w - rightW - 22, top + 20, rightW, 98)
        setRect(self.stageLabel, 14, 6, rightW - 28, 20)
        setRect(self.stageProgress, 14, 86, rightW - 28, 5)
        setRect(self.roundLabel, 14, 26, rightW - 28, 34)
        self.roundLabel.TextSize = 30
        self.roundLabel.TextXAlignment = Enum.TextXAlignment.Left
        setRect(self.phaseLabel, 14, 61, rightW - 28, 22)
        local resourceTop = top + 148
        setRect(self.left, 22, resourceTop, leftW, 600)
        setRect(self.wallet, 0, 0, leftW, 82)
        setRect(self.coinModel, 8, 6, 78, 70)
        setRect(self.coinCaption, 94, 6, leftW - 104, 25)
        setRect(self.coins, 94, 29, leftW - 104, 48)
        self.coins.TextSize = 44
        setRect(self.reservePlate, 0, 94, leftW, 78)
        setRect(self.reserveCaption, 12, 5, leftW - 90, 26)
        self.reserveCaption.Text, self.reserveCaption.TextSize = "BALLS LEFT", 21
        setRect(self.reserves, leftW - 76, 5, 64, 26)
        self.reserves.TextSize = 25
        for index, icon in self.reserveIcons do
            icon.Visible = true
            setRect(icon, 8 + (index - 1) * ((leftW - 16) / 5), 32, (leftW - 16) / 5, 40)
        end
        setRect(self.statsPanel, 22, resourceTop + 186, leftW, 166)
        setRect(self.right, w - rightW - 22, resourceTop, rightW, 570)
        setRect(self.scorePlate, 0, 0, rightW, 236)
        setRect(self.scoreCaption, 16, 10, rightW - 32, 30)
        self.scoreCaption.Text, self.scoreCaption.TextSize = "SHOT SCORE", 23
        setRect(self.score, 16, 42, rightW - 32, 62)
        setRect(self.quota, 16, 110, rightW - 32, 30)
        self.quota.TextXAlignment = Enum.TextXAlignment.Left
        setRect(self.progressCaption, 16, 146, rightW - 32, 26)
        setRect(self.progress, 15, 178, rightW - 30, 44)
        setRect(self.restockPlate, 0, 250, rightW, h < 850 and 138 or 210)
        setRect(self.restockCaption, 14, 8, rightW - 28, 28)
        self.restockCaption.TextSize = 20
        self.restockCaption.TextXAlignment = Enum.TextXAlignment.Left
        setRect(self.restockModel, 4, 40, 100, 85)
        setRect(self.restockCount, 110, 44, rightW - 122, 68)
        self.restockCount.TextSize = 50
        self.restockCount.TextXAlignment = Enum.TextXAlignment.Left
        self.restockHint.Visible = h >= 850
        setRect(self.restockHint, 14, 160, rightW - 28, 38)
        for index, icon in self.stackIcons do
            setRect(
                icon,
                12 + (index - 1) * ((rightW - 24) / 8),
                h < 850 and 109 or 127,
                (rightW - 24) / 8,
                30
            )
        end
        setRect(self.perksPanel, w - rightW - 22, resourceTop + 474, rightW, 174)
        setRect(self.best, 4, 660, rightW - 8, 27)
        setRect(self.profile, 4, 691, rightW - 8, 24)
        if self.lowDesktop then
            self.restockHint.Visible = false
            setRect(self.scorePlate, 0, 0, rightW, 172)
            setRect(self.scoreCaption, 14, 5, rightW - 28, 26)
            setRect(self.score, 14, 30, rightW - 28, 50)
            setRect(self.quota, 14, 83, rightW - 28, 28)
            self.progressCaption.Visible = false
            setRect(self.progress, 14, 121, rightW - 28, 38)
            setRect(self.restockPlate, 0, 184, rightW, 96)
            setRect(self.restockCaption, 12, 2, rightW - 24, 24)
            setRect(self.restockModel, 4, 28, 90, 60)
            setRect(self.restockCount, 106, 30, rightW - 118, 54)
            setRect(self.perksPanel, w - rightW - 22, resourceTop + 292, rightW, 130)
        end
        boardRect = {
            x = leftW + 44,
            y = top + 22 + invHeight + 14,
            w = w - leftW - rightW - 88,
            h = h - (top + 22 + invHeight + 14) - 96,
        }
        local cw = math.min(440, boardRect.w)
        setRect(self.controls, boardRect.x + (boardRect.w - cw) / 2, h - 83, cw, 54)
        setRect(self.jumbleButton, 0, 0, cw * 0.36 - 5, 54)
        setRect(self.primary, cw * 0.36 + 5, 0, cw * 0.64 - 5, 54)
        self.primary.TextSize, self.jumbleButton.TextSize = 28, 23
        for index, speedButton in self.speedButtons do
            setRect(speedButton, w - rightW - 22 + (index - 1) * 66, h - 79, 58, 48)
        end
        setRect(self.soundButton, 24, h - 79, 148, 48)
        setRect(self.help, boardRect.x - 40, h - 25, boardRect.w + 80, 20)
    end
    local columns = compact and 3 or 2
    local statW = (self.statsPanel.Size.X.Offset - 20) / columns
    local rowH = compact and 18 or 22
    setRect(self.statsTitle, 10, 2, self.statsPanel.Size.X.Offset - 20, 21)
    self.statsTitle.TextSize = compact and 16 or 18
    for index, field in
        {
            "pops",
            "walls",
            "doubles",
            "halves",
            "quotas",
            "time",
            "first",
            "drain",
            "clear",
            "itemTriggers",
            "perkTriggers",
        }
    do
        local text = self.statLabels[field]
        setRect(
            text,
            10 + ((index - 1) % columns) * statW,
            24 + math.floor((index - 1) / columns) * rowH,
            statW - 3,
            rowH
        )
        text.TextSize = compact and 16 or 18
    end
    local cellW = (invWidth - 12) / 7
    for index, slot in self.itemSlots do
        setRect(slot.button, 6 + (index - 1) * cellW + 2, 5, cellW - 4, invHeight - 10)
        local showName = not compact or invHeight >= 74 or (shop and self.shortWide)
        setRect(slot.viewport, 2, 3, cellW - 8, showName and invHeight - 35 or invHeight - 17)
        setRect(slot.number, 4, 0, 17, 19)
        slot.number.TextSize = compact and 14 or 17
        setRect(slot.level, cellW - 34, 0, 24, 19)
        slot.level.TextSize = compact and 14 or 17
        setRect(slot.name, 3, invHeight - 31, cellW - 10, 21)
        slot.name.Visible = showName
        slot.name.TextSize = compact and 14 or (shop and 18 or 23)
        slot.name.Font = Enum.Font.SourceSansBold
    end
    self.boardRect = boardRect
    setRect(
        self.notice,
        math.max(12, (w - 720) / 2),
        h - (self.mobile and 262 or 125),
        math.min(720, w - 24),
        40
    )
    self.notice.TextSize = compact and 20 or 24
    self.modalKey = nil
    local vh =
        math.max(34.5 * h / math.max(120, boardRect.h), 26.8 * h / math.max(170, boardRect.w))
    local distance = vh / (2 * math.tan(math.rad(17.5)))
    local cameraX = (w / 2 - boardRect.x - boardRect.w / 2) * vh / h
    local cameraY = 11.7 + (boardRect.y + boardRect.h / 2 - h / 2) * vh / h
    self.cameraCFrame =
        CFrame.lookAt(Vector3.new(cameraX, cameraY, distance), Vector3.new(cameraX, cameraY, 0))
    camera.CameraType, camera.FieldOfView, camera.CFrame =
        Enum.CameraType.Scriptable, 35, self.cameraCFrame
    self:_layoutSettlement()
    self:_renderCounters()
    self:_renderControls()
    self:_updateInventory()
    self:_updatePerks()
end

function Presentation:_updatePerks()
    local state = self.snapshot
    if not state then
        return
    end
    local counts, total = {}, 0
    for _, id in state.perks or {} do
        if self.perkCells[id] then
            counts[id] = (counts[id] or 0) + 1
            total += 1
        end
    end
    self.perkCounts = counts
    if self.selectedPerk and not counts[self.selectedPerk] then
        self.selectedPerk = nil
    end
    local order = {}
    for _, id in Catalog.PerkIds do
        local cell = self.perkCells[id]
        cell.button.Visible = counts[id] ~= nil
        cell.viewport.Visible = counts[id] ~= nil
        if counts[id] then
            table.insert(order, id)
            cell.count.Text = "×" .. tostring(counts[id])
            self:_mount(cell.viewport, id, 1)
            Theme.select(cell.button, self.selectedPerk == id, C.muted)
        end
    end
    self.perksEmpty.Visible = #order == 0
    local w, h = self.perksPanel.Size.X.Offset, self.perksPanel.Size.Y.Offset
    local columns = self.compact and 8 or 4
    local rows = self.compact and 1 or 2
    local headerH = h < 70 and 18 or 23
    local cw = (w - 12 - (columns - 1) * 4) / columns
    local ch = (h - headerH - 8 - (rows - 1) * 4) / rows
    setRect(self.perksTitle, 7, 1, w * 0.42, headerH)
    self.perksTitle.TextSize = h < 70 and 14 or 18
    self.perksTitle.Text = "PERKS • " .. total
    setRect(self.perksStatus, w * 0.42, 1, w * 0.58 - 7, headerH)
    self.perksStatus.TextXAlignment = Enum.TextXAlignment.Right
    if os.clock() >= (self.perkUntil or 0) then
        self.perksStatus.Text = "RUN BONUSES"
    end
    setRect(self.perksEmpty, 9, headerH, w - 18, h - headerH - 4)
    self.perksEmpty.TextXAlignment = Enum.TextXAlignment.Center
    for index, id in order do
        local cell = self.perkCells[id]
        setRect(
            cell.button,
            6 + ((index - 1) % columns) * (cw + 4),
            headerH + 3 + math.floor((index - 1) / columns) * (ch + 4),
            cw,
            ch
        )
        local nameH = h < 70 and 0 or 16
        local modelH = math.min(cw - 2, ch - nameH)
        setRect(cell.viewport, (cw - modelH) / 2, 0, modelH, modelH)
        setRect(cell.name, 2, ch - nameH, cw - 4, nameH)
        cell.name.Visible = nameH > 0
        cell.name.TextSize = self.compact and 13 or 15
        setRect(cell.count, cw - 24, 0, 22, 16)
    end
end

function Presentation:pulsePerk(id)
    local cell = self.perkCells[id]
    if not cell or not self.perkCounts[id] then
        return
    end
    cell.flash = 0.8
    local mounted = self.models[cell.viewport]
    if mounted then
        mounted.handle:pulse(0.8)
    end
    self.perkUntil = os.clock() + 1.2
    self.perksStatus.Text = "ACTIVE • " .. Catalog.Perks[id].name
end

function Presentation:pulseCounter(kind, strength)
    if game:GetService("GuiService").ReducedMotionEnabled then
        return
    end
    if not ({ score = true, coins = true, restocks = true })[kind] then
        return
    end
    local current = self.counterPulses[kind]
    if current then
        current.strength = math.max(current.strength, math.min(1.5, strength or 1))
    else
        self.counterPulses[kind] = { remaining = 0.26, strength = math.min(1.5, strength or 1) }
    end
end

function Presentation:_updateInventory()
    local state = self.snapshot
    if not state then
        return
    end
    self.selectedSlot =
        Selection.reconcile(self.selectedSlot, state.inventory, state.slots, state.phase, self.busy)
    for index, cell in self.itemSlots do
        local item = state.inventory[index]
        local definition = itemDefinition(item)
        local locked = index > state.slots
        Theme.select(cell.button, self.selectedSlot == index, definition and C.panel or C.board)
        cell.name.TextColor3 = self.selectedSlot == index and C.ink or C.paper
        cell.number.TextColor3 = self.selectedSlot == index and C.ink or C.paper
        self:_mount(
            cell.viewport,
            locked and "lock" or (definition and item.id or "restock"),
            definition and item.level or 1
        )
        cell.viewport.ImageTransparency = not definition and not locked and 0.65 or 0
        cell.name.Text = locked and "5 COINS" or (definition and definition.name or "EMPTY")
        cell.level.Text = definition
                and (definition.evolved and "EVO" or ("L" .. tostring(item.level or 1)))
            or ""
    end
    self.inspector:refresh()
end

function Presentation:_renderCounters()
    local state = self.snapshot
    if not state then
        return
    end
    local overrides = self.counterOverrides
    local score = overrides.score or state.score or 0
    local quota = math.max(1, state.quota or 1)
    local layers =
        { C.mint, C.gold, C.blue, Color3.fromRGB(215, 132, 255), Color3.fromRGB(255, 141, 65) }
    local progress = CounterProgress.compute(score, quota, state.maxRestocks, #layers)
    local completed = progress.completed
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
    self.progressCaption.Text = progress.capped and "RESTOCK LIMIT" or "NEXT RESTOCK"
    self.fraction.Text = progress.capped and "FULL"
        or (Format.number(math.floor(progress.remainder + 0.5)) .. " / " .. Format.number(quota))
    self.progress.BackgroundColor3 = completed > 0 and layers[progress.previousLayer] or C.ink
    self.progressFill.BackgroundColor3 = layers[progress.nextLayer]
    self.progressFill.Size = UDim2.fromScale(progress.fraction, 1)
    self.scorePlate.BackgroundColor3 = C.paper
    self.restockPlate.BackgroundColor3 = C.paper
    self.restockHint.Text = restocks > 0 and "Ready to refill + merge your board!"
        or "Fill the meter to grow your board"
    for index, viewport in self.reserveIcons do
        viewport.ImageTransparency = index <= reserves and 0 or 0.78
    end
    for index, viewport in self.stackIcons do
        viewport.Visible = not self.compact and not self.lowDesktop and index <= restocks
    end
    local stage = state.stage
    if stage and state.stageCleared and state.stageCleared.index == stage.index then
        stage = state.stageCleared
    end
    if stage then
        self.roundLabel.Text = (self.compact and ("LV " .. stage.index .. " • ") or "ROUND ")
            .. tostring(state.round)
            .. " / "
            .. tostring(stage.targetRound)
        self.stageLabel.Text = "LEVEL "
            .. tostring(stage.index)
            .. " • "
            .. string.upper(stage.name)
        self.stageFill.Size = UDim2.fromScale(math.clamp(stage.progress or 0, 0, 1), 1)
        if self.boardArt and self.boardArt.setStage then
            self.boardArt:setStage(stage)
        end
    else
        self.roundLabel.Text = "ROUND " .. tostring(state.round)
        self.stageLabel.Text = "YOUR RUN"
        self.stageFill.Size = UDim2.fromScale(0, 1)
    end
    self.best.Text = "BEST ROUND " .. tostring(state.bestRound or 0)
    self.profile.Text = ({
        session = "RECORDS: STUDIO SESSION",
        saved = "CLOUD RECORDS ENABLED",
        unavailable = "SESSION RECORDS • CLOUD UNAVAILABLE",
    })[state.profileStatus] or "SESSION RECORDS"
    local held = not self.statsCleared and state.phase ~= "flight" and state.lastShotStats
    local stats = held or (not self.statsCleared and state.shotStats) or {}
    self.statsTitle.Text = (held and "LAST SHOT" or "THIS SHOT")
        .. "  •  ROUND "
        .. tostring(stats.round or state.round)
    local names = {
        pops = "Pops",
        walls = "Walls",
        doubles = "Doubles",
        halves = "Halves",
        quotas = "Quotas",
        time = "Time",
        first = "First hit",
        drain = "Drain",
        clear = "Clear",
        itemTriggers = "Items",
        perkTriggers = "Perks",
    }
    for field, text in self.statLabels do
        local value = stats[field] or 0
        text.Text = names[field]
            .. ": "
            .. (field == "time" and string.format("%.1fs", value) or Format.number(value))
    end
end

function Presentation:_renderControls()
    local state = self.snapshot
    if not state then
        return
    end
    local phase = state.phase
    self.swapHelp.Text = (phase == "aim" or phase == "shop")
            and "Click item: select / clear • Other slot: swap"
        or "Your equipment works together automatically"
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
    if state.stageCleared and (phase == "result" or phase == "victory") then
        self.phaseLabel.Text = "LEVEL " .. tostring(state.stageCleared.index) .. " COMPLETE!"
    end
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
        Theme.select(speedButton, (state.speed or 1) == value, speedButton.BackgroundColor3)
    end
end

function Presentation:_shopGeometry()
    local size = self.viewport or Vector2.new(1440, 900)
    local width = math.min(1380, size.X - 24)
    local top = self.inventory.Position.Y.Offset + self.inventory.Size.Y.Offset + 4
    return width, math.min(790, size.Y - top - 12), top
end

function Presentation:_buildShop(state)
    local width, height, top = self:_shopGeometry()
    local size = self.viewport or Vector2.new(1440, 900)
    local modal = plate(self.overlay, "Shop", C.panel, 22)
    self.modal = modal
    setRect(modal, (size.X - width) / 2, top, width, height)
    local supplies = math.min(2, math.max(0, #(state.shopOffers or {}) - 4))
    local layout = ShopLayout.compute(width, height, supplies)
    local function place(object, rect)
        setRect(object, rect.x, rect.y, rect.w, rect.h)
    end
    local shop = {
        cards = {},
        sections = {},
        layout = layout,
        width = width,
        height = height,
        top = top,
        count = 4 + supplies,
    }
    self.shop = shop
    shop.title = label(modal, "Title", "", 28, C.paper, 25)
    place(shop.title, layout.title)
    shop.title.Visible = layout.title.h > 0
    for kind, rect in layout.groups do
        local enclosure = plate(modal, string.upper(kind) .. "Enclosure", C.paper, 23)
        place(enclosure, rect)
        local section = label(modal, kind, string.upper(kind), height < 300 and 18 or 21, C.ink, 25)
        section.Font = Enum.Font.SourceSansBold
        place(section, layout.sections[kind])
        shop.sections[kind] = section
    end
    if layout.divider then
        local divider = frame(modal, "SectionDivider", C.paper, 24)
        place(divider, layout.divider)
    end
    for index, rect in layout.cards do
        local positions = ShopLayout.card(rect.w, rect.h, index > 4)
        local short = positions.short
        local card = plate(modal, "Offer" .. index, C.board, 25)
        place(card, rect)
        local inspect = make("TextButton", {
            Name = "Inspect",
            Text = "",
            AutoButtonColor = false,
            BorderSizePixel = 0,
            BackgroundTransparency = 1,
            ZIndex = 28,
        }, card)
        place(inspect, positions.inspect)
        inspect.Activated:Connect(function()
            self.selectedOffer = if self.selectedOffer == index then nil else index
            self.selectedSlot, self.selectedPerk = nil, nil
            self:_updateInventory()
            self:_updatePerks()
            self:_refreshShop(self.snapshot)
            local offer = self.snapshot.shopOffers[index]
            if self.selectedOffer and offer then
                self.inspector:show(offer.id, self:_offerLevel(offer), inspect, true)
            else
                self.inspector:hide()
            end
        end)
        self.inspector:bind(inspect, function()
            local offer = self.snapshot and self.snapshot.shopOffers[index]
            return offer and offer.id, offer and self:_offerLevel(offer) or 1
        end)
        local model = make(
            "ViewportFrame",
            { Name = "Item", BackgroundTransparency = 1, BorderSizePixel = 0, ZIndex = 29 },
            inspect
        )
        local name = label(inspect, "Name", "", short and 17 or 26, C.paper, 30)
        name.Font = Enum.Font.SourceSansBold
        name.TextWrapped, name.TextScaled = true, true
        make(
            "UITextSizeConstraint",
            { MinTextSize = short and 13 or 18, MaxTextSize = short and 18 or 28 },
            name
        )
        local trigger = label(inspect, "Trigger", "", 20, C.gold, 30)
        trigger.TextWrapped, trigger.TextScaled = true, true
        make("UITextSizeConstraint", { MinTextSize = 14, MaxTextSize = 22 }, trigger)
        trigger.TextXAlignment = Enum.TextXAlignment.Center
        local level = label(inspect, "Level", "", short and 12 or 15, C.gold, 31)
        level.Font = Enum.Font.SourceSansBold
        level.TextXAlignment = Enum.TextXAlignment.Right
        local evolutions = EvolutionDisplay.new(card, self, 28, true)
        local buy = button(card, "Buy", "", C.mint, function()
            local offer = self.snapshot and self.snapshot.shopOffers[index]
            if offer then
                self:_send("buy", { offer = index, itemId = offer.id })
            end
        end, 29)
        place(buy, positions.purchase)
        buy.TextSize = short and 18 or 23
        local priceGroup = frame(buy, "CenteredPrice", nil, 31)
        priceGroup.BackgroundTransparency = 1
        priceGroup.AnchorPoint = Vector2.new(0.5, 0)
        priceGroup.Position = UDim2.fromScale(0.5, 0)
        local price = label(priceGroup, "ActionPrice", "", short and 22 or 30, C.paper, 32)
        price.Font = Enum.Font.SourceSansBold
        price.TextXAlignment = Enum.TextXAlignment.Left
        price.TextStrokeTransparency = 0.55
        local coin = self:_viewport(priceGroup, "Coin", "coin", 1, 32)
        local hold
        if index <= 4 then
            hold = button(card, "Hold", "HOLD", C.panel, function()
                local offer = self.snapshot and self.snapshot.shopOffers[index]
                local definition = offer and Catalog.Items[offer.id]
                if offer then
                    self:_send(
                        definition and definition.evolved and "cycleEvolution" or "freeze",
                        { offer = index, itemId = offer.id }
                    )
                end
            end, 29)
            place(hold, positions.hold)
            hold.TextSize = short and 16 or 19
            hold.TextScaled = true
            make(
                "UITextSizeConstraint",
                { MinTextSize = 10, MaxTextSize = short and 16 or 19 },
                hold
            )
        end
        shop.cards[index] = {
            card = card,
            viewport = model,
            name = name,
            trigger = trigger,
            buy = buy,
            priceGroup = priceGroup,
            price = price,
            coin = coin,
            hold = hold,
            short = short,
            positions = positions,
            inspect = inspect,
            level = level,
            rect = rect,
            evolutions = evolutions,
        }
    end
    local footer, fw = layout.footer, (layout.footer.w - 16) / 3
    local function action(name, text, index, color, callback)
        local control = button(modal, name, text, color, callback, 28)
        setRect(control, footer.x + (index - 1) * (fw + 8), footer.y, fw, footer.h)
        control.TextSize = width < 650 and 17 or (height < 300 and 18 or 22)
        control.TextWrapped = true
        return control
    end
    shop.reroll = action("Reroll", "REROLL • 1 COIN", 1, C.gold, function()
        self:_send("reroll")
    end)
    shop.sell = action("Sell", "", 2, C.coral, function()
        local current = self.snapshot
        local selected = current and self.selectedSlot and current.inventory[self.selectedSlot]
        if selected and selected.id ~= "" then
            local slot = self.selectedSlot
            self.selectedSlot = nil
            self:_send("sell", { slot = slot })
        elseif current and current.slots < 7 then
            self:_send("buySlot")
        end
    end)
    action("Continue", "NEXT ROUND", 3, C.blue, function()
        self.statsCleared = true
        self.selectedSlot, self.selectedOffer, self.selectedPerk = nil, nil, nil
        self:_send("continue")
    end)
    self:_refreshShop(state)
end

function Presentation:_offerLevel(offer)
    local state = self.snapshot
    if not state or not offer then
        return 1
    end
    local definition = Catalog.Items[offer.id]
    if definition and definition.evolved then
        return Catalog.MaxLevel
    end
    local intent = Catalog.purchaseState(state.inventory, state.slots, offer, state.coins)
    if intent.action == "upgrade" then
        return math.max(1, intent.level - 1)
    end
    if intent.action == "maxLevel" then
        return Catalog.MaxLevel
    end
    if intent.action == "sold" then
        for slot = 1, state.slots do
            local item = state.inventory[slot]
            if item and item.id == offer.id then
                return item.level
            end
        end
    end
    return 1
end

function Presentation:_layoutShopCard(cell, data, recipeCount, canCycle)
    local rect = cell.rect
    local positions = ShopLayout.card(
        rect.w,
        rect.h,
        data.consumable or (data.evolved and not canCycle),
        recipeCount
    )
    cell.positions = positions
    local function place(object, area)
        setRect(object, area.x, area.y, area.w, area.h)
    end
    place(cell.inspect, positions.inspect)
    place(cell.buy, positions.purchase)
    if cell.hold then
        place(cell.hold, positions.hold)
    end
    local short, bandH = positions.short, positions.inspect.h
    local nameH = short and 26 or 48
    local triggerH = not data.consumable and (short and 0 or 36) or 0
    local modelH = math.max(20, bandH - nameH - triggerH - 10)
    local modelSize = math.min(rect.w - 12, modelH)
    setRect(cell.viewport, (rect.w - modelSize) / 2 - 3, 3, modelSize, modelH)
    setRect(cell.name, 5, modelH + 2, rect.w - 16, nameH)
    setRect(cell.trigger, 5, modelH + nameH + 5, rect.w - 16, triggerH)
    setRect(cell.level, 3, 0, rect.w - 16, short and 13 or 18)
    cell.trigger.Visible = triggerH > 0
    cell.level.Visible = bandH >= 70
    if short and bandH < 70 then
        local side = math.max(20, math.min(36, bandH - 2))
        setRect(cell.viewport, 1, (bandH - side) / 2, side, side)
        setRect(cell.name, side + 5, 0, rect.w - side - 14, bandH)
    end
end

function Presentation:_refreshShop(state)
    local shop = self.shop
    if not shop or not state then
        return
    end
    shop.title.Text = "UPGRADE SHOP   •   " .. Format.integer(state.coins) .. " COINS"
    shop.sections.items.Text = shop.height < 300
            and ("ITEMS   •   " .. Format.integer(state.coins) .. " COINS")
        or "ITEMS"
    local displayed = {}
    for _, offer in state.shopOffers or {} do
        displayed[offer.id] = true
    end
    local hiddenEvolution = false
    for _, id in state.evolutionChoices or {} do
        if not displayed[id] then
            hiddenEvolution = true
            break
        end
    end
    for index, cell in shop.cards do
        local offer = state.shopOffers[index]
        local data = offer and Catalog.Items[offer.id]
        if data then
            local selected = self.selectedOffer == index
            Theme.select(cell.card, selected, C.board)
            local level = self:_offerLevel(offer)
            local detail = Catalog.detail(offer.id, level)
            local recipes = detail.evolutions or {}
            self:_layoutShopCard(cell, data, #recipes, hiddenEvolution)
            cell.name.Text, cell.trigger.Text = data.name, detail.trigger
            cell.name.TextColor3 = selected and C.ink or C.paper
            cell.trigger.TextColor3 = selected and C.board or C.gold
            cell.level.TextColor3 = selected and C.board or C.gold
            cell.level.Text = data.evolved and "EVOLVED"
                or (data.consumable and "SUPPLY" or ("L" .. level .. "/5"))
            self:_mount(cell.viewport, offer.id, level)
            cell.evolutions:update(offer.id, cell.positions.evolutions, selected)
            local intent = Catalog.purchaseState(state.inventory, state.slots, offer, state.coins)
            local verb = ({ purchase = "", upgrade = "Upgrade ", use = "Use " })[intent.action]
            cell.buy.Text = ({
                maxLevel = "MAX LEVEL",
                full = "RACK FULL",
                sold = "SOLD",
                unavailable = "UNAVAILABLE",
                ingredients = "NEED TWO L5",
                evolve = "EVOLVE",
            })[intent.action] or ""
            Theme.setEnabled(cell.buy, intent.allowed, C.mint)
            cell.priceGroup.Visible = verb ~= nil
            if verb then
                local text = verb .. tostring(intent.price)
                local fontSize = cell.short and 22 or 30
                local coinSize = math.min(48, cell.positions.purchase.h - 4)
                local gap = cell.short and 1 or 3
                local available = cell.positions.purchase.w - 8
                local measured = TextService:GetTextSize(
                    text,
                    fontSize,
                    Enum.Font.SourceSansBold,
                    Vector2.new(1000, 100)
                )
                while fontSize > 16 and measured.X + gap + coinSize > available do
                    fontSize -= 1
                    measured = TextService:GetTextSize(
                        text,
                        fontSize,
                        Enum.Font.SourceSansBold,
                        Vector2.new(1000, 100)
                    )
                end
                cell.price.Text, cell.price.TextSize = text, fontSize
                cell.priceGroup.Size =
                    UDim2.fromOffset(measured.X + gap + coinSize, cell.positions.purchase.h)
                setRect(cell.price, 0, 0, measured.X + 1, cell.positions.purchase.h)
                setRect(
                    cell.coin,
                    measured.X + gap,
                    (cell.positions.purchase.h - coinSize) / 2,
                    coinSize,
                    coinSize
                )
                cell.price.TextTransparency = intent.allowed and 0 or 0.2
            end
            if cell.hold then
                cell.hold.Visible = not data.evolved or hiddenEvolution
                cell.hold.Text = data.evolved and "OTHER EVOLUTION"
                    or (offer.frozen and "HELD" or "HOLD")
                Theme.setEnabled(cell.hold, not offer.sold, C.panel)
                Theme.select(
                    cell.hold,
                    not data.evolved and offer.frozen and not offer.sold,
                    cell.hold.BackgroundColor3
                )
            end
        end
    end
    Theme.setEnabled(shop.reroll, (state.rerollsLeft or 0) > 0 and state.coins >= 1, C.gold)
    local selected = self.selectedSlot and state.inventory[self.selectedSlot]
    local occupied = selected and selected.id ~= ""
    shop.sell.Text = occupied and "SELL ITEM"
        or (state.slots < 7 and "+ SLOT • 5" or "SELECT TO SELL")
    Theme.setEnabled(shop.sell, occupied or (state.slots < 7 and state.coins >= 5), C.coral)
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
    if phase == "shop" then
        local width, height, top = self:_shopGeometry()
        local count = math.min(6, #(state.shopOffers or {}))
        if
            self.shop
            and self.modal
            and self.shop.width == width
            and self.shop.height == height
            and self.shop.top == top
            and self.shop.count == count
        then
            self:_refreshShop(state)
        else
            if self.modal then
                self:_dropModels(self.modal)
                self.modal:Destroy()
            end
            self.shop = nil
            self:_buildShop(state)
        end
        self.modalKey = nil
        return
    end
    local parts = {
        phase,
        tostring(state.round),
        tostring(state.coins),
        tostring(state.slots),
        tostring(state.rerollsLeft),
        tostring(self.selectedSlot),
        tostring(self.selectedOffer),
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
    self.shop = nil
    self.inspector:hide()
    local size = self.viewport or Vector2.new(1440, 900)
    local width = math.min(1160, size.X - 28)
    local top = self.inventory.AbsolutePosition.Y
        + self.inventory.AbsoluteSize.Y
        - self.overlay.AbsolutePosition.Y
        + 14
    local height = math.min(680, size.Y - top - 18)
    local modal = plate(self.overlay, "Choices", C.paper, 22)
    self.modal = modal
    setRect(modal, (size.X - width) / 2, top, width, height)
    local title = label(modal, "Title", "", width < 500 and 26 or 36, C.ink, 25)
    if self.shortWide then
        title.TextSize = 28
    end
    setRect(title, 16, self.shortWide and 8 or 9, width - 32, self.shortWide and 32 or 43)
    local subtitle = label(modal, "Subtitle", "", 21, C.board, 25)
    subtitle.TextWrapped = true
    setRect(subtitle, 16, self.shortWide and 44 or 55, width - 32, self.shortWide and 22 or 47)
    local tinyChoice = (phase == "perk" or phase == "event") and height < 280
    if tinyChoice then
        title.TextSize = 24
        setRect(title, 12, 2, width - 24, 30)
        subtitle.Visible = false
    end
    local bodyTop = tinyChoice and 36 or (self.shortWide and 70 or 112)
    local footerY = height - (tinyChoice and 44 or (self.shortWide and 54 or 67))
    local body = make("ScrollingFrame", {
        Name = "Content",
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ScrollBarThickness = 6,
        ScrollBarImageColor3 = C.paper,
        CanvasSize = UDim2.fromOffset(0, 0),
        ScrollingDirection = Enum.ScrollingDirection.Y,
        ZIndex = 24,
    }, modal)
    setRect(
        body,
        14,
        bodyTop,
        width - 28,
        math.max(50, footerY - bodyTop - (tinyChoice and 8 or (self.shortWide and 10 or 13)))
    )
    local function action(name, text, x, buttonWidth, color, callback)
        local result = button(modal, name, text, color, callback, 27)
        setRect(result, x, footerY, buttonWidth, tinyChoice and 36 or (self.shortWide and 42 or 51))
        result.TextSize = width < 650 and 18 or 24
        result.TextWrapped = true
        return result
    end
    if phase == "perk" or phase == "event" then
        title.Text = phase == "perk" and "CHOOSE YOUR PERK"
            or (state.eventTitle or "CHOOSE YOUR REWARD")
        subtitle.Text = "Make your next combo even stronger. Pick one."
        local choices = phase == "perk" and state.perkOffers or state.eventChoices
        body.ScrollingEnabled = false
        body.ScrollBarThickness = 0
        if phase == "event" then
            body.Size = UDim2.fromOffset(width - 28, height - bodyTop - 8)
        else
            action(
                "SkipPerk",
                "TAKE " .. tostring(state.perkSkipCoins or 5) .. " COINS INSTEAD",
                14,
                width - 28,
                C.gold,
                function()
                    self:_send("skipPerk")
                end
            )
        end
        local cards = ChoiceLayout.compute(body.Size.X.Offset, body.Size.Y.Offset, #(choices or {}))
        for index, choice in choices or {} do
            local id = type(choice) == "table" and choice.id or choice
            local data = phase == "perk" and Catalog.Perks[id] or choice
            local card = plate(body, "Choice" .. index, C.muted, 25)
            if phase == "perk" then
                self.inspector:bind(card, function()
                    return id, 1
                end)
            end
            local rect = cards[index]
            setRect(card, rect.x, rect.y, rect.w, rect.h)
            local positions = ChoiceLayout.card(rect.w, rect.h, phase == "perk")
            local function place(object, area)
                setRect(object, area.x, area.y, area.w, area.h)
            end
            local model = self:_viewport(card, "Reward", id, 1, 27)
            place(model, positions.model)
            local name = label(card, "Name", data.name, positions.nameFont, C.ink, 28)
            name.Font = Enum.Font.SourceSansBold
            name.TextXAlignment = positions.stacked and Enum.TextXAlignment.Center
                or Enum.TextXAlignment.Left
            name.TextWrapped, name.TextScaled = true, true
            make(
                "UITextSizeConstraint",
                { MinTextSize = positions.tight and 16 or 18, MaxTextSize = positions.nameFont },
                name
            )
            place(name, positions.name)
            local detail = phase == "perk" and Catalog.detail(id, 1)
            if detail then
                local trigger =
                    label(card, "Trigger", detail.trigger, positions.triggerFont, C.trigger, 28)
                trigger.Font = Enum.Font.SourceSansBold
                trigger.TextWrapped, trigger.TextScaled = true, true
                make(
                    "UITextSizeConstraint",
                    { MinTextSize = 14, MaxTextSize = positions.triggerFont },
                    trigger
                )
                trigger.TextXAlignment = positions.stacked and Enum.TextXAlignment.Center
                    or Enum.TextXAlignment.Left
                place(trigger, positions.trigger)
            end
            local effect = detail and detail.effects[1]
            local description = label(
                card,
                "Effect",
                effect and effect.text or data.description,
                positions.effectFont,
                id == "overtime" and C.negative or C.positive,
                28
            )
            description.TextWrapped, description.TextScaled = true, true
            make(
                "UITextSizeConstraint",
                { MinTextSize = positions.tight and 14 or 17, MaxTextSize = positions.effectFont },
                description
            )
            description.TextXAlignment = positions.stacked and Enum.TextXAlignment.Center
                or Enum.TextXAlignment.Left
            description.TextYAlignment = Enum.TextYAlignment.Center
            place(description, positions.effect)
            local choose = button(card, "Choose", "CHOOSE", C.mint, function()
                self:_send(phase == "perk" and "choosePerk" or "chooseEvent", { index = index })
            end, 29)
            place(choose, positions.choose)
            choose.TextSize = positions.tight and 20 or 27
        end
        body.CanvasSize = UDim2.fromOffset(0, body.Size.Y.Offset)
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
            C.ink,
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
            C.board,
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

function Presentation:_layoutSettlement()
    local camera = workspace.CurrentCamera
    if not camera or not self.boardArt then
        return
    end
    local size = self.viewport or camera.ViewportSize
    if size.X < 32 or size.Y < 48 then
        return
    end
    if self.cameraCFrame then
        camera.CameraType = Enum.CameraType.Scriptable
        camera.FieldOfView = 35
        camera.CFrame = self.cameraCFrame
    end
    local first = camera:WorldToViewportPoint(self.boardArt.screenCorners.topLeft)
    local last = camera:WorldToViewportPoint(self.boardArt.screenCorners.bottomRight)
    local width, height = math.abs(last.X - first.X), math.abs(last.Y - first.Y)
    local compact = width < 118
    local safeTop = math.clamp(self.safeTop or 8, 8, math.max(8, size.Y - 40))
    local w = math.clamp(math.max(compact and 138 or 0, width), 16, math.max(16, size.X - 16))
    local h =
        math.clamp(math.max(compact and 42 or 0, height), 20, math.max(20, size.Y - safeTop - 8))
    local x = math.clamp(last.X - w, 8, math.max(8, size.X - w - 8))
    local y = math.clamp(first.Y, safeTop, math.max(safeTop, size.Y - h - 8))
    setRect(self.settlement, x, y, w, h)
    self.settlement.BackgroundTransparency = compact and 0 or 1
    self.settlementOutline.Transparency = compact and 0 or 1
    self.settlementText.TextScaled = true
    setRect(self.settlementText, 4, 2, w - 8, h - 10)
    self.settlementProgress.Position = UDim2.fromOffset(4, h - 5)
    self.settlementProgress.Size =
        UDim2.new(self.settlementFraction or 0, -8 * (self.settlementFraction or 0), 0, 3)
    setRect(self.skipButton, math.max(0, w - 65), h + 5, 65, 28)
    self.skipButton.TextSize = 16
end

function Presentation:setSettlement(text, progress, canSkip)
    self.settlement.Visible = type(text) == "string" and text ~= ""
    self.settlementFraction = math.clamp(progress or 0, 0, 1)
    self.settlementText.Text =
        self.boardArt:setStatus(text, progress, self.settlement.Visible, canSkip)
    self.skipButton.Visible = canSkip == true
    self:_layoutSettlement()
end

function Presentation:pulseItem(slot, strength, params)
    local cell = self.itemSlots[slot]
    if cell then
        local mounted = self.models[cell.viewport]
        if mounted then
            mounted.handle:pulse(strength or 1, params)
        end
        cell.flash = 0.3
    end
end

function Presentation:pulseScore(strength)
    self:pulseCounter("score", strength)
end

function Presentation:setBusy(active)
    local changed = self.busy ~= (active == true)
    self.busy = active == true
    if changed then
        self:_updateInventory()
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
    self.pendingMove = Selection.reconcileMove(self.pendingMove, snapshot, os.clock())
    if previous and (snapshot.round < previous.round or snapshot.seed ~= previous.seed) then
        self.selectedSlot = nil
        self.counterOverrides = {}
        self.statsCleared = false
        self.selectedOffer = nil
        self.pendingMove = nil
    end
    self.snapshot = snapshot
    if previous and previous.phase ~= snapshot.phase then
        self.selectedPerk = nil
        self.inspector:hide()
    end
    if snapshot.phase == "flight" then
        self.statsCleared = false
    end
    self.receivedAt = os.clock()
    self.loading.Visible = false
    self:_updatePerks()
    self.feedback:update(snapshot)
    if not previous or previous.phase ~= snapshot.phase then
        self:_layout()
    end
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
    self.inspector:step()
    local reduced = game:GetService("GuiService").ReducedMotionEnabled
    for kind, scale in
        { score = self.scoreScale, coins = self.coinScale, restocks = self.restockScale }
    do
        local pulse = self.counterPulses[kind]
        if pulse then
            pulse.remaining = math.max(0, pulse.remaining - dt)
            scale.Scale = reduced and 1
                or 1 + math.sin(pulse.remaining / 0.26 * math.pi) * 0.045 * pulse.strength
            if pulse.remaining == 0 then
                self.counterPulses[kind] = nil
            end
        else
            scale.Scale = 1
        end
    end
    for viewport, mounted in self.models do
        if
            viewport.Visible
            and (not self.modal or not viewport:IsDescendantOf(self.modal) or self.overlay.Visible)
        then
            mounted.handle:step(dt)
        end
    end
    for id, cell in self.perkCells do
        cell.flash = math.max(0, cell.flash - dt)
        if cell.button.Visible then
            local border = cell.button:FindFirstChildWhichIsA("UIStroke")
            border.Color = cell.flash > 0 and C.gold
                or (self.selectedPerk == id and C.gold or C.edge)
            border.Thickness = (cell.flash > 0 or self.selectedPerk == id) and 5 or 2
        end
    end
    if os.clock() >= (self.perkUntil or 0) then
        self.perksStatus.Text = "RUN BONUSES"
    end
    for index, cell in self.itemSlots do
        cell.flash = math.max(0, (cell.flash or 0) - dt)
        if cell.flash > 0 then
            cell.border.Color = C.gold
            cell.border.Thickness = 5
        else
            cell.border.Color = self.selectedSlot == index and C.gold or C.edge
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
        counterPulses = {},
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
