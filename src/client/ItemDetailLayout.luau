-- Measured detail rows may scroll, but no content is omitted or shrunk to illegibility.
local Layout = {}
local function rect(x, y, w, h)
    return { x = x, y = y, w = w, h = h }
end

function Layout.columns(width, height)
    local wide = width >= 520
    local modelW = wide and math.min(330, width * 0.34) or width
    local modelH = wide and math.max(96, math.min(height - 72, 340))
        or math.max(104, math.min(210, width * 0.7, height * 0.31))
    return {
        wide = wide,
        model = rect(0, 0, modelW, modelH),
        name = rect(0, modelH + 8, modelW, 54),
        detailsX = wide and modelW + 12 or 0,
        detailsY = wide and 0 or modelH + 70,
        detailsW = wide and width - modelW - 12 or width,
    }
end

function Layout.compute(width, height, rowHeights, recipes)
    local result = Layout.columns(width, height)
    local x, y, w = result.detailsX, result.detailsY, result.detailsW
    result.effects = {}
    for _, lineHeight in rowHeights do
        table.insert(result.effects, rect(x, y, w, lineHeight + 12))
        y += lineHeight + 20
    end
    local recipeH = recipes > 0 and (recipes * 104 + 12) or 0
    result.recipes = rect(x, y, w, recipeH)
    result.contentHeight = math.max(result.name.y + result.name.h, y + recipeH)
    return result
end

return Layout
