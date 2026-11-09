--!nonstrict

local UserInputService = game:GetService("UserInputService")
local Catalog = require(game:GetService("ReplicatedStorage").Shared.Catalog)
local Theme = require(script.Parent.UiTheme)
local ItemDetailCard = require(script.Parent.ItemDetailCard)
local Layout = require(script.Parent.RunLayout)
local C = Theme.colors
local Inspector = {}
Inspector.__index = Inspector

function Inspector.new(host)
    local self = setmetatable({
        host = host,
        effectLabels = {},
        resolvers = setmetatable({}, { __mode = "k" }),
        rackAnchors = setmetatable({}, { __mode = "k" }),
    }, Inspector)
    local panel = Theme.plate(host.root, "HoverStats", C.paper, 80)
    panel:SetAttribute("BlocksAim", true)
    panel.Visible = false
    self.panel = panel
    self.title = Theme.heading(panel, "Title", "INSPECT ITEM", 23, C.ink, 82)
    self.title.TextScaled = true
    Theme.make("UITextSizeConstraint", { MinTextSize = 15, MaxTextSize = 23 }, self.title)
    self.close = Theme.button(panel, "Close", "×", C.ice, function()
        self:hide()
    end, 84)
    self.close.TextSize = 24
    self.card = ItemDetailCard.new(panel, host, 82)
    self.evolutions = self.card.evolutions
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
    if not pinned and not self.rackAnchors[anchor] then
        return
    end
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

function Inspector:bind(control, resolve, options)
    self.resolvers[control] = resolve
    self.rackAnchors[control] = options and options.rack == true or nil
    control.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch then
            local id, level = resolve()
            if id then
                self:show(id, level, control, true)
            end
        end
    end)
    control.MouseEnter:Connect(function()
        if not self.rackAnchors[control] then
            return
        end
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
    local size = self.host.viewport or Vector2.new(1280, 720)
    local passiveRack = self.rackAnchors[self.anchor] and not self.pinned
    local bounds = Layout.inspector(size.X, size.Y, passiveRack)
    local width, height = bounds.w, bounds.h
    self.panel.Size = UDim2.fromOffset(width, height)
    self.panel:SetAttribute("PassiveRack", passiveRack == true)
    self.close.Visible = not passiveRack
    Theme.rect(self.title, 14, 6, width - (passiveRack and 28 or 80), passiveRack and 28 or 36)
    Theme.rect(self.close, width - 54, 7, 44, 44)
    local top = passiveRack and 40 or 54
    self.card:update(
        self.id,
        self.level,
        { x = 12, y = top, w = width - 24, h = height - top - 12 }
    )

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
