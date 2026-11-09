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
local ItemModels = require(script.Parent.GameItemModels)
local Feedback = require(script.Parent.Feedback)
local Selection = require(script.Parent.InventorySelection)
local ShopLayout = require(script.Parent.ShopLayout)
local ShopView = require(script.Parent.ShopView)
local ChoiceLayout = require(script.Parent.ChoiceLayout)
local CounterProgress = require(script.Parent.CounterProgress)
local HoverInspector = require(script.Parent.HoverInspector)
local BoardArt = require(script.Parent.BoardArt)
local RunLayout = require(script.Parent.RunLayout)

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
local heading = Theme.heading
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
    local animate = Catalog.Items[id] ~= nil
        or Catalog.Perks[id] ~= nil
        or ({ coins = true, grow = true, repair = true, upgrade = true, overtime = true })[id]
            == true
    local reduced = game:GetService("GuiService").ReducedMotionEnabled
    local outline = viewport:GetAttribute("NoOutline") ~= true
    local idlePreview = viewport:GetAttribute("ShopPreview") == true
    local key = tostring(id)
        .. ":"
        .. tostring(level or 1)
        .. ":"
        .. tostring(animate)
        .. ":"
        .. tostring(reduced)
        .. ":"
        .. tostring(outline)
        .. ":"
        .. tostring(idlePreview)
    local current = self.models[viewport]
    if current and current.key == key then
        return
    end
    if current then
        current.handle:destroy()
    end
    self.models[viewport] = {
        key = key,
        handle = ItemModels.mount(viewport, id, level or 1, {
            animate = animate,
            reducedMotion = reduced,
            outline = outline,
            idlePreview = idlePreview,
        }),
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
    self.detailsPanel = plate(self.root, "RunDetails", C.paper, 65)
    blockAim(self.detailsPanel)
    self.detailsPanel.Visible = false
    self.detailsTitle = label(self.detailsPanel, "Title", "SHOT STATS & PERKS", 21, C.ink, 67)
    self.detailsClose = button(self.detailsPanel, "Close", "×", C.ice, function()
        self.detailsOpen = false
        self:_layout()
    end, 69)
    self.detailsTab = button(self.detailsPanel, "Tab", "PERKS", C.muted, function()
        self.detailsTabMode = self.detailsTabMode == "perks" and "stats" or "perks"
        self:_layout()
    end, 69)
    self.detailsButton = button(self.root, "Details", "STATS", C.paper, function()
        self.detailsOpen = not self.detailsOpen
        self:_layout()
    end, 9)
    self.rackToggle = button(self.root, "RackToggle", "RACK", C.paper, function()
        self.shopRackOpen = not self.shopRackOpen
        self:_layout()
        self:_updateModal()
    end, 40)
    self.rackToggle.TextColor3 = C.ink
    self.rackToggle.TextStrokeTransparency = 1
    self.rackToggle.Visible = false
    self.brand = heading(self.root, "Brand", "POP A PEG", 37, C.paper, 5)
    self.brand.TextStrokeTransparency = 0.2
    self.tag = label(self.root, "Tag", "BUILD A BIGGER BOUNCE!", 18, C.gold, 5)
    self.roundPlate = plate(self.root, "RoundPlate", C.paper, 3)
    blockAim(self.roundPlate)
    self.roundLabel = heading(self.roundPlate, "Round", "ROUND 1", 30, C.ink, 5)
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
    self.swapHelp.TextColor3 = C.paper
    self.swapHelp.BackgroundTransparency = 0
    Theme.decorate(self.swapHelp, C.ink, 31)
    make("UITextSizeConstraint", { MinTextSize = 14, MaxTextSize = 18 }, self.swapHelp)
    self.itemSlots = {}
    for index = 1, 7 do
        local cell = button(self.inventory, "Slot" .. index, "", C.ice, function()
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
            if self.selectedSlot == index and item and item.id ~= "" and not self.shopRackOpen then
                self.inspector:show(item.id, item.level, self.itemSlots[index].button, true)
            else
                self.inspector:hide()
            end
        end, 32)
        local border = cell:FindFirstChildWhichIsA("UIStroke")
        local model = self:_viewport(cell, "Equipment", index <= 4 and "restock" or "lock", 1, 34)
        local number = label(cell, "Position", tostring(index), 18, C.ink, 36)
        local level = label(cell, "Level", "", 18, C.board, 36)
        level.TextXAlignment = Enum.TextXAlignment.Right
        local name = label(cell, "Name", index <= 4 and "EMPTY" or "5 COINS", 18, C.ink, 36)
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
        end, { rack = true })
    end

    self.left = frame(self.root, "Resources", nil, 2)
    self.left.BackgroundTransparency = 1
    self.wallet = plate(self.left, "Wallet", C.paper, 3)
    self.coinScale = make("UIScale", { Scale = 1 }, self.wallet)
    blockAim(self.wallet)
    self.coinModel = self:_viewport(self.wallet, "Coin", "coin", 1, 5)
    self.coinModel:SetAttribute("ShopPreview", true)
    self:_mount(self.coinModel, "coin", 1)
    self.coinCaption = heading(self.wallet, "Caption", "COINS", 22, C.board, 5)
    self.coins = heading(self.wallet, "Amount", "0", 56, C.ink, 5)
    self.reservePlate = plate(self.left, "ReserveRack", C.paper, 3)
    blockAim(self.reservePlate)
    self.reserveCaption = heading(self.reservePlate, "Caption", "BALLS LEFT", 22, C.ink, 5)
    self.reserves = heading(self.reservePlate, "Count", "5 / 5", 28, C.ink, 5)
    self.reserves.TextXAlignment = Enum.TextXAlignment.Right
    self.reserveIcons = {}
    for index = 1, 5 do
        self.reserveIcons[index] = self:_viewport(self.reservePlate, "Ball" .. index, "ball", 1, 5)
        self.reserveIcons[index]:SetAttribute("ShopPreview", true)
        self:_mount(self.reserveIcons[index], "ball", 1)
    end
    self.stats = label(self.left, "ShotStats", "0 POPS   0 WALLS", 19, C.paper, 5)
    self.timer = label(self.left, "Time", "00:00.00", 18, C.muted, 5)
    self.statsPanel = plate(self.root, "TriggerCounts", C.paper, 5)
    blockAim(self.statsPanel)
    self.statsTitle = Theme.ribbon(self.statsPanel, "Title", "THIS SHOT", 18, 7)
    self.statsTitle.TextScaled = true
    make("UITextSizeConstraint", { MinTextSize = 11, MaxTextSize = 18 }, self.statsTitle)
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
        self.statLabels[field] = label(self.statsPanel, field, "", 18, C.ink, 7)
    end

    self.right = frame(self.root, "ScoreTower", nil, 2)
    self.right.BackgroundTransparency = 1
    self.scorePlate = plate(self.right, "Score", C.paper, 3)
    blockAim(self.scorePlate)
    self.scoreScale = make("UIScale", { Scale = 1 }, self.scorePlate)
    self.scoreCaption = Theme.ribbon(self.scorePlate, "Caption", "SHOT SCORE", 23, 5)
    self.score = label(self.scorePlate, "Total", "0", 60, C.ink, 5)
    self.score.Font = Enum.Font.FredokaOne
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
    self.restockCaption = Theme.ribbon(self.restockPlate, "Caption", "RESTOCKS EARNED", 20, 5)
    self.restockCount = heading(self.restockPlate, "Count", "×0", 55, C.ink, 5)
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
    self.perksTitle.Font = Enum.Font.FredokaOne
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

    self.controls = plate(self.root, "Controls", C.paper, 10)
    blockAim(self.controls)
    self.jumbleButton = button(self.controls, "Jumble", "JUMBLE", C.blue, function()
        self:_send("jumble")
    end, 12)
    self.primary = button(self.controls, "Launch", "LAUNCH!", C.mint, function()
        self:_primaryAction()
    end, 12)
    self.speedButtons = {}
    self.speedGroup = plate(self.root, "SpeedControls", C.paper, 10)
    blockAim(self.speedGroup)
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
    self.soundButton = button(self.root, "Sound", "", C.ice, function()
        self.muted = not self.muted
        self.soundSlash.Visible = self.muted
        self.soundButton:SetAttribute("Muted", self.muted)
        if self.feedback then
            self.feedback:setMuted(self.muted)
        end
    end, 12)
    local music = frame(self.soundButton, "Music", nil, 14)
    music.BackgroundTransparency = 1
    music.Size, music.Position = UDim2.fromScale(0.68, 0.68), UDim2.fromScale(0.16, 0.16)
    for _, notePart in
        {
            { "StemLeft", 0.38, 0.20, 0.09, 0.56, 0 },
            { "StemRight", 0.73, 0.12, 0.09, 0.56, 0 },
            { "Beam", 0.38, 0.16, 0.44, 0.11, -12 },
            { "NoteLeft", 0.14, 0.65, 0.32, 0.22, -20 },
            { "NoteRight", 0.49, 0.57, 0.32, 0.22, -20 },
        }
    do
        local glyph = frame(music, notePart[1], C.ink, 14)
        glyph.Position, glyph.Size =
            UDim2.fromScale(notePart[2], notePart[3]), UDim2.fromScale(notePart[4], notePart[5])
        glyph.Rotation = notePart[6]
        corner(glyph, 8)
    end
    self.soundSlash = frame(self.soundButton, "MutedSlash", C.negative, 15)
    self.soundSlash.AnchorPoint = Vector2.new(0.5, 0.5)
    self.soundSlash.Position = UDim2.fromScale(0.5, 0.5)
    self.soundSlash.Size = UDim2.new(0.84, 0, 0, 4)
    self.soundSlash.Rotation = -45
    self.soundSlash.Visible = false
    corner(self.soundSlash, 2)
    self.help = label(self.root, "Help", "AIM • CLICK THE BOARD OR PRESS SPACE", 18, C.paper, 12)
    self.help.TextColor3 = C.ink
    self.help.BackgroundTransparency = 0
    Theme.decorate(self.help, C.paper, 12)
    self.help.TextXAlignment = Enum.TextXAlignment.Center
    self.notice = label(self.root, "Notice", "", 24, C.gold, 70)
    self.notice.TextXAlignment = Enum.TextXAlignment.Center
    self.notice.TextWrapped = true
    self.notice.Visible = false
    self.notice.TextColor3 = C.ink
    self.notice.BackgroundTransparency = 0
    Theme.decorate(self.notice, C.paper, 70)
    self.settlement = plate(self.root, "Settlement", C.board, 55)
    self.settlement.BackgroundTransparency = 1
    self.settlementOutline = self.settlement:FindFirstChildWhichIsA("UIStroke")
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
    local screen = camera.ViewportSize
    local guiService = game:GetService("GuiService")
    local full = guiService:GetInsetArea(Enum.ScreenInsets.None)
    local safe = guiService:GetInsetArea(Enum.ScreenInsets.CoreUISafeInsets)
    local origin = safe.Min - full.Min
    local size = safe.Max - safe.Min
    self.screenViewport, self.viewport, self.safeOrigin = screen, size, origin
    self.safeArea = safe
    self.fullArea = full
    self.root.Position, self.root.Size =
        UDim2.fromOffset(origin.X, origin.Y), UDim2.fromOffset(size.X, size.Y)
    local w, h = size.X, size.Y
    local top = 8
    self.safeTop = top
    self.mobile = w < 850 and h > w * 0.8
    self.shortWide = (h < 620 or w < 1100) and not self.mobile
    self.compact = self.mobile or self.shortWide
    self.foldHud = self.mobile or (self.shortWide and h < 450)
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
    self.restockCaption.Visible = true
    self.restockHint.Visible, self.restockModel.Visible = not compact, not compact
    self.best.Visible, self.profile.Visible = not compact and h >= 1040, not compact and h >= 1040
    self.stats.Visible, self.timer.Visible = false, false
    self.statsPanel.Visible = true
    self.perksPanel.Visible = true
    if choosing then
        self.detailsOpen = false
    end
    self.statsPanel.Parent, self.perksPanel.Parent = self.root, self.root
    self.detailsPanel.Visible, self.detailsButton.Visible, self.rackToggle.Visible =
        false, false, false
    self.inventory.Visible, self.swapHelp.Visible = true, true
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
                    math.min(88, h - 132 - resourceTop - 150)
                )
            end
            setRect(self.statsPanel, 12, statsY, uiX - 26, 100)
            local cw = uiW
            setRect(self.controls, uiX, h - 66, cw, 50)
            setRect(self.jumbleButton, 0, 0, cw * 0.4 - 4, 50)
            setRect(self.primary, cw * 0.4 + 4, 0, cw * 0.6 - 4, 50)
            for index, speedButton in self.speedButtons do
                setRect(speedButton, w - 159 + (index - 1) * 50, h - 121, 44, 44)
            end
            setRect(self.soundButton, uiX, h - 121, 44, 44)
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
        local g = RunLayout.desktop(w, h)
        local function place(object, area)
            setRect(object, area.x, area.y, area.w, area.h)
        end
        invWidth, invHeight = g.rack.w, g.rack.h
        place(self.inventory, g.rack)
        setRect(self.swapHelp, g.rack.x, g.rack.y + g.rack.h + 6, g.rack.w, 20)
        local brandW = math.max(110, g.rack.x - 32)
        setRect(self.brand, 22, 14, brandW, 48)
        self.brand.TextScaled = true
        self.brand.TextSize = 37
        setRect(self.tag, 22, 66, brandW, 24)
        self.tag.Visible = w >= 1400
        self.tag.TextSize = 15
        place(self.roundPlate, g.round)
        local rw, rh = g.round.w, g.round.h
        setRect(self.stageLabel, 12, 5, rw - 24, 18)
        setRect(self.roundLabel, 12, 24, rw - 24, rh >= 80 and 32 or 25)
        self.roundLabel.TextSize = rh >= 80 and 30 or 24
        self.roundLabel.TextXAlignment = Enum.TextXAlignment.Left
        self.phaseLabel.Visible = rh >= 90
        setRect(self.phaseLabel, 12, 57, rw - 24, 20)
        setRect(self.stageProgress, 12, rh - 9, rw - 24, 4)
        setRect(self.left, 0, 0, w, h)
        place(self.wallet, g.wallet)
        local lw, wh = g.wallet.w, g.wallet.h
        setRect(self.coinModel, 5, 3, wh - 6, wh - 6)
        setRect(self.coinCaption, wh + 2, 9, lw - wh - 12, 25)
        setRect(self.coins, wh + 2, 32, lw - wh - 12, wh - 38)
        self.coins.TextSize = 48
        place(self.reservePlate, g.balls)
        local bh = g.balls.h
        setRect(self.reserveCaption, 10, 5, lw - 90, 26)
        self.reserveCaption.Text, self.reserveCaption.TextSize = "BALLS LEFT", 21
        setRect(self.reserves, lw - 76, 5, 66, 26)
        self.reserves.TextSize = 25
        for index, icon in self.reserveIcons do
            icon.Visible = true
            setRect(icon, 7 + (index - 1) * ((lw - 14) / 5), 31, (lw - 14) / 5, bh - 35)
        end
        place(self.statsPanel, g.stats)
        setRect(self.right, 0, 0, w, h)
        place(self.scorePlate, g.score)
        local sw, sh = g.score.w, g.score.h
        setRect(self.scoreCaption, 12, 7, sw - 24, 26)
        self.scoreCaption.Text, self.scoreCaption.TextSize = "SHOT SCORE", 22
        local numberH = sh >= 170 and 52 or math.min(32, sh - 99)
        setRect(self.score, 14, 34, sw - 28, numberH)
        setRect(self.quota, 14, 35 + numberH, sw - 28, 24)
        self.quota.TextXAlignment = Enum.TextXAlignment.Left
        self.progressCaption.Visible = sh >= 190
        setRect(self.progressCaption, 14, sh - 75, sw - 28, 22)
        setRect(self.progress, 14, sh - (sh >= 170 and 48 or 35), sw - 28, sh >= 170 and 36 or 27)
        place(self.restockPlate, g.restocks)
        local restH = g.restocks.h
        setRect(self.restockCaption, 10, 5, sw - 20, 24)
        self.restockCaption.TextSize = 19
        self.restockCaption.TextXAlignment = Enum.TextXAlignment.Center
        setRect(self.restockModel, 9, 28, math.min(84, restH - 30), restH - 31)
        setRect(self.restockCount, 94, 28, sw - 104, restH - 32)
        self.restockCount.TextSize = restH >= 90 and 48 or 32
        self.restockCount.TextXAlignment = Enum.TextXAlignment.Left
        self.restockHint.Visible = false
        for _, icon in self.stackIcons do
            icon.Visible = false
        end
        place(self.perksPanel, g.perks)
        self.best.Visible, self.profile.Visible = false, false
        boardRect = g.board
        place(self.controls, g.controls)
        setRect(self.jumbleButton, 8, 8, (g.controls.w - 24) * 0.38, 56)
        setRect(self.primary, 16 + (g.controls.w - 24) * 0.38, 8, (g.controls.w - 24) * 0.62, 56)
        self.primary.TextSize, self.jumbleButton.TextSize = 32, 25
        for index, speedButton in self.speedButtons do
            local cellW = (g.speeds.w - 32) / 3
            setRect(
                speedButton,
                g.speeds.x + 8 + (index - 1) * (cellW + 8),
                g.speeds.y + 8,
                cellW,
                56
            )
            speedButton.TextSize = 28
        end
        place(self.soundButton, g.sound)
        setRect(self.help, boardRect.x, h - 19, boardRect.w, 16)
    end
    -- Keep session navigation beside, rather than over, the rack instructions.
    local navigationWidth = math.min(112, invWidth * 0.28)
    self.sessionNavigation = {
        x = self.swapHelp.Position.X.Offset + invWidth - navigationWidth,
        y = self.swapHelp.Position.Y.Offset,
        w = navigationWidth,
        h = 20,
    }
    self.swapHelp.Size = UDim2.fromOffset(invWidth - navigationWidth - 8, 20)
    if self.foldHud then
        local layout = self.mobile and RunLayout.portrait(w, h) or RunLayout.landscape(w, h)
        self.phoneLayout = layout
        local function place(object, area)
            setRect(object, area.x, area.y, area.w, area.h)
        end
        place(self.roundPlate, layout.round)
        setRect(self.roundLabel, 4, 0, layout.round.w - 8, 44)
        self.roundLabel.TextSize = 19
        invWidth, invHeight = layout.rack.w, layout.rack.h
        place(self.inventory, layout.rack)
        self.swapHelp.Visible = false
        self.sessionNavigation = layout.navigation
        place(self.left, layout.resources)
        local half = (layout.resources.w - 6) / 2
        local resourceH = layout.resources.h
        setRect(self.wallet, 0, 0, half, resourceH)
        setRect(self.coinModel, 0, -1, resourceH + 2, resourceH + 2)
        setRect(self.coins, 34, 0, half - 38, resourceH)
        self.coins.TextSize = 24
        setRect(self.reservePlate, half + 6, 0, half, resourceH)
        setRect(self.reserveCaption, 6, 0, 54, resourceH)
        self.reserveCaption.TextSize = 15
        setRect(self.reserves, 62, 0, half - 68, resourceH)
        self.reserves.TextSize = 21
        place(self.right, layout.score)
        local scoreH = layout.score.h
        local tightScore = scoreH < 50
        local numberH, progressY = tightScore and 20 or 26, tightScore and 22 or 29
        setRect(self.scorePlate, 0, 0, layout.score.w, scoreH)
        setRect(self.scoreCaption, 7, 0, 45, numberH)
        self.scoreCaption.TextSize = 15
        setRect(self.score, 54, 0, layout.score.w - 178, numberH)
        setRect(self.quota, layout.score.w - 119, 0, 112, numberH)
        setRect(self.progress, 7, progressY, layout.score.w - 94, scoreH - progressY - 3)
        setRect(self.restockPlate, layout.score.w - 81, progressY - 2, 75, scoreH - progressY)
        setRect(self.restockCaption, 1, 0, 73, 12)
        self.restockCaption.TextSize = 11
        self.restockCaption.Visible = not tightScore
        setRect(self.restockCount, 1, tightScore and 0 or 11, 73, 18)
        self.restockCount.TextSize = 18
        boardRect = layout.board
        place(self.controls, layout.controls)
        local controlPadY = (layout.controls.h - 44) / 2
        setRect(self.jumbleButton, 4, controlPadY, (layout.controls.w - 16) * 0.34, 44)
        setRect(
            self.primary,
            12 + (layout.controls.w - 16) * 0.34,
            controlPadY,
            (layout.controls.w - 16) * 0.66,
            44
        )
        for index, speedButton in self.speedButtons do
            place(speedButton, layout.extras[index])
        end
        place(self.soundButton, layout.extras[4])
        place(self.detailsButton, layout.extras[5])
        self.detailsButton.TextSize = 15
        self.detailsButton.TextColor3 = C.ink
        self.detailsButton.Visible = not choosing
        self.detailsButton.Text = self.detailsOpen and "CLOSE" or "STATS"
        self.detailsPanel.Visible = self.detailsOpen and not choosing
        place(self.detailsPanel, layout.details)
        setRect(self.detailsTitle, 10, 0, layout.details.w - 60, 44)
        setRect(self.detailsClose, layout.details.w - 50, 0, 44, 44)
        self.statsPanel.Parent, self.perksPanel.Parent = self.detailsPanel, self.detailsPanel
        setRect(self.statsPanel, 6, 48, layout.details.w - 12, 100)
        setRect(self.perksPanel, 6, 154, layout.details.w - 12, layout.details.h - 160)
        self.detailsTab.Visible = not self.mobile
        if not self.mobile then
            self.detailsTitle.Text = self.detailsTabMode == "perks" and "OWNED PERKS"
                or "SHOT STATISTICS"
            setRect(self.detailsTitle, 10, 0, layout.details.w - 160, 44)
            setRect(self.detailsTab, layout.details.w - 142, 0, 86, 44)
            self.detailsTab.Text = self.detailsTabMode == "perks" and "STATS" or "PERKS"
            self.detailsTab.TextColor3 = C.ink
            self.detailsTab.TextSize = 18
            self.statsPanel.Visible = self.detailsTabMode ~= "perks"
            self.perksPanel.Visible = self.detailsTabMode == "perks"
            setRect(self.perksPanel, 6, 48, layout.details.w - 12, layout.details.h - 54)
        else
            self.detailsTitle.Text = "SHOT STATS & PERKS"
            self.perksPanel.Visible = true
        end
        if choosing then
            self.left.Visible, self.right.Visible, self.roundPlate.Visible = false, false, false
            self.rackToggle.Visible = true
            self.rackToggle.Text = self.shopRackOpen and "CLOSE RACK" or "RACK / SELL"
            place(self.rackToggle, layout.round)
            self.inventory.Visible = self.shopRackOpen == true
            if self.shopRackOpen then
                invWidth = layout.rackOverlay.w
                invHeight = layout.rackOverlay.h
                place(self.inventory, layout.rackOverlay)
            end
        else
            self.left.Visible, self.right.Visible = true, true
        end
    else
        self.left.Visible, self.right.Visible = true, true
    end
    -- Main's return button uses physical viewport coordinates.
    local speedX, speedY, speedRight, speedBottom = math.huge, math.huge, 0, 0
    for _, control in self.speedButtons do
        local p, s = control.Position, control.Size
        speedX, speedY = math.min(speedX, p.X.Offset), math.min(speedY, p.Y.Offset)
        speedRight, speedBottom =
            math.max(speedRight, p.X.Offset + s.X.Offset),
            math.max(speedBottom, p.Y.Offset + s.Y.Offset)
    end
    local speedPad = compact and 3 or 8
    setRect(
        self.speedGroup,
        speedX - speedPad,
        speedY - speedPad,
        speedRight - speedX + speedPad * 2,
        speedBottom - speedY + speedPad * 2
    )
    for _, control in self.speedButtons do
        control.Position = UDim2.fromOffset(
            control.Position.X.Offset - speedX + speedPad,
            control.Position.Y.Offset - speedY + speedPad
        )
        control.Parent = self.speedGroup
    end
    if compact and not self.foldHud then
        local cw = self.controls.Size.X.Offset
        setRect(self.jumbleButton, 3, 3, (cw - 15) * 0.38, 44)
        setRect(self.primary, 12 + (cw - 15) * 0.38, 3, (cw - 15) * 0.62, 44)
    end
    self.sessionNavigation.x += origin.X
    self.sessionNavigation.y += origin.Y
    for _, panel in { self.statsPanel, self.perksPanel } do
        local descendants = panel:GetDescendants()
        table.insert(descendants, panel)
        for _, object in descendants do
            if object:IsA("GuiObject") and not object:GetAttribute("ItemSilhouette") then
                local baseZ = object:GetAttribute("RunBaseZ") or object.ZIndex
                object:SetAttribute("RunBaseZ", baseZ)
                object.ZIndex = baseZ + (self.foldHud and 64 or 0)
            end
        end
    end
    local columns = compact and 3 or 2
    local statW = (self.statsPanel.Size.X.Offset - 20) / columns
    local rowH = compact and 18 or math.min(22, (self.statsPanel.Size.Y.Offset - 28) / 6)
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
    if shop then
        self.rackToggle.Visible, self.swapHelp.Visible = false, false
        self.inventory.Visible = self.shopRackOpen == true
        local window = ShopLayout.window(w, h)
        local drawerH = math.min(220, window.h - 24)
        invWidth, invHeight = window.w - 48, drawerH - 100
        setRect(
            self.inventory,
            window.x + 24,
            window.y + math.max(8, (window.h - drawerH) / 2) + 40,
            invWidth,
            invHeight
        )
    end
    local rackObjects = self.inventory:GetDescendants()
    table.insert(rackObjects, self.inventory)
    for _, object in rackObjects do
        if object:IsA("GuiObject") then
            local baseZ = object:GetAttribute("ShopBaseZ") or object.ZIndex
            object:SetAttribute("ShopBaseZ", baseZ)
            object.ZIndex = baseZ + (shop and 34 or 0)
        end
    end
    local cellW = (invWidth - (self.foldHud and 8 or 12)) / 7
    for index, slot in self.itemSlots do
        slot.viewport:SetAttribute("ShopPreview", shop)
        setRect(
            slot.button,
            (self.foldHud and 4 or 6) + (index - 1) * cellW + 1,
            5,
            cellW - (self.foldHud and 2 or 4),
            invHeight - 10
        )
        local showName = not compact or invHeight >= 74 or (shop and self.shortWide)
        setRect(slot.viewport, 2, 3, cellW - 8, showName and invHeight - 35 or invHeight - 17)
        setRect(slot.number, 4, 0, 17, 19)
        slot.number.TextSize = compact and 14 or 17
        setRect(slot.level, cellW - 34, 0, 24, 19)
        slot.level.TextSize = compact and 14 or 17
        setRect(slot.name, 3, invHeight - 31, cellW - 10, 21)
        slot.name.Visible = showName
        slot.name.TextSize = compact and 14 or (shop and 18 or 23)
        slot.name.Font = Enum.Font.FredokaOne
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
    local cameraFrame = RunLayout.cameraFrame(
        { x = full.Min.X, y = full.Min.Y, w = full.Width, h = full.Height },
        { x = safe.Min.X, y = safe.Min.Y },
        boardRect
    )
    self.cameraCFrame = CFrame.lookAt(
        Vector3.new(cameraFrame.x, cameraFrame.y, cameraFrame.z),
        Vector3.new(cameraFrame.x, cameraFrame.y, 0)
    )
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
    local layout = RunLayout.perks(w, h, #order, self.compact, self.foldHud)
    local headerH = layout.headerH
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
        local geometry = layout.cells[index]
        for _, entry in
            {
                { cell.button, geometry.card },
                { cell.viewport, geometry.model },
                { cell.name, geometry.name },
                { cell.count, geometry.count },
            }
        do
            local area = entry[2]
            setRect(entry[1], area.x, area.y, area.w, area.h)
        end
        cell.name.Visible = geometry.name.h > 0
        cell.name.TextSize = self.compact and 13 or 15
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
        Theme.select(cell.button, self.selectedSlot == index, definition and C.ice or C.paper)
        cell.name.TextColor3 = C.ink
        cell.number.TextColor3 = C.board
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
        .. Format.integer(restocks)
        .. " / "
        .. tostring(state.maxRestocks or 12)
    self.quota.Text = "TARGET " .. Format.number(quota)
    self.progressCaption.Text = progress.capped and "RESTOCK LIMIT" or "NEXT RESTOCK"
    self.fraction.Text = progress.capped and "FULL"
        or (
            Format.number(math.floor(progress.remainder + 0.5))
            .. " / "
            .. Format.number(progress.nextQuota)
        )
    self.progress.BackgroundColor3 = completed > 0 and layers[progress.previousLayer] or C.ink
    self.progressFill.BackgroundColor3 = layers[progress.nextLayer]
    self.progressFill.Size = UDim2.fromScale(progress.fraction, 1)
    self.restockHint.Text = progress.capped and "All restocks earned this shot!"
        or "Each next restock costs twice as much"
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
        halves = "Item halves",
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
    local shortHint = self.swapHelp.Size.X.Offset < 360
    self.swapHelp.Text = (phase == "aim" or phase == "shop")
            and (shortHint and "Select · Swap · Clear" or "Click item: select / clear • Other slot: swap")
        or (
            shortHint and "Items trigger automatically"
            or "Your equipment works together automatically"
        )
    self.soundButton.Text = ""
    self.soundSlash.Visible = self.muted == true
    self.soundButton:SetAttribute("Muted", self.muted == true)
    local draining = phase == "flight" and state.ball and not state.ball.active
    local playable = (phase == "aim" or phase == "flight") and not self.busy and not draining
    self.controls.Visible = playable
    self.speedGroup.Visible = phase == "aim" or phase == "flight"
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
    if draining then
        self.phaseLabel.Text = "FINISHING ITEM EFFECTS"
    end
    if state.stageCleared and (phase == "result" or phase == "victory") then
        self.phaseLabel.Text = "LEVEL " .. tostring(state.stageCleared.index) .. " COMPLETE!"
    elseif phase == "aim" and #(state.activeSeeds or {}) > 0 then
        self.phaseLabel.Text = "READY • " .. #state.activeSeeds .. " SEEDED PEGS"
    elseif (state.pendingSeeds or 0) > 0 and phase ~= "flight" then
        self.phaseLabel.Text = tostring(state.pendingSeeds) .. " SEEDS BANKED FOR NEXT SHOT"
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
            (state.speed or 1) == value and C.aqua or C.ice
        )
        Theme.select(speedButton, (state.speed or 1) == value)
    end
