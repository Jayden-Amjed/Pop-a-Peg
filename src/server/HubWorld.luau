--!nonstrict

-- Original native-part aquarium arcade. The shared world is static; each player's
-- game board remains client-local, far away at the simulation's existing origin.
local HubWorld = {}
HubWorld.__index = HubWorld

HubWorld.Origin = Vector3.new(0, 0, 1000)
HubWorld.Capacity = 8

local C = {
    pearl = Color3.fromRGB(246, 253, 255),
    ice = Color3.fromRGB(217, 245, 249),
    aqua = Color3.fromRGB(65, 206, 220),
    blue = Color3.fromRGB(32, 137, 181),
    deep = Color3.fromRGB(18, 68, 92),
    water = Color3.fromRGB(52, 186, 212),
    leaf = Color3.fromRGB(84, 167, 107),
    lime = Color3.fromRGB(168, 218, 89),
    gold = Color3.fromRGB(255, 209, 103),
    coral = Color3.fromRGB(255, 155, 122),
    sand = Color3.fromRGB(236, 226, 188),
}

local PODS = {
    { x = -42, z = 34, color = C.aqua, name = "BUBBLE BAY" },
    { x = -42, z = 12, color = C.lime, name = "MEADOW CURRENT" },
    { x = -42, z = -12, color = C.blue, name = "GLASS LAGOON" },
    { x = -42, z = -34, color = C.gold, name = "SUNLIT REEF" },
    { x = 42, z = -34, color = C.coral, name = "CORAL COVE" },
    { x = 42, z = -12, color = C.aqua, name = "PEARL SHOAL" },
    { x = 42, z = 12, color = C.lime, name = "LEAF CHANNEL" },
    { x = 42, z = 34, color = C.blue, name = "SKY TIDE" },
}

local function make(className, properties, parent)
    local object = Instance.new(className)
    for key, value in properties do
        object[key] = value
    end
    object.Parent = parent
    return object
end

local function part(parent, name, size, cf, color, shape, collide)
    return make("Part", {
        Name = name,
        Size = size,
        CFrame = cf,
        Color = color,
        Shape = shape or Enum.PartType.Block,
        Material = Enum.Material.SmoothPlastic,
        Anchored = true,
        CanCollide = collide == true,
        CanTouch = false,
        CanQuery = collide == true,
        CastShadow = false,
        TopSurface = Enum.SurfaceType.Smooth,
        BottomSurface = Enum.SurfaceType.Smooth,
    }, parent)
end

local function oval(parent, name, size, cf, color)
    local object = part(parent, name, Vector3.one, cf, color)
    make("SpecialMesh", { MeshType = Enum.MeshType.Sphere, Scale = size }, object)
    return object
end

local function disc(parent, name, radius, thickness, cf, color, collide)
    return part(
        parent,
        name,
        Vector3.new(thickness, radius * 2, radius * 2),
        cf * CFrame.Angles(0, 0, math.pi / 2),
        color,
        Enum.PartType.Cylinder,
        collide
    )
end

local function tube(parent, name, a, b, radius, color)
    return part(
        parent,
        name,
        Vector3.new((b - a).Magnitude, radius * 2, radius * 2),
        CFrame.lookAt((a + b) / 2, b) * CFrame.Angles(0, math.pi / 2, 0),
        color,
        Enum.PartType.Cylinder
    )
end

local function ring(parent, name, radius, y, thickness, color, count)
    count = count or 24
    for index = 1, count do
        local first = (index - 1) / count * math.pi * 2
        local last = index / count * math.pi * 2
        tube(
            parent,
            name,
            HubWorld.Origin + Vector3.new(math.cos(first) * radius, y, math.sin(first) * radius),
            HubWorld.Origin + Vector3.new(math.cos(last) * radius, y, math.sin(last) * radius),
            thickness,
            color
        )
    end
end

