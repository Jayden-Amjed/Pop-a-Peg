--!nonstrict

local UserInputService = game:GetService("UserInputService")
local TextService = game:GetService("TextService")
local Catalog = require(game:GetService("ReplicatedStorage").Shared.Catalog)
local Theme = require(script.Parent.UiTheme)
local EvolutionDisplay = require(script.Parent.EvolutionDisplay)
local C = Theme.colors
local Inspector = {}
Inspector.__index = Inspector

function Inspector.new(host)
    local self = setmetatable({
        host = host,
        effectLabels = {},
        resolvers = setmetatable({}, { __mode = "k" }),
    }, Inspector)
    local panel = Theme.plate(host.root, "HoverStats", C.paper, 80)
    panel:SetAttribute("BlocksAim", true)
    panel.Visible = false
    self.panel = panel
    self.title = Theme.heading(panel, "Name", "", 28, C.ink, 82)
    self.title.TextWrapped = true
    self.title.TextScaled = true
    self.titleScale =
        Theme.make("UITextSizeConstraint", { MinTextSize = 17, MaxTextSize = 28 }, self.title)
    self.kind = Theme.label(panel, "Kind", "", 14, C.board, 82)
    self.trigger = Theme.label(panel, "Trigger", "", 21, C.trigger, 82)
    self.trigger.Font = Enum.Font.SourceSansBold
    self.trigger.TextWrapped = true
    self.close = Theme.button(panel, "Close", "×", C.ice, function()
        self:hide()
    end, 84)
    self.close.TextSize = 24
    for index = 1, 12 do
        local line = Theme.label(panel, "Effect" .. index, "", 21, C.positive, 82)
        line.TextWrapped = true
        line.TextYAlignment = Enum.TextYAlignment.Center
        self.effectLabels[index] = line
    end
    self.evolutions = EvolutionDisplay.new(panel, host, 82, false)
    panel.MouseEnter:Connect(function()
        self.overPanel = true
        self.hideAt = nil
    end)
    panel.MouseLeave:Connect(function()
        self.overPanel = false
        if not self.pinned then
            self.hideAt = os.clock() + 0.12
        end
    end)
    return self
end

function Inspector:hide()
    self.panel.Visible = false
    self.anchor, self.id, self.pinned, self.hideAt = nil, nil, false, nil
    self.overPanel = false
end

function Inspector:show(id, level, anchor, pinned)
    local detail = Catalog.detail(id, level)
    if not detail then
        return
    end
    self.id, self.level, self.anchor = id, level or 1, anchor
    self.pinned, self.hideAt = pinned == true, nil
    self.detail = detail
    self.panel.Visible = true
    self:refresh()
end

function Inspector:bind(control, resolve)
    self.resolvers[control] = resolve
    control.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch then
            local id, level = resolve()
            if id then
                self:show(id, level, control, true)
            end
        end
    end)
    control.MouseEnter:Connect(function()
        local id, level = resolve()
        if id then
            self:show(id, level, control, false)
        end
    end)
    control.MouseLeave:Connect(function()
        if self.anchor == control and not self.pinned then
            self.hideAt = os.clock() + 0.12
        end
    end)
    control.SelectionGained:Connect(function()
        local id, level = resolve()
        if id then
            self:show(id, level, control, true)
        end
    end)
    control.SelectionLost:Connect(function()
        if self.anchor == control then
            self:hide()
        end
    end)
end

