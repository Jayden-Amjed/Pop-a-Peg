-- Shared information card for shop inspection, hover/touch detail and gallery recipes.
local TextService = game:GetService("TextService")
local Catalog = require(game:GetService("ReplicatedStorage").Shared.Catalog)
local Theme = require(script.Parent.UiTheme)
local Layout = require(script.Parent.ItemDetailLayout)
local EvolutionDisplay = require(script.Parent.EvolutionDisplay)
local C = Theme.colors
local Card = {}
Card.__index = Card

local function place(object, area, inset)
    inset = inset or 0
    Theme.rect(object, area.x + inset, area.y + inset, area.w, area.h)
end

function Card.new(parent, host, z, options)
    z = z or 30
    local self = setmetatable({ host = host, z = z, options = options or {}, rows = {} }, Card)
    self.frame = Theme.make("ScrollingFrame", {
        Name = "ItemDetailCard",
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ScrollBarThickness = 4,
        ScrollBarImageColor3 = C.board,
        ScrollingDirection = Enum.ScrollingDirection.Y,
        CanvasSize = UDim2.fromOffset(0, 0),
        Active = true,
        ZIndex = z,
    }, parent)
    self.frame:SetAttribute("BlocksAim", true)
    self.modelBox = Theme.inset(self.frame, "ModelBox", C.ice, z + 1, 12)
    self.viewport = Theme.make("ViewportFrame", {
        Name = "Item",
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Position = UDim2.fromOffset(5, 5),
        Size = UDim2.new(1, -10, 1, -10),
        ZIndex = z + 2,
    }, self.modelBox)
    self.viewport:SetAttribute("NoOutline", true)
    self.viewport:SetAttribute("ShopPreview", true)
    self.nameBox = Theme.inset(self.frame, "NameBox", C.aqua, z + 1, 10)
    self.name = Theme.heading(self.nameBox, "Name", "", 25, C.ink, z + 2)
    self.name.TextScaled, self.name.TextWrapped = true, true
    self.name.TextXAlignment = Enum.TextXAlignment.Center
    Theme.make("UITextSizeConstraint", { MinTextSize = 15, MaxTextSize = 25 }, self.name)
    self.kind = Theme.label(self.nameBox, "Kind", "", 12, C.board, z + 2)
    self.kind.TextScaled = true
    self.kind.TextXAlignment = Enum.TextXAlignment.Center
    Theme.make("UITextSizeConstraint", { MinTextSize = 10, MaxTextSize = 12 }, self.kind)
    self.recipeBox = Theme.inset(self.frame, "RecipeBox", C.ice, z + 1, 10)
    self.evolutions =
        EvolutionDisplay.new(self.recipeBox, host, z + 2, false, { showTitle = false })
    return self
end

function Card:update(id, level, area, options)
    options = options or self.options
    local detail = Catalog.detail(id, level)
    if not detail then
        self.frame.Visible = false
        return
    end
    self.frame.Visible = true
    place(self.frame, area)
    local width = math.max(32, area.w - 8)
    local columns = Layout.columns(width, area.h)
    local font = area.h < 400 and 16 or 18
    local lines = { { text = detail.trigger, tone = "trigger" } }
    for _, effect in detail.effects do
        table.insert(lines, effect)
    end
    local heights = {}
    for _, line in lines do
        table.insert(
            heights,
            math.max(
                font + 3,
                math.ceil(
                    TextService:GetTextSize(
                        line.text,
                        font,
                        Enum.Font.SourceSansSemibold,
                        Vector2.new(math.max(20, columns.detailsW - 20), 1000)
                    ).Y
                )
            )
        )
    end
    local recipes = options.recipes or Catalog.evolutionsFor(id)
    local layout = Layout.compute(width, area.h, heights, #recipes)
    -- Keep compartment outlines inside the clipped scrolling viewport.
    place(self.modelBox, layout.model, 2)
    place(self.nameBox, layout.name, 2)
    self.name.Text = detail.name
    self.kind.Text = options.kindText
        or (
            detail.kind == "evolved" and "EVOLVED · MAX POWER"
            or detail.kind == "item" and (string.upper(detail.tier or "common") .. " · LEVEL " .. detail.level .. "/5")
            or string.upper(detail.kind)
        )
    Theme.rect(self.name, 7, 3, layout.name.w - 14, 30)
    Theme.rect(self.kind, 7, 34, layout.name.w - 14, 16)
    self.host:_mount(self.viewport, id, level)
    for index, line in lines do
        local row = self.rows[index]
        if not row then
            local box = Theme.inset(self.frame, "EffectBox" .. index, C.paper, self.z + 1, 9)
            local text = Theme.label(box, "Text", "", font, C.ink, self.z + 2)
            text.Font = Enum.Font.SourceSansSemibold
            text.TextWrapped = true
            text.TextXAlignment = Enum.TextXAlignment.Center
            row = { box = box, text = text }
            self.rows[index] = row
        end
        row.box.Visible = true
        place(row.box, layout.effects[index], 2)
        row.text.Text, row.text.TextColor3, row.text.TextSize =
            line.text, C[line.tone] or C.ink, font
        row.text.Position, row.text.Size = UDim2.fromOffset(9, 6), UDim2.new(1, -18, 1, -12)
    end
    for index = #lines + 1, #self.rows do
        self.rows[index].box.Visible = false
    end
    self.recipeBox.Visible = #recipes > 0
    place(self.recipeBox, layout.recipes, 2)
    self.evolutions:update(
        id,
        { x = 6, y = 6, w = layout.recipes.w - 12, h = math.max(0, layout.recipes.h - 12) },
        true,
        recipes,
        options.recipeMode
    )
    local key = id .. ":" .. tostring(level)
    if self.key ~= key then
        self.frame.CanvasPosition = Vector2.zero
        self.key = key
    end
    -- Include the 2px inset plus the last compartment's 4px depth shadow.
    local canvasHeight = layout.contentHeight + 6
    self.frame.CanvasSize = UDim2.fromOffset(0, canvasHeight)
    self.frame.ScrollingEnabled = canvasHeight > area.h
    self.frame.ScrollBarThickness = self.frame.ScrollingEnabled and 4 or 0
    self.layout, self.detail = layout, detail
end

return Card