local function sign(object, text, color, textSize)
    local gui = make("SurfaceGui", {
        Name = "Screen",
        Face = Enum.NormalId.Front,
        SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud,
        PixelsPerStud = 70,
        LightInfluence = 0,
        AlwaysOnTop = false,
    }, object)
    return make("TextLabel", {
        Name = "Text",
        BackgroundTransparency = 1,
        Position = UDim2.fromScale(0.035, 0.06),
        Size = UDim2.fromScale(0.93, 0.88),
        Font = Enum.Font.GothamBold,
        Text = text,
        TextColor3 = color or C.deep,
        TextSize = textSize or 32,
        TextScaled = true,
        TextWrapped = true,
    }, gui)
end

local function prompt(parent, name, action, objectText)
    return make("ProximityPrompt", {
        Name = name,
        ActionText = action,
        ObjectText = objectText,
        KeyboardKeyCode = Enum.KeyCode.E,
        GamepadKeyCode = Enum.KeyCode.ButtonX,
        HoldDuration = 0,
        MaxActivationDistance = 10,
        RequiresLineOfSight = false,
    }, parent)
end

local function plant(parent, position, scale, color)
    disc(parent, "PearlPlanter", 1.8 * scale, 1.5 * scale, CFrame.new(position), C.pearl)
    disc(
        parent,
        "PlanterSoil",
        1.55 * scale,
        0.1,
        CFrame.new(position + Vector3.new(0, 0.8 * scale, 0)),
        C.deep
    )
    for index = 1, 4 do
        local angle = index * math.pi / 2 + 0.3
        local cf = CFrame.new(
            position + Vector3.new(math.cos(angle) * scale, 2.1 * scale, math.sin(angle) * scale)
        ) * CFrame.Angles(0, -angle, math.rad(-24))
        oval(parent, "Leaf", Vector3.new(1.3, 4, 0.55) * scale, cf, color or C.leaf)
    end
end

local function fish(parent, position, scale, color, yaw)
    local cf = CFrame.new(position) * CFrame.Angles(0, yaw, math.rad(-8))
    oval(parent, "FishBody", Vector3.new(2.7, 1.45, 0.85) * scale, cf, color)
    for _, direction in { -1, 1 } do
        oval(
            parent,
            "TailFin",
            Vector3.new(1.2, 0.65, 0.16) * scale,
            cf
                * CFrame.new(-1.7 * scale, direction * 0.3 * scale, 0)
                * CFrame.Angles(0, 0, direction * 0.55),
            color
        )
        oval(
            parent,
            "EyeWhite",
            Vector3.new(0.28, 0.28, 0.12) * scale,
            cf * CFrame.new(0.83 * scale, 0.2 * scale, direction * 0.42 * scale),
            C.pearl
        )
        oval(
            parent,
            "EyePupil",
            Vector3.new(0.13, 0.15, 0.06) * scale,
            cf * CFrame.new(0.88 * scale, 0.2 * scale, direction * 0.49 * scale),
            C.deep
        )
    end
    oval(
        parent,
        "DorsalFin",
        Vector3.new(0.9, 0.6, 0.16) * scale,
        cf * CFrame.new(0, 0.85 * scale, 0),
        color
    )
end

