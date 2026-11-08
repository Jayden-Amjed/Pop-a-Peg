local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ContentProvider = game:GetService("ContentProvider")
local libraries = ReplicatedStorage:WaitForChild("PilotLibraries")
local ItemModels = require(libraries.ItemModels)
local ItemMotion = require(libraries.ItemMotion)
local PilotMotion = require(libraries.PilotMotion)
local pilots = ReplicatedStorage:WaitForChild("BlenderPilots")
local catalog = {
    { "spring_coil", "WAVE SPRING", "Continuous coil / 3,184 triangles", 7 },
    { "seed_bank", "SEED BANK", "Golden seeds / 2,040 triangles", 8 },
    { "chest_common", "MEADOW CHEST", "Hollow shell / 3,168 triangles", 10 },
}
local gui = Instance.new("ScreenGui")
gui.Name = "BlenderPilotGallery"
gui.IgnoreGuiInset = true
gui.ResetOnSpawn = false
gui:SetAttribute("Pose", -1)
gui:SetAttribute("Strength", 1)
gui:SetAttribute("Animate", true)
gui:SetAttribute("AutoTrigger", false)
gui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")
local function make(class, parent, properties)
    local object = Instance.new(class)
    for key, value in properties do
        object[key] = value
    end
    object.Parent = parent
    return object
end
local colors = {
    ink = Color3.fromRGB(30, 67, 89),
    pearl = Color3.fromRGB(249, 253, 255),
    aqua = Color3.fromRGB(217, 244, 247),
    teal = Color3.fromRGB(39, 155, 177),
}
local function label(parent, text, position, size, fontSize, color)
    return make("TextLabel", parent, {
        BackgroundTransparency = 1,
        Text = text,
        Position = position,
        Size = size,
        Font = Enum.Font.GothamBold,
        TextSize = fontSize,
        TextColor3 = color or colors.ink,
    })
end
make(
    "Frame",
    gui,
    { Size = UDim2.fromScale(1, 1), BackgroundColor3 = colors.aqua, BorderSizePixel = 0 }
)
label(
    gui,
    "POP A PEG  /  BLENDER MODEL LAB",
    UDim2.fromScale(0.03, 0.035),
    UDim2.fromScale(0.94, 0.055),
    28
)
label(
    gui,
    "Original meshes • Same game lighting • Click a model to activate",
    UDim2.fromScale(0.03, 0.095),
    UDim2.fromScale(0.94, 0.035),
    16
)
local comparison = make("Frame", gui, {
    Name = "Comparison",
    BackgroundTransparency = 1,
    Position = UDim2.fromScale(0.03, 0.15),
    Size = UDim2.fromScale(0.94, 0.74),
})
local thumbnails = make("Frame", gui, {
    Name = "SizeChecks",
    BackgroundTransparency = 1,
    Visible = false,
    Position = UDim2.fromScale(0.03, 0.15),
    Size = UDim2.fromScale(0.94, 0.74),
})
local handles = {}
local loaded = {}
local largePairs = {}
local function preview(parent, model, id, isPilot, position, size, fitMargin)
    local viewport = make("ViewportFrame", parent, {
        BackgroundTransparency = 0,
        BackgroundColor3 = Color3.fromRGB(211, 235, 240),
        BorderSizePixel = 0,
        Position = position,
        Size = size,
        Ambient = Color3.fromRGB(185, 214, 232),
        LightColor = Color3.fromRGB(255, 252, 244),
        LightDirection = Vector3.new(-0.7, -1, -0.6),
    })
    make("UICorner", viewport, { CornerRadius = UDim.new(0, 12) })
    model.Parent = viewport
    table.insert(loaded, model)
    local camera = make("Camera", viewport, { FieldOfView = 30 })
    viewport.CurrentCamera = camera
    local _, bounds = model:GetBoundingBox()
    local controller = if isPilot then PilotMotion.new(model) else ItemMotion.new(model, id)
    local handle =
        { age = nil, controller = controller, hover = ItemMotion.newHover(true), model = model }
    local trigger = make(
        "TextButton",
        viewport,
        { Text = "", BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1) }
    )
    trigger.Activated:Connect(function()
        gui:SetAttribute("Pose", -1)
        handle.age = 0
    end)
    function handle:step(dt)
        local dimensions = viewport.AbsoluteSize
        local aspect = dimensions.X / math.max(1, dimensions.Y)
        local fov = math.min(math.rad(15), math.atan(math.tan(math.rad(15)) * aspect))
        camera.CFrame = CFrame.lookAt(
            Vector3.new(0.72, 0.43, 1).Unit * bounds.Magnitude / 2 * fitMargin / math.sin(fov),
            Vector3.zero
        )
        local explicit = gui:GetAttribute("Pose")
        if explicit >= 0 then
            controller:apply(explicit, gui:GetAttribute("Strength"), CFrame.new())
            return
        end
        if not gui:GetAttribute("Animate") then
            return
        end
        if self.age then
            self.age += dt
            if self.age >= controller.duration then
                self.age = nil
            end
        end
        local pose = ItemMotion.stepHover(self.hover, dt, self.age ~= nil)
        local root = CFrame.new(
            camera.CFrame.RightVector * pose.x * bounds.X
                + camera.CFrame.UpVector * pose.y * bounds.Y
        ) * CFrame.Angles(pose.pitch, pose.yaw, pose.roll)
        controller:apply(
            if self.age then self.age / controller.duration else 0,
            gui:GetAttribute("Strength"),
            root
        )
    end
    table.insert(handles, handle)
    return viewport
