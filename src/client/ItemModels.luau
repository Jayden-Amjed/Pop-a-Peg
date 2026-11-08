local ItemModels = {}
local ItemMotion = require(script.Parent.ItemMotion)

local P = {
    steel = Color3.fromRGB(139, 189, 219),
    dark = Color3.fromRGB(44, 88, 126),
    silver = Color3.fromRGB(218, 241, 253),
    ceramic = Color3.fromRGB(249, 253, 255),
    teal = Color3.fromRGB(39, 189, 220),
    blue = Color3.fromRGB(48, 153, 239),
    cyan = Color3.fromRGB(145, 244, 255),
    gold = Color3.fromRGB(249, 189, 63),
    brass = Color3.fromRGB(169, 206, 223),
    copper = Color3.fromRGB(113, 178, 214),
    orange = Color3.fromRGB(250, 129, 55),
    green = Color3.fromRGB(142, 220, 103),
    purple = Color3.fromRGB(147, 177, 245),
    red = Color3.fromRGB(236, 91, 92),
}
local V = Vector3.new
local builders = {}
local categories = {}
local ids = {}

local function frame(x, y, z, rx, ry, rz)
    return CFrame.new(x, y, z)
        * CFrame.Angles(math.rad(rx or 0), math.rad(ry or 0), math.rad(rz or 0))
end

local function part(model, shape, color, size, transform, material)
    local object = Instance.new("Part")
    object.Name = "Detail"
    object.Shape = shape
    object.Size = size
    object.CFrame = transform
    object.Color = color
    object.Material = material or Enum.Material.SmoothPlastic
    object.Reflectance = if color == P.ceramic then 0.08 elseif color == P.silver then 0.18 else 0.04
    object.Anchored = true
    object.CanCollide = false
    object.CanTouch = false
    object.CanQuery = false
    object.Massless = true
    object.TopSurface = Enum.SurfaceType.Smooth
    object.BottomSurface = Enum.SurfaceType.Smooth
    object.Parent = model
    return object
end

local function block(m, color, w, h, d, x, y, z, rx, ry, rz)
    return part(m, Enum.PartType.Block, color, V(w, h, d), frame(x, y, z, rx, ry, rz))
end

local function sphere(m, color, w, h, d, x, y, z)
    return part(m, Enum.PartType.Ball, color, V(w, h, d), frame(x, y, z))
end

local function disc(m, color, radius, depth, x, y, z)
    return part(
        m,
        Enum.PartType.Cylinder,
        color,
        V(depth, radius * 2, radius * 2),
        frame(x, y, z, 0, 90)
    )
end

local function drum(m, color, radius, height, x, y, z)
    return part(
        m,
        Enum.PartType.Cylinder,
        color,
        V(height, radius * 2, radius * 2),
        frame(x, y, z, 0, 0, 90)
    )
end

local function rod(m, color, a, b, radius)
    local delta = b - a
    return part(
        m,
        Enum.PartType.Cylinder,
        color,
        V(delta.Magnitude, radius * 2, radius * 2),
        CFrame.lookAt((a + b) / 2, b) * CFrame.Angles(0, math.pi / 2, 0),
        Enum.Material.Metal
    )
end

local function wedge(m, color, size, transform)
    local object = Instance.new("WedgePart")
    object.Name = "Facet"
    object.Size, object.CFrame, object.Color = size, transform, color
    object.Material = Enum.Material.SmoothPlastic
    object.Anchored, object.CanCollide, object.CanTouch, object.CanQuery = true, false, false, false
    object.TopSurface, object.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
    object.Parent = m
    return object
end

local function light(object)
    object.Name = "Glow"
    object.Material = Enum.Material.Neon
    return object
end

local function glass(object, transparency)
    object.Material = Enum.Material.Glass
    object.Transparency = transparency or 0.24
    object.Reflectance = 0.16
    return object
end

local function named(object, group)
    object.Name = group
    object:SetAttribute("MotionGroup", group)
    return object
end

local function bolt(m, x, y, z, radius)
    disc(m, P.silver, radius or 0.085, 0.06, x, y, z)
    block(m, P.dark, (radius or 0.085) * 1.2, 0.025, 0.012, x, y, z + 0.035, 0, 0, 30)
end

local function bezel(m, x, y, z, radius, color)
    disc(m, P.brass, radius, 0.14, x, y, z)
    disc(m, P.dark, radius * 0.84, 0.06, x, y, z + 0.085)
    disc(m, color, radius * 0.69, 0.03, x, y, z + 0.13)
end

local function ring(m, color, radius, thickness, transform, segments, arc)
    local count = segments or 16
    local sweep = arc or math.pi * 2
    for index = 0, count - 1 do
        local first, second = sweep * index / count, sweep * (index + 1) / count
        rod(
            m,
            color,
            transform:PointToWorldSpace(V(math.cos(first) * radius, math.sin(first) * radius, 0)),
            transform:PointToWorldSpace(V(math.cos(second) * radius, math.sin(second) * radius, 0)),
            thickness
        )
    end
end

local function gear(m, x, y, z, radius, color, group)
    local before = #m:GetChildren()
    disc(m, color, radius * 0.84, 0.16, x, y, z)
    for index = 0, 9 do
        local angle = index * math.pi / 5
        block(
            m,
            color,
            0.2,
            radius * 0.37,
            0.18,
            x + math.sin(angle) * radius,
            y + math.cos(angle) * radius,
            z,
            0,
            0,
            -index * 36
        )
    end
    disc(m, P.steel, radius * 0.29, 0.2, x, y, z + 0.03)
    bolt(m, x, y, z + 0.14, radius * 0.13)
    if group then
        for index, object in ipairs(m:GetChildren()) do
            if index > before then
                named(object, group)
            end
        end
    end
end

local function feet(m, width, y, depth)
    for _, x in ipairs({ -width / 2, width / 2 }) do
        for _, z in ipairs({ -depth / 2, depth / 2 }) do
            block(m, P.dark, 0.35, 0.22, 0.4, x, y, z)
        end
    end
end

local function plinth(m, width, y, depth, color)
    -- Structural feet belong to the device; broad circular display pads do not.
    block(m, P.steel, width * 0.86, 0.18, depth * 0.86, 0, y - 0.06, 0)
    block(m, P.dark, width * 0.79, 0.055, depth * 0.78, 0, y - 0.17, 0)
    glass(block(m, color or P.cyan, width * 0.8, 0.045, depth * 0.8, 0, y + 0.055, 0), 0.3)
    for _, x in ipairs({ -width * 0.32, width * 0.32 }) do
        sphere(m, P.silver, 0.18, 0.08, 0.16, x, y - 0.22, 0)
    end
end

local function register(id, category, builder)
    builders[id], categories[id] = builder, category
    table.insert(ids, id)
end

register("tap_driver", "equipment", function(m, level)
    block(m, P.teal, 1.85, 0.88, 0.9, 0, 0.45, 0)
    block(m, P.dark, 1.35, 0.7, 0.64, 0, 0.45, 0.03)
    block(m, P.silver, 0.9, 0.5, 0.72, 0.78, 0.45, 0)
    rod(m, P.steel, V(1.1, 0.45, 0), V(1.62, 0.45, 0), 0.22)
    rod(m, P.silver, V(1.62, 0.45, 0), V(1.96, 0.45, 0), 0.11)
    block(m, P.orange, 0.48, 1.1, 0.58, -0.2, -0.45, 0, 0, 0, -12)
    for index = 0, 4 do
        block(m, P.dark, 0.5, 0.075, 0.61, -0.2 - index * 0.025, -0.12 - index * 0.18, 0, 0, 0, -12)
    end
    block(m, P.copper, 0.17, 0.35, 0.14, 0.22, -0.22, 0.3)
    for _, x in ipairs({ -0.7, 0.55 }) do
        for _, y in ipairs({ 0.18, 0.72 }) do
            bolt(m, x, y, 0.48)
        end
    end
    rod(m, P.dark, V(-0.95, 0.4, 0), V(-1.2, -0.35, 0), 0.09)
    rod(m, P.dark, V(-1.2, -0.35, 0), V(-0.4, -1.08, 0), 0.09)
    light(disc(m, P.cyan, 0.13, 0.05, 0.1, 0.47, 0.5))
    if level >= 2 then
        rod(m, P.gold, V(0.9, 0.95, 0), V(1.6, 0.95, 0), 0.18)
    end
end)

register("split_prism", "equipment", function(m, level)
    plinth(m, 1.85, -0.86, 1.25)
    glass(named(wedge(m, P.cyan, V(1.1, 1.9, 0.8), frame(-0.28, 0.2, 0)), "Crystal"), 0.18)
    glass(named(wedge(m, P.purple, V(1.1, 1.9, 0.8), frame(0.28, 0.2, 0, 0, 180)), "Crystal"), 0.18)
    for _, x in ipairs({ -0.8, 0.8 }) do
        rod(m, P.brass, V(x, -0.7, -0.4), V(0, 1.24, -0.4), 0.075)
        rod(m, P.brass, V(x, -0.7, 0.4), V(0, 1.24, 0.4), 0.075)
    end
    rod(m, P.silver, V(-0.8, -0.7, 0.4), V(0.8, -0.7, 0.4), 0.08)
    bezel(m, 0, 0.1, 0.5, 0.27, P.ceramic)
    for _, side in ipairs({ -1, 1 }) do
        light(
            rod(
                m,
                if side < 0 then P.cyan else P.purple,
                V(side * 0.4, 0.32, 0),
                V(side * 1.25, 0.8, 0),
                0.1
            )
        )
        bolt(m, side * 0.68, -0.75, 0.65)
    end
    if level >= 2 then
        light(sphere(m, P.gold, 0.4, 0.4, 0.4, 0, 1.3, 0))
    end
end)

register("wall_meter", "equipment", function(m)
    plinth(m, 2.1, -1, 1.1)
    block(m, P.teal, 1.35, 1.7, 0.72, 0.35, 0, 0)
    block(m, P.dark, 0.98, 1.2, 0.07, 0.35, 0.12, 0.4)
    for index = 0, 2 do
        light(
            block(
                m,
                ({ P.green, P.gold, P.orange })[index + 1],
                0.17,
                0.42 + index * 0.22,
                0.04,
                0.07 + index * 0.28,
                -0.15 + index * 0.11,
                0.45
            )
        )
    end
    block(m, P.steel, 0.24, 2.1, 1.03, -0.88, 0, 0)
    block(m, P.orange, 0.34, 1.75, 1.15, -1.1, 0, 0)
    for index = 0, 4 do
        block(m, P.dark, 0.37, 0.09, 1.18, -1.12, -0.65 + index * 0.32, 0)
    end
    bezel(m, 0.35, -0.67, 0.43, 0.16, P.silver)
    for _, x in ipairs({ -0.2, 0.9 }) do
        for _, y in ipairs({ -0.7, 0.73 }) do
            bolt(m, x, y, 0.43)
        end
    end
end)

register("clockwork", "equipment", function(m, level)
    disc(m, P.brass, 1.12, 0.5, 0, 0.15, 0)
    disc(m, P.dark, 0.96, 0.06, 0, 0.15, 0.29)
    gear(m, -0.34, 0.12, 0.36, 0.43, P.gold, "LeftGear")
    gear(m, 0.36, 0.42, 0.36, 0.32, P.copper, "RightGear")
    for index = 0, 11 do
        local angle = index * math.pi / 6
        block(
            m,
            P.ceramic,
            0.07,
            0.17,
            0.04,
            math.sin(angle) * 0.88,
            0.15 + math.cos(angle) * 0.88,
            0.37,
            0,
            0,
            -index * 30
        )
    end
    rod(m, P.cyan, V(0, 0.15, 0.62), V(0, 0.83, 0.62), 0.045)
    rod(m, P.ceramic, V(0, 0.15, 0.65), V(0.43, 0.43, 0.65), 0.055)
    disc(m, P.silver, 0.11, 0.12, 0, 0.15, 0.67)
    feet(m, 1.35, -0.98, 0.4)
    rod(m, P.steel, V(1, 0.25, 0), V(1.38, 0.25, 0), 0.1)
    disc(m, P.gold, 0.23, 0.1, 1.4, 0.25, 0)
    if level >= 2 then
        gear(m, 0.3, -0.46, 0.38, 0.25, P.silver, "LowerGear")
    end
end)

register("burst_capsule", "equipment", function(m, level)
    drum(m, P.orange, 0.68, 1.5, 0, 0, 0)
    sphere(m, P.orange, 1.36, 0.8, 1.36, 0, 0.69, 0)
    sphere(m, P.steel, 1.38, 0.65, 1.38, 0, -0.7, 0)
    drum(m, P.dark, 0.72, 0.28, 0, 0.05, 0)
    light(drum(m, P.cyan, 0.735, 0.12, 0, 0.05, 0))
    for index = 0, 2 do
        local angle = index * math.pi * 2 / 3
        wedge(
            m,
            P.steel,
            V(0.18, 1.05, 0.55),
            frame(math.cos(angle) * 0.7, -0.45, math.sin(angle) * 0.7, 0, -index * 120, 0)
        )
    end
    drum(m, P.brass, 0.22, 0.15, 0, 1.1, 0)
    ring(m, P.silver, 0.23, 0.045, frame(0, 1.41, 0), 12)
    for _, side in ipairs({ -1, 1 }) do
        block(m, P.dark, 0.08, 0.4, 0.055, side * 0.35, 0.6, 0.61, 0, 0, -side * 25)
        bolt(m, side * 0.4, -0.58, 0.6)
    end
    if level >= 2 then
        light(drum(m, P.gold, 0.74, 0.1, 0, 0.31, 0))
    end
end)