end

function Presentation:_shopGeometry()
    local size = self.viewport or Vector2.new(1440, 900)
    local area = ShopLayout.window(size.X, size.Y)
    return area.w, area.h, area.y
end

function Presentation:_buildShop(state)
    local width, height, top = self:_shopGeometry()
    ShopView.build(self, state, width, height, top)
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

function Presentation:_refreshShop(state)
    ShopView.refresh(self, state)
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
            local size = self.viewport or Vector2.new(1440, 900)
            setRect(self.modal, (size.X - width) / 2, top, width, height)
            self:_refreshShop(state)
        else
            self.inspector:hide()
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
    if self.foldHud then
        top = 50
    end
    local height = math.min(680, size.Y - top - 18)
    local modal = plate(self.overlay, "Choices", C.paper, 22)
    self.modal = modal
    setRect(modal, (size.X - width) / 2, top, width, height)
    local title = Theme.ribbon(modal, "Title", "", width < 500 and 26 or 36, 25)
    if self.shortWide then
        title.TextSize = 28
    end
    setRect(title, 16, self.shortWide and 8 or 9, width - 32, self.shortWide and 32 or 43)
    local subtitle = label(modal, "Subtitle", "", 21, C.board, 25)
    subtitle.TextWrapped = true
    setRect(subtitle, 16, self.shortWide and 44 or 55, width - 32, self.shortWide and 22 or 47)
    local tinyChoice = height < 300
    if tinyChoice then
        title.TextSize = 24
        setRect(title, 12, 2, width - 24, 30)
        subtitle.Visible = false
    end
    local choicePhase = phase == "perk" or phase == "event"
    if choicePhase then
        subtitle.Visible = false
    end
    local bodyTop = choicePhase and (tinyChoice and 36 or 62)
        or (tinyChoice and 36 or (self.shortWide and 70 or 112))
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
        setRect(result, x, footerY, buttonWidth, tinyChoice and 44 or (self.shortWide and 44 or 51))
        result.TextSize = width < 650 and 18 or 24
        result.TextWrapped = true
        return result
    end
    if phase == "perk" or phase == "event" then
        title.Text = phase == "perk" and "CHOOSE YOUR PERK"
            or (state.eventTitle or "CHOOSE YOUR REWARD")
        subtitle.Text = ""
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
            local card = plate(body, "Choice" .. index, C.paper, 25)
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
            local well = Theme.inset(card, "ModelBox", C.ice, 26)
            place(well, positions.model)
            local model = self:_viewport(well, "Reward", id, 1, 27)
            model:SetAttribute("ShopPreview", true)
            self:_mount(model, id, 1)
            setRect(model, 3, 3, positions.model.w - 6, positions.model.h - 6)
            local name = Theme.ribbon(card, "Name", data.name, positions.nameFont, 28)
            name.TextWrapped, name.TextScaled = true, true
            make(
                "UITextSizeConstraint",
                { MinTextSize = 13, MaxTextSize = positions.nameFont },
                name
            )
            place(name, positions.name)
            local detail = phase == "perk" and Catalog.detail(id, 1)
            if detail then
                local box = Theme.inset(card, "TriggerBox", C.paper, 26)
                place(box, positions.trigger)
                local trigger =
                    label(box, "Trigger", detail.trigger, positions.triggerFont, C.trigger, 28)
                trigger.Font = Enum.Font.SourceSansBold
                trigger.TextWrapped, trigger.TextScaled = true, true
                trigger.TextXAlignment = Enum.TextXAlignment.Center
                trigger.Size, trigger.Position = UDim2.new(1, -8, 1, 0), UDim2.fromOffset(4, 0)
                make(
                    "UITextSizeConstraint",
                    { MinTextSize = 12, MaxTextSize = positions.triggerFont },
                    trigger
                )
            end
            local effects = detail and detail.effects
                or {
                    {
                        text = data.description,
                        tone = id == "overtime" and "negative" or "positive",
                    },
                }
            local effectGap = #effects > 1 and 4 or 0
            local effectH = (positions.effect.h - effectGap * (#effects - 1)) / #effects
            for effectIndex, effect in effects do
                local box = Theme.inset(card, "EffectBox" .. effectIndex, C.paper, 26)
                setRect(
                    box,
                    positions.effect.x,
                    positions.effect.y + (effectIndex - 1) * (effectH + effectGap),
                    positions.effect.w,
                    effectH
                )
                local description = label(
                    box,
                    effectIndex == 1 and "Effect" or "Effect" .. effectIndex,
                    effect.text,
                    positions.effectFont,
                    C[effect.tone] or C.ink,
                    28
                )
                description.TextWrapped, description.TextScaled = true, true
                description.TextXAlignment = Enum.TextXAlignment.Center
                description.Size, description.Position =
                    UDim2.new(1, -8, 1, 0), UDim2.fromOffset(4, 0)
                make(
                    "UITextSizeConstraint",
                    { MinTextSize = 12, MaxTextSize = positions.effectFont },
                    description
                )
            end
            local choose = button(card, "Choose", "CHOOSE", C.mint, function()
                self:_send(phase == "perk" and "choosePerk" or "chooseEvent", { index = index })
            end, 29)
            place(choose, positions.choose)
            choose.TextSize = positions.tight and 20 or 27
        end
        body.CanvasSize = UDim2.fromOffset(0, body.Size.Y.Offset)
    else
        title.Text = phase == "victory" and "WHAT A RUN!" or "RUN COMPLETE"
        subtitle.Text = phase == "victory" and "Keep your build and take on Endless."
            or "Your records and discoveries stay with you."
        body.ScrollingEnabled, body.ScrollBarThickness = false, 0
        local layout = ChoiceLayout.result(body.Size.X.Offset, body.Size.Y.Offset)
        local function place(object, area)
            setRect(object, area.x, area.y, area.w, area.h)
        end
        local model = self:_viewport(body, "RunReward", "restock", 2, 26)
        model:SetAttribute("ShopPreview", true)
        self:_mount(model, "restock", 2)
        place(model, layout.model)
        local result = heading(body, "Result", "ROUND " .. state.round, 42, C.ink, 27)
        result.TextXAlignment = Enum.TextXAlignment.Center
        result.TextScaled = true
        make("UITextSizeConstraint", { MinTextSize = 20, MaxTextSize = 42 }, result)
        place(result, layout.round)
        local records = label(
            body,
            "Records",
            "BEST SCORE  "
                .. Format.number(state.bestScore or 0)
                .. "\nBEST ROUND  "
                .. tostring(state.bestRound or 0),
            24,
            C.ink,
            27
        )
        records.TextXAlignment = Enum.TextXAlignment.Center
        records.TextWrapped, records.TextScaled = true, true
        records.BackgroundTransparency = 0
        Theme.decorate(records, C.ice, 27)
        make("UITextSizeConstraint", { MinTextSize = 14, MaxTextSize = 24 }, records)
        place(records, layout.records)
        local names = {}
        for _, id in state.unlocks or {} do
            local definition = Catalog.Unlocks and Catalog.Unlocks[id]
            table.insert(names, definition and definition.name or id)
        end
        local unlocks = label(
            body,
            "Unlocks",
            #names > 0 and (#names .. " unlocks saved for future runs")
                or "Try a new combination on your next run.",
            19,
            C.board,
            27
        )
        unlocks.TextWrapped, unlocks.TextScaled = true, true
        unlocks.TextXAlignment = Enum.TextXAlignment.Center
        make("UITextSizeConstraint", { MinTextSize = 12, MaxTextSize = 19 }, unlocks)
        place(unlocks, layout.unlocks)
        body.CanvasSize = UDim2.fromOffset(0, body.Size.Y.Offset)
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
            local point = camera:WorldToScreenPoint(object.Position)
            return Vector2.new(point.X, point.Y) - layerOrigin
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
    local first = camera:WorldToScreenPoint(self.boardArt.screenCorners.topLeft)
    local last = camera:WorldToScreenPoint(self.boardArt.screenCorners.bottomRight)
    local origin = self.root.AbsolutePosition
    first, last =
        first - Vector3.new(origin.X, origin.Y, 0), last - Vector3.new(origin.X, origin.Y, 0)
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
    self.settlement.Depth.Visible = compact
    self.settlementText.TextColor3 = C.paper
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

function Presentation:getActivationDuration(id, slot)
    local cell = Catalog.Perks[id] and self.perkCells[id] or self.itemSlots[slot]
    local mounted = cell and self.models[cell.viewport]
    return mounted and mounted.handle.activationDuration or 0.8
end

function Presentation:hasActiveItemAnimations()
    for _, collection in { self.itemSlots, self.perkCells } do
        for _, cell in collection do
            local mounted = self.models[cell.viewport]
            if mounted and mounted.handle.isAnimating and mounted.handle:isAnimating() then
                return true
            end
        end
    end
    return false
end

function Presentation:clearItemActivations()
    for _, collection in { self.itemSlots, self.perkCells } do
        for _, cell in collection do
            local mounted = self.models[cell.viewport]
            if mounted and mounted.handle.resetActivation then
                mounted.handle:resetActivation()
            end
            cell.flash = 0
        end
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
    -- InputObject.Position and GUI AbsolutePosition both use core-UI space.
    local ray = camera:ScreenPointToRay(point.X, point.Y)
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
    elseif self.snapshot.phase == "flight" and self.snapshot.ball and self.snapshot.ball.active then
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
                and self.snapshot.ball
                and self.snapshot.ball.active
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
    self.notice.Visible = type(message) == "string" and message ~= ""
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
    if
        not self.viewport
        or self.screenViewport ~= camera.ViewportSize
        or self.safeArea ~= game:GetService("GuiService")
            :GetInsetArea(Enum.ScreenInsets.CoreUISafeInsets)
        or self.fullArea ~= game:GetService("GuiService"):GetInsetArea(Enum.ScreenInsets.None)
    then
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
            local playbackSpeed = if self.feedback.getPlaybackSpeed
                    and (
                        viewport:IsDescendantOf(self.inventory)
                        or viewport:IsDescendantOf(self.perksPanel)
                    )
                then self.feedback:getPlaybackSpeed()
                else 1
            local remaining = math.min(dt, 0.1) * playbackSpeed
            repeat
                local slice = math.min(remaining, 0.1)
                mounted.handle:step(slice)
                remaining -= slice
            until remaining <= 0
        end
    end
    for id, cell in self.perkCells do
        cell.flash = math.max(0, cell.flash - dt)
        if cell.button.Visible then
            local border = cell.button:FindFirstChildWhichIsA("UIStroke")
            border.Color = cell.flash > 0 and C.gold
                or (self.selectedPerk == id and C.gold or C.ink)
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
            cell.border.Color = self.selectedSlot == index and C.gold or C.ink
            cell.border.Thickness = self.selectedSlot == index and 5 or 3
        end
    end
    if os.clock() > self.noticeUntil then
        self.notice.Text = ""
        self.notice.Visible = false
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
    self.feedback = Feedback.new(self, function(receiptId)
        self:_send("continue", { receiptId = receiptId })
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