function HubWorld:_buildAtrium()
    local shell = make("Model", { Name = "PearlAtrium" }, self.model)
    local origin = HubWorld.Origin
    disc(shell, "Foundation", 67, 3.5, CFrame.new(origin + Vector3.new(0, -2.5, 0)), C.blue, true)
    disc(
        shell,
        "WalkableFloor",
        64,
        1.5,
        CFrame.new(origin + Vector3.new(0, -0.75, 0)),
        C.pearl,
        true
    )
    disc(shell, "AquaInlay", 54, 0.08, CFrame.new(origin + Vector3.new(0, 0.045, 0)), C.ice)
    disc(shell, "CentralPlaza", 24, 0.1, CFrame.new(origin + Vector3.new(0, 0.1, 0)), C.pearl)
    ring(shell, "PlazaBorder", 24, 0.18, 0.12, C.aqua, 32)
    for _, x in { -29, 29 } do
        part(
            shell,
            "GalleryPath",
            Vector3.new(12, 0.12, 91),
            CFrame.new(origin + Vector3.new(x, 0.1, 0)),
            C.pearl
        )
        for z = -38, 38, 19 do
            part(
                shell,
                "PathMarker",
                Vector3.new(0.5, 0.16, 3),
                CFrame.new(origin + Vector3.new(x, 0.2, z)),
                C.aqua
            )
        end
    end
    part(
        shell,
        "ArrivalPath",
        Vector3.new(13, 0.13, 34),
        CFrame.new(origin + Vector3.new(0, 0.11, 43)),
        C.pearl
    )
    for index = 1, 32 do
        local angle = (index - 0.5) * math.pi / 16
        local cf = CFrame.new(origin + Vector3.new(math.sin(angle) * 62, 3.7, math.cos(angle) * 62))
            * CFrame.Angles(0, angle, 0)
        local rail = part(shell, "SafetyGlass", Vector3.new(12.2, 7.4, 0.5), cf, C.aqua, nil, true)
        rail.Material = Enum.Material.Glass
        rail.Transparency = 0.72
    end
    ring(shell, "PearlBalustrade", 62, 7.6, 0.35, C.pearl, 32)
    ring(shell, "WaterlineTrim", 63.4, 0.5, 0.35, C.aqua, 32)
    for _, side in { -1, 1 } do
        for _, z in { -36, 0, 36 } do
            local foot = origin + Vector3.new(side * 51, 0, z)
            part(
                shell,
                "AtriumPillar",
                Vector3.new(1.7, 24, 1.7),
                CFrame.new(foot + Vector3.new(0, 12, 0)),
                C.pearl
            )
            part(
                shell,
                "PillarChannel",
                Vector3.new(0.2, 18, 0.35),
                CFrame.new(foot + Vector3.new(-side, 13, -0.5)),
                C.aqua
            )
            oval(
                shell,
                "PillarCrown",
                Vector3.new(3.8, 1.6, 3.8),
                CFrame.new(foot + Vector3.new(0, 24, 0)),
                C.pearl
            )
        end
    end
    -- Repeated arch ribs suggest a glazed conservatory without an opaque ceiling.
    for _, z in { -36, 0, 36 } do
        for step = 1, 16 do
            local function point(t)
                local angle = t * math.pi
                return origin + Vector3.new(math.cos(angle) * 51, 24 + math.sin(angle) * 11, z)
            end
            tube(shell, "SkylightArch", point((step - 1) / 16), point(step / 16), 0.65, C.pearl)
        end
    end
    for _, x in { -37, 0, 37 } do
        local height = 24 + math.sqrt(1 - (x / 51) ^ 2) * 11
        tube(
            shell,
            "SkylightSpine",
            origin + Vector3.new(x, height, -36),
            origin + Vector3.new(x, height, 36),
            0.35,
            C.aqua
        )
    end
    local banner = part(
        shell,
        "WelcomeMarquee",
        Vector3.new(31, 4.3, 1),
        CFrame.new(origin + Vector3.new(0, 15, 49)) * CFrame.Angles(0, math.pi, 0),
        C.pearl
    )
    sign(banner, "POP A PEG\nAQUARIUM ARCADE", C.deep)
    local back = part(
        shell,
        "WelcomeInside",
        Vector3.new(31, 4.3, 0.2),
        CFrame.new(origin + Vector3.new(0, 15, 48.35)),
        C.pearl
    )
    sign(back, "YOUR NEXT GREAT RUN STARTS HERE", C.blue)
    for _, side in { -1, 1 } do
        part(
            shell,
            "WelcomeSupport",
            Vector3.new(0.9, 15, 0.9),
            CFrame.new(origin + Vector3.new(side * 16, 7.5, 49)),
            C.aqua
        )
        plant(shell, origin + Vector3.new(side * 13, 1.2, 52), 1.3, C.lime)
        plant(shell, origin + Vector3.new(side * 55, 1, 23), 1, C.leaf)
        plant(shell, origin + Vector3.new(side * 55, 1, -23), 1, C.leaf)
    end
    self.spawn = make("SpawnLocation", {
        Name = "ArcadeArrival",
        Size = Vector3.new(10, 0.2, 7),
        CFrame = CFrame.new(origin + Vector3.new(0, 0.12, 42)),
        Anchored = true,
        CanCollide = false,
        CanTouch = false,
        Transparency = 1,
        Neutral = true,
        Duration = 0,
        Enabled = true,
    }, self.model)