register("relay", "equipment", function(m, level)
    plinth(m, 1.95, -0.78, 1.3, P.ceramic)
    block(m, P.steel, 0.28, 1.4, 0.45, -0.65, 0, -0.15)
    block(m, P.steel, 0.28, 1.4, 0.45, 0.65, 0, -0.15)
    block(m, P.steel, 1.55, 0.22, 0.45, 0, 0.7, -0.15)
    rod(m, P.dark, V(-0.54, -0.08, 0), V(0.54, -0.08, 0), 0.29)
    for index = 0, 8 do
        part(
            m,
            Enum.PartType.Cylinder,
            P.copper,
            V(0.07, 0.78, 0.78),
            frame(-0.44 + index * 0.11, -0.08, 0),
            Enum.Material.Metal
        )
    end
    for _, x in ipairs({ -0.65, 0.65 }) do
        drum(m, P.gold, 0.13, 0.35, x, -0.42, 0.49)
        bolt(m, x, -0.72, 0.7)
    end
    block(m, P.silver, 1.2, 0.12, 0.16, 0, 0.5, 0.4, 0, 0, -10)
    light(sphere(m, P.cyan, 0.18, 0.18, 0.18, 0.57, 0.44, 0.43))
    if level >= 2 then
        block(m, P.gold, 1.18, 0.1, 0.14, 0, 0.31, 0.5, 0, 0, 8)
    end
end)

local function coin(m, x, y, z, radius)
    local r = radius or 0.75
    disc(m, P.brass, r, 0.24, x, y, z)
    disc(m, P.gold, r * 0.91, 0.26, x, y, z)
    disc(m, P.brass, r * 0.71, 0.025, x, y, z + 0.14)
    disc(m, P.gold, r * 0.61, 0.025, x, y, z + 0.16)
    for index = 0, 11 do
        local a = index * math.pi / 6
        block(
            m,
            P.ceramic,
            r * 0.035,
            r * 0.09,
            0.03,
            x + math.sin(a) * r * 0.84,
            y + math.cos(a) * r * 0.84,
            z + 0.145,
            0,
            0,
            -index * 30
        )
    end
    disc(m, P.ceramic, r * 0.2, 0.055, x, y + r * 0.1, z + 0.19)
    block(m, P.ceramic, r * 0.15, r * 0.34, 0.05, x, y - r * 0.18, z + 0.19)
end

register("landing_fund", "equipment", function(m)
    plinth(m, 2.1, -0.95, 1.45)
    sphere(m, P.ceramic, 2.1, 0.5, 1.55, 0, -0.59, 0.1)
    glass(sphere(m, P.cyan, 1.78, 0.23, 1.31, 0, -0.34, 0.13), 0.22)
    named(sphere(m, P.ceramic, 1.95, 1.6, 0.3, 0, 0.33, -0.49), "ShellLid")
    for index = -4, 4 do
        local angle = index * math.pi / 11
        named(
            rod(
                m,
                P.silver,
                V(0, -0.42, -0.26),
                V(math.sin(angle) * 0.85, -0.08 + math.cos(angle) * 1.15, -0.26),
                0.045
            ),
            "ShellLid"
        )
        named(
            sphere(
                m,
                P.ceramic,
                0.24,
                0.27,
                0.32,
                math.sin(angle) * 0.85,
                -0.08 + math.cos(angle) * 1.15,
                -0.4
            ),
            "ShellLid"
        )
    end
    coin(m, 0, 0.05, 0.4, 0.42)
    sphere(m, P.ceramic, 0.3, 0.3, 0.3, -0.56, -0.16, 0.37)
    sphere(m, P.ceramic, 0.24, 0.24, 0.24, 0.6, -0.2, 0.3)
end)

register("survey_lens", "equipment", function(m, level)
    for _, sign in ipairs({ -1, 1 }) do
        rod(m, P.steel, V(0, -0.2, 0), V(sign * 0.78, -1.3, 0.35), 0.1)
    end
    rod(m, P.steel, V(0, -0.2, 0), V(0, -1.3, -0.88), 0.1)
    drum(m, P.brass, 0.24, 0.65, 0, -0.16, 0)
    for index = 0, 2 do
        disc(
            m,
            if index == 1 then P.teal else P.steel,
            0.48 + index * 0.09,
            0.62,
            0,
            0.62,
            -0.58 + index * 0.57
        )
    end
    bezel(m, 0, 0.62, 0.92, 0.68, P.blue)
    light(disc(m, P.cyan, 0.46, 0.04, 0, 0.62, 1.08))
    rod(m, P.ceramic, V(-0.27, 0.76, 1.12), V(0.08, 0.97, 1.12), 0.04)
    gear(m, 0.53, 0.55, 0.12, 0.22, P.brass)
    for _, x in ipairs({ -0.52, 0.52 }) do
        bolt(m, x, 0.62, 0.97)
    end
    if level >= 2 then
        disc(m, P.gold, 0.7, 0.13, 0, 0.62, 0.69)
    end
end)

register("gain_dial", "equipment", function(m)
    disc(m, P.steel, 1.02, 0.55, 0, 0, 0)
    for index = 0, 7 do
        local a = index * math.pi / 4
        block(
            m,
            P.purple,
            0.6,
            0.25,
            0.58,
            math.sin(a) * 0.93,
            math.cos(a) * 0.93,
            0,
            0,
            0,
            -index * 45
        )
    end
    bezel(m, 0, 0, 0.36, 0.78, P.dark)
    for index = 0, 10 do
        local a = math.rad(-135 + index * 27)
        block(
            m,
            P.ceramic,
            0.055,
            0.15,
            0.04,
            math.sin(a) * 0.65,
            math.cos(a) * 0.65,
            0.51,
            0,
            0,
            135 - index * 27
        )
    end
    disc(m, P.steel, 0.46, 0.4, 0, 0, 0.67)
    block(m, P.gold, 0.11, 0.46, 0.07, 0.13, 0.17, 0.9, 0, 0, -35)
    for _, x in ipairs({ -0.55, 0.55 }) do
        drum(m, P.gold, 0.13, 0.3, x, -1.15, 0)
    end
end)

register("soft_saw", "equipment", function(m)
    plinth(m, 2.2, -1, 1.25)
    glass(sphere(m, P.blue, 1.88, 0.25, 1.05, 0, -0.75, 0), 0.24)
    for index = 0, 23 do
        local a, b =
            -math.pi * 0.65 + index * math.pi * 1.7 / 24,
            -math.pi * 0.65 + (index + 1) * math.pi * 1.7 / 24
        local ra, rb = 0.88 - index * 0.021, 0.88 - (index + 1) * 0.021
        local wave = rod(
            m,
            if index < 12 then P.blue else P.cyan,
            V(math.cos(a) * ra, math.sin(a) * ra + 0.12, 0),
            V(math.cos(b) * rb, math.sin(b) * rb + 0.12, 0),
            0.14
        )
        glass(named(wave, "Current"), 0.12)
    end
    for index = 0, 4 do
        named(
            sphere(m, P.ceramic, 0.15, 0.15, 0.15, -0.85 + index * 0.32, -0.5 + index * 0.25, 0.14),
            "Foam"
        )
    end
end)

register("balance_scale", "equipment", function(m)
    plinth(m, 1.5, -1.1, 1)
    drum(m, P.brass, 0.16, 1.7, 0, -0.12, 0)
    sphere(m, P.gold, 0.35, 0.35, 0.35, 0, 0.89, 0)
    rod(m, P.gold, V(-1.15, 0.87, 0), V(1.15, 0.87, 0), 0.08)
    for _, x in ipairs({ -1.02, 1.02 }) do
        for _, z in ipairs({ -0.27, 0.27 }) do
            rod(m, P.silver, V(x, 0.83, 0), V(x, -0.32, z), 0.035)
        end
        drum(m, P.brass, 0.47, 0.12, x, -0.38, 0)
        drum(m, P.gold, 0.39, 0.08, x, -0.3, 0)
        sphere(
            m,
            if x < 0 then P.ceramic else P.cyan,
            if x < 0 then 0.35 else 0.55,
            if x < 0 then 0.35 else 0.55,
            if x < 0 then 0.35 else 0.55,
            x,
            if x < 0 then -0.08 else 0.02,
            0
        )
    end
    bezel(m, 0, -0.78, 0.43, 0.18, P.teal)
end)

register("resonator", "equipment", function(m, level)
    plinth(m, 1.25, -1.1, 1)
    drum(m, P.copper, 0.27, 0.5, 0, -0.75, 0)
    block(m, P.silver, 1.16, 0.3, 0.28, 0, -0.3, 0)
    for _, x in ipairs({ -0.46, 0.46 }) do
        block(m, P.silver, 0.25, 1.65, 0.28, x, 0.45, 0)
        block(m, P.teal, 0.31, 0.5, 0.34, x, 1.03, 0)
    end
    for index = 0, 3 do
        drum(m, P.brass, 0.33, 0.055, 0, -0.9 + index * 0.11, 0)
    end
    rod(m, P.dark, V(0, 0.9, 0), V(0, 0.35, 0), 0.035)
    light(sphere(m, P.cyan, 0.38, 0.38, 0.38, 0, 0.32, 0))
    if level >= 2 then
        block(m, P.gold, 0.2, 1.2, 0.2, 0, 0.7, -0.28)
    end
end)

register("echo_plate", "equipment", function(m)
    plinth(m, 1.4, -1.18, 1.1)
    sphere(m, P.ceramic, 1.85, 1.75, 0.5, 0, 0.05, 0)
    glass(sphere(m, P.purple, 1.57, 1.47, 0.35, 0, 0.08, 0.25), 0.22)
    for index = -5, 5 do
        local angle = index * math.pi / 12
        local x, y = math.sin(angle) * 0.94, -0.35 + math.cos(angle) * 1.28
        named(rod(m, P.silver, V(0, -0.85, 0.27), V(x, y, 0.27), 0.045), "ShellRibs")
        named(sphere(m, P.ceramic, 0.22, 0.25, 0.48, x, y, 0.04), "ShellRibs")
    end
    named(light(sphere(m, P.cyan, 0.39, 0.39, 0.39, 0, -0.55, 0.56)), "Pearl")
end)

register("growth_array", "equipment", function(m, level)
    plinth(m, 2.4, -0.93, 1.4)
    glass(sphere(m, P.cyan, 2.1, 0.32, 1.13, 0, -0.64, 0), 0.24)
    for index, x in ipairs({ -0.78, -0.26, 0.26, 0.78 }) do
        local color = ({ P.red, P.teal, P.purple, P.green })[index]
        local height = 0.65 + (index % 2) * 0.3
        named(rod(m, color, V(x, -0.54, 0), V(x, height, 0), 0.1), "Coral")
        for _, side in ipairs({ -1, 1 }) do
            named(rod(m, color, V(x, 0.06, 0), V(x + side * 0.18, 0.4, 0), 0.07), "Coral")
            named(sphere(m, color, 0.2, 0.2, 0.2, x + side * 0.18, 0.4, 0), "Coral")
        end
        named(sphere(m, P.ceramic, 0.22, 0.25, 0.22, x, height, 0), "Coral")
        sphere(m, P.ceramic, 0.2, 0.14, 0.23, x, -0.48, 0.32)
    end
    if level >= 2 then
        glass(sphere(m, P.gold, 0.3, 0.3, 0.3, 0, 1.08, 0), 0.1)
    end
end)

register("quota_bonus", "equipment", function(m)
    plinth(m, 1.8, -1, 1.4)
    block(m, P.steel, 0.3, 1.9, 0.4, -0.65, 0, -0.38)
    block(m, P.teal, 1.4, 0.38, 0.65, -0.1, 0.9, -0.2)
    drum(m, P.silver, 0.12, 1.05, 0.3, 0.3, 0)
    for index = 0, 4 do
        drum(m, P.brass, 0.24, 0.05, 0.3, 0.2 + index * 0.11, 0)
    end
    block(m, P.orange, 0.72, 0.24, 0.64, 0.3, -0.3, 0)
    block(m, P.dark, 0.76, 0.12, 0.68, 0.3, -0.45, 0)
    block(m, P.ceramic, 1.28, 0.06, 0.8, 0.18, -0.78, 0.34)
    for index = 0, 3 do
        block(m, P.teal, 0.58, 0.013, 0.045, 0.06, -0.741, 0.13 + index * 0.15)
    end
    rod(m, P.gold, V(0.3, 0.98, 0), V(1.02, 1.27, 0), 0.07)
    sphere(m, P.orange, 0.3, 0.3, 0.3, 1.05, 1.28, 0)
    bolt(m, -0.63, 0.62, -0.1)
end)

register("spring_coil", "equipment", function(m, level)
    drum(m, P.steel, 0.83, 0.24, 0, -1, 0)
    drum(m, P.teal, 0.74, 0.23, 0, 1.04, 0)
    drum(m, P.dark, 0.19, 1.9, 0, 0, 0)
    for index = 0, 35 do
        local a, b = index * math.pi / 6, (index + 1) * math.pi / 6
        local startPoint = V(math.cos(a) * 0.56, -0.85 + index * 0.05, math.sin(a) * 0.56)
        local endPoint = V(math.cos(b) * 0.56, -0.85 + (index + 1) * 0.05, math.sin(b) * 0.56)
        local segment = rod(m, if level >= 2 then P.gold else P.copper, startPoint, endPoint, 0.075)
        named(segment, "Coil")
        segment:SetAttribute("SpringA", startPoint)
        segment:SetAttribute("SpringB", endPoint)
    end
    for _, x in ipairs({ -0.5, 0.5 }) do
        for _, z in ipairs({ -0.4, 0.4 }) do
            drum(m, P.silver, 0.085, 0.1, x, 1.19, z)
        end
    end
end)

register("pulse_cell", "equipment", function(m, level)
    block(m, P.blue, 1.55, 1.85, 1, 0, 0, 0)
    block(m, P.dark, 1.05, 1.42, 0.07, 0, 0, 0.54)
    for index = 0, 4 do
        light(
            block(
                m,
                if index > 2 then P.green else P.cyan,
                0.8,
                0.18,
                0.045,
                0,
                -0.48 + index * 0.24,
                0.59
            )
        )
    end
    for _, x in ipairs({ -0.8, 0.8 }) do
        for index = 0, 4 do
            block(m, P.ceramic, 0.16, 0.11, 1.1, x, -0.58 + index * 0.28, 0)
        end
        drum(m, P.brass, 0.19, 0.25, x * 0.56, 1.04, 0)
    end
    block(m, P.silver, 1.68, 0.18, 1.12, 0, -0.91, 0)
    for _, x in ipairs({ -0.61, 0.61 }) do
        bolt(m, x, 0.73, 0.58)
    end
    if level >= 2 then
        rod(m, P.gold, V(-0.45, 1.18, 0), V(0.45, 1.18, 0), 0.07)
    end
end)