end
for i, entry in catalog do
    local id, name, detail = entry[1], entry[2], entry[3]
    local source = pilots:WaitForChild(id, 30)
    assert(source, "Import and normalize the Blender pilot models before playing")
    local card = make("Frame", comparison, {
        Position = UDim2.fromScale((i - 1) / 3 + 0.005, 0),
        Size = UDim2.fromScale(1 / 3 - 0.01, 1),
        BackgroundColor3 = colors.pearl,
        BorderSizePixel = 0,
    })
    make("UICorner", card, { CornerRadius = UDim.new(0, 18) })
    label(card, name, UDim2.fromScale(0.02, 0.02), UDim2.fromScale(0.96, 0.06), 23)
    label(card, detail, UDim2.fromScale(0.02, 0.09), UDim2.fromScale(0.96, 0.04), 13)
    local pilotLarge = preview(
        card,
        source:Clone(),
        id,
        true,
        UDim2.fromScale(0, 0.14),
        UDim2.fromScale(1, 0.53),
        1.06
    )
    local nativeLarge = preview(
        card,
        ItemModels.create(id, 1),
        id,
        false,
        UDim2.fromScale(0, 0.14),
        UDim2.fromScale(1, 0.53),
        1.06
    )
    nativeLarge.Visible = false
    local modelLabel = label(
        card,
        "BLENDER PILOT  •  " .. entry[4] .. " MESH PIECES",
        UDim2.fromScale(0.02, 0.66),
        UDim2.fromScale(0.96, 0.04),
        13,
        colors.teal
    )
    table.insert(
        largePairs,
        {
            pilot = pilotLarge,
            native = nativeLarge,
            label = modelLabel,
            pilotText = modelLabel.Text,
        }
    )
    make("Frame", card, {
        BackgroundColor3 = colors.aqua,
        BorderSizePixel = 0,
        Position = UDim2.fromScale(0.07, 0.72),
        Size = UDim2.fromScale(0.86, 0.003),
    })
    preview(
        card,
        ItemModels.create(id, 1),
        id,
        false,
        UDim2.fromScale(0.14, 0.75),
        UDim2.fromScale(0.45, 0.24),
        1.28
    )
    label(
        card,
        "CURRENT\nNATIVE MODEL",
        UDim2.fromScale(0.56, 0.81),
        UDim2.fromScale(0.40, 0.10),
        13
    )
    local smallCard = make("Frame", thumbnails, {
        Position = UDim2.fromScale((i - 1) / 3 + 0.005, 0),
        Size = UDim2.fromScale(1 / 3 - 0.01, 1),
        BackgroundColor3 = colors.pearl,
        BorderSizePixel = 0,
    })
    make("UICorner", smallCard, { CornerRadius = UDim.new(0, 18) })
    label(smallCard, name, UDim2.fromScale(0, 0.02), UDim2.fromScale(1, 0.08), 23)
    for index, pixels in { 48, 96, 192 } do
        local horizontal = if index == 3 then 0.65 else 0.18
        local vertical = if index == 1 then 235 elseif index == 2 then 70 else 90
        local vp = preview(
            smallCard,
            source:Clone(),
            id,
            true,
            UDim2.new(horizontal, -pixels / 2, 0, vertical),
            UDim2.fromOffset(pixels, pixels),
            1.28
        )
        label(
            smallCard,
            pixels .. " px",
            UDim2.new(horizontal, -31, 0, vertical - 25),
            UDim2.fromOffset(62, 25),
            15
        )
        vp.Name = "Size" .. pixels
    end
