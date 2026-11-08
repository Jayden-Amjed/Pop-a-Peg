--!strict

local Layout = {}

function Layout.compute(width: number, height: number)
    local w, h = math.max(280, width), math.max(240, height)
    local margin = if w < 600 then 10 else 20
    local panelW = math.min(1040, w - margin * 2)
    local panelH = math.min(660, h - margin * 2)
    local columns = if panelW < 620 then 2 else 3
    local rows = if panelH < 400 then 1 else 2
    local bodyW, bodyH = panelW - 32, panelH - 148
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
    local dockW = math.min(980, w - margin * 2)
    local stackedDock = w < 760
    local dockH = if stackedDock then 128 else 76
    local dock = { x = (w - dockW) / 2, y = h - dockH - margin, w = dockW, h = dockH }
    local controls = {}
    local dockColumns = stackedDock and 3 or 6
    local controlW = (dockW - 16 - 8 * (dockColumns - 1)) / dockColumns
    for index, name in { "play", "chests", "collection", "leaderboards", "records", "help" } do
        controls[name] = {
            x = 8 + ((index - 1) % dockColumns) * (controlW + 8),
            y = 8 + math.floor((index - 1) / dockColumns) * 52,
            w = controlW,
            h = 44,
        }
    end
    local brandW = math.min(282, (w - margin * 3) * 0.56)
    local crewW = math.min(202, w - brandW - margin * 3)
    return {
        panel = { x = (w - panelW) / 2, y = (h - panelH) / 2, w = panelW, h = panelH },
        body = { x = 16, y = 78, w = bodyW, h = bodyH },
        cells = cells,
        pageSize = #cells,
        compact = panelH < 400,
        narrow = panelW < 620,
        margin = margin,
        dock = dock,
        controls = controls,
        hint = { x = 8, y = dockH - 22, w = dockW - 16, h = 18 },
        brand = { x = margin, y = 10, w = brandW, h = 62 },
        crew = { x = w - margin - crewW, y = 10, w = crewW, h = 62 },
        notice = {
            x = math.max(margin, (w - 600) / 2),
            y = dock.y - 34,
            w = math.min(600, w - margin * 2),
            h = 26,
        },
    }
end

return Layout
