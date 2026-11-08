-- Pure small-screen geometry. Coordinates are relative to the core-safe root.
local Layout = {}
local function rect(x, y, w, h)
    return { x = x, y = y, w = w, h = h }
end

function Layout.safeRect(w, h, left, top, right, bottom)
    return rect(left, top, math.max(1, w - left - right), math.max(1, h - top - bottom))
end

function Layout.portrait(w, h)
    local pad, gap = 8, 6
    local width = w - pad * 2
    local unit = (width - gap * 4) / 5
    local extras = {}
    for index = 1, 5 do
        extras[index] = rect(pad + (index - 1) * (unit + gap), h - 50, unit, 44)
    end
    return {
        round = rect(pad, 0, width - 98, 44),
        navigation = rect(w - pad - 92, 0, 92, 44),
        rack = rect(pad, 48, width, 54),
        resources = rect(pad, 106, width, 30),
        score = rect(pad, 140, width, 58),
        board = rect(pad, 204, width, math.max(1, h - 308)),
        controls = rect(pad, h - 100, width, 44),
        extras = extras,
        details = rect(pad, 52, width, math.min(330, h - 160)),
        shop = rect(pad, 50, width, h - 56),
        rackOverlay = rect(pad, 50, width, 122),
    }
end

function Layout.landscape(w, h)
    local x = math.floor(w * 0.43)
    local right = Layout.portrait(w - x, h)
    for _, key in { "navigation", "rack", "resources", "score", "controls" } do
        right[key].x += x
    end
    for _, area in right.extras do
        area.x += x
    end
    right.round = rect(8, 0, x - 16, 34)
    right.board = rect(8, 42, x - 16, h - 50)
    right.details = rect(8, 48, w - 16, h - 104)
    right.shop = rect(8, 50, w - 16, h - 56)
    right.rackOverlay = rect(8, 50, w - 16, 122)
    return right
end

return Layout