end
local function button(text, x, action)
    local b = make("TextButton", gui, {
        Text = text,
        Font = Enum.Font.GothamBold,
        TextSize = 13,
        TextColor3 = colors.pearl,
        BackgroundColor3 = colors.teal,
        BorderSizePixel = 0,
        Position = UDim2.fromScale(x, 0.915),
        Size = UDim2.fromScale(0.176, 0.055),
    })
    make("UICorner", b, { CornerRadius = UDim.new(0, 12) })
    b.Activated:Connect(action)
end
button("ACTIVATE ALL", 0.03, function()
    gui:SetAttribute("Pose", -1)
    for _, h in handles do
        h.age = 0
    end
end)
button("REST POSE", 0.222, function()
    gui:SetAttribute("Pose", 0)
end)
button("OPEN / TRIGGER", 0.414, function()
    gui:SetAttribute("Pose", 0.5)
end)
button("48 / 96 / 192 px", 0.606, function()
    comparison.Visible = not comparison.Visible
    thumbnails.Visible = not comparison.Visible
end)
button("BLENDER / NATIVE", 0.798, function()
    comparison.Visible, thumbnails.Visible = true, false
    for _, pair in largePairs do
        pair.pilot.Visible = not pair.pilot.Visible
        pair.native.Visible = not pair.pilot.Visible
        pair.label.Text = if pair.pilot.Visible
            then pair.pilotText
            else "CURRENT NATIVE  •  SAME VIEWPORT / CAMERA"
    end
end)
local failures = {}
ContentProvider:PreloadAsync(loaded, function(assetId, status)
    if status ~= Enum.AssetFetchStatus.Success then
        table.insert(failures, tostring(assetId))
    end
end)
if #failures > 0 then
    gui:SetAttribute("LoadFailures", table.concat(failures, ", "))
    label(
        gui,
        "MESH LOAD FAILED — check this account's asset access",
        UDim2.fromScale(0.03, 0.12),
        UDim2.fromScale(0.94, 0.04),
        15,
        Color3.fromRGB(170, 35, 35)
    )
    error("[RBX-019] Pilot asset load failed: " .. table.concat(failures, ", "))
end
gui:SetAttribute("Ready", true)
print("[RBX-019] Gallery ready: 3 Blender pilots, equal-size native toggle, 9 size previews")
local elapsed = 0
RunService.RenderStepped:Connect(function(dt)
    elapsed += dt
    if gui:GetAttribute("AutoTrigger") and elapsed >= 4 then
        elapsed = 0
        for _, h in handles do
            h.age = 0
        end
    end
    for _, h in handles do
        h:step(math.min(dt, 0.1))
    end
end)