register("compass", "equipment", function(m)
    bezel(m, 0, 0, 0, 1.03, P.ceramic)
    for index = 0, 7 do
        local a = index * math.pi / 4
        block(
            m,
            P.steel,
            0.06,
            if index % 2 == 0 then 0.22 else 0.12,
            0.035,
            math.sin(a) * 0.67,
            math.cos(a) * 0.67,
            0.15,
            0,
            0,
            -index * 45
        )
    end
    wedge(m, P.red, V(0.15, 0.7, 0.1), frame(0.16, 0.26, 0.25, 0, 90, -35))
    wedge(m, P.blue, V(0.15, 0.7, 0.1), frame(-0.16, -0.26, 0.25, 0, -90, 145))
    disc(m, P.gold, 0.13, 0.08, 0, 0, 0.3)
    disc(m, P.brass, 0.78, 0.1, 0, 1.43, -0.3)
    disc(m, P.teal, 0.65, 0.11, 0, 1.43, -0.23)
    rod(m, P.silver, V(-0.36, 0.97, -0.11), V(0.36, 0.97, -0.11), 0.1)
    drum(m, P.gold, 0.18, 0.23, 1.04, 0, 0)
    for _, x in ipairs({ -0.7, 0.7 }) do
        bolt(m, x, -0.6, 0.14)
    end
end)

register("seed_bank", "equipment", function(m)
    plinth(m, 1.9, -0.96, 1.25)
    block(m, P.teal, 1.8, 0.48, 1.12, 0, -0.62, 0)
    block(m, P.steel, 1.85, 0.18, 1.18, 0, 1, 0)
    for _, x in ipairs({ -0.78, 0.78 }) do
        for _, z in ipairs({ -0.45, 0.45 }) do
            rod(m, P.brass, V(x, -0.4, z), V(x, 0.95, z), 0.065)
        end
    end
    for index = 0, 2 do
        local x = -0.53 + index * 0.53
        drum(m, P.ceramic, 0.21, 0.12, x, -0.3, 0)
        sphere(m, P.green, 0.42, 0.87, 0.4, x, 0.22, 0)
        rod(m, P.brass, V(x, -0.1, 0.2), V(x, 0.55, 0.2), 0.025)
    end
    block(m, P.gold, 0.25, 0.42, 0.09, 0, -0.53, 0.63)
    bolt(m, 0, -0.54, 0.7)
    for _, x in ipairs({ -0.5, 0.5 }) do
        rod(m, P.silver, V(x - 0.15, 0.94, -0.57), V(x + 0.15, 0.94, -0.57), 0.1)
    end
    block(m, P.dark, 0.75, 0.1, 0.2, 0, 1.19, 0)
end)

register("encore", "equipment", function(m, level)
    plinth(m, 2.2, -1.03, 1.3)
    block(m, P.purple, 1.7, 0.72, 0.9, 0, -0.5, 0)
    for index = 0, 4 do
        block(m, P.dark, 1.18, 0.05, 0.04, 0, -0.7 + index * 0.1, 0.48)
    end
    for _, x in ipairs({ -0.65, 0.65 }) do
        rod(m, P.brass, V(x, -0.18, 0), V(x, 0.45, 0), 0.12)
        disc(m, P.brass, 0.25, 0.55, x, 0.57, -0.15)
        disc(m, P.gold, 0.4, 0.22, x, 0.57, 0.22)
        disc(m, P.copper, 0.62, 0.15, x, 0.57, 0.43)
        disc(m, P.dark, 0.51, 0.035, x, 0.57, 0.52)
        light(disc(m, if level >= 2 then P.gold else P.purple, 0.22, 0.05, x, 0.57, 0.55))
        bolt(m, x, -0.83, 0.49)
    end
    bezel(m, 0.65, -0.43, 0.51, 0.14, P.cyan)
    block(m, P.silver, 0.8, 0.12, 0.16, 0, 1.27, -0.15)
    for _, x in ipairs({ -0.33, 0.33 }) do
        block(m, P.silver, 0.12, 0.3, 0.16, x, 1.13, -0.15)
    end
end)

local function fish(m, center, scale)
    local before = #m:GetChildren()
    named(sphere(m, P.orange, 1.35, 0.83, 0.61, 0, 0, 0), "FishBody")
    named(sphere(m, P.gold, 0.66, 0.71, 0.57, 0.52, 0.03, 0), "FishBody")
    for _, side in ipairs({ -1, 1 }) do
        named(sphere(m, P.ceramic, 0.22, 0.25, 0.11, 0.58, 0.17, side * 0.275), "FishBody")
        named(sphere(m, P.dark, 0.1, 0.13, 0.055, 0.62, 0.18, side * 0.335), "FishBody")
        named(sphere(m, P.ceramic, 0.035, 0.035, 0.025, 0.64, 0.21, side * 0.365), "FishBody")
        named(
            wedge(m, P.gold, V(0.42, 0.4, 0.1), frame(-0.1, -0.22, side * 0.3, 20 * side, 0, -35)),
            "FishFin"
        )
        for index = 0, 2 do
            named(
                rod(
                    m,
                    P.orange,
                    V(0.33, -0.15 + index * 0.1, side * 0.3),
                    V(0.39, -0.09 + index * 0.1, side * 0.3),
                    0.02
                ),
                "FishBody"
            )
        end
    end
    named(wedge(m, P.gold, V(0.8, 0.43, 0.1), frame(-0.2, 0.5, 0, 0, 0, -12)), "FishFin")
    for _, side in ipairs({ -1, 1 }) do
        named(
            wedge(
                m,
                P.orange,
                V(0.65, 0.56, 0.17),
                frame(-0.92, side * 0.22, 0, 0, side < 0 and 180 or 0, side * 65)
            ),
            "FishTail"
        )
        named(rod(m, P.gold, V(-0.56, 0, 0.08), V(-1.16, side * 0.46, 0.08), 0.035), "FishTail")
    end
    for index = 0, 5 do
        named(
            disc(
                m,
                if index % 2 == 0 then P.gold else P.orange,
                0.1,
                0.025,
                -0.4 + (index % 3) * 0.24,
                -0.1 + math.floor(index / 3) * 0.2,
                0.3
            ),
            "FishBody"
        )
    end
    named(
        part(m, Enum.PartType.Cylinder, P.orange, V(0.06, 0.17, 0.17), frame(0.87, -0.04, 0)),
        "FishBody"
    )
    for index, object in ipairs(m:GetChildren()) do
        if index > before then
            object.CFrame = CFrame.new(center + object.Position * scale) * object.CFrame.Rotation
            object.Size *= scale
            if object:GetAttribute("MotionGroup") == "FishTail" then
                object:SetAttribute("MotionPivot", center + V(-0.56, 0, 0) * scale)
            end
        end
    end
end

register("goldfish", "equipment", function(m, level)
    fish(m, V(0, 0.12, 0), 1)
    for index = 0, 2 do
        named(
            glass(
                sphere(
                    m,
                    P.cyan,
                    0.18 + index * 0.025,
                    0.18 + index * 0.025,
                    0.18 + index * 0.025,
                    0.92 + index * 0.15,
                    0.34 + index * 0.27,
                    0.05
                ),
                0.45
            ),
            "Bubbles"
        )
    end
    if level >= 2 then
        glass(named(sphere(m, P.cyan, 0.29, 0.29, 0.29, -0.86, 0.83, 0), "Bubbles"), 0.4)
    end
end)

register("fishbowl", "equipment", function(m, level)
    glass(named(sphere(m, P.cyan, 2.08, 1.64, 2.08, 0, -0.15, 0), "Water"), 0.69)
    named(glass(drum(m, P.blue, 0.94, 0.035, 0, 0.5, 0), 0.4), "Waterline")
    fish(m, V(0.06, -0.08, 0.22), if level >= 2 then 0.6 else 0.52)
    for index = 0, 6 do
        local a = index * math.pi * 2 / 7
        sphere(
            m,
            if index % 2 == 0 then P.ceramic else P.silver,
            0.4,
            0.13,
            0.28,
            math.cos(a) * 0.65,
            -0.86,
            math.sin(a) * 0.65
        )
    end
    for index = 0, 2 do
        local x = -0.63 + index * 0.18
        named(
            rod(m, P.green, V(x, -0.79, -0.35), V(x - 0.1, -0.06 + index * 0.13, -0.35), 0.045),
            "Reeds"
        )
        named(
            wedge(m, P.green, V(0.22, 0.37, 0.06), frame(x - 0.06, -0.3, -0.35, 0, 0, -22)),
            "Reeds"
        )
    end
    for index = 0, 2 do
        named(
            glass(
                sphere(m, P.cyan, 0.14, 0.14, 0.14, 0.58 + index * 0.12, 0.05 + index * 0.22, 0.3),
                0.4
            ),
            "Bubbles"
        )
    end
    glass(sphere(m, P.silver, 2.36, 2.21, 2.36, 0, 0.02, 0), 0.83)
    ring(m, P.ceramic, 0.76, 0.055, frame(0, 0.97, 0, 90), 20)
    glass(drum(m, P.cyan, 0.74, 0.025, 0, 0.97, 0), 0.88)
    sphere(m, P.ceramic, 0.1, 0.52, 0.045, -0.68, 0.31, 0.88)
    sphere(m, P.ceramic, 0.09, 0.22, 0.045, -0.69, -0.12, 0.94)
end)

-- Evolution devices are authored as complete objects, with moving subassemblies
-- and recognisable parts from both ingredients rather than two overlapping icons.
-- Unlock collection: each device has its own silhouette and articulated parts.
local function moving(object, group, pivot)
    named(object, group)
    if pivot then
        object:SetAttribute("MotionPivot", pivot)
    end
    return object
end

register("rain_catcher", "equipment", function(m)
    feet(m, 1.1, -1.02, 0.68)
    glass(block(m, P.cyan, 1.18, 0.96, 0.82, 0, -0.48, 0), 0.28)
    block(m, P.ceramic, 1.25, 0.13, 0.89, 0, -0.97, 0)
    moving(block(m, P.blue, 1.04, 0.31, 0.71, 0, -0.73, 0), "RainWater")
    rod(m, P.silver, V(0, 0.03, 0), V(0, 0.53, 0), 0.12)
    for _, side in { -1, 1 } do
        wedge(
            m,
            P.ceramic,
            V(0.86, 0.56, 0.95),
            frame(side * 0.43, 0.62, 0, 0, side == 1 and 0 or 180)
        )
        rod(m, P.teal, V(side * 0.89, 0.91, -0.46), V(side * 0.89, 0.91, 0.46), 0.055)
    end
    for i = 1, 3 do
        moving(
            glass(
                sphere(m, P.blue, 0.16, 0.28, 0.16, (i - 2) * 0.52, 1.27 + (i % 2) * 0.15, 0),
                0.08
            ),
            "RainDrop"
        )
    end
    for i = 0, 3 do
        block(m, P.gold, 0.18, 0.035, 0.03, 0.43, -0.7 + i * 0.19, 0.43)
    end
end)

register("bubble_wand", "equipment", function(m)
    drum(m, P.ceramic, 0.4, 0.65, -0.49, -0.69, 0)
    drum(m, P.teal, 0.44, 0.12, -0.49, -0.33, 0)
    moving(
        rod(m, P.gold, V(-0.49, -0.35, 0), V(0.24, 0.61, 0), 0.085),
        "WandStem",
        V(-0.49, -0.35, 0)
    )
    local before = #m:GetChildren()
    ring(m, P.gold, 0.47, 0.085, frame(0.53, 0.97, 0, 0, 0, -28), 14)
    glass(disc(m, P.cyan, 0.39, 0.025, 0.53, 0.97, 0), 0.6)
    for i = before + 1, #m:GetChildren() do
        moving(m:GetChildren()[i], "WandLoop", V(-0.49, -0.35, 0))
    end
    for i = 1, 3 do
        local r = 0.16 + i * 0.055
        moving(
            glass(
                sphere(m, P.cyan, r * 2, r * 2, r * 2, 0.9 + i * 0.12, 0.32 - i * 0.31, 0.25),
                0.54
            ),
            "WandBubble"
        )
    end
    disc(m, P.cyan, 0.19, 0.03, -0.49, -0.66, 0.4)
end)

register("lily_pad", "equipment", function(m)
    glass(drum(m, P.blue, 1.03, 0.1, 0, -0.73, 0), 0.28)
    local pad = moving(sphere(m, P.green, 1.82, 0.16, 1.51, 0, -0.57, 0), "LilyPad")
    pad.CFrame *= CFrame.Angles(0, 0, math.rad(-5))
    for i = 0, 4 do
        local a = i * math.pi * 0.4
        rod(m, P.ceramic, V(0, -0.47, 0), V(math.cos(a) * 0.75, -0.47, math.sin(a) * 0.6), 0.018)
    end
    for i = 0, 5 do
        local a = i * math.pi / 3
        local petal = moving(
            sphere(m, P.ceramic, 0.32, 0.9, 0.2, math.sin(a) * 0.24, -0.03, math.cos(a) * 0.24),
            "LilyPetal",
            V(0, -0.4, 0)
        )
        petal.CFrame *= CFrame.Angles(math.cos(a) * 0.55, 0, -math.sin(a) * 0.55)
    end
    moving(light(sphere(m, P.gold, 0.36, 0.33, 0.36, 0, 0.11, 0)), "LilyHeart")
    moving(glass(sphere(m, P.cyan, 0.23, 0.3, 0.23, -0.66, -0.32, 0.29), 0.12), "LilyDew")
end)

