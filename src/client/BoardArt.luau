--!nonstrict

-- Original, non-interactive scenery around the unchanged simulation board.
local BoardArt = {}
BoardArt.__index = BoardArt

local C = {
    pearl = Color3.fromRGB(248, 254, 255),
    shadow = Color3.fromRGB(66, 143, 168),
    aqua = Color3.fromRGB(66, 204, 220),
    pale = Color3.fromRGB(177, 244, 249),
    deep = Color3.fromRGB(14, 70, 105),
    water = Color3.fromRGB(28, 133, 178),
    lime = Color3.fromRGB(160, 213, 74),
    leaf = Color3.fromRGB(73, 157, 106),
    gold = Color3.fromRGB(255, 219, 112),
}

local function make(className, properties, parent)
    local object = Instance.new(className)
    for key, value in properties do
        object[key] = value
    end
    object.Parent = parent
    return object
end

local function part(parent, name, size, position, color, shape)
    return make("Part", {
        Name = name,
        Size = size,
        Position = position,
        Color = color,
        Shape = shape or Enum.PartType.Block,
        Material = Enum.Material.SmoothPlastic,
        Anchored = true,
        CanCollide = false,
        CanTouch = false,
        CanQuery = false,
        CastShadow = false,
        TopSurface = Enum.SurfaceType.Smooth,
        BottomSurface = Enum.SurfaceType.Smooth,
    }, parent)
end

local function oval(parent, name, size, position, color)
    local object = part(parent, name, Vector3.one, position, color)
    make("SpecialMesh", { MeshType = Enum.MeshType.Sphere, Scale = size }, object)
    return object
end

local function tube(parent, name, a, b, radius, color)
    local object = part(
        parent,
        name,
        Vector3.new((b - a).Magnitude, radius * 2, radius * 2),
        (a + b) / 2,
        color,
        Enum.PartType.Cylinder
    )
    object.CFrame = CFrame.lookAt((a + b) / 2, b) * CFrame.Angles(0, math.pi / 2, 0)
    return object
end

local function path(parent, name, points, radius, color)
    for index = 2, #points do
        tube(parent, name, points[index - 1], points[index], radius, color)
    end
end

local function roundedPanel(parent, name, size, position, radius, color)
    local model = make("Model", { Name = name }, parent)
    part(model, "Center", Vector3.new(size.X - radius * 2, size.Y, size.Z), position, color)
    part(model, "Sides", Vector3.new(size.X, size.Y - radius * 2, size.Z), position, color)
    for _, sx in { -1, 1 } do
        for _, sy in { -1, 1 } do
            local corner = part(
                model,
                "Corner",
                Vector3.new(size.Z, radius * 2, radius * 2),
                position + Vector3.new(sx * (size.X / 2 - radius), sy * (size.Y / 2 - radius), 0),
                color,
                Enum.PartType.Cylinder
            )
            corner.CFrame = CFrame.new(corner.Position) * CFrame.Angles(0, math.pi / 2, 0)
        end
    end
    return model
end

local function bubble(parent, name, position, radius)
    oval(parent, name .. "Body", Vector3.one * radius * 2, position, C.aqua)
    oval(
        parent,
        name .. "Reflection",
        Vector3.new(radius * 0.88, radius * 0.38, radius * 0.12),
        position + Vector3.new(-radius * 0.18, radius * 0.43, radius * 0.88),
        C.pearl
    )
end

local function leaf(parent, position, size, angle, color)
    local object = oval(parent, "WaterLeaf", size, position, color)
    object.CFrame = CFrame.new(position) * CFrame.Angles(0, 0, angle)
    local length = size.Y * 0.64
    local direction = Vector3.new(-math.sin(angle), math.cos(angle), 0)
    tube(
        parent,
        "LeafVein",
        position - direction * length / 2 + Vector3.new(0, 0, size.Z / 2),
        position + direction * length / 2 + Vector3.new(0, 0, size.Z / 2),
        0.035,
        C.pale
    )
end

