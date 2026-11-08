--!nonstrict

local Theme = {}
Theme.colors = {
    ink = Color3.fromRGB(12, 27, 16),
    board = Color3.fromRGB(25, 62, 35),
    panel = Color3.fromRGB(44, 88, 47),
    edge = Color3.fromRGB(103, 170, 70),
    muted = Color3.fromRGB(210, 232, 192),
    paper = Color3.fromRGB(255, 253, 235),
    mint = Color3.fromRGB(113, 222, 55),
    coral = Color3.fromRGB(242, 94, 72),
    gold = Color3.fromRGB(255, 205, 56),
    blue = Color3.fromRGB(78, 189, 227),
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
        Font = Enum.Font.FredokaOne,
        Text = text or "",
        TextSize = size or 20,
        TextColor3 = color or Theme.colors.paper,
        TextStrokeColor3 = Theme.colors.ink,
        TextStrokeTransparency = 0,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Center,
        ZIndex = z or 3,
    }, parent)
end

function Theme.decorate(object, color, z)
    z = z or object.ZIndex
    object.BackgroundColor3 = color or Theme.colors.panel
    Theme.corner(object, 5)
    Theme.stroke(object, Theme.colors.ink, 4)
    local shadow = Theme.frame(object, "Depth", Theme.colors.ink, math.max(1, z - 1))
    shadow.Position = UDim2.fromOffset(0, 6)
    shadow.Size = UDim2.fromScale(1, 1)
    Theme.corner(shadow, 5)
    local shine = Theme.frame(object, "Bevel", Color3.new(1, 1, 1), z + 1)
    shine.BackgroundTransparency = 0.65
    shine.Position = UDim2.fromOffset(3, 3)
    shine.Size = UDim2.new(1, -6, 0, 3)
    Theme.make("UIGradient", {
        Color = ColorSequence.new(Color3.new(1, 1, 1), Color3.fromRGB(179, 195, 169)),
        Rotation = 90,
    }, object)
    return object
end

function Theme.plate(parent, name, color, z)
    return Theme.decorate(Theme.frame(parent, name, color, z), color, z)
end

function Theme.button(parent, name, text, color, callback, z)
    z = z or 6
    local object = Theme.make("TextButton", {
        Name = name,
        BackgroundColor3 = color or Theme.colors.mint,
        BorderSizePixel = 0,
        AutoButtonColor = true,
        Font = Enum.Font.FredokaOne,
        Text = text,
        TextSize = 24,
        TextColor3 = Theme.colors.paper,
        TextStrokeColor3 = Theme.colors.ink,
        TextStrokeTransparency = 0,
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
        or Color3.fromRGB(90, 107, 88)
    object.TextTransparency = enabled and 0 or 0.2
end

function Theme.rect(object, x, y, width, height)
    object.Position = UDim2.fromOffset(x, y)
    object.Size = UDim2.fromOffset(width, height)
end

return Theme