register("solar_leaf", "equipment", function(m)
    block(m, P.ceramic, 0.75, 0.43, 0.75, 0, -0.83, 0)
    rod(m, P.gold, V(0, -0.62, 0), V(0, 0.47, 0), 0.065)
    for _, side in { -1, 1 } do
        local pivot = V(0, -0.05, 0)
        local leaf =
            moving(sphere(m, P.green, 0.62, 1.29, 0.16, side * 0.4, 0.42, 0), "SolarLeaf", pivot)
        leaf.CFrame *= CFrame.Angles(0, 0, -side * 0.47)
        for i = 0, 3 do
            moving(
                block(
                    m,
                    P.blue,
                    0.39,
                    0.13,
                    0.05,
                    side * (0.27 + i * 0.07),
                    0.1 + i * 0.22,
                    0.1,
                    0,
                    0,
                    -side * 27
                ),
                "SolarCell",
                pivot
            )
        end
        moving(
            rod(m, P.gold, V(0, -0.05, 0.12), V(side * 0.65, 0.97, 0.12), 0.025),
            "SolarVein",
            pivot
        )
    end
    moving(light(sphere(m, P.gold, 0.36, 0.36, 0.36, 0, 1.28, 0)), "SolarSun")
end)

register("mist_fan", "equipment", function(m)
    feet(m, 1.1, -1.05, 0.65)
    block(m, P.ceramic, 1.75, 1.71, 0.58, 0, 0, 0)
    disc(m, P.dark, 0.72, 0.13, 0, 0.09, 0.33)
    for i = 0, 3 do
        local a = i * math.pi / 2
        moving(
            wedge(
                m,
                P.teal,
                V(0.36, 0.68, 0.1),
                frame(0, 0.09, 0.43) * CFrame.Angles(0, 0, a) * frame(0.18, 0.3, 0)
            ),
            "MistRotor",
            V(0, 0.09, 0.43)
        )
    end
    disc(m, P.silver, 0.17, 0.1, 0, 0.09, 0.51)
    for _, x in { -0.54, -0.27, 0, 0.27, 0.54 } do
        rod(m, P.silver, V(x, -0.49, 0.58), V(x, 0.67, 0.58), 0.025)
    end
    for i = 0, 2 do
        moving(
            glass(
                sphere(
                    m,
                    P.cyan,
                    0.22 + i * 0.08,
                    0.16,
                    0.28,
                    -0.36 + i * 0.36,
                    0.04,
                    0.85 + i * 0.12
                ),
                0.55
            ),
            "MistPuff"
        )
    end
    block(m, P.blue, 1.3, 0.13, 0.08, 0, -0.69, 0.37)
end)

register("coral_fork", "equipment", function(m)
    block(m, P.dark, 1.15, 0.22, 0.95, 0, -0.89, 0)
    rod(m, P.ceramic, V(0, -0.76, 0), V(0, 0.85, 0), 0.13)
    for _, side in { -1, 1 } do
        for i = 0, 2 do
            local y = -0.31 + i * 0.43
            moving(
                rod(
                    m,
                    i % 2 == 0 and P.orange or P.cyan,
                    V(0, y, 0),
                    V(side * (0.57 + i * 0.13), y + 0.3, 0),
                    0.085
                ),
                "CoralTine"
            )
            moving(
                sphere(m, P.ceramic, 0.2, 0.2, 0.2, side * (0.57 + i * 0.13), y + 0.3, 0),
                "CoralTip"
            )
        end
    end
    moving(sphere(m, P.teal, 0.3, 0.5, 0.3, 0, 1.03, 0), "CoralCrown")
    for _, x in { -0.4, 0.4 } do
        sphere(m, P.gold, 0.21, 0.2, 0.23, x, -0.7, 0.2)
    end
end)

register("tide_valve", "equipment", function(m)
    rod(m, P.ceramic, V(-1.16, -0.4, 0), V(1.16, -0.4, 0), 0.32)
    for _, x in { -1, 1 } do
        part(
            m,
            Enum.PartType.Cylinder,
            P.teal,
            V(0.18, 0.91, 0.91),
            frame(x, -0.4, 0),
            Enum.Material.Metal
        )
    end
    block(m, P.silver, 0.85, 0.63, 0.72, 0, -0.31, 0)
    rod(m, P.gold, V(0, -0.04, 0), V(0, 0.55, 0), 0.1)
    local before = #m:GetChildren()
    ring(m, P.blue, 0.57, 0.09, frame(0, 0.61, 0, 64, 0, 0), 14)
    for a = 0, 3 do
        local transform = frame(0, 0.61, 0, 64, 0, 0)
        local v = transform:PointToWorldSpace(
            V(math.cos(a * math.pi / 2) * 0.53, math.sin(a * math.pi / 2) * 0.53, 0)
        )
        rod(m, P.ceramic, V(0, 0.61, 0), v, 0.045)
    end
    for i = before + 1, #m:GetChildren() do
        moving(m:GetChildren()[i], "ValveWheel", V(0, 0.61, 0))
    end
    moving(glass(sphere(m, P.cyan, 0.37, 0.37, 0.37, 0, -0.4, 0.42), 0.2), "ValveFlow")
end)

register("dew_lantern", "equipment", function(m)
    block(m, P.dark, 0.9, 0.18, 0.75, 0, -0.89, 0)
    for _, x in { -0.43, 0.43 } do
        for _, z in { -0.32, 0.32 } do
            rod(m, P.gold, V(x, -0.8, z), V(x, 0.73, z), 0.04)
        end
    end
    glass(block(m, P.cyan, 0.81, 1.32, 0.61, 0, -0.06, 0), 0.68)
    moving(light(sphere(m, P.cyan, 0.38, 0.73, 0.38, 0, 0.03, 0)), "LanternDrop")
    for _, side in { -1, 1 } do
        wedge(
            m,
            P.ceramic,
            V(0.55, 0.35, 0.93),
            frame(side * 0.275, 0.86, 0, 0, side == 1 and 0 or 180)
        )
    end
    ring(m, P.gold, 0.28, 0.045, frame(0, 1.28, 0), 12, math.pi)
    for i = 0, 2 do
        moving(
            light(sphere(m, P.gold, 0.09, 0.09, 0.09, (i - 1) * 0.16, -0.41 + i * 0.19, 0.26)),
            "LanternMote"
        )
    end
end)

register("moss_capacitor", "equipment", function(m)
    feet(m, 1.2, -0.99, 0.75)
    block(m, P.ceramic, 1.75, 0.23, 1.09, 0, -0.82, 0)
    for _, x in { -0.47, 0.47 } do
        glass(drum(m, P.green, 0.37, 1.3, x, -0.04, 0), 0.35)
        drum(m, P.silver, 0.4, 0.12, x, 0.66, 0)
        for i = 0, 3 do
            moving(
                sphere(
                    m,
                    P.green,
                    0.35,
                    0.18,
                    0.32,
                    x + ((i % 2) * 2 - 1) * 0.09,
                    -0.46 + i * 0.27,
                    0.18
                ),
                "MossCharge"
            )
        end
        rod(m, P.gold, V(x, 0.73, 0), V(x, 1, 0), 0.055)
    end
    moving(light(rod(m, P.cyan, V(-0.47, 1, 0), V(0.47, 1, 0), 0.055)), "MossBridge")
    bezel(m, 0, -0.62, 0.56, 0.17, P.green)
end)

register("pearl_diver", "equipment", function(m)
    -- A diving bell, rather than the shell/pearl silhouettes used elsewhere.
    drum(m, P.dark, 0.72, 0.18, 0, -0.9, 0)
    sphere(m, P.ceramic, 1.5, 1.69, 1.12, 0, -0.03, 0)
    drum(m, P.gold, 0.65, 0.12, 0, -0.71, 0)
    disc(m, P.gold, 0.48, 0.14, 0, 0.11, 0.56)
    glass(disc(m, P.blue, 0.37, 0.14, 0, 0.11, 0.67), 0.35)
    moving(sphere(m, P.ceramic, 0.32, 0.32, 0.32, 0, 0.1, 0.73), "DiverPearl")
    for _, side in { -1, 1 } do
        rod(m, P.gold, V(side * 0.68, 0.1, 0), V(side * 1, -0.31, 0.07), 0.1)
        moving(
            wedge(m, P.teal, V(0.32, 0.31, 0.42), frame(side * 0.96, -0.48, 0.2, 0, 0, -side * 25)),
            "DiverClaw",
            V(side * 0.68, 0.1, 0)
        )
    end
    ring(m, P.gold, 0.18, 0.055, frame(0, 0.98, 0), 10)
    for i = 0, 3 do
        local a = i * math.pi / 2
        bolt(m, math.cos(a) * 0.43, 0.11 + math.sin(a) * 0.43, 0.69, 0.05)
    end
end)

register("stream_wheel", "equipment", function(m)
    for _, side in { -1, 1 } do
        wedge(
            m,
            P.ceramic,
            V(0.48, 1.24, 0.85),
            frame(side * 0.73, -0.41, -0.04, 0, side == 1 and 0 or 180)
        )
    end
    rod(m, P.gold, V(-0.85, 0.05, 0), V(0.85, 0.05, 0), 0.09)
    local pivot = V(0, 0.05, 0)
    for i = 0, 7 do
        local a = i * math.pi / 4
        local y, z = 0.05 + math.cos(a) * 0.75, math.sin(a) * 0.75
        moving(
            block(m, i % 2 == 0 and P.teal or P.cyan, 1.12, 0.24, 0.32, 0, y, z, -i * 45),
            "StreamPaddle",
            pivot
        )
        for _, x in { -0.48, 0.48 } do
            moving(rod(m, P.silver, V(x, 0.05, 0), V(x, y, z), 0.035), "StreamSpoke", pivot)
        end
    end
    glass(block(m, P.blue, 1.3, 0.1, 1.6, 0, -1, 0), 0.3)
end)

register("cloud_mirror", "equipment", function(m)
    block(m, P.ceramic, 1.04, 0.22, 0.67, 0, -0.99, 0)
    rod(m, P.gold, V(0, -0.89, 0), V(0, 0.21, 0), 0.09)
    for _, p in { { -0.57, 0.43, 0.72 }, { 0, 0.65, 1 }, { 0.59, 0.44, 0.76 } } do
        moving(sphere(m, P.ceramic, p[3], p[3], 0.27, p[1], p[2], 0), "CloudFrame", V(0, 0.25, 0))
        moving(
            glass(sphere(m, P.blue, p[3] * 0.8, p[3] * 0.8, 0.08, p[1], p[2], 0.16), 0.22),
            "CloudGlass",
            V(0, 0.25, 0)
        )
    end
    moving(
        rod(m, P.cyan, V(-0.41, 0.45, 0.23), V(0.21, 0.88, 0.23), 0.035),
        "CloudGlint",
        V(0, 0.25, 0)
    )
    for i = 1, 2 do
        moving(sphere(m, P.cyan, 0.12, 0.25, 0.12, (i - 1.5) * 0.55, -0.22, 0.12), "CloudRain")
    end
end)

register("nectar_pump", "equipment", function(m)
    block(m, P.ceramic, 1.37, 0.24, 0.9, 0, -0.91, 0)
    glass(drum(m, P.gold, 0.48, 1.18, -0.22, -0.2, 0), 0.4)
    moving(drum(m, P.orange, 0.4, 0.44, -0.22, -0.56, 0), "NectarLiquid")
    drum(m, P.silver, 0.5, 0.12, -0.22, 0.43, 0)
    moving(rod(m, P.gold, V(-0.22, 0.45, 0), V(-0.22, 0.94, 0), 0.07), "PumpStem")
    moving(block(m, P.teal, 0.72, 0.17, 0.32, -0.22, 0.97, 0), "PumpHandle")
    rod(m, P.silver, V(0.2, 0.29, 0), V(0.78, 0.29, 0), 0.1)
    rod(m, P.silver, V(0.78, 0.29, 0), V(0.78, 0.02, 0), 0.1)
    moving(sphere(m, P.gold, 0.2, 0.27, 0.2, 0.78, -0.22, 0), "NectarDrop")
    for i = 0, 4 do
        local a = i * math.pi * 2 / 5
        sphere(
            m,
            P.ceramic,
            0.2,
            0.26,
            0.08,
            -0.22 + math.sin(a) * 0.19,
            -0.2 + math.cos(a) * 0.19,
            0.49
        )
    end
    disc(m, P.gold, 0.11, 0.08, -0.22, -0.2, 0.51)
end)

register("lagoon_synth", "equipment", function(m)
    feet(m, 1.6, -0.88, 0.82)
    block(m, P.blue, 2.13, 0.62, 1.21, 0, -0.44, 0)
    block(m, P.ceramic, 2.19, 0.12, 1.28, 0, -0.09, 0)
    for i = 0, 6 do
        moving(block(m, P.ceramic, 0.23, 0.1, 0.59, -0.78 + i * 0.26, 0.04, 0.37), "SynthKey")
        if i % 3 ~= 0 then
            moving(block(m, P.dark, 0.11, 0.12, 0.3, -0.65 + i * 0.26, 0.13, 0.18), "SynthKey")
        end
    end
    for i = 0, 4 do
        moving(
            light(
                block(
                    m,
                    i % 2 == 0 and P.cyan or P.green,
                    0.14,
                    0.25 + i * 0.11,
                    0.11,
                    -0.56 + i * 0.28,
                    0.31 + i * 0.055,
                    -0.35
                )
            ),
            "SynthWave"
        )
    end
    for _, x in { -0.9, 0.9 } do
        drum(m, P.gold, 0.12, 0.15, x, 0.06, -0.32)
    end
end)

register("aurora_kite", "equipment", function(m)
    -- A translucent asymmetric diamond with a streaming ribbon tail.
    local pivot = V(0, 0.36, 0)
    for _, side in { -1, 1 } do
        moving(
            glass(
                wedge(
                    m,
                    side == 1 and P.cyan or P.green,
                    V(0.8, 1.06, 0.13),
                    frame(side * 0.4, 0.71, 0, 0, side == 1 and 180 or 0)
                ),
                0.22
            ),
            "KiteSail",
            pivot
        )
        moving(
            glass(
                wedge(
                    m,
                    side == 1 and P.blue or P.purple,
                    V(0.8, 0.73, 0.13),
                    frame(side * 0.4, -0.18, 0, 0, side == 1 and 0 or 180, 180)
                ),
                0.18
            ),
            "KiteSail",
            pivot
        )
    end
    moving(rod(m, P.gold, V(0, -0.56, 0.1), V(0, 1.23, 0.1), 0.035), "KiteSpar", pivot)
    moving(rod(m, P.silver, V(-0.8, 0.2, 0.1), V(0.8, 0.2, 0.1), 0.03), "KiteSpar", pivot)
    for i = 0, 3 do
        local x = math.sin(i * 1.7) * 0.28
        moving(
            rod(
                m,
                P.ceramic,
                V(x, -0.57 - i * 0.25, 0),
                V(math.sin((i + 1) * 1.7) * 0.28, -0.82 - i * 0.25, 0),
                0.025
            ),
            "KiteRibbon"
        )
        moving(
            block(
                m,
                i % 2 == 0 and P.gold or P.teal,
                0.35,
                0.12,
                0.06,
                x,
                -0.76 - i * 0.25,
                0,
                0,
                0,
                25 - i * 12
            ),
            "KiteRibbon"
        )
    end
end)