end

function HubWorld:_buildAquarium()
    local tank = make("Model", { Name = "LivingLagoon" }, self.model)
    local origin = HubWorld.Origin
    disc(tank, "TankPlinth", 13.4, 1, CFrame.new(origin + Vector3.new(0, 0.5, 0)), C.blue, true)
    disc(
        tank,
        "PearlFoundation",
        12.8,
        1,
        CFrame.new(origin + Vector3.new(0, 1.3, 0)),
        C.pearl,
        true
    )
    disc(tank, "SandBed", 11.7, 0.5, CFrame.new(origin + Vector3.new(0, 2, 0)), C.sand)
    local water =
        disc(tank, "LagoonWater", 11.8, 10, CFrame.new(origin + Vector3.new(0, 7.2, 0)), C.water)
    water.Transparency = 0.83
    for index = 1, 16 do
        local angle = index * math.pi / 8
        local cf = CFrame.new(origin + Vector3.new(math.sin(angle) * 12, 7.3, math.cos(angle) * 12))
            * CFrame.Angles(0, angle, 0)
        local glass =
            part(tank, "AquariumWindow", Vector3.new(4.8, 10.3, 0.2), cf, C.ice, nil, true)
        glass.Material = Enum.Material.Glass
        glass.Transparency = 0.82
    end
    ring(tank, "TankFootSeal", 12.2, 2.2, 0.2, C.aqua, 24)
    ring(tank, "TankCrown", 12.2, 12.6, 0.45, C.pearl, 24)
    ring(tank, "TankCrownInlay", 12.2, 13.2, 0.14, C.aqua, 24)
    for index = 1, 7 do
        local angle = index * 2.4
        local radius = 4 + index % 3 * 2
        local position = origin
            + Vector3.new(math.cos(angle) * radius, 4 + index % 4 * 1.65, math.sin(angle) * radius)
        fish(
            tank,
            position,
            0.8 + index % 3 * 0.18,
            if index % 2 == 0 then C.gold else C.coral,
            angle + math.pi / 2
        )
    end
    for index = 1, 5 do
        local angle = index * 1.25
        local base = origin + Vector3.new(math.cos(angle) * 7.5, 2.25, math.sin(angle) * 7.5)
        oval(tank, "RiverStone", Vector3.new(3.1, 1.1, 2.3), CFrame.new(base), C.ice)
        for leaf = 1, 3 do
            oval(
                tank,
                "AquaticLeaf",
                Vector3.new(0.65, 3.5 + leaf * 0.4, 0.3),
                CFrame.new(base + Vector3.new((leaf - 2) * 0.5, 1.7, 0))
                    * CFrame.Angles(0, angle, (leaf - 2) * 0.3),
                C.leaf
            )
        end
    end
    for index = 1, 9 do
        local bubble = oval(
            tank,
            "AirPearl",
            Vector3.one * (0.25 + index % 3 * 0.14),
            CFrame.new(
                origin + Vector3.new(math.sin(index * 2) * 8, 3 + index, math.cos(index * 2) * 8)
            ),
            C.pearl
        )
        bubble.Transparency = 0.25
    end
    local plaque = part(
        tank,
        "LagoonPlaque",
        Vector3.new(9, 2.1, 0.3),
        CFrame.new(origin + Vector3.new(0, 3.3, 13.3)) * CFrame.Angles(0, math.pi, 0),
        C.pearl
    )
    sign(plaque, "THE LIVING LAGOON\n8 PLAYERS · ENDLESS POSSIBILITIES", C.deep)
    for _, x in { -18, 18 } do
        local cf = CFrame.new(origin + Vector3.new(x, 1.65, 0)) * CFrame.Angles(0, math.pi / 2, 0)
        part(tank, "LoungeSeat", Vector3.new(13, 0.7, 2.8), cf, C.pearl, nil, true)
        part(
            tank,
            "LoungeCushion",
            Vector3.new(12.4, 0.35, 2.3),
            cf * CFrame.new(0, 0.45, 0),
            C.aqua
        )
        for _, direction in { -1, 1 } do
            part(
                tank,
                "BenchLeg",
                Vector3.new(0.7, 1.5, 2),
                cf * CFrame.new(direction * 4.8, -1, 0),
                C.blue
            )
        end
    end
