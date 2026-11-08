--!nonstrict

local Theme = {}
Theme.colors = {
    ink = Color3.fromRGB(18, 49, 71),
    board = Color3.fromRGB(24, 105, 147),
    panel = Color3.fromRGB(34, 125, 172),
    edge = Color3.fromRGB(145, 207, 225),
    muted = Color3.fromRGB(201, 229, 239),
    paper = Color3.fromRGB(244, 250, 253),
    mint = Color3.fromRGB(141, 203, 55),
    coral = Color3.fromRGB(238, 136, 68),
    gold = Color3.fromRGB(255, 210, 93),
    blue = Color3.fromRGB(48, 160, 200),
    positive = Color3.fromRGB(38, 135, 63),
    negative = Color3.fromRGB(192, 54, 66),
    trigger = Color3.fromRGB(242, 183, 33),
}

function Theme.make(className, properties, parent)
    local object = Instance.new(className)
    for key, value in properties do
        object[key] = value
    end
    object.Parent = parent
    return object
end

function Theme.corner(parent, radius)
    return Theme.make("UICorner", { CornerRadius = UDim.new(0, radius or 5) }, parent)
end

function Theme.stroke(parent, color, width)
    return Theme.make("UIStroke", {
        Color = color or Theme.colors.ink,
        Thickness = width or 3,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
        LineJoinMode = Enum.LineJoinMode.Round,
    }, parent)
end

function Theme.frame(parent, name, color, z)
    return Theme.make("Frame", {
        Name = name,
        BackgroundColor3 = color or Theme.colors.panel,
        BorderSizePixel = 0,
        ZIndex = z or 2,
    }, parent)
end

function Theme.label(parent, name, text, size, color, z)
    return Theme.make("TextLabel", {
        Name = name,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Font = Enum.Font.SourceSansSemibold,
        Text = text or "",
        TextSize = size or 20,
        TextColor3 = color or Theme.colors.paper,
        TextStrokeColor3 = Theme.colors.ink,
        TextStrokeTransparency = 0.82,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Center,
        ZIndex = z or 3,
    }, parent)
end

function Theme.decorate(object, color, z)
    z = z or object.ZIndex
    object.BackgroundColor3 = color or Theme.colors.panel
    Theme.corner(object, 10)
    Theme.stroke(object, Theme.colors.edge, 2)
    local shadow = Theme.frame(object, "Depth", Theme.colors.ink, math.max(1, z - 1))
    shadow.Position = UDim2.fromOffset(0, 5)
    shadow.BackgroundTransparency = 0.48
    shadow.Size = UDim2.fromScale(1, 1)
    Theme.corner(shadow, 10)
    local shine = Theme.frame(object, "Bevel", Color3.new(1, 1, 1), z + 1)
    shine.BackgroundTransparency = 0.58
    shine.Position = UDim2.fromOffset(3, 3)
    shine.Size = UDim2.new(1, -6, 0, 2)
    Theme.make("UIGradient", {
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.new(1, 1, 1)),
            ColorSequenceKeypoint.new(0.45, Color3.fromRGB(234, 245, 250)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(185, 215, 229)),
        }),
        Rotation = 90,
    }, object)
    return object
end

function Theme.plate(parent, name, color, z)
    return Theme.decorate(Theme.frame(parent, name, color, z), color, z)
end

function Theme.tile(parent, name, color, z)
    local object = Theme.plate(parent, name, color, z)
    for _, child in object:GetDescendants() do
        if child:IsA("UICorner") then
            child.CornerRadius = UDim.new(0, 4)
        end
    end
    return object
end

function Theme.button(parent, name, text, color, callback, z)
    z = z or 6
    local object = Theme.make("TextButton", {
        Name = name,
        BackgroundColor3 = color or Theme.colors.mint,
        BorderSizePixel = 0,
        AutoButtonColor = true,
        Font = Enum.Font.SourceSansBold,
        Text = text,
        TextSize = 24,
        TextColor3 = Theme.colors.paper,
        TextStrokeColor3 = Theme.colors.ink,
        TextStrokeTransparency = 0.7,
        ZIndex = z,
    }, parent)
    Theme.decorate(object, color or Theme.colors.mint, z)
    object.Activated:Connect(function()
        if object.Active then
            callback()
        end
    end)
    return object
end

function Theme.setEnabled(object, enabled, color)
    object.Active = enabled
    object.AutoButtonColor = enabled
    object.BackgroundColor3 = enabled and (color or Theme.colors.mint)
        or Color3.fromRGB(111, 145, 161)
    object.TextTransparency = enabled and 0 or 0.2
end

function Theme.select(object, selected, color)
    object.BackgroundColor3 = selected and Theme.colors.paper or color
    local border = object:FindFirstChildWhichIsA("UIStroke")
    if border then
        border.Color = selected and Theme.colors.gold or Theme.colors.edge
        border.Thickness = selected and 5 or 2
    end
    if object:IsA("TextButton") then
        object.TextColor3 = selected and Theme.colors.ink or Theme.colors.paper
        object.TextStrokeTransparency = selected and 1 or 0.7
    end
end

function Theme.rect(object, x, y, width, height)
    object.Position = UDim2.fromOffset(x, y)
    object.Size = UDim2.fromOffset(width, height)
end

return Theme