register("biolume_jar", "equipment", function(m)
    drum(m, P.dark, 0.65, 0.15, 0, -0.93, 0)
    glass(drum(m, P.cyan, 0.63, 1.6, 0, -0.05, 0), 0.7)
    drum(m, P.ceramic, 0.71, 0.17, 0, 0.84, 0)
    for i = 0, 7 do
        local a = i * math.pi / 4
        disc(m, P.teal, 0.04, 0.06, math.sin(a) * 0.49, 0.84, math.cos(a) * 0.49)
    end
    for i = 0, 4 do
        local x, z, h = math.cos(i * 2.3) * 0.35, math.sin(i * 2.3) * 0.3, 0.35 + (i % 3) * 0.22
        moving(rod(m, P.green, V(x, -0.83, z), V(x, -0.83 + h, z), 0.035), "LumeStem")
        moving(
            light(sphere(m, i % 2 == 0 and P.cyan or P.green, 0.3, 0.18, 0.3, x, -0.83 + h, z)),
            "LumeCap"
        )
    end
    for _, p in { V(-0.25, 0.39, 0.1), V(0.32, 0.28, 0.14), V(0, 0.61, 0) } do
        moving(light(sphere(m, P.gold, 0.1, 0.1, 0.1, p.X, p.Y, p.Z)), "LumeFirefly")
    end
end)

register("ozone_orb", "equipment", function(m)
    for i = 0, 2 do
        local a = i * math.pi * 2 / 3
        rod(
            m,
            P.silver,
            V(math.cos(a) * 0.7, -0.9, math.sin(a) * 0.7),
            V(math.cos(a) * 0.35, -0.28, math.sin(a) * 0.35),
            0.09
        )
    end
    moving(glass(sphere(m, P.blue, 1.2, 1.2, 1.2, 0, 0.24, 0), 0.44), "OzoneShell")
    moving(light(sphere(m, P.cyan, 0.35, 0.35, 0.35, 0, 0.24, 0)), "OzoneCore")
    for i = 0, 1 do
        local before = #m:GetChildren()
        ring(
            m,
            i == 0 and P.ceramic or P.gold,
            0.86 + i * 0.13,
            0.045,
            frame(0, 0.24, 0, 35 + i * 70, 0, i * 55),
            20
        )
        for n = before + 1, #m:GetChildren() do
            moving(m:GetChildren()[n], i == 0 and "OzoneOrbitA" or "OzoneOrbitB", V(0, 0.24, 0))
        end
    end
    moving(sphere(m, P.gold, 0.2, 0.2, 0.2, 0.86, 0.24, 0), "OzoneSatellite", V(0, 0.24, 0))
end)

register("monsoon_loom", "equipment", function(m)
    feet(m, 1.4, -1.02, 0.75)
    for _, x in { -0.84, 0.84 } do
        block(m, P.ceramic, 0.2, 2.1, 0.46, x, 0.03, 0)
        sphere(m, P.gold, 0.27, 0.27, 0.27, x, 1.16, 0)
    end
    for _, y in { -0.73, 0.97 } do
        rod(m, P.silver, V(-0.83, y, 0), V(0.83, y, 0), 0.11)
    end
    for i = 0, 6 do
        moving(
            rod(
                m,
                i % 2 == 0 and P.cyan or P.green,
                V(-0.63 + i * 0.21, -0.68, 0),
                V(-0.63 + i * 0.21, 0.92, 0),
                0.025
            ),
            "LoomThread"
        )
    end
    for i = 0, 3 do
        moving(
            rod(m, P.blue, V(-0.65, -0.5 + i * 0.28, 0.06), V(0.65, -0.5 + i * 0.28, 0.06), 0.04),
            "LoomWeave"
        )
    end
    moving(wedge(m, P.gold, V(0.7, 0.22, 0.25), frame(0, 0.52, 0.22, 0, 0, 90)), "LoomShuttle")
    for _, x in { -0.58, 0, 0.58 } do
        moving(glass(sphere(m, P.cyan, 0.15, 0.25, 0.15, x, 1.4, 0), 0.15), "LoomRain")
    end
end)

local function evolvedRing(m, color, radius, transform, group)
    local first = #m:GetChildren()
    ring(m, color, radius, 0.055, transform, 20)
    for index, object in ipairs(m:GetChildren()) do
        if index > first then
            named(object, group or "EvolvedOrbit")
            object:SetAttribute("MotionPivot", transform.Position)
        end
    end
end

local function evolvedBase(m, width, depth)
    feet(m, width * 0.7, -1.12, depth * 0.65)
    block(m, P.silver, width, 0.23, depth, 0, -0.98, 0)
    block(m, P.teal, width * 0.86, 0.12, depth * 0.89, 0, -0.8, 0)
    for index = 1, 5 do
        light(block(m, P.gold, 0.12, 0.05, 0.04, (index - 3) * 0.23, -0.96, depth / 2 + 0.025))
    end
end

local function evolvedCore(m, color, radius, x, y, z)
    return named(
        light(sphere(m, color, radius * 2, radius * 2, radius * 2, x, y, z)),
        "EvolvedCore"
    )
end

register("aurora_aquarium", "evolved", function(m)
    evolvedBase(m, 2.8, 1.5)
    glass(block(m, P.cyan, 2.56, 1.76, 1.34, 0, 0.13, 0), 0.68)
    glass(block(m, P.blue, 2.4, 1.2, 1.15, 0, -0.12, 0), 0.72)
    for _, side in ipairs({ -1, 1 }) do
        block(m, P.ceramic, 0.12, 1.92, 1.5, side * 1.3, 0.12, 0)
        rod(m, P.green, V(side * 0.9, -0.7, -0.36), V(side * 0.83, 0.56, -0.3), 0.06)
        named(sphere(m, P.green, 0.42, 0.17, 0.1, side * 0.86, 0.31, -0.28), "Reeds")
    end
    block(m, P.ceramic, 2.8, 0.15, 1.5, 0, 1.1, 0)
    fish(m, V(-0.3, 0.15, 0.25), 0.59)
    fish(m, V(0.55, -0.29, -0.13), 0.36)
    for index = 1, 5 do
        named(
            glass(sphere(m, P.cyan, 0.13, 0.13, 0.13, 0.76, -0.55 + index * 0.27, 0.5), 0.35),
            "Bubbles"
        )
    end
    evolvedRing(m, P.gold, 0.49, frame(0, 1.35, -0.08), "EvolvedOrbit")
    evolvedCore(m, P.cyan, 0.13, 0, 1.35, 0)
end)

register("spectrum_reef", "evolved", function(m)
    evolvedBase(m, 2.45, 1.5)
    for index = 1, 3 do
        local x = (index - 2) * 0.78
        local h = index == 2 and 2.1 or 1.45
        named(
            glass(
                wedge(
                    m,
                    ({ P.blue, P.cyan, P.purple })[index],
                    V(0.7, h, 0.55),
                    frame(x, h / 2 - 0.7, 0, 0, 0, index == 1 and -12 or 12)
                ),
                0.18
            ),
            "EvolvedCrystal"
        )
        named(light(sphere(m, P.ceramic, 0.18, 0.18, 0.18, x, h - 0.58, 0.05)), "EvolvedCore")
    end
    for _, side in ipairs({ -1, 1 }) do
        named(
            rod(m, P.silver, V(side * 0.9, -0.7, 0.5), V(side * 0.9, 0.85, 0.5), 0.09),
            "EvolvedFork"
        )
    end
    evolvedCore(m, P.gold, 0.24, 0, 0.4, 0.55)
    evolvedRing(m, P.gold, 0.67, frame(0, 0.4, 0.4), "EvolvedOrbit")
end)

register("tidal_engine", "evolved", function(m)
    evolvedBase(m, 2.5, 1.6)
    for _, side in ipairs({ -1, 1 }) do
        block(m, P.ceramic, 0.44, 1.5, 1.15, side * 0.93, 0.05, 0)
        bezel(m, side * 0.93, 0.34, 0.62, 0.32, P.cyan)
        named(
            block(m, P.gold, 0.05, 0.29, 0.06, side * 0.93, 0.41, 0.81, 0, 0, side * 32),
            "EvolvedNeedle"
        )
    end
    for index = 0, 5 do
        evolvedRing(
            m,
            index % 2 == 0 and P.teal or P.silver,
            0.62,
            frame(0, -0.45 + index * 0.25, 0, 90),
            "EvolvedSpring"
        )
    end
    named(drum(m, P.gold, 0.64, 0.18, 0, 1.02, 0), "EvolvedWeight")
    evolvedCore(m, P.cyan, 0.31, 0, 0.32, 0)
end)

register("storm_clock", "evolved", function(m)
    evolvedBase(m, 2.35, 1.4)
    bezel(m, 0, 0.25, 0, 1.02, P.ceramic)
    for index = 0, 11 do
        local a = index * math.pi / 6
        block(
            m,
            P.blue,
            0.055,
            0.14,
            0.055,
            math.sin(a) * 0.75,
            0.25 + math.cos(a) * 0.75,
            0.2,
            0,
            0,
            -index * 30
        )
    end
    local hand = named(block(m, P.gold, 0.07, 0.61, 0.06, 0, 0.52, 0.25), "EvolvedFastHand")
    hand:SetAttribute("MotionPivot", V(0, 0.25, 0.25))
    hand = named(block(m, P.teal, 0.48, 0.08, 0.06, 0.22, 0.25, 0.3), "EvolvedSlowHand")
    hand:SetAttribute("MotionPivot", V(0, 0.25, 0.3))
    evolvedCore(m, P.gold, 0.13, 0, 0.25, 0.38)
    for _, side in ipairs({ -1, 1 }) do
        named(glass(drum(m, P.cyan, 0.23, 1.05, side * 1.06, 0.1, -0.03), 0.38), "EvolvedCell")
        evolvedCore(m, P.cyan, 0.19, side * 1.06, 0.7, -0.03)
        named(
            wedge(m, P.gold, V(0.3, 0.6, 0.13), frame(side * 0.79, 1.1, 0.13, 0, 0, side * 25)),
            "EvolvedLightning"
        )
    end
end)

register("horizon_observatory", "evolved", function(m)
    evolvedBase(m, 2.5, 1.65)
    glass(sphere(m, P.cyan, 2.1, 1.64, 1.5, 0, 0.05, 0), 0.45)
    block(m, P.ceramic, 0.27, 1.35, 0.32, 0, 0.14, 0.1, 0, 0, -22)
    local barrel =
        named(rod(m, P.ceramic, V(-0.5, 0.6, 0), V(0.7, 1.08, 0.48), 0.29), "EvolvedLens")
    barrel:SetAttribute("MotionPivot", V(0, 0.7, 0.2))
    named(light(sphere(m, P.blue, 0.42, 0.42, 0.3, 0.78, 1.12, 0.52)), "EvolvedLens")
    bezel(m, -0.55, -0.35, 0.82, 0.39, P.ceramic)
    local needle = named(
        wedge(m, P.orange, V(0.12, 0.46, 0.05), frame(-0.55, -0.28, 0.99, 0, 0, -30)),
        "EvolvedNeedle"
    )
    needle:SetAttribute("MotionPivot", V(-0.55, -0.35, 0.99))
    evolvedRing(m, P.gold, 1.11, frame(0, 0.05, 0, 0, 28), "EvolvedOrbit")
end)

register("eden_greenhouse", "evolved", function(m)
    evolvedBase(m, 2.8, 1.6)
    for _, x in ipairs({ -1.18, 1.18 }) do
        for _, z in ipairs({ -0.62, 0.62 }) do
            rod(m, P.ceramic, V(x, -0.8, z), V(x, 0.88, z), 0.055)
            rod(m, P.ceramic, V(x, 0.88, z), V(0, 1.65, z), 0.055)
        end
    end
    rod(m, P.gold, V(0, 1.65, -0.7), V(0, 1.65, 0.7), 0.065)
    glass(block(m, P.cyan, 2.3, 1.6, 1.18, 0, 0.03, 0), 0.8)
    for index = 1, 3 do
        local x = (index - 2) * 0.7
        drum(m, P.blue, 0.25, 0.24, x, -0.58, 0)
        named(rod(m, P.green, V(x, -0.48, 0), V(x, 0.72, 0), 0.07), "EvolvedSprout")
        named(sphere(m, P.green, 0.65, 0.25, 0.28, x - 0.1, 0.12, 0), "EvolvedSprout")
        named(sphere(m, P.green, 0.65, 0.25, 0.28, x + 0.1, 0.4, 0), "EvolvedSprout")
        evolvedCore(m, index == 2 and P.gold or P.cyan, 0.21, x, 0.78, 0)
    end
end)

register("pearl_turbine", "evolved", function(m)
    evolvedBase(m, 2.55, 1.4)
    evolvedRing(m, P.teal, 0.94, frame(0, 0.2, 0), "EvolvedOrbit")
    for index = 0, 5 do
        local a = index * math.pi / 3
        local blade = named(
            wedge(
                m,
                index % 2 == 0 and P.cyan or P.silver,
                V(0.37, 0.68, 0.25),
                frame(math.cos(a) * 0.67, 0.2 + math.sin(a) * 0.67, 0, 0, 0, index * 60 + 35)
            ),
            "EvolvedRotor"
        )
        blade:SetAttribute("MotionPivot", V(0, 0.2, 0))
    end
    evolvedCore(m, P.ceramic, 0.35, 0, 0.2, 0.15)
    named(rod(m, P.gold, V(-1.1, 1.04, 0.25), V(1.1, 1.04, 0.25), 0.045), "EvolvedBalance")
    for _, side in ipairs({ -1, 1 }) do
        named(
            rod(m, P.gold, V(side * 0.9, 1.04, 0.25), V(side * 0.9, 0.58, 0.25), 0.025),
            "EvolvedBalance"
        )
        named(drum(m, P.ceramic, 0.25, 0.07, side * 0.9, 0.53, 0.25), "EvolvedBalance")
        named(sphere(m, P.gold, 0.18, 0.18, 0.18, side * 0.9, 0.65, 0.25), "EvolvedBalance")
    end
end)