function Inspector:refresh()
    if not self.panel.Visible or not self.detail then
        return
    end
    local resolve = self.anchor and self.resolvers[self.anchor]
    if resolve then
        local id, level = resolve()
        local current = id and Catalog.detail(id, level)
        if not current then
            self:hide()
            return
        end
        self.id, self.level, self.detail = id, level or 1, current
    end
    local data = self.detail
    local size = self.host.viewport or Vector2.new(1280, 720)
    local small = size.Y < 500
    local width = math.min(small and 380 or 430, size.X - 20)
    local recipeCount = math.min(2, #(data.evolutions or {}))
    local recipeHeight = recipeCount > 0
            and ((small and 14 or 20) + recipeCount * (small and 44 or (size.Y >= 760 and 96 or 80)))
        or 0
    local font = small and 17 or 21
    local titleH = small and 32 or 42
    local function measured(text, textSize)
        return math.ceil(
            TextService:GetTextSize(
                text,
                textSize,
                Enum.Font.SourceSansBold,
                Vector2.new(width - 30, 1000)
            ).Y
        ) + 5
    end
    local function contentHeight(textSize)
        local total = 26 + titleH + measured(data.trigger, textSize) + recipeHeight + 15
        for _, effect in data.effects do
            total += measured((effect.tone == "trigger" and "" or "• ") .. effect.text, textSize) + 3
        end
        return total
    end
    while font > 13 and contentHeight(font) > size.Y - 20 do
        font -= 1
    end
    self.title.Text = data.name
    self.kind.Text = data.kind == "evolved" and "EVOLVED • MAX POWER"
        or (
            data.kind == "item"
                and (string.upper(data.tier or "common") .. " • LEVEL " .. tostring(data.level) .. "/5")
            or string.upper(data.kind)
        )
    self.title.TextSize = small and 23 or 28
    self.titleScale.MaxTextSize = small and 23 or 28
    self.trigger.Text, self.trigger.TextSize = data.trigger, font
    local y = 23 + titleH
    Theme.rect(self.kind, 14, 5, width - 80, 18)
    Theme.rect(self.title, 14, 21, width - 80, titleH)
    Theme.rect(self.close, width - 54, 7, 44, 44)
    local triggerH = measured(data.trigger, font)
    Theme.rect(self.trigger, 14, y, width - 28, triggerH)
    y += triggerH + 3
    for index, line in self.effectLabels do
        local effect = data.effects[index]
        line.Visible = effect ~= nil
        if effect then
            line.Text = (effect.tone == "trigger" and "" or "• ") .. effect.text
            line.TextColor3 = C[effect.tone] or C.ink
            line.Font = effect.tone == "trigger" and Enum.Font.SourceSansBold
                or Enum.Font.SourceSansSemibold
            line.TextSize = font
            local lineH = measured(line.Text, font)
            Theme.rect(line, 14, y, width - 28, lineH)
            y += lineH + 3
        end
    end
    self.evolutions:update(self.id, { x = 14, y = y, w = width - 28, h = recipeHeight }, true)
    y += recipeHeight
    self.panel.Size = UDim2.fromOffset(width, y + 12)
    self:_position()
end

function Inspector:_position()
    local size = self.host.viewport or Vector2.new(1280, 720)
    local w, h = self.panel.Size.X.Offset, self.panel.Size.Y.Offset
    local origin = self.host.root.AbsolutePosition
    local anchor = self.anchor
    local at = anchor and anchor.Parent and anchor.AbsolutePosition - origin
        or UserInputService:GetMouseLocation() - origin
    local extent = anchor and anchor.Parent and anchor.AbsoluteSize or Vector2.zero
    local x = at.X + extent.X + 12
    if x + w > size.X - 10 then
        x = at.X - w - 12
    end
    if x < 10 then
        x = math.clamp(at.X, 10, math.max(10, size.X - w - 10))
    end
    local y = at.Y
    if extent.X > w and at.Y + extent.Y + h < size.Y - 10 then
        y = at.Y + extent.Y + 10
    end
    self.panel.Position = UDim2.fromOffset(
        math.clamp(x, 10, math.max(10, size.X - w - 10)),
        math.clamp(y, 10, math.max(10, size.Y - h - 10))
    )
end

function Inspector:step()
    if self.hideAt and os.clock() >= self.hideAt and not self.overPanel then
        self:hide()
    end
    if self.panel.Visible then
        local visible = true
        local parent = self.anchor
        while parent and parent ~= self.host.root do
            if parent:IsA("GuiObject") and not parent.Visible then
                visible = false
                break
            end
            parent = parent.Parent
        end
        if self.anchor and (not self.anchor.Parent or not visible) then
            self:hide()
        else
            self:_position()
        end
    end
end

return Inspector
