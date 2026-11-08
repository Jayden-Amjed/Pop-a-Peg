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
    local base = drum(m, P.ceramic, width / 2, 0.2, 0, y - 0.06, 0)
    base.Size = V(0.2, width + 0.18, depth + 0.18)
    local rim = drum(m, P.silver, width / 2, 0.055, 0, y - 0.19, 0)
    rim.Size = V(0.055, width + 0.1, depth + 0.1)
    local glaze = glass(drum(m, color or P.cyan, width / 2, 0.045, 0, y + 0.065, 0), 0.3)
    glaze.Size = V(0.045, width * 0.89, depth * 0.89)
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
    if level == 2 then
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
    if level == 2 then
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
    if level == 2 then
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
    if level == 2 then
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
    if level == 2 then
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
    if level == 2 then
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
    if level == 2 then
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
    if level == 2 then
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
        local segment = rod(m, if level == 2 then P.gold else P.copper, startPoint, endPoint, 0.075)
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
    if level == 2 then
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
        light(disc(m, if level == 2 then P.gold else P.purple, 0.22, 0.05, x, 0.57, 0.55))
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
    plinth(m, 2.4, -0.91, 1.25)
    glass(sphere(m, P.cyan, 2.07, 0.2, 0.94, 0, -0.66, 0), 0.32)
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
    if level == 2 then
        glass(named(sphere(m, P.cyan, 0.29, 0.29, 0.29, -0.86, 0.83, 0), "Bubbles"), 0.4)
    end
end)

register("fishbowl", "equipment", function(m, level)
    plinth(m, 2.5, -1.1, 2.05)
    glass(named(sphere(m, P.cyan, 2.08, 1.64, 2.08, 0, -0.15, 0), "Water"), 0.69)
    named(glass(drum(m, P.blue, 0.94, 0.035, 0, 0.5, 0), 0.4), "Waterline")
    fish(m, V(0.06, -0.08, 0.22), if level == 2 then 0.6 else 0.52)
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

local aliases = {
    ball = "life",
    coins = "coin",
    grow = "growth_array",
    repair = "reserve_pack",
    upgrade = "tuning_oil",
    overtime = "clockwork",
}

ItemModels.Ids = table.freeze(ids)

-- One extra render layer gives the whole model a camera-relative silhouette.
-- Keeping it behind the colored pass avoids drawing edges between model parts.
local function silhouette(viewport, model, camera, options)
    if options and options.outline == false then
        return nil
    end
    local mask = Instance.new("ViewportFrame")
    mask.Name = viewport.Name .. "Silhouette"
    mask:SetAttribute("ItemSilhouette", true)
    mask.BackgroundTransparency, mask.BorderSizePixel = 1, 0
    mask.Active, mask.Selectable = false, false
    mask.Ambient, mask.LightColor, mask.ImageColor3 = Color3.new(), Color3.new(), Color3.new()
    local maskCamera = Instance.new("Camera")
    maskCamera.Name = "SilhouetteCamera"
    maskCamera.Parent = mask
    mask.CurrentCamera = maskCamera
    local geometry = Instance.new("Model")
    geometry.Name = "SilhouetteGeometry"
    geometry.Parent = mask
    local links, connections = {}, {}
    for _, original in model:GetDescendants() do
        if original:IsA("BasePart") then
            local copy = original:Clone()
            copy:ClearAllChildren()
            copy.Color = Color3.new()
            copy.Material, copy.Reflectance = Enum.Material.SmoothPlastic, 0
            copy.CastShadow = false
            copy.Parent = geometry
            table.insert(links, { original = original, copy = copy })
        end
    end
    local function layout()
        mask.AnchorPoint, mask.Position, mask.Size =
            viewport.AnchorPoint, viewport.Position, viewport.Size
        mask.Rotation = viewport.Rotation
        mask.ZIndex = math.max(1, viewport.ZIndex - 1)
        mask.Visible = viewport.Visible
        mask.ImageTransparency = viewport.ImageTransparency
        mask.Parent = viewport.Parent
    end
    for _, property in
        {
            "AnchorPoint",
            "Position",
            "Size",
            "Rotation",
            "ZIndex",
            "Visible",
            "ImageTransparency",
            "Parent",
        }
    do
        table.insert(connections, viewport:GetPropertyChangedSignal(property):Connect(layout))
    end
    layout()
    local outline = { frame = mask }
    function outline:fit()
        local dimensions = viewport.AbsoluteSize
        local shortest = math.max(1, math.min(dimensions.X, dimensions.Y))
        local pixels = math.clamp(shortest * 0.024, 1.5, 4.5)
        local expansion = 1 + pixels * 2 / shortest
        maskCamera.CFrame = camera.CFrame
        maskCamera.FieldOfView =
            math.deg(2 * math.atan(math.tan(math.rad(camera.FieldOfView / 2)) / expansion))
    end
    function outline:sync()
        for _, link in links do
            link.copy.CFrame, link.copy.Size = link.original.CFrame, link.original.Size
            link.copy.Transparency = link.original.Transparency
        end
    end
    function outline:destroy()
        for _, connection in connections do
            connection:Disconnect()
        end
        mask:Destroy()
    end
    return outline
end

function ItemModels.create(id, level)
    local canonical = aliases[id] or id
    local builder = builders[canonical]
    assert(builder, "Unknown item model: " .. tostring(id))
    local itemLevel = if level == 2 then 2 else 1
    local model = Instance.new("Model")
    -- The first primitive may be rotated; keep builder and bounds axes fixed.
    model.WorldPivot = CFrame.new()
    model.Name = "Item_" .. id
    model:SetAttribute("ItemId", id)
    model:SetAttribute("ItemLevel", itemLevel)
    model:SetAttribute("Category", categories[canonical])
    builder(model, itemLevel)
    if itemLevel == 2 and categories[canonical] == "equipment" then
        local bounds, size = model:GetBoundingBox()
        local bottom = bounds.Position.Y - size.Y / 2
        for _, side in ipairs({ -1, 1 }) do
            local x = bounds.Position.X + side * size.X * 0.31
            block(
                model,
                P.gold,
                0.17,
                0.17,
                math.max(size.Z * 0.83, 0.5),
                x,
                bottom + 0.12,
                bounds.Position.Z
            )
            light(
                sphere(
                    model,
                    P.cyan,
                    0.16,
                    0.16,
                    0.12,
                    x,
                    bottom + 0.14,
                    bounds.Position.Z + size.Z / 2 + 0.03
                )
            )
        end
    end
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
    local outline = silhouette(viewport, model, camera, options)
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
        if outline then
            outline:fit()
        end
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
        if outline then
            outline:sync()
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
        if outline then
            outline:destroy()
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
    if outline then
        outline:sync()
    end
    return handle
end

return ItemModels