register("current_nexus", "evolved", function(m)
    evolvedBase(m, 2.6, 1.6)
    for index = 0, 2 do
        local a = index * math.pi * 2 / 3 - math.pi / 2
        local x, y = math.cos(a) * 0.97, 0.25 + math.sin(a) * 0.87
        local nextA = a + math.pi * 2 / 3
        named(
            rod(
                m,
                P.gold,
                V(x, y, 0),
                V(math.cos(nextA) * 0.97, 0.25 + math.sin(nextA) * 0.87, 0),
                0.07
            ),
            "EvolvedCircuit"
        )
        disc(m, P.ceramic, 0.36, 0.23, x, y, 0)
        evolvedRing(m, P.teal, 0.26, frame(x, y, 0.2), "EvolvedRotor")
        evolvedCore(m, P.cyan, 0.16, x, y, 0.23)
    end
    evolvedCore(m, P.purple, 0.36, 0, 0.24, 0.16)
    evolvedRing(m, P.silver, 0.54, frame(0, 0.24, 0.16, 30, 15), "EvolvedOrbit")
end)

register("ocean_orchestra", "evolved", function(m)
    evolvedBase(m, 2.9, 1.55)
    for index = 1, 5 do
        local x, h = (index - 3) * 0.48, 0.9 + math.abs(index - 3) * 0.32
        named(rod(m, P.silver, V(x, -0.7, -0.28), V(x, h, -0.28), 0.13), "EvolvedHorn")
        named(disc(m, P.gold, 0.22, 0.09, x, h, -0.12), "EvolvedHorn")
        named(light(disc(m, P.cyan, 0.14, 0.1, x, h, -0.06)), "EvolvedHorn")
    end
    for index = -3, 3 do
        named(
            sphere(
                m,
                index % 2 == 0 and P.ceramic or P.cyan,
                0.35,
                0.94,
                0.3,
                index * 0.17,
                -0.12,
                0.35
            ),
            "EvolvedShell"
        )
    end
    evolvedCore(m, P.gold, 0.26, 0, -0.27, 0.66)
    for index = -2, 2 do
        block(m, P.ceramic, 0.35, 0.09, 0.45, index * 0.37, -0.65, 0.75)
    end
end)

register("bubble_reactor", "evolved", function(m)
    evolvedBase(m, 2.8, 1.6)
    glass(sphere(m, P.cyan, 1.75, 1.92, 1.45, 0, 0.15, 0), 0.62)
    evolvedCore(m, P.orange, 0.42, 0, 0.15, 0.12)
    evolvedRing(m, P.gold, 0.95, frame(0, 0.15, 0, 15, 25), "EvolvedOrbit")
    for _, side in ipairs({ -1, 1 }) do
        block(m, P.ceramic, 0.39, 1.34, 0.72, side * 1.1, -0.05, 0)
        named(
            rod(m, P.teal, V(side * 1.1, 0.42, 0), V(side * 0.65, 0.42, 0), 0.16),
            "EvolvedPiston"
        )
        evolvedCore(m, P.cyan, 0.14, side * 1.1, 0.76, 0)
    end
    for index = 1, 4 do
        local a = index * 1.8
        named(
            glass(
                sphere(
                    m,
                    P.ceramic,
                    0.15,
                    0.15,
                    0.15,
                    math.cos(a) * 0.52,
                    0.15 + math.sin(a) * 0.6,
                    0.43
                ),
                0.28
            ),
            "Bubbles"
        )
    end
    named(block(m, P.gold, 0.6, 0.22, 0.6, 0, 1.25, 0), "EvolvedWeight")
end)

register("solar_treasury", "evolved", function(m)
    evolvedBase(m, 2.4, 1.6)
    block(m, P.blue, 2.1, 1.88, 1.25, 0, 0.12, 0)
    block(m, P.ceramic, 1.85, 1.6, 0.16, 0, 0.15, 0.71)
    bezel(m, 0, 0.25, 0.85, 0.68, P.gold)
    for index = 0, 7 do
        local a = index * math.pi / 4
        local ray = named(
            block(
                m,
                P.gold,
                0.13,
                0.32,
                0.1,
                math.sin(a) * 0.76,
                0.25 + math.cos(a) * 0.76,
                1.02,
                0,
                0,
                -index * 45
            ),
            "EvolvedRotor"
        )
        ray:SetAttribute("MotionPivot", V(0, 0.25, 1.02))
    end
    evolvedCore(m, P.cyan, 0.21, 0, 0.25, 1.08)
    block(m, P.dark, 0.9, 0.08, 0.1, 0, -0.46, 0.83)
    for index = 1, 3 do
        local before = #m:GetChildren()
        coin(m, (index - 2) * 0.52, 1.08 + (index % 2) * 0.32, 0.1, 0.27)
        for order, object in ipairs(m:GetChildren()) do
            if order > before then
                named(object, "EvolvedCoin")
            end
        end
    end
end)

register("sun_koi", "evolved", function(m)
    fish(m, V(0, 0, 0), 1.05)
    evolvedRing(m, P.gold, 1.02, frame(0.05, 0.08, -0.27, 0, 20), "EvolvedOrbit")
    for index = -2, 2 do
        named(
            glass(
                wedge(
                    m,
                    index % 2 == 0 and P.cyan or P.gold,
                    V(0.27, 0.62 - math.abs(index) * 0.08, 0.2),
                    frame(index * 0.3, 0.64, -0.02, 0, 0, index * -14)
                ),
                0.15
            ),
            "EvolvedCrystal"
        )
    end
    for _, side in ipairs({ -1, 1 }) do
        evolvedCore(m, P.cyan, 0.09, side * 0.76, 0.67, 0.18)
    end
end)

register("tide_gyroscope", "evolved", function(m)
    evolvedBase(m, 2.45, 1.55)
    for _, side in ipairs({ -1, 1 }) do
        rod(m, P.ceramic, V(side * 0.9, -0.8, 0), V(side * 1.13, 0.3, 0), 0.09)
        bolt(m, side * 1.13, 0.3, 0.13, 0.15)
    end
    evolvedRing(m, P.gold, 1.1, frame(0, 0.3, 0), "EvolvedOrbit")
    evolvedRing(m, P.teal, 0.87, frame(0, 0.3, 0, 42, 25), "EvolvedRotor")
    evolvedRing(m, P.silver, 0.62, frame(0, 0.3, 0, -30, -40), "EvolvedGyro")
    evolvedCore(m, P.cyan, 0.27, 0, 0.3, 0)
    local hand = named(block(m, P.ceramic, 0.07, 0.52, 0.06, 0, 0.51, 0.32), "EvolvedFastHand")
    hand:SetAttribute("MotionPivot", V(0, 0.3, 0.32))
end)

local function badgeBase(m)
    drum(m, P.brass, 1.03, 0.2, 0, -1.08, 0)
    drum(m, P.gold, 0.95, 0.09, 0, -0.94, 0)
    drum(m, P.dark, 0.79, 0.04, 0, -0.87, 0)
    for _, x in ipairs({ -0.72, 0.72 }) do
        block(m, P.gold, 0.12, 0.18, 0.18, x, -1.12, 0.56)
    end
end

register("first_spark", "perk", function(m)
    badgeBase(m)
    for _, x in ipairs({ -0.76, 0.76 }) do
        drum(m, P.steel, 0.2, 0.75, x, -0.48, 0)
        for index = 0, 3 do
            drum(m, P.ceramic, 0.25, 0.07, x, -0.7 + index * 0.17, 0)
        end
        sphere(m, P.gold, 0.38, 0.38, 0.38, x, -0.04, 0)
    end
    local points = { V(0.37, 1.18, 0), V(-0.33, 0.33, 0), V(0.24, 0.33, 0), V(-0.35, -0.53, 0) }
    for index = 1, #points - 1 do
        light(rod(m, P.gold, points[index], points[index + 1], 0.17))
    end
    for _, side in ipairs({ -1, 1 }) do
        for index = 0, 2 do
            local x = side * (0.51 + index * 0.17)
            rod(
                m,
                P.copper,
                V(x, 0.52 + index * 0.1, 0),
                V(x + side * 0.15, 0.65 + index * 0.12, 0),
                0.035
            )
        end
    end
end)

register("tailwind", "perk", function(m)
    badgeBase(m)
    rod(m, P.silver, V(0, -0.86, 0), V(0, 0.3, 0), 0.12)
    disc(m, P.brass, 0.3, 0.28, 0, 0.35, 0)
    for index = 0, 2 do
        local angle = index * math.pi * 2 / 3
        local transform = frame(0, 0.35, 0) * CFrame.Angles(0, 0, angle)
        wedge(m, P.teal, V(0.67, 0.96, 0.17), transform * frame(0.31, 0.66, 0, 0, 0, -20))
        local a = transform:PointToWorldSpace(V(0.04, 0.23, 0.16))
        local b = transform:PointToWorldSpace(V(0.2, 0.82, 0.16))
        rod(m, P.gold, a, b, 0.045)
    end
    bezel(m, 0, 0.35, 0.17, 0.24, P.cyan)
    for index = 0, 2 do
        ring(
            m,
            P.silver,
            0.5 + index * 0.18,
            0.035,
            frame(0, 0.35, -0.2 - index * 0.12, 0, 0, 15 + index * 22),
            6,
            math.pi * 0.8
        )
    end
end)

register("ricochet", "perk", function(m)
    badgeBase(m)
    for _, side in ipairs({ -1, 1 }) do
        block(m, P.steel, 0.28, 1.6, 0.68, side * 0.91, 0.03, 0, 0, 0, side * 15)
        block(m, P.orange, 0.12, 1.33, 0.75, side * 0.75, 0.06, 0, 0, 0, side * 15)
        for index = 0, 3 do
            block(
                m,
                P.gold,
                0.15,
                0.06,
                0.78,
                side * (0.63 + index * 0.07),
                0.55 - index * 0.29,
                0,
                0,
                0,
                side * 15
            )
        end
    end
    local points = { V(-0.67, 0.63, 0.48), V(0.61, 0.12, 0.48), V(-0.36, -0.5, 0.48) }
    for index = 1, 2 do
        rod(m, P.ceramic, points[index], points[index + 1], 0.045)
    end
    for _, point in ipairs(points) do
        sphere(m, P.cyan, 0.34, 0.34, 0.34, point.X, point.Y, point.Z)
    end
    for _, x in ipairs({ -0.93, 0.93 }) do
        bolt(m, x, -0.55, 0.42)
    end
end)

register("growth_ring", "perk", function(m)
    badgeBase(m)
    ring(m, P.gold, 0.88, 0.11, frame(0, 0.22, 0), 16)
    ring(m, P.copper, 0.73, 0.035, frame(0, 0.22, 0.08), 16)
    for index = 0, 3 do
        local angle = index * math.pi / 2 + math.pi / 4
        local x, y = math.cos(angle) * 0.86, 0.22 + math.sin(angle) * 0.86
        sphere(m, P.green, 0.38, 0.5, 0.3, x, y, 0.09)
        rod(m, P.ceramic, V(x, y - 0.13, 0.25), V(x, y + 0.13, 0.25), 0.025)
    end
    sphere(m, P.teal, 0.54, 0.75, 0.46, 0, 0.24, 0)
    rod(m, P.gold, V(0, -0.8, 0), V(0, -0.11, 0), 0.07)
    wedge(m, P.green, V(0.35, 0.31, 0.12), frame(0.2, -0.31, 0, 0, 0, -35))
end)

local function arrowArc(m, color, radius, startDegrees, centerY, z)
    local transform = frame(0, centerY, z, 0, 0, startDegrees)
    local sweep = math.pi * 0.72
    ring(m, color, radius, 0.11, transform, 9, sweep)
    local endPoint =
        transform:PointToWorldSpace(V(math.cos(sweep) * radius, math.sin(sweep) * radius, 0))
    wedge(
        m,
        color,
        V(0.4, 0.4, 0.2),
        frame(endPoint.X, endPoint.Y, endPoint.Z, 0, 0, startDegrees + 130)
    )
end

register("recovery", "perk", function(m)
    badgeBase(m)
    arrowArc(m, P.gold, 0.93, 5, 0.24, 0)
    arrowArc(m, P.gold, 0.93, 185, 0.24, 0)
    sphere(m, P.green, 1.12, 1.12, 0.47, 0, 0.24, 0)
    block(m, P.ceramic, 0.63, 0.19, 0.12, 0, 0.24, 0.27)
    block(m, P.ceramic, 0.19, 0.63, 0.12, 0, 0.24, 0.28)
    rod(m, P.brass, V(0, -0.86, 0), V(0, -0.3, 0), 0.1)
end)

register("last_word", "perk", function(m)
    badgeBase(m)
    block(m, P.brass, 1.85, 1.3, 0.28, 0, 0.26, 0)
    block(m, P.purple, 1.64, 1.09, 0.32, 0, 0.26, 0)
    wedge(m, P.brass, V(0.48, 0.55, 0.28), frame(-0.47, -0.56, 0, 0, 0, 180))
    for _, x in ipairs({ -0.38, 0.29 }) do
        sphere(m, P.ceramic, 0.32, 0.32, 0.16, x, 0.47, 0.23)
        wedge(m, P.ceramic, V(0.24, 0.38, 0.16), frame(x - 0.04, 0.23, 0.23, 0, 0, 180))
    end
    for _, x in ipairs({ -0.78, 0.78 }) do
        for _, y in ipairs({ -0.24, 0.75 }) do
            bolt(m, x, y, 0.21, 0.06)
        end
    end
    block(m, P.gold, 0.12, 0.1, 0.08, 0.53, -0.07, 0.23)
    block(m, P.gold, 0.12, 0.1, 0.08, 0.32, -0.07, 0.23)
end)

