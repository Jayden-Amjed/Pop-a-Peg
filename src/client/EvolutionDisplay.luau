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

function Display.new(parent, host, z, inspectTiles)
    local self = setmetatable({ host = host, rows = {} }, Display)
    self.frame = Theme.frame(parent, "Evolutions", nil, z)
    self.frame.BackgroundTransparency = 1
    self.title = Theme.label(self.frame, "Title", "EVOLUTIONS • L5 + L5", 17, C.ink, z + 2)
    self.title.Font = Enum.Font.SourceSansBold
    self.title.TextXAlignment = Enum.TextXAlignment.Center
    self.title.TextScaled = true
    Theme.make("UITextSizeConstraint", { MinTextSize = 10, MaxTextSize = 17 }, self.title)
    for index = 1, 2 do
        local row = { boxes = {}, statuses = {}, viewports = {}, symbols = {}, ids = {} }
        for column = 1, 3 do
            local box =
                Theme.tile(self.frame, "Recipe" .. index .. "Item" .. column, C.paper, z + 1)
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
    end
    return self
end

function Display:update(id, area, onWhite)
    local recipes = Catalog.evolutionsFor(id)
    local count = math.min(2, #recipes)
    place(self.frame, area)
    self.frame.Visible = count > 0
    local layout = Layout.equations(area.w, area.h, count)
    place(self.title, layout.title)
    self.title.TextColor3 = onWhite and C.ink or C.paper
    local state = self.host.snapshot or {}
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
                local ready = column == 3 and status.ready
                    or (status.levels[column] or 0) >= Catalog.MaxLevel
                local text = column == 3 and "EVOLVED"
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
                row.statuses[column].TextColor3 = ready and (onWhite and C.positive or C.gold)
                    or (onWhite and C.ink or C.paper)
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
                border.Color = column == 3 and C.gold or (ready and C.mint or C.edge)
                if column < 3 then
                    place(row.symbols[column], geometry.symbols[column])
                    row.symbols[column].TextColor3 = onWhite and C.ink or C.paper
                    row.symbols[column].TextSize = math.max(13, geometry.font + 8)
                end
                self.host:_mount(row.viewports[column], row.ids[column], Catalog.MaxLevel)
            end
        end
    end
end

return Display
