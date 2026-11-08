--!strict

local Layout = {}

function Layout.compute(width: number, height: number)
    local w, h = math.max(280, width), math.max(240, height)
    local margin = if w < 600 then 10 else 20
    local panelW = math.min(1040, w - margin * 2)
    local panelH = math.min(660, h - margin * 2)
    local columns = if panelW < 620 then 2 else 3
    local rows = if panelH < 400 then 1 else 2
    local bodyW, bodyH = panelW - 32, panelH - 138
    local gap = 12
    local cellW = (bodyW - gap * (columns - 1)) / columns
    local cellH = (bodyH - gap * (rows - 1)) / rows
    local cells = {}
    for index = 1, columns * rows do
        local column, row = (index - 1) % columns, math.floor((index - 1) / columns)
        table.insert(cells, {
            x = column * (cellW + gap),
            y = row * (cellH + gap),
            w = cellW,
            h = cellH,
        })
    end
    return {
        panel = { x = (w - panelW) / 2, y = (h - panelH) / 2, w = panelW, h = panelH },
        body = { x = 16, y = 78, w = bodyW, h = bodyH },
        cells = cells,
        pageSize = #cells,
        compact = panelH < 400,
        narrow = panelW < 620,
        margin = margin,
        dockWidth = math.min(680, w - margin * 2),
    }
end

return Layout