register("metronome", "perk", function(m)
    badgeBase(m)
    wedge(m, P.brass, V(1.46, 2.02, 0.68), frame(0, 0.13, -0.06, 0, 180))
    block(m, P.dark, 0.7, 1.6, 0.12, 0, 0.11, 0.34)
    for index = 0, 7 do
        block(
            m,
            P.ceramic,
            if index % 2 == 0 then 0.43 else 0.29,
            0.035,
            0.035,
            0,
            -0.43 + index * 0.17,
            0.43
        )
    end
    rod(m, P.silver, V(0.35, -0.59, 0.53), V(-0.33, 0.98, 0.53), 0.052)
    block(m, P.gold, 0.35, 0.28, 0.2, -0.15, 0.57, 0.53, 0, 0, 23)
    bezel(m, 0.35, -0.59, 0.52, 0.18, P.purple)
    block(m, P.copper, 1.19, 0.19, 0.87, 0, -0.81, 0)
    for _, x in ipairs({ -0.49, 0.49 }) do
        bolt(m, x, -0.79, 0.47)
    end
end)

register("milestone", "perk", function(m)
    badgeBase(m)
    for index = 0, 2 do
        local x, height = -0.62 + index * 0.61, 0.44 + index * 0.4
        block(m, P.steel, 0.57, height, 0.82, x, -0.83 + height / 2, 0)
        block(m, P.gold, 0.61, 0.09, 0.9, x, -0.78 + height, 0)
        for mark = 0, index do
            disc(m, P.ceramic, 0.055, 0.04, x - index * 0.09 + mark * 0.18, -0.61, 0.44)
        end
    end
    rod(m, P.silver, V(0.62, 0.45, -0.14), V(0.62, 1.43, -0.14), 0.055)
    wedge(m, P.teal, V(0.72, 0.43, 0.1), frame(0.99, 1.19, -0.14, 0, 0, 90))
    sphere(m, P.gold, 0.2, 0.2, 0.2, 0.62, 1.47, -0.14)
    wedge(m, P.cyan, V(0.44, 0.39, 0.4), frame(0.61, 0.65, 0.12))
    wedge(m, P.teal, V(0.44, 0.39, 0.4), frame(0.61, 0.65, 0.12, 0, 180))
end)

register("reserve_pack", "consumable", function(m)
    block(m, P.steel, 2.05, 0.25, 1.3, 0, -0.75, 0)
    for _, z in ipairs({ -0.66, 0.66 }) do
        block(m, P.teal, 2.13, 0.62, 0.14, 0, -0.48, z)
    end
    for _, x in ipairs({ -1.03, 1.03 }) do
        block(m, P.teal, 0.14, 0.78, 1.4, x, -0.4, 0)
    end
    for _, x in ipairs({ -0.65, 0, 0.65 }) do
        sphere(m, P.blue, 0.7, 0.7, 0.7, x, -0.08, 0)
        sphere(m, P.cyan, 0.17, 0.12, 0.08, x + 0.14, 0.12, 0.29)
        disc(m, P.silver, 0.13, 0.05, x, -0.09, 0.34)
    end
    for _, x in ipairs({ -0.76, 0.76 }) do
        block(m, P.orange, 0.15, 0.9, 1.48, x, -0.39, 0)
        block(m, P.steel, 0.23, 0.17, 0.1, x, -0.44, 0.79)
        bolt(m, x, -0.42, 0.85)
        rod(m, P.silver, V(x, -0.1, -0.51), V(x, 0.76, -0.51), 0.075)
    end
    rod(m, P.silver, V(-0.76, 0.76, -0.51), V(0.76, 0.76, -0.51), 0.075)
    rod(m, P.dark, V(-0.43, 0.76, -0.51), V(0.43, 0.76, -0.51), 0.13)
end)

register("coin_press", "consumable", function(m)
    plinth(m, 1.8, -0.97, 1.3, P.teal)
    for _, x in ipairs({ -0.66, 0.66 }) do
        block(m, P.steel, 0.24, 1.92, 0.37, x, 0.04, -0.25)
        bolt(m, x, -0.73, -0.03)
    end
    block(m, P.teal, 1.81, 0.3, 0.66, 0, 1.01, -0.25)
    rod(m, P.silver, V(0, -0.16, -0.25), V(0, 1.33, -0.25), 0.11)
    for index = 0, 8 do
        drum(m, P.brass, 0.17, 0.05, 0, -0.01 + index * 0.14, -0.25)
    end
    drum(m, P.steel, 0.38, 0.26, 0, -0.31, -0.25)
    drum(m, P.gold, 0.43, 0.11, 0, -0.76, -0.25)
    rod(m, P.silver, V(-0.55, 1.37, -0.25), V(0.55, 1.37, -0.25), 0.06)
    sphere(m, P.dark, 0.22, 0.22, 0.22, 0.55, 1.37, -0.25)
    for index = 0, 3 do
        drum(m, P.gold, 0.26, 0.07, 0.53, -0.73 + index * 0.08, 0.33)
    end
    coin(m, -0.41, -0.49, 0.58, 0.29)
end)

register("tuning_oil", "consumable", function(m)
    drum(m, P.orange, 0.68, 0.85, -0.19, -0.35, 0)
    drum(m, P.brass, 0.73, 0.12, -0.19, -0.81, 0)
    drum(m, P.steel, 0.5, 0.14, -0.19, 0.15, 0)
    drum(m, P.brass, 0.2, 0.22, -0.19, 0.34, 0)
    for index = 0, 7 do
        local angle = index * math.pi / 4
        block(
            m,
            P.silver,
            0.065,
            0.18,
            0.065,
            -0.19 + math.cos(angle) * 0.19,
            0.34,
            math.sin(angle) * 0.19
        )
    end
    rod(m, P.silver, V(0.3, -0.09, 0), V(0.91, 0.16, 0), 0.14)
    rod(m, P.silver, V(0.91, 0.16, 0), V(1.31, 0.83, 0), 0.095)
    rod(m, P.brass, V(1.31, 0.83, 0), V(1.54, 0.86, 0), 0.07)
    ring(m, P.steel, 0.47, 0.1, frame(-0.83, -0.12, 0, 0, 0, 60), 10, math.pi * 1.4)
    bezel(m, -0.19, -0.33, 0.64, 0.24, P.teal)
    sphere(m, P.cyan, 0.17, 0.28, 0.17, 1.53, 0.57, 0)
    wedge(m, P.cyan, V(0.16, 0.17, 0.13), frame(1.53, 0.75, 0, 0, 180))
end)

register("coin", "utility", function(m)
    coin(m, 0, 0, 0, 1)
end)

register("restock", "utility", function(m)
    disc(m, P.steel, 1.05, 0.24, 0, 0, 0)
    disc(m, P.teal, 0.93, 0.3, 0, 0, 0)
    disc(m, P.dark, 0.73, 0.33, 0, 0, 0)
    arrowArc(m, P.cyan, 0.65, 0, 0, 0.25)
    arrowArc(m, P.cyan, 0.65, 180, 0, 0.25)
    disc(m, P.gold, 0.25, 0.41, 0, 0, 0)
    for index = 0, 5 do
        local angle = index * math.pi / 3
        bolt(m, math.cos(angle) * 0.92, math.sin(angle) * 0.92, 0.17, 0.055)
    end
end)

register("life", "utility", function(m)
    sphere(m, P.blue, 1.64, 1.64, 1.64, 0, 0, 0)
    ring(m, P.silver, 0.82, 0.055, frame(0, 0, 0, 0, 28), 16)
    ring(m, P.teal, 0.82, 0.045, frame(0, 0, 0, 90, 0), 16)
    bezel(m, 0, 0, 0.79, 0.27, P.cyan)
    sphere(m, P.ceramic, 0.29, 0.22, 0.09, -0.28, 0.41, 0.69)
end)

register("score", "utility", function(m)
    plinth(m, 1.99, -0.88, 0.8, P.gold)
    for index = 0, 2 do
        local x, height = -0.63 + index * 0.63, 0.7 + index * 0.49
        block(m, P.teal, 0.47, height, 0.54, x, -0.71 + height / 2, 0)
        block(m, P.cyan, 0.51, 0.1, 0.59, x, -0.66 + height, 0)
        for tick = 0, index + 1 do
            block(m, P.ceramic, 0.27, 0.035, 0.035, x, -0.5 + tick * 0.2, 0.29)
        end
        bolt(m, x, -0.77, 0.45, 0.055)
    end
    sphere(m, P.gold, 0.49, 0.49, 0.49, 0.63, 1.28, 0)
end)

register("lock", "utility", function(m)
    block(m, P.gold, 1.6, 1.25, 0.65, 0, -0.33, 0)
    block(m, P.brass, 1.45, 1.1, 0.73, 0, -0.33, 0)
    ring(m, P.silver, 0.55, 0.13, frame(0, 0.64, 0), 10, math.pi)
    for _, x in ipairs({ -0.55, 0.55 }) do
        rod(m, P.silver, V(x, 0.15, 0), V(x, 0.64, 0), 0.13)
    end
    disc(m, P.dark, 0.19, 0.04, 0, -0.22, 0.39)
    block(m, P.dark, 0.17, 0.32, 0.04, 0, -0.44, 0.39)
    for _, x in ipairs({ -0.59, 0.59 }) do
        for _, y in ipairs({ -0.73, 0.06 }) do
            bolt(m, x, y, 0.4, 0.06)
        end
    end
end)

register("jumble", "utility", function(m)
    for index, color in ipairs({ P.teal, P.purple, P.orange }) do
        local x, y = -0.7 + (index - 1) * 0.7, if index == 2 then 0.45 else -0.37
        disc(m, P.steel, 0.4, 0.34, x, y, 0)
        disc(m, color, 0.33, 0.38, x, y, 0)
        bolt(m, x, y, 0.22)
    end
    arrowArc(m, P.gold, 1.05, 10, 0, 0.12)
    arrowArc(m, P.gold, 1.05, 190, 0, 0.12)
end)

local function chestLid(m, width, depth, y, color)
    local pivot = V(0, y, -depth / 2)
    moving(block(m, color, width, 0.22, depth, 0, y + 0.11, 0), "ChestLid", pivot)
    for _, x in { -width * 0.34, width * 0.34 } do
        moving(block(m, P.gold, 0.13, 0.045, depth * 1.02, x, y + 0.24, 0), "ChestLid", pivot)
    end
    return pivot
end

register("chest_common", "utility", function(m)
    -- Meadow picnic coffer: slatted sides, a leaf clasp and a low handle.
    block(m, P.ceramic, 1.92, 0.18, 1.3, 0, -0.67, 0)
    for i = 0, 4 do
        block(m, i % 2 == 0 and P.green or P.teal, 0.33, 0.81, 1.2, -0.72 + i * 0.36, -0.19, 0)
    end
    for _, z in { -0.62, 0.62 } do
        block(m, P.ceramic, 1.88, 0.1, 0.09, 0, 0.12, z)
    end
    local pivot = chestLid(m, 2.02, 1.38, 0.3, P.ceramic)
    moving(rod(m, P.gold, V(-0.35, 0.64, 0), V(0.35, 0.64, 0), 0.07), "ChestLid", pivot)
    for _, x in { -0.35, 0.35 } do
        moving(rod(m, P.gold, V(x, 0.51, 0), V(x, 0.64, 0), 0.05), "ChestLid", pivot)
    end
    moving(sphere(m, P.green, 0.24, 0.43, 0.11, 0, 0.13, 0.75), "ChestClasp")
    moving(light(sphere(m, P.cyan, 0.32, 0.32, 0.32, 0, -0.09, 0)), "ChestTreasure")
end)

register("chest_uncommon", "utility", function(m)
    -- Tide coffer: a rounded tank, exterior portholes and a scalloped shell lid.
    glass(sphere(m, P.blue, 2.16, 1.13, 1.4, 0, -0.15, 0), 0.18)
    for _, x in { -0.79, 0.79 } do
        block(m, P.silver, 0.22, 0.22, 1.03, x, -0.69, 0)
    end
    block(m, P.ceramic, 2.03, 0.13, 1.3, 0, 0.29, 0)
    local pivot = V(0, 0.35, -0.67)
    moving(sphere(m, P.ceramic, 2.11, 0.78, 1.39, 0, 0.49, 0), "ChestLid", pivot)
    for i = -3, 3 do
        local x = i * 0.28
        moving(rod(m, P.teal, V(x * 0.55, 0.75, -0.4), V(x, 0.49, 0.62), 0.055), "ChestLid", pivot)
    end
    for _, x in { -0.59, 0.59 } do
        disc(m, P.gold, 0.22, 0.08, x, -0.12, 0.7)
        glass(disc(m, P.cyan, 0.15, 0.1, x, -0.12, 0.76), 0.22)
    end
    moving(sphere(m, P.ceramic, 0.32, 0.32, 0.2, 0, 0.3, 0.77), "ChestClasp")
    moving(light(sphere(m, P.cyan, 0.4, 0.4, 0.4, 0, -0.05, 0)), "ChestTreasure")
end)

register("chest_rare", "utility", function(m)
    -- Aurora vault: upright faceted octagonal case with crystal window and fins.
    block(m, P.dark, 1.5, 0.85, 1.04, 0, -0.18, 0)
    for _, side in { -1, 1 } do
        wedge(
            m,
            P.blue,
            V(0.51, 0.89, 1.09),
            frame(side * 0.88, -0.17, 0, 0, side == 1 and 180 or 0)
        )
        rod(m, P.gold, V(side * 0.63, -0.67, 0.47), V(side * 0.63, 0.3, 0.47), 0.065)
        wedge(m, P.ceramic, V(0.46, 0.7, 0.2), frame(side * 1.16, -0.13, 0, 0, 0, side * 25))
    end
    local pivot = chestLid(m, 1.63, 1.14, 0.3, P.blue)
    moving(wedge(m, P.cyan, V(0.58, 0.52, 0.4), frame(0, 0.74, 0, 0, 0, 90)), "ChestLid", pivot)
    moving(
        wedge(m, P.ceramic, V(0.58, 0.52, 0.4), frame(0, 0.74, 0, 0, 180, -90)),
        "ChestLid",
        pivot
    )
    moving(glass(disc(m, P.cyan, 0.29, 0.13, 0, 0.01, 0.6), 0.23), "ChestClasp")
    moving(light(sphere(m, P.purple, 0.39, 0.53, 0.39, 0, -0.05, 0)), "ChestTreasure")
    for _, x in { -0.7, 0.7 } do
        block(m, P.silver, 0.4, 0.17, 0.9, x, -0.72, 0)
    end
end)

