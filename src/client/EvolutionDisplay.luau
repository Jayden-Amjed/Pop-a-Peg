--!nonstrict

local Catalog = require(game:GetService("ReplicatedStorage").Shared.Catalog)
local Theme = require(script.Parent.UiTheme)
local Layout = require(script.Parent.ShopLayout)
local C = Theme.colors
local Display = {}
Display.__index = Display

local function place(object, area)
    Theme.rect(object, area.x, area.y, area.w, area.h)
end

function Display.new(parent, host, z, inspectTiles, options)
    local self = setmetatable(
        { host = host, rows = {}, z = z, inspectTiles = inspectTiles, options = options or {} },
        Display
    )
    self.frame = Theme.frame(parent, "Evolutions", nil, z)
    self.frame.BackgroundTransparency = 1
    self.title = Theme.label(self.frame, "Title", "EVOLUTIONS • L5 + L5", 17, C.ink, z + 2)
    self.title.Font = Enum.Font.FredokaOne
    self.title.TextXAlignment = Enum.TextXAlignment.Center
    self.title.TextScaled = true
    Theme.make("UITextSizeConstraint", { MinTextSize = 10, MaxTextSize = 17 }, self.title)
    return self
end

function Display:_row(index)
    local host, z, inspectTiles = self.host, self.z, self.inspectTiles
    local row = { boxes = {}, statuses = {}, viewports = {}, symbols = {}, ids = {} }
    for column = 1, 3 do
        local box =
            Theme.inset(self.frame, "Recipe" .. index .. "Item" .. column, C.paper, z + 1, 9)
        local status =
            Theme.label(self.frame, "Status" .. index .. "Item" .. column, "", 13, C.ink, z + 3)
        status.Font = Enum.Font.SourceSansBold
        status.TextXAlignment = Enum.TextXAlignment.Center
        local viewport = Theme.make("ViewportFrame", {
            Name = "Item",
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            ZIndex = z + 3,
        }, box)
        viewport:SetAttribute("NoOutline", true)
        viewport:SetAttribute("ShopPreview", true)
        row.boxes[column], row.statuses[column], row.viewports[column] = box, status, viewport
        if column < 3 then
            local symbol = Theme.label(
                self.frame,
                "Symbol" .. index .. "Item" .. column,
                column == 1 and "+" or "=",
                21,
                C.ink,
                z + 3
            )
            symbol.Font = Enum.Font.SourceSansBold
            symbol.TextXAlignment = Enum.TextXAlignment.Center
            row.symbols[column] = symbol
        end
        if inspectTiles then
            host.inspector:bind(box, function()
                return row.ids[column], Catalog.MaxLevel
            end)
        end
    end
    self.rows[index] = row
    return row
end

function Display:update(id, area, _onWhite, recipeOverride, recipeMode)
    local recipes = recipeOverride or Catalog.evolutionsFor(id)
    local count = #recipes
    place(self.frame, area)
    self.frame.Visible = count > 0
    local layout = Layout.equations(area.w, area.h, count, self.options.showTitle ~= false)
    place(self.title, layout.title)
    self.title.Visible = self.options.showTitle ~= false
    self.title.TextColor3 = C.ink
    local state = self.host.snapshot or {}
    for index = #self.rows + 1, count do
        self:_row(index)
    end
    for index, row in self.rows do
        local recipe = recipes[index]
        local geometry = layout.rows[index]
        local status = recipe
            and Catalog.evolutionState(state.inventory or {}, state.slots or 0, recipe.id)
        row.ids = recipe and { recipe.ingredients[1], recipe.ingredients[2], recipe.id } or {}
        for column, box in row.boxes do
            local visible = recipe ~= nil
            box.Visible, row.statuses[column].Visible, row.viewports[column].Visible =
                visible, visible, visible
            if column < 3 then
                row.symbols[column].Visible = visible
            end
            if visible then
                local ready = recipeMode == "reference"
                    or column == 3 and status.ready
                    or (status.levels[column] or 0) >= Catalog.MaxLevel
                local text = column == 3 and (geometry.compact and "EVO" or "EVOLVED")
                    or recipeMode == "reference" and "LEVEL 5"
                    or (
                        ready and "READY"
                        or (
                            status.owned[column]
                                and ("L" .. tostring(status.levels[column]) .. "/5")
                            or "NEED"
                        )
                    )
                row.statuses[column].Text = text
                row.statuses[column].TextSize = geometry.font
                row.statuses[column].TextColor3 = ready and C.positive or C.ink
                place(box, geometry.boxes[column])
                place(row.statuses[column], geometry.statuses[column])
                Theme.rect(
                    row.viewports[column],
                    1,
                    1,
                    geometry.boxes[column].w - 2,
                    geometry.boxes[column].h - 2
                )
                local border = box:FindFirstChildWhichIsA("UIStroke")
                border.Color = C.ink
                -- Keep the shared navy edge; show recipe readiness through its fill.
                Theme.setSurface(
                    box,
                    true,
                    column == 3 and C.gold:Lerp(C.paper, 0.7)
                        or (ready and C.mint:Lerp(C.paper, 0.78) or C.paper)
                )
                if column < 3 then
                    place(row.symbols[column], geometry.symbols[column])
                    row.symbols[column].TextColor3 = C.ink
                    row.symbols[column].TextSize = math.max(13, geometry.font + 8)
                end
                self.host:_mount(row.viewports[column], row.ids[column], Catalog.MaxLevel)
            end
        end
    end
end

return Display
