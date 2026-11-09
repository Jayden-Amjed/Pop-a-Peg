--!nonstrict

local Theme = {}
Theme.colors = {
    ink = Color3.fromRGB(16, 55, 78),
    board = Color3.fromRGB(21, 99, 125),
    panel = Color3.fromRGB(19, 139, 158),
    aqua = Color3.fromRGB(13, 199, 211),
    ice = Color3.fromRGB(204, 237, 245),
    edge = Color3.fromRGB(145, 207, 225),
    muted = Color3.fromRGB(204, 237, 245),
    paper = Color3.fromRGB(243, 252, 255),
    mint = Color3.fromRGB(102, 210, 13),
    coral = Color3.fromRGB(255, 159, 85),
    gold = Color3.fromRGB(255, 208, 65),
    blue = Color3.fromRGB(13, 199, 211),
    positive = Color3.fromRGB(38, 135, 63),
    negative = Color3.fromRGB(192, 54, 66),
    trigger = Color3.fromRGB(157, 103, 9),
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
        TextStrokeTransparency = 1,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Center,
        ZIndex = z or 3,
    }, parent)
end

function Theme.heading(parent, name, value, size, color, z)
    local object = Theme.label(parent, name, value, size, color or Theme.colors.ink, z)
    object.Font = Enum.Font.FredokaOne
    return object
end

function Theme.ribbon(parent, name, value, size, z)
    local object = Theme.heading(parent, name, value, size, Theme.colors.ink, z)
    object.BackgroundTransparency = 0
    object.BackgroundColor3 = Theme.colors.aqua
    object.TextXAlignment = Enum.TextXAlignment.Center
    Theme.corner(object, 10)
    return object
end

function Theme.decorate(object, color, z)
    z = z or object.ZIndex
    object.BackgroundColor3 = color or Theme.colors.panel
    Theme.corner(object, 16)
    Theme.stroke(object, Theme.colors.ink, 2)
    local shadow = Theme.frame(object, "Depth", Theme.colors.ink, math.max(1, z - 1))
    shadow.Position = UDim2.fromOffset(0, 4)
    shadow.BackgroundTransparency = 0.55
    shadow.Size = UDim2.fromScale(1, 1)
    Theme.corner(shadow, 16)
    Theme.make("UIGradient", {
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.new(1, 1, 1)),
            ColorSequenceKeypoint.new(0.45, Color3.new(1, 1, 1)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(204, 227, 239)),
        }),
        Rotation = 90,
    }, object)
    return object
end

function Theme.plate(parent, name, color, z)
    return Theme.decorate(Theme.frame(parent, name, color, z), color, z)
end

-- Recessed compartments share the rounded silhouette; no floating highlight strips.
function Theme.inset(parent, name, color, z, radius)
    local object = Theme.frame(parent, name, color or Theme.colors.ice, z)
    Theme.corner(object, radius or 10)
    Theme.stroke(object, Theme.colors.edge, 1)
    Theme.make("UIGradient", {
        Color = ColorSequence.new(Color3.fromRGB(228, 241, 246), Color3.new(1, 1, 1)),
        Rotation = 90,
    }, object)
    return object
end

function Theme.tile(parent, name, color, z)
    local object = Theme.plate(parent, name, color, z)
    for _, child in object:GetDescendants() do
        if child:IsA("UICorner") then
            child.CornerRadius = UDim.new(0, 10)
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
        Font = Enum.Font.FredokaOne,
        Text = text,
        TextSize = 24,
        TextColor3 = Theme.colors.paper,
        TextStrokeColor3 = Theme.colors.ink,
        TextStrokeTransparency = 0.7,
        ZIndex = z,
    }, parent)
    Theme.decorate(object, color or Theme.colors.mint, z)
    Theme.setEnabled(object, true, color or Theme.colors.mint)
    object.Activated:Connect(function()
        if object.Active then
            callback()
        end
    end)
    return object
end

function Theme.setEnabled(object, enabled, color)
    object.Active = enabled
    object.Selectable = enabled
    object.AutoButtonColor = enabled
    object.BackgroundColor3 = enabled and (color or Theme.colors.mint)
        or Color3.fromRGB(191, 210, 217)
    object.TextTransparency = enabled and 0 or 0.2
    local background = object.BackgroundColor3
    local dark = background == Theme.colors.ink
        or background == Theme.colors.board
        or background == Theme.colors.panel
        or background == Theme.colors.mint
    object.TextColor3 = enabled and dark and Theme.colors.paper or Theme.colors.ink
    object.TextStrokeTransparency = enabled and dark and 0.45 or 1
end

function Theme.select(object, selected, color)
    object.BackgroundColor3 = selected and Theme.colors.ice or color
    local border = object:FindFirstChildWhichIsA("UIStroke")
    if border then
        border.Color = selected and Theme.colors.aqua or Theme.colors.ink
        border.Thickness = selected and 3 or 2
    end
    if object:IsA("TextButton") then
        local background = object.BackgroundColor3
        local dark = not selected
            and (
                background == Theme.colors.ink
                or background == Theme.colors.board
                or background == Theme.colors.panel
                or background == Theme.colors.mint
            )
        object.TextColor3 = dark and Theme.colors.paper or Theme.colors.ink
        object.TextStrokeTransparency = dark and 0.45 or 1
    end
end

function Theme.rect(object, x, y, width, height)
    object.Position = UDim2.fromOffset(x, y)
    object.Size = UDim2.fromOffset(width, height)
end

return Theme