register("chest_legendary", "utility", function(m)
    -- Celestial reliquary: floating pearl globe inside an open gold armillary.
    drum(m, P.dark, 0.86, 0.17, 0, -0.79, 0)
    drum(m, P.ceramic, 0.76, 0.2, 0, -0.64, 0)
    glass(sphere(m, P.blue, 1.48, 1.23, 1.3, 0, -0.08, 0), 0.38)
    for i = 0, 3 do
        local a = i * math.pi / 2 + math.pi / 4
        rod(
            m,
            P.gold,
            V(math.cos(a) * 0.73, -0.57, math.sin(a) * 0.73),
            V(math.cos(a) * 0.94, 0.56, math.sin(a) * 0.94),
            0.065
        )
        sphere(m, P.ceramic, 0.2, 0.2, 0.2, math.cos(a) * 0.94, 0.56, math.sin(a) * 0.94)
    end
    local pivot = V(0, 0.48, -0.67)
    moving(drum(m, P.gold, 0.86, 0.13, 0, 0.48, 0), "ChestLid", pivot)
    moving(glass(sphere(m, P.ceramic, 1.44, 0.59, 1.44, 0, 0.65, 0), 0.22), "ChestLid", pivot)
    for _, side in { -1, 1 } do
        moving(
            wedge(
                m,
                P.gold,
                V(0.34, 0.49, 0.21),
                frame(side * 0.17, 1.03, 0, 0, side == 1 and 0 or 180)
            ),
            "ChestLid",
            pivot
        )
    end
    moving(light(sphere(m, P.gold, 0.25, 0.25, 0.25, 0, 1.32, 0)), "ChestLid", pivot)
    moving(light(sphere(m, P.cyan, 0.48, 0.48, 0.48, 0, -0.01, 0)), "ChestTreasure")
    local before = #m:GetChildren()
    ring(m, P.gold, 1.16, 0.04, frame(0, 0.08, 0, 63, 0, 22), 24)
    for i = before + 1, #m:GetChildren() do
        moving(m:GetChildren()[i], "ChestOrbit", V(0, 0.08, 0))
    end
    moving(disc(m, P.gold, 0.23, 0.12, 0, 0.18, 0.78), "ChestClasp")
end)

-- Event previews are independent reward emblems, never equipment aliases.
register("event_growth", "utility", function(m)
    glass(sphere(m, P.blue, 1.18, 1.18, 1.18, 0, -0.28, 0), 0.4)
    for _, side in { -1, 1 } do
        moving(
            sphere(m, P.green, 0.47, 0.94, 0.17, side * 0.27, 0.56, 0),
            "EventSprout",
            V(0, 0.09, 0)
        ).CFrame *= CFrame.Angles(
            0,
            0,
            -side * 0.5
        )
    end
    moving(rod(m, P.ceramic, V(0, -0.1, 0), V(0, 0.82, 0), 0.045), "EventSprout")
    for i = 0, 3 do
        light(
            sphere(
                m,
                P.gold,
                0.12,
                0.12,
                0.12,
                math.cos(i * math.pi / 2) * 0.73,
                -0.28 + math.sin(i * math.pi / 2) * 0.73,
                0
            )
        )
    end
end)

register("event_repair", "utility", function(m)
    block(m, P.ceramic, 1.63, 1.21, 0.59, 0, -0.07, 0)
    for _, x in { -0.35, 0.35 } do
        rod(m, P.teal, V(x, 0.54, 0), V(x, 0.83, 0), 0.07)
    end
    rod(m, P.teal, V(-0.35, 0.83, 0), V(0.35, 0.83, 0), 0.07)
    moving(block(m, P.green, 0.79, 0.24, 0.08, 0, -0.07, 0.34), "EventCross")
    moving(block(m, P.green, 0.24, 0.79, 0.08, 0, -0.07, 0.35), "EventCross")
    for _, x in { -0.6, 0.6 } do
        block(m, P.gold, 0.12, 0.2, 0.08, x, 0.33, 0.34)
    end
end)

register("event_upgrade", "utility", function(m)
    -- Ascending three-prong crystal arrow, unlike any upgrade item.
    for i = -1, 1 do
        local height = i == 0 and 1.65 or 1.05
        moving(
            block(
                m,
                i == 0 and P.gold or P.teal,
                0.25,
                height,
                0.28,
                i * 0.51,
                -0.6 + height / 2,
                0
            ),
            "EventArrow"
        )
        moving(
            wedge(m, P.ceramic, V(0.49, 0.39, 0.31), frame(i * 0.51 - 0.12, -0.4 + height, 0)),
            "EventArrow"
        )
        moving(
            wedge(m, P.cyan, V(0.49, 0.39, 0.31), frame(i * 0.51 + 0.12, -0.4 + height, 0, 0, 180)),
            "EventArrow"
        )
    end
end)

register("event_overtime", "utility", function(m)
    -- Sand clock; the Clockwork equipment remains a separate mechanical face.
    for _, y in { -0.92, 0.92 } do
        block(m, P.ceramic, 1.45, 0.16, 0.88, 0, y, 0)
    end
    for _, x in { -0.62, 0.62 } do
        rod(m, P.gold, V(x, -0.84, 0), V(x, 0.84, 0), 0.06)
    end
    for _, side in { -1, 1 } do
        glass(sphere(m, P.cyan, 0.9, 0.77, 0.7, 0, side * 0.44, 0), 0.63)
        moving(sphere(m, P.gold, 0.68, 0.32, 0.51, 0, side * 0.58, 0), "EventSand")
    end
    moving(light(rod(m, P.gold, V(0, -0.43, 0), V(0, 0.4, 0), 0.028)), "EventStream")
end)

local aliases = {
    ball = "life",
    coins = "coin",
    grow = "event_growth",
    repair = "event_repair",
    upgrade = "event_upgrade",
    overtime = "event_overtime",
}

ItemModels.Ids = table.freeze(ids)

-- A preview owns one colored render pass. A magnified duplicate behind glass
-- is not an outline: it shows shifted interior geometry through transparent parts.
-- Keep one live handle per viewport so remounting cannot stack old models/cameras.
local activeMounts = setmetatable({}, { __mode = "k" })

function ItemModels.create(id, level)
    local canonical = aliases[id] or id
    local builder = builders[canonical]
    assert(builder, "Unknown item model: " .. tostring(id))
    local itemLevel = if categories[canonical] == "evolved"
        then 5
        else math.clamp(math.floor(tonumber(level) or 1), 1, 5)
    local model = Instance.new("Model")
    -- The first primitive may be rotated; keep builder and bounds axes fixed.
    model.WorldPivot = CFrame.new()
    model.Name = "Item_" .. id
    model:SetAttribute("ItemId", id)
    model:SetAttribute("ItemLevel", itemLevel)
    model:SetAttribute("Category", categories[canonical])
    builder(model, itemLevel)
    -- Builders may author their own upgrade details. Do not place universal rails
    -- or tier lights from bounding-box extents: irregular devices leave them floating.
    -- The rack/shop level badge remains the consistent upgrade indicator.
    local bounds = model:GetBoundingBox()
    ItemMotion.tag(model, canonical)
    model:SetAttribute("ArtCenter", bounds.Position)
    model.WorldPivot = CFrame.new(bounds.Position)
    model:PivotTo(CFrame.new())
    model:SetAttribute("PartCount", #model:GetChildren())
    return model
end

function ItemModels.mount(viewport, id, level, options)
    assert(viewport:IsA("ViewportFrame"), "ItemModels.mount requires a ViewportFrame")
    local model = ItemModels.create(id, level)
    local previous = activeMounts[viewport]
    if previous then
        previous:destroy()
    end
    local container = Instance.new("Model")
    container.Name = "ItemDisplay"
    container.Parent = viewport
    model.Parent = container
    local camera = Instance.new("Camera")
    camera.Name = "ItemCamera"
    camera.FieldOfView = 30
    camera.Parent = container
    viewport.CurrentCamera = camera
    viewport.Ambient = Color3.fromRGB(185, 214, 232)
    viewport.LightColor = Color3.fromRGB(255, 252, 244)
    viewport.LightDirection = V(-0.7, -1, -0.6)
    local _, size = model:GetBoundingBox()
    local radius = size.Magnitude / 2
    local canonical = aliases[id] or id
    if categories[canonical] == "perk" then
        local floorY = -size.Y / 2 - 0.1
        local floorRadius = math.max(size.X, size.Z) * 0.57
        local top = glass(drum(container, P.cyan, floorRadius, 0.055, 0, floorY, 0), 0.36)
        top.Name = "PerkPedestalTop"
        local base = drum(container, P.ceramic, floorRadius * 1.03, 0.035, 0, floorY - 0.036, 0)
        base.Name = "PerkPedestalBase"
    end
    local motion = ItemMotion.new(model, canonical)
    local handle = { model = model }
    local animate = not options or (options.animate ~= false and options.reducedMotion ~= true)
    local hover = ItemMotion.newHover(animate)
    local age, strength = 0, 1
    local active, aimAngle, aimFrom, currentAim = false, 0, 0, 0
    local queuedAmount, queuedParams
    local destroyed = false
    local destroyConnection
    local previousWidth, previousHeight = -1, -1
    local function fit()
        local dimensions = viewport.AbsoluteSize
        if dimensions.X == previousWidth and dimensions.Y == previousHeight then
            return
        end
        previousWidth, previousHeight = dimensions.X, dimensions.Y
        local aspect = if dimensions.X > 0 and dimensions.Y > 0
            then dimensions.X / dimensions.Y
            else 1
        local halfFov = math.rad(camera.FieldOfView / 2)
        local limitingFov = math.min(halfFov, math.atan(math.tan(halfFov) * aspect))
        local distance = radius * 1.28 / math.sin(limitingFov)
        camera.CFrame = CFrame.lookAt(V(0.72, 0.43, 1).Unit * distance, V(0, 0, 0))
    end
    local function hoverFrame(pose)
        local position = camera.CFrame.RightVector * pose.x * size.X
            + camera.CFrame.UpVector * pose.y * size.Y
        return CFrame.new(position) * CFrame.Angles(pose.pitch, pose.yaw, pose.roll)
    end
    local idleFrame = CFrame.new()
    function handle:step(dt)
        if destroyed then
            return
        end
        fit()
        if not animate and not active then
            return
        end
        local delta = if type(dt) == "number" and dt == dt then math.clamp(dt, 0, 0.1) else 0
        idleFrame = hoverFrame(ItemMotion.stepHover(hover, delta, active))
        local rootPose = idleFrame
        local t = 1
        if active then
            age += delta
            t = math.min(1, age / motion.duration)
            if canonical == "split_prism" then
                local aim = if t < 0.18 then t / 0.18 elseif t < 0.54 then 1 else (1 - t) / 0.46
                aim = aim * aim * (3 - 2 * aim)
                currentAim = if t < 0.18
                    then aimFrom + (aimAngle - aimFrom) * aim
                    else aimAngle * aim
                rootPose = CFrame.new(idleFrame.Position)
                    * CFrame.fromAxisAngle(camera.CFrame.LookVector, currentAim)
                    * idleFrame.Rotation
            end
        end
        model:PivotTo(rootPose)
        if active then
            motion:apply(t, strength, rootPose)
            active = t < 1
            if not active and queuedAmount then
                local nextAmount, nextParams = queuedAmount, queuedParams
                queuedAmount, queuedParams = nil, nil
                self:pulse(nextAmount, nextParams)
            end
        end
    end
    function handle:pulse(amount, params)
        if destroyed then
            return
        end
        local requestedStrength = if type(amount) == "number" and amount == amount
            then math.clamp(amount, 0, 2)
            else 1
        if requestedStrength <= 0 then
            return
        end
        if active and canonical ~= "split_prism" then
            queuedAmount = math.max(queuedAmount or 0, requestedStrength)
            queuedParams = params
            return
        end
        strength = requestedStrength
        age, active = 0, true
        aimFrom = currentAim
        aimAngle = 0
        if type(params) == "table" then
            local direction = params.direction
            local angle
            if
                typeof(direction) == "Vector2"
                and direction.Magnitude > 0
                and direction.Magnitude < math.huge
            then
                angle = math.atan2(direction.Y, direction.X)
            elseif
                type(direction) == "number"
                and direction == direction
                and math.abs(direction) < math.huge
            then
                angle = direction
            end
            if angle then
                local up = idleFrame.UpVector
                local baseAngle =
                    math.atan2(-camera.CFrame.UpVector:Dot(up), camera.CFrame.RightVector:Dot(up))
                aimAngle = (angle - baseAngle + math.pi) % (math.pi * 2) - math.pi
                aimAngle = aimFrom + (aimAngle - aimFrom + math.pi) % (math.pi * 2) - math.pi
            end
            if type(params.effect) == "string" then
                model:SetAttribute("ActivationEffect", params.effect)
            end
        end
    end
    function handle:destroy()
        if destroyed then
            return
        end
        destroyed = true
        if destroyConnection then
            destroyConnection:Disconnect()
        end
        if activeMounts[viewport] == self then
            activeMounts[viewport] = nil
        end
        if viewport.CurrentCamera == camera then
            viewport.CurrentCamera = nil
        end
        container:Destroy()
    end
    destroyConnection = viewport.Destroying:Connect(function()
        handle:destroy()
    end)
    fit()
    if animate then
        idleFrame = hoverFrame(ItemMotion.stepHover(hover, 0, false))
        model:PivotTo(idleFrame)
    end
    activeMounts[viewport] = handle
    return handle
end

return ItemModels