end

function HubWorld:_buildPod(index, config)
    local model = make("Model", { Name = "ArcadeStation" .. index }, self.model)
    model:SetAttribute("Station", index)
    local position = HubWorld.Origin + Vector3.new(config.x, 0, config.z)
    local basis =
        CFrame.lookAt(position, position + Vector3.new(if config.x < 0 then 1 else -1, 0, 0))
    local function p(name, size, offset, color, shape, collide)
        return part(model, name, size, basis * CFrame.new(offset), color, shape, collide)
    end
    disc(model, "StationIsland", 7, 0.35, CFrame.new(position + Vector3.new(0, 0.2, 0)), C.pearl)
    p("CabinetFoot", Vector3.new(10.2, 0.8, 6), Vector3.new(0, 0.8, 0), C.blue, nil, true)
    p("CabinetBody", Vector3.new(9.2, 6.1, 4.8), Vector3.new(0, 4.2, 0.5), C.pearl, nil, true)
    p("LowerAccent", Vector3.new(8.4, 2.7, 0.3), Vector3.new(0, 3.2, -2.1), config.color)
    for _, side in { -1, 1 } do
        p("PearlPillar", Vector3.new(0.8, 8.8, 1.1), Vector3.new(side * 4.4, 8.4, 0), C.pearl)
        p(
            "LightChannel",
            Vector3.new(0.2, 7.8, 0.3),
            Vector3.new(side * 4.4, 8.4, -0.65),
            config.color
        )
    end
    p("ScreenSurround", Vector3.new(8.3, 6.7, 1.4), Vector3.new(0, 9, 0.65), C.blue, nil, true)
    p("ScreenPearlRim", Vector3.new(7.8, 6.25, 0.2), Vector3.new(0, 9, -0.15), C.pearl)
    p("PegDisplay", Vector3.new(7.2, 5.7, 0.15), Vector3.new(0, 9, -0.3), C.deep)
    for row = 1, 4 do
        local count = if row % 2 == 0 then 4 else 3
        for column = 1, count do
            local x = (column - (count + 1) / 2) * 1.45
            local y = 11.4 - row * 1.08
            p(
                "DisplayPeg",
                Vector3.new(0.57, 0.57, 0.57),
                Vector3.new(x, y, -0.6),
                if (row + column + index) % 4 == 0 then C.gold else config.color,
                Enum.PartType.Ball
            )
        end
    end
    p("DisplayBall", Vector3.one * 0.62, Vector3.new(0, 11.45, -0.7), C.pearl, Enum.PartType.Ball)
    local controls = part(
        model,
        "ControlDeck",
        Vector3.new(9.8, 0.65, 3.5),
        basis * CFrame.new(0, 6.3, -2.5) * CFrame.Angles(math.rad(8), 0, 0),
        C.ice,
        nil,
        true
    )
    for buttonIndex = 1, 3 do
        disc(
            model,
            "ControlButton",
            0.4,
            0.17,
            basis * CFrame.new(0.9 + buttonIndex * 0.85, 6.83, -3.1),
            if buttonIndex == 3 then C.gold else config.color
        )
    end
    p("JoystickStem", Vector3.new(0.18, 0.85, 0.18), Vector3.new(-2.6, 7.1, -3), C.blue)
    p(
        "JoystickGrip",
        Vector3.one * 0.66,
        Vector3.new(-2.6, 7.55, -3),
        config.color,
        Enum.PartType.Ball
    )
    for vent = 1, 4 do
        p(
            "SpeakerVent",
            Vector3.new(0.16, 1.1, 0.1),
            Vector3.new(-2.6 + vent * 0.5, 3.4, -2.3),
            C.deep
        )
    end
    p("MarqueeFrame", Vector3.new(10, 2.6, 1.7), Vector3.new(0, 13.5, 0.3), config.color)
    local marquee = p("Marquee", Vector3.new(9.1, 1.8, 0.12), Vector3.new(0, 13.6, -0.65), C.pearl)
    sign(marquee, string.format("%02d  /  %s", index, config.name), C.deep)
    local owner = p("OwnerScreen", Vector3.new(8.7, 1.7, 0.15), Vector3.new(0, 1.9, -2.3), C.ice)
    local ownerText = sign(owner, "OPEN", C.deep)
    local status =
        p("StatusScreen", Vector3.new(8.7, 1.35, 0.15), Vector3.new(0, 4.65, -2.3), C.deep)
    local statusText = sign(status, "YOUR NEXT RUN", C.pearl)
    local light = p(
        "AvailabilityLight",
        Vector3.one * 0.7,
        Vector3.new(4.5, 15.1, 0.3),
        C.lime,
        Enum.PartType.Ball
    )
    light.Material = Enum.Material.Neon
    p("Antenna", Vector3.new(0.12, 1, 0.12), Vector3.new(4.5, 14.5, 0.3), C.blue)
    local play = prompt(controls, "PlayArcade", "Play", config.name)
    table.insert(
        self.connections,
        play.Triggered:Connect(function(player)
            self.onPlayRequested(player, index)
        end)
    )
    self.stations[index] = {
        model = model,
        basis = basis,
        ownerText = ownerText,
        statusText = statusText,
        light = light,
        prompt = play,
        name = config.name,
    }