function BoardArt.new(parent)
    local self = setmetatable({}, BoardArt)
    self.model = make("Model", { Name = "BoardEnclosure" }, parent)
    local model = self.model
    local center = Vector3.new(0, 10.9, -0.92)

    -- A broad sculpted shell surrounds the play surface instead of a flat slab.
    roundedPanel(model, "AquaUndershell", Vector3.new(22.6, 30.1, 1.3), center, 1.35, C.shadow)
    roundedPanel(
        model,
        "PearlBody",
        Vector3.new(22.15, 29.8, 1.05),
        center + Vector3.new(0, 0.12, 0.05),
        1.25,
        C.pearl
    )
    roundedPanel(
        model,
        "AquaGasket",
        Vector3.new(20.9, 28.65, 0.24),
        Vector3.new(0, 10.9, -0.25),
        0.75,
        C.aqua
    )
    roundedPanel(
        model,
        "DeepWaterWell",
        Vector3.new(20.2, 28.0, 0.24),
        Vector3.new(0, 10.9, -0.09),
        0.58,
        C.deep
    )
    -- Opaque, adjacent bands avoid translucent sorting and coplanar shimmer.
    for index = 1, 12 do
        local h = 27.0 / 12
        part(
            model,
            "WaterDepthBand",
            Vector3.new(19.7, h, 0.06),
            Vector3.new(0, -2.6 + (index - 0.5) * h, 0.065),
            Color3.fromRGB(17, 91, 142):Lerp(Color3.fromRGB(59, 157, 193), (index - 1) / 11)
        )
    end

    for _, side in { -1, 1 } do
        tube(
            model,
            "AquaRail",
            Vector3.new(side * 10.5, -2.6, 0.32),
            Vector3.new(side * 10.5, 24.35, 0.32),
            0.27,
            C.aqua
        )
        tube(
            model,
            "RailGlint",
            Vector3.new(side * 10.39, -2.1, 0.57),
            Vector3.new(side * 10.39, 23.8, 0.57),
            0.055,
            C.pearl
        )
        for _, y in { -3.25, 25.1 } do
            oval(
                model,
                "PearlShoulder",
                Vector3.new(1.8, 1.5, 1.0),
                Vector3.new(side * 10.15, y, 0.05),
                C.pearl
            )
            bubble(model, "CornerBubble", Vector3.new(side * 10.15, y, 0.56), 0.3)
        end
        -- The sinuous side pods stay outside the simulated wall and peg columns.
        oval(
            model,
            "FlowPod",
            Vector3.new(1.7, 9.4, 0.8),
            Vector3.new(side * 11.12, 12.1, -0.42),
            C.pale
        )
        local flowing = {}
        for index = 0, 15 do
            local t = index / 15
            table.insert(
                flowing,
                Vector3.new(side * (10.95 + math.sin(t * math.pi * 2) * 0.24), 8.1 + t * 8.1, 0.07)
            )
        end
        path(model, "WaterChannel", flowing, 0.09, C.aqua)
        for index = 1, 3 do
            bubble(
                model,
                "PodBubble",
                Vector3.new(side * (11.0 + (index % 2) * 0.22), 8.3 + index * 1.2, 0.25),
                0.13 + index * 0.025
            )
        end
        local stem = {
            Vector3.new(side * 10.92, -2.7, 0.04),
            Vector3.new(side * 11.17, -1.0, 0.04),
            Vector3.new(side * 10.98, 1.0, 0.04),
            Vector3.new(side * 11.28, 3.0, 0.04),
        }
        path(model, "PlantStem", stem, 0.06, C.leaf)
        leaf(
            model,
            Vector3.new(side * 11.35, -0.6, 0.15),
            Vector3.new(0.75, 1.8, 0.27),
            side * -0.4,
            C.lime
        )
        leaf(
            model,
            Vector3.new(side * 10.97, 1.55, 0.15),
            Vector3.new(0.7, 1.6, 0.27),
            side * 0.36,
            C.leaf
        )
        leaf(
            model,
            Vector3.new(side * 11.4, 3.15, 0.15),
            Vector3.new(0.6, 1.35, 0.25),
            side * -0.28,
            C.lime
        )
    end

    tube(
        model,
        "TopPearlTrim",
        Vector3.new(-9.5, 25.3, 0.23),
        Vector3.new(9.5, 25.3, 0.23),
        0.34,
        C.pearl
    )
    tube(
        model,
        "BottomPearlTrim",
        Vector3.new(-9.5, -3.5, 0.23),
        Vector3.new(9.5, -3.5, 0.23),
        0.34,
        C.pearl
    )
    tube(
        model,
        "DrainGlow",
        Vector3.new(-8.7, -3.12, 0.3),
        Vector3.new(8.7, -3.12, 0.3),
        0.07,
        C.aqua
    )
    roundedPanel(
        model,
        "MakerBadge",
        Vector3.new(5.9, 1.2, 0.22),
        Vector3.new(-5.9, 25.2, 0.62),
        0.4,
        C.pale
    )
    for index = 1, 3 do
        oval(
            model,
            "BadgePetal",
            Vector3.new(0.34, 0.63, 0.13),
            Vector3.new(-7.8 + index * 0.5, 25.2, 0.81),
            index == 2 and C.lime or C.aqua
        )
    end
    for index = 1, 4 do
        part(
            model,
            "BadgeLine",
            Vector3.new(0.7, 0.06, 0.04),
            Vector3.new(-5.2 + index * 0.18, 25.45 - index * 0.14, 0.82),
            C.pearl
        )
    end

    -- An articulated pearl stem makes the status display part of the enclosure.
    path(model, "StatusArmShadow", {
        Vector3.new(9.4, 24.75, -0.05),
        Vector3.new(11.1, 25.4, -0.05),
        Vector3.new(9.4, 26.35, -0.05),
    }, 0.24, C.shadow)
    path(model, "StatusArm", {
        Vector3.new(9.4, 24.75, 0.19),
        Vector3.new(11.1, 25.4, 0.19),
        Vector3.new(9.4, 26.35, 0.19),
    }, 0.17, C.pearl)
    oval(model, "MonitorHinge", Vector3.new(0.62, 0.62, 0.38), Vector3.new(10.8, 25.4, 0.3), C.aqua)
    oval(model, "HingeHub", Vector3.new(0.31, 0.31, 0.12), Vector3.new(10.8, 25.4, 0.53), C.pearl)
    -- A visible braided data line and sealed port connect the little appliance
    -- to the board. All decoration is opaque so the fixed camera stays stable.
    path(model, "MonitorDataLine", {
        Vector3.new(10.56, 24.5, 0.53),
        Vector3.new(11.36, 24.85, 0.53),
        Vector3.new(11.48, 25.42, 0.53),
        Vector3.new(10.54, 26.12, 0.53),
    }, 0.065, C.aqua)
    for index = 1, 3 do
        tube(
            model,
            "CableCollar",
            Vector3.new(10.66 + index * 0.18, 24.63 + index * 0.08, 0.53),
            Vector3.new(10.72 + index * 0.18, 24.65 + index * 0.08, 0.53),
            0.09,
            C.pearl
        )
    end
    local screenCenter = Vector3.new(6.6, 26.5, 0.8)
    roundedPanel(
        model,
        "MonitorWaterSeal",
        Vector3.new(8.65, 3.95, 0.56),
        screenCenter + Vector3.new(0, 0, -0.35),
        0.7,
        C.aqua
    )
    roundedPanel(
        model,
        "MonitorShadow",
        Vector3.new(8.25, 3.66, 0.7),
        screenCenter + Vector3.new(0.1, -0.09, -0.45),
        0.5,
        C.shadow
    )
    roundedPanel(model, "MonitorShell", Vector3.new(8.1, 3.55, 0.55), screenCenter, 0.48, C.pearl)
    roundedPanel(
        model,
        "MonitorInnerPearl",
        Vector3.new(7.92, 3.36, 0.08),
        screenCenter + Vector3.new(0, 0.035, 0.24),
        0.4,
        C.pale
    )
    roundedPanel(
        model,
        "MonitorBezel",
        Vector3.new(7.66, 3.12, 0.11),
        screenCenter + Vector3.new(0, 0.04, 0.32),
        0.3,
        C.aqua
    )
    self.screenPart = part(
        model,
        "StatusScreen",
        Vector3.new(7.2, 2.62, 0.07),
        screenCenter + Vector3.new(0, 0.09, 0.42),
        C.deep
    )
    self.screenCorners = {
        topLeft = self.screenPart.Position + Vector3.new(-3.6, 1.31, 0.05),
        bottomRight = self.screenPart.Position + Vector3.new(3.6, -1.31, 0.05),
    }
    part(
        model,
        "ScreenGlint",
        Vector3.new(6.9, 0.06, 0.03),
        screenCenter + Vector3.new(0, 1.33, 0.48),
        C.pale
    )
    -- Curved cheek fins, vents and botanical details frame the screen without
    -- crossing its usable rectangle or its projected GUI corners.
    for _, side in { -1, 1 } do
        local x = screenCenter.X + side * 4.31
        oval(
            model,
            "MonitorCheek",
            Vector3.new(0.76, 2.5, 0.75),
            Vector3.new(x, 26.63, 0.66),
            C.pearl
        )
        oval(
            model,
            "CheekInset",
            Vector3.new(0.42, 1.86, 0.15),
            Vector3.new(x, 26.66, 1.06),
            C.pale
        )
        for index = 1, 4 do
            local vent = part(
                model,
                "MonitorVent",
                Vector3.new(0.3, 0.055, 0.05),
                Vector3.new(x, 26.1 + index * 0.22, 1.17),
                C.shadow
            )
            vent.CFrame *= CFrame.Angles(0, 0, side * -0.2)
        end
        bubble(model, "MonitorFastener", Vector3.new(x, 25.73, 1.12), 0.12)
        leaf(
            model,
            Vector3.new(screenCenter.X + side * 3.58, 28.23, 0.79),
            Vector3.new(0.38, 0.83, 0.14),
            side * -0.92,
            C.lime
        )
        leaf(
            model,
            Vector3.new(screenCenter.X + side * 3.93, 28.36, 0.77),
            Vector3.new(0.29, 0.65, 0.13),
            side * 0.6,
            C.leaf
        )
    end
    path(model, "PearlCrown", {
        Vector3.new(3.0, 28.17, 1.01),
        Vector3.new(3.54, 28.51, 1.01),
        Vector3.new(5.0, 28.66, 1.01),
        Vector3.new(8.2, 28.66, 1.01),
        Vector3.new(9.66, 28.51, 1.01),
        Vector3.new(10.2, 28.17, 1.01),
    }, 0.085, C.pearl)
    roundedPanel(
        model,
        "LevelBadge",
        Vector3.new(2.65, 0.53, 0.26),
        Vector3.new(6.6, 28.48, 1.03),
        0.22,
        C.deep
    )
    self.stagePips = {}
    for index = 1, 4 do
        self.stagePips[index] = oval(
            model,
            "LevelPip" .. index,
            Vector3.new(0.26, 0.26, 0.10),
            Vector3.new(5.7 + (index - 1) * 0.6, 28.48, 1.23),
            C.pale
        )
    end
    tube(
        model,
        "SignalStem",
        Vector3.new(10.94, 27.72, 0.55),
        Vector3.new(11.48, 28.16, 0.55),
        0.07,
        C.shadow
    )
    bubble(model, "SignalBubble", Vector3.new(11.53, 28.31, 0.57), 0.24)
    bubble(model, "SignalSatellite", Vector3.new(11.96, 28.62, 0.57), 0.1)
    -- The lower lip has an inset progress channel rather than floating LEDs.
    roundedPanel(
        model,
        "ProgressChannel",
        Vector3.new(6.25, 0.25, 0.04),
        screenCenter + Vector3.new(-0.04, -1.5, 0.355),
        0.1,
        C.deep
    )
    self.lamp = oval(
        model,
        "StatusLamp",
        Vector3.new(0.2, 0.2, 0.08),
        screenCenter + Vector3.new(-3.52, -1.5, 0.37),
        C.aqua
    )
    self.progress = {}
    for index = 1, 10 do
        self.progress[index] = part(
            model,
            "StatusProgress" .. index,
            Vector3.new(0.5, 0.06, 0.03),
            screenCenter + Vector3.new(-2.65 + (index - 1) * 0.57, -1.5, 0.38),
            C.pale
        )
    end
    self:setStage({ index = 1 })
    self:setStatus(nil, 0, false, false)
    return self
