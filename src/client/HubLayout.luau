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
    local dockW = math.min(700, w - margin * 2)
    local stackedDock = w < 600
    local dockH = if stackedDock then 128 else 76
    local dock = { x = (w - dockW) / 2, y = h - dockH - margin, w = dockW, h = dockH }
    local controls = {}
    if stackedDock then
        controls.play = { x = 8, y = 8, w = dockW - 16, h = 44 }
        local secondaryW = (dockW - 32) / 3
        for index, name in { "collection", "records", "help" } do
            controls[name] =
                { x = 8 + (index - 1) * (secondaryW + 8), y = 60, w = secondaryW, h = 44 }
        end
    else
        local secondaryW = (dockW - 40) * 0.215
        local playW = dockW - 40 - secondaryW * 3
        controls.collection = { x = 8, y = 8, w = secondaryW, h = 42 }
        controls.play = { x = 16 + secondaryW, y = 8, w = playW, h = 42 }
        controls.records = { x = 24 + secondaryW + playW, y = 8, w = secondaryW, h = 42 }
        controls.help = { x = 32 + secondaryW * 2 + playW, y = 8, w = secondaryW, h = 42 }
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