end

function HubWorld:_buildGallery()
    local gallery = make("Model", { Name = "DiscoveryGallery" }, self.model)
    local origin = HubWorld.Origin
    local wall = part(
        gallery,
        "GalleryHeader",
        Vector3.new(43, 4, 0.8),
        CFrame.new(origin + Vector3.new(0, 13.5, -47)) * CFrame.Angles(0, math.pi, 0),
        C.pearl
    )
    sign(wall, "DISCOVER · EVOLVE · REMEMBER", C.blue)
    for _, side in { -1, 1 } do
        local basis = CFrame.new(origin + Vector3.new(side * 17, 0, -46))
            * CFrame.Angles(0, math.pi, 0)
        part(
            gallery,
            "GallerySupport",
            Vector3.new(1, 12, 1),
            basis * CFrame.new(side * 5, 6, 0),
            C.aqua
        )
        disc(gallery, "KioskPlinth", 5.5, 0.45, basis * CFrame.new(0, 0.3, 0), C.pearl)
        part(
            gallery,
            "KioskBase",
            Vector3.new(9, 3.5, 3.3),
            basis * CFrame.new(0, 2.2, 0),
            C.blue,
            nil,
            true
        )
        local display = part(
            gallery,
            "KioskScreen",
            Vector3.new(8.5, 3.3, 0.3),
            basis * CFrame.new(0, 4.6, -1.7),
            C.pearl
        )
        if side < 0 then
            sign(display, "EVOLUTION COLLECTION\nDiscover all 13 creations", C.deep)
            prompt(display, "CollectionPrompt", "Browse collection", "Evolution Gallery")
            local orb = oval(
                gallery,
                "EvolutionOrb",
                Vector3.new(3.7, 3.7, 3.7),
                basis * CFrame.new(0, 8, 0),
                C.aqua
            )
            orb.Material = Enum.Material.Glass
            orb.Transparency = 0.25
            for index = 1, 5 do
                local angle = index * math.pi * 2 / 5
                oval(
                    gallery,
                    "EvolutionSatellite",
                    Vector3.one * 0.8,
                    basis
                        * CFrame.new(
                            math.cos(angle) * 3.3,
                            8 + math.sin(angle) * 1.5,
                            math.sin(angle) * 0.7
                        ),
                    if index % 2 == 0 then C.gold else C.pearl
                )
            end
            fish(gallery, (basis * CFrame.new(0, 8, -0.3)).Position, 0.65, C.gold, math.pi)
        else
            sign(display, "ARCADE RECORDS\nEvery great run leaves a mark", C.deep)
            prompt(display, "RecordsPrompt", "View records", "Record Pavilion")
            disc(gallery, "TrophyFoot", 1.8, 0.5, basis * CFrame.new(0, 6.8, 0), C.pearl)
            part(
                gallery,
                "TrophyStem",
                Vector3.new(0.6, 1.7, 0.6),
                basis * CFrame.new(0, 7.7, 0),
                C.gold
            )
            oval(
                gallery,
                "TrophyCup",
                Vector3.new(3.4, 2, 2.3),
                basis * CFrame.new(0, 9.3, 0),
                C.gold
            )
            for _, direction in { -1, 1 } do
                oval(
                    gallery,
                    "TrophyHandle",
                    Vector3.new(1.3, 1.7, 0.5),
                    basis * CFrame.new(direction * 1.7, 9.5, 0),
                    C.gold
                )
            end
            oval(
                gallery,
                "TrophyPearl",
                Vector3.one * 0.85,
                basis * CFrame.new(0, 10.9, 0),
                C.pearl
            )
        end
    end
    for _, x in { -7, 7 } do
        plant(gallery, origin + Vector3.new(x, 0.9, -49), 0.9, C.lime)
    end
    local tutorial = part(
        gallery,
        "HowToPlay",
        Vector3.new(12, 5, 0.4),
        CFrame.new(origin + Vector3.new(0, 5.2, -52)) * CFrame.Angles(0, math.pi, 0),
        C.deep
    )
    sign(
        tutorial,
        "AIM → POP → GROW\nReach the target. Earn restocks.\nUpgrade your rack. Discover evolutions.",
        C.pearl
    )
    local info = part(
        gallery,
        "ArcadeRules",
        Vector3.new(12, 1.5, 0.3),
        CFrame.new(origin + Vector3.new(0, 1.8, -52)) * CFrame.Angles(0, math.pi, 0),
        C.pearl
    )
    sign(info, "8 FRIENDS · 8 INDEPENDENT RUNS", C.blue)
