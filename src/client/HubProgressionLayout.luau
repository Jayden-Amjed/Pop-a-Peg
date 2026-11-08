-- Pure geometry for hub rewards; all actions remain reachable on small safe areas.
local Layout = {}
local function rect(x, y, w, h)
    return { x = x, y = y, w = math.max(1, w), h = math.max(1, h) }
end

function Layout.chest(w, h)
    local gap, tabs = 6, {}
    for i = 1, 4 do
        tabs[i] = rect((i - 1) * ((w - 18) / 4 + gap), 0, (w - 18) / 4, 44)
    end
    local top, contentH = 50, h - 100
    local stacked = w < 480 and contentH >= 300
    local modelW = stacked and w or math.min(w * 0.42, contentH)
    local modelH = stacked and contentH * 0.48 or contentH
    local x, y = stacked and 0 or modelW + 12, stacked and top + modelH + 8 or top
    local textW = stacked and w or w - x
    local usable = stacked and contentH - modelH - 8 or contentH
    return {
        tabs = tabs,
        model = rect(0, top, modelW, modelH),
        title = rect(x, y, textW, math.min(38, math.max(12, usable))),
        showDetail = usable >= 90,
        detail = rect(x, y + 42, textW, math.max(16, usable - 42)),
        buy = rect(0, h - 44, (w - 8) / 2, 44),
        action = rect((w + 8) / 2, h - 44, (w - 8) / 2, 44),
    }
end

function Layout.catalog(w, h)
    local columns = w < 620 and 2 or 3
    local rows = h >= 390 and 2 or 1
    local top, gap = 50, 10
    local cellW = (w - gap * (columns - 1)) / columns
    local cellH = (h - top - gap * (rows - 1)) / rows
    local cells = {}
    for i = 1, columns * rows do
        cells[i] = rect(
            ((i - 1) % columns) * (cellW + gap),
            top + math.floor((i - 1) / columns) * (cellH + gap),
            cellW,
            cellH
        )
    end
    return {
        cells = cells,
        pageSize = #cells,
        back = rect(0, 0, math.min(150, w * 0.48), 44),
        currency = rect(w * 0.5, 0, w * 0.5, 44),
    }
end

function Layout.item(w, h)
    local bottom = h - 50
    local modelW = math.min(w * 0.34, bottom)
    return {
        model = rect(0, 0, modelW, bottom),
        stats = rect(modelW + 12, 0, w - modelW - 12, bottom),
        action = rect(0, h - 44, w, 44),
    }
end

function Layout.leaders(w, h)
    local tabs = {}
    for i = 1, 3 do
        tabs[i] = rect((i - 1) * ((w - 16) / 3 + 8), 0, (w - 16) / 3, 44)
    end
    local rowH = math.max(34, math.min(54, (h - 54) / 5))
    local count = math.max(1, math.min(10, math.floor((h - 54) / rowH)))
    local rows = {}
    for i = 1, count do
        rows[i] = rect(0, 54 + (i - 1) * rowH, w, rowH - 3)
    end
    return { tabs = tabs, rows = rows, pageSize = #rows }
end

return Layout
