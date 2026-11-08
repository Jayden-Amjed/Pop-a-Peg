--!nonstrict

local UserInputService = game:GetService("UserInputService")
local Catalog = require(game:GetService("ReplicatedStorage").Shared.Catalog)
local Theme = require(script.Parent.UiTheme)
local C = Theme.colors
local Inspector = {}
Inspector.__index = Inspector

function Inspector.new(host)
    local self = setmetatable({
        host = host,
        effectLabels = {},
        pairs = {},
        resolvers = setmetatable({}, { __mode = "k" }),
    }, Inspector)
    local panel = Theme.plate(host.root, "HoverStats", C.paper, 80)
    panel:SetAttribute("BlocksAim", true)
    panel.Visible = false
    self.panel = panel
    self.title = Theme.label(panel, "Name", "", 28, C.ink, 82)
    self.title.Font = Enum.Font.SourceSansBold
    self.title.TextWrapped = true
    self.kind = Theme.label(panel, "Kind", "", 14, C.board, 82)
    self.trigger = Theme.label(panel, "Trigger", "", 21, C.trigger, 82)
    self.trigger.Font = Enum.Font.SourceSansBold
    self.trigger.TextWrapped = true
    self.close = Theme.button(panel, "Close", "×", C.panel, function()
        self:hide()
    end, 84)
    self.close.TextSize = 24
    for index = 1, 4 do
        local line = Theme.label(panel, "Effect" .. index, "", 21, C.positive, 82)
        line.TextWrapped = true
        line.TextYAlignment = Enum.TextYAlignment.Center
        self.effectLabels[index] = line
    end
    self.pairsTitle = Theme.label(panel, "Pairs", "PAIRS", 16, C.ink, 82)
    self.pairsTitle.Font = Enum.Font.SourceSansBold
    for index = 1, 3 do
        local box = Theme.tile(panel, "Pair" .. index, C.muted, 82)
        local status = Theme.label(box, "Ownership", "", 13, C.ink, 84)
        status.Font = Enum.Font.SourceSansBold
        status.TextXAlignment = Enum.TextXAlignment.Center
        local viewport = Theme.make("ViewportFrame", {
            Name = "Item",
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            ZIndex = 84,
        }, box)
        viewport:SetAttribute("NoOutline", true)
        local name = Theme.label(box, "Name", "", 13, C.ink, 84)
        name.TextXAlignment = Enum.TextXAlignment.Center
        name.TextTruncate = Enum.TextTruncate.AtEnd
        self.pairs[index] = { box = box, status = status, viewport = viewport, name = name }
    end
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
    for _, pair in self.pairs do
        pair.viewport.Visible = false
    end
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
    local width = math.min(small and 360 or 420, size.X - 20)
    local font = small and 17 or 21
    self.title.Text, self.kind.Text = data.name, string.upper(data.kind)
    self.title.TextSize = small and 23 or 28
    self.trigger.Text, self.trigger.TextSize = data.trigger, font
    local y = small and 54 or 64
    Theme.rect(self.kind, 14, 5, width - 68, 18)
    Theme.rect(self.title, 14, 21, width - 65, small and 30 or 39)
    Theme.rect(self.close, width - 44, 10, 32, 30)
    local triggerH = small and 36 or 44
    Theme.rect(self.trigger, 14, y, width - 28, triggerH)
    y += triggerH + 3
    for index, line in self.effectLabels do
        local effect = data.effects[index]
        line.Visible = effect ~= nil
        if effect then
            line.Text = "• " .. effect.text
            line.TextColor3 = C[effect.tone] or C.ink
            line.TextSize = font
            local h = small and 36 or 44
            Theme.rect(line, 14, y, width - 28, h)
            y += h + 3
        end
    end
    local count = math.min(3, #data.partners)
    self.pairsTitle.Visible = count > 0
    if count > 0 then
        Theme.rect(self.pairsTitle, 14, y, width - 28, 20)
        y += 23
    end
    local boxSize = small and 66 or 86
    local start = (width - count * boxSize - math.max(0, count - 1) * 10) / 2
    local inventory = self.host.snapshot and self.host.snapshot.inventory or {}
    for index, pair in self.pairs do
        local id = data.partners[index]
        pair.box.Visible, pair.viewport.Visible = id ~= nil, id ~= nil
        if id then
            local owned = Catalog.owns(inventory, id)
            pair.status.Text = owned and "OWNED" or "NEED"
            pair.status.TextColor3 = owned and C.positive or C.ink
            pair.name.Text = Catalog.Items[id].name
            Theme.rect(pair.box, start + (index - 1) * (boxSize + 10), y, boxSize, boxSize + 29)
            Theme.rect(pair.status, 1, 0, boxSize - 2, 18)
            Theme.rect(pair.viewport, 3, 18, boxSize - 6, boxSize - 10)
            Theme.rect(pair.name, 2, boxSize + 8, boxSize - 4, 19)
            self.host:_mount(pair.viewport, id, 1)
        end
    end
    if count > 0 then
        y += boxSize + 29
    end
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