end

function BoardArt:setStage(stage)
    local index = type(stage) == "table" and stage.index or 1
    local finished = type(stage) == "table" and stage.cleared == true
    if type(index) ~= "number" or index ~= index or math.abs(index) == math.huge then
        index = 1
    end
    index = math.max(1, math.floor(index))
    for number, pip in self.stagePips do
        local cleared = number < index or (number == index and finished)
        pip.Color = if cleared then C.lime elseif number == index then C.gold else C.pale
    end
end

function BoardArt:setStatus(text, progress, visible, canSkip)
    local active = visible == true and type(text) == "string" and text ~= ""
    self.lamp.Color = active and (canSkip and C.lime or C.gold) or C.aqua
    local value = math.clamp(progress or 0, 0, 1)
    for index, segment in self.progress do
        segment.Color = active and index <= math.ceil(value * #self.progress) and C.lime or C.pale
    end
    if not active then
        return ""
    end
    local caption = text
    if string.find(text, "COUNTING", 1, true) then
        caption = "COUNTING SCORE"
    elseif string.find(text, "MERGING", 1, true) then
        caption = "MERGING"
    elseif string.find(text, "RESETTING", 1, true) then
        caption = "RESETTING"
    elseif string.find(text, "READY", 1, true) then
        caption = "READY!"
    elseif string.find(text, "OUT OF BALLS", 1, true) then
        caption = "RUN COMPLETE"
    elseif string.find(text, "AIM AGAIN", 1, true) then
        caption = "AIM AGAIN"
    end
    return caption
end

function BoardArt:destroy()
    self.model:Destroy()
end

return BoardArt
