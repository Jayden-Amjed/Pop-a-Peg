--!strict

local Layout = {}
local function rect(x, y, w, h)
    return { x = x, y = y, w = w, h = h }
end

function Layout.compute(width, height, supplies)
    supplies = math.clamp(supplies, 0, 2)
    local portrait, short = width < 650, height < 300
    local gap, margin = short and 6 or 8, short and 8 or 10
    local footerH, titleH = short and 36 or 52, short and 0 or 40
    local footerY = height - margin - footerH
    local bodyTop = short and 0 or titleH + gap
    local bodyBottom = footerY - gap
    local bodyH, innerW = bodyBottom - bodyTop, width - margin * 2
    local headerH, pad, groupGap = short and 20 or 24, short and 4 or 6, short and 10 or 12
    local result = {
        title = rect(margin, 0, innerW, titleH),
        footer = rect(margin, footerY, innerW, footerH),
        cards = {},
        sections = {},
        groups = {},
    }
    local function group(name, x, y, w, h, first, count, columns)
        result.groups[name] = rect(x, y, w, h)
        result.sections[name] = rect(x + pad, y + 1, w - pad * 2, headerH - 1)
        local rows = math.ceil(count / columns)
        local cw = (w - pad * 2 - gap * (columns - 1)) / columns
        local ch = (h - headerH - pad * 2 - gap * (rows - 1)) / rows
        for offset = 0, count - 1 do
            result.cards[first + offset] = rect(
                x + pad + (offset % columns) * (cw + gap),
                y + headerH + pad + math.floor(offset / columns) * (ch + gap),
                cw,
                ch
            )
        end
    end
    if portrait then
        if supplies > 0 then
            local ch = (bodyH - 2 * (headerH + pad * 2) - gap - groupGap) / 3
            local itemH = headerH + pad * 2 + ch * 2 + gap
            group("items", margin, bodyTop, innerW, itemH, 1, 4, 2)
            group(
                "supplies",
                margin,
                bodyTop + itemH + groupGap,
                innerW,
                bodyH - itemH - groupGap,
                5,
                supplies,
                2
            )
            result.divider = rect(margin, bodyTop + itemH + groupGap / 2 - 1, innerW, 2)
        else
            group("items", margin, bodyTop, innerW, bodyH, 1, 4, 2)
        end
    else
        local itemW = supplies > 0 and (innerW - groupGap) * 4 / (4 + supplies) or innerW
        group("items", margin, bodyTop, itemW, bodyH, 1, 4, 4)
        if supplies > 0 then
            group(
                "supplies",
                margin + itemW + groupGap,
                bodyTop,
                innerW - itemW - groupGap,
                bodyH,
                5,
                supplies,
                supplies
            )
            result.divider = rect(margin + itemW + groupGap / 2 - 1, bodyTop + 2, 2, bodyH - 4)
        end
    end
    return result
end

function Layout.card(width, height, consumable, evolutionCount)
    local short = height < 210
    local purchaseH = short and 36 or (height < 200 and 44 or 56)
    local holdH = short and 18 or 25
    local footH = consumable and 0 or holdH
    local purchaseY = height - purchaseH - footH - (short and 6 or 12)
    local count = math.clamp(evolutionCount or 0, 0, 2)
    -- Short cards use two small horizontal equations; taller cards can show
    -- larger boxes without shrinking the primary model or purchase control.
    local titleH = short and 13 or 20
    local preferredH = titleH + count * (short and 35 or 81)
    local recipeH = count > 0 and math.min(preferredH, math.max(0, purchaseY - 37)) or 0
    local recipeY = purchaseY - recipeH - (count > 0 and 5 or 0)
    return {
        inspect = rect(3, 2, width - 6, recipeY - 5),
        evolutions = rect(5, recipeY, width - 10, recipeH),
        purchase = rect(5, purchaseY, width - 10, purchaseH),
        hold = rect(5, height - footH - 2, width - 10, footH),
        short = short,
    }
end

function Layout.equations(width, height, count)
    count = math.clamp(count, 0, 2)
    local compact = height < 20 + count * 64
    local titleH = compact and 13 or 20
    local result = { title = rect(0, 0, width, count > 0 and titleH or 0), rows = {} }
    if count == 0 then
        return result
    end
    local rowH = (height - titleH) / count
    local statusH = compact and math.min(12, rowH - 11) or 17
    local symbolW = compact and 12 or 16
    local boxSize =
        math.floor(math.max(8, math.min(62, rowH - statusH - 3, (width - symbolW * 2 - 8) / 3)))
    local columnW = (width - symbolW * 2) / 3
    for index = 1, count do
        local y = titleH + (index - 1) * rowH
        local row = {
            boxes = {},
            statuses = {},
            symbols = {},
            font = compact and math.min(10, statusH) or 13,
            compact = compact,
        }
        for column = 1, 3 do
            local columnX = (column - 1) * (columnW + symbolW)
            local x = columnX + (columnW - boxSize) / 2
            row.statuses[column] = rect(columnX, y, columnW, statusH)
            row.boxes[column] = rect(x, y + statusH, boxSize, boxSize)
            if column < 3 then
                row.symbols[column] = rect(columnX + columnW, y + statusH, symbolW, boxSize)
            end
        end
        table.insert(result.rows, row)
    end
    return result
end

return Layout