end

function HubWorld:spawnCFrame(station)
    local pod = self.stations[station]
    if pod then
        local position = (pod.basis * CFrame.new(0, 3.5, -10)).Position
        return CFrame.lookAt(position, pod.basis.Position + Vector3.new(0, 3.5, 0))
    end
    local position = HubWorld.Origin + Vector3.new(0, 3.5, 42)
    return CFrame.lookAt(position, HubWorld.Origin + Vector3.new(0, 3.5, 0))
end

function HubWorld:setStation(station, occupant)
    local pod = self.stations[station]
    if not pod then
        return
    end
    if occupant then
        pod.model:SetAttribute("OccupantUserId", occupant.userId)
        pod.ownerText.Text = string.sub(occupant.name or "Player", 1, 30)
        pod.statusText.Text = if occupant.view == "run"
            then "IN RUN · ROUND " .. tostring(occupant.round or 1)
            else "IN ARCADE · BEST " .. tostring(occupant.bestRound or 0)
        pod.light.Color = if occupant.view == "run" then C.gold else C.aqua
        pod.prompt.ObjectText = pod.ownerText.Text .. " · " .. pod.name
        pod.prompt.ActionText = if occupant.view == "run" then "In run" else "Play"
    else
        pod.model:SetAttribute("OccupantUserId", nil)
        pod.ownerText.Text = "OPEN"
        pod.statusText.Text = "YOUR NEXT RUN"
        pod.light.Color = C.lime
        pod.prompt.ObjectText = pod.name
        pod.prompt.ActionText = "Play"
    end
end

function HubWorld.new(onPlayRequested)
    local self = setmetatable({
        model = make("Model", { Name = "AquariumArcade" }, workspace),
        connections = {},
        stations = {},
        onPlayRequested = onPlayRequested,
    }, HubWorld)
    self.model:SetAttribute("Capacity", HubWorld.Capacity)
    self:_buildAtrium()
    self:_buildAquarium()
    for index, config in PODS do
        self:_buildPod(index, config)
    end
    self:_buildGallery()
    return self
end

function HubWorld:destroy()
    for _, connection in self.connections do
        connection:Disconnect()
    end
    self.model:Destroy()
end

return HubWorld
