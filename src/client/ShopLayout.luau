--!strict
-- Shop coordinates are relative to the core-safe root.
local Layout = {}
local function rect(x, y, w, h)
    return { x = x, y = y, w = w, h = h }
end
function Layout.window(w, h)
    local width = math.min(1520, w - 24)
    local height = math.min(880, h - 56)
    return rect((w - width) / 2, math.max(44, (h - height) / 2), width, height)
end
function Layout.compute(width, height, supplies)
    supplies = math.clamp(supplies, 0, 2)
    local compact = height < 500
    local pad, gap = compact and 5 or 20, compact and 3 or 14
    local headerH, footerH = compact and 28 or 72, compact and 44 or 64
    local footerY = height - pad - footerH
    local top = pad + headerH + gap
    local bodyH = footerY - gap - top
    local sideW = width >= 1240 and height >= 640 and 260 or 0
    local contentW = width - pad * 2 - (sideW > 0 and sideW + gap or 0)
    local supplyH = supplies > 0 and (compact and math.min(86, bodyH - 82) or 112) or 0
    local itemH = bodyH - (supplies > 0 and supplyH + gap or 0)
    local result = {
        compact = compact,
        title = rect(pad, pad, width - pad * 2, headerH),
        footer = rect(pad, footerY, width - pad * 2, footerH),
        groups = { items = rect(pad, top, contentW, itemH) },
        sections = {},
        cards = {},
    }
    local columns = width < 600 and height > 450 and 2 or 4
    local rows = 4 / columns
    local cw, ch = (contentW - gap * (columns - 1)) / columns, (itemH - gap * (rows - 1)) / rows
    for index = 1, 4 do
        result.cards[index] = rect(
            pad + ((index - 1) % columns) * (cw + gap),
            top + math.floor((index - 1) / columns) * (ch + gap),
            cw,
            ch
        )
    end
    if supplies > 0 then
        local y = top + itemH + gap
        result.groups.supplies = rect(pad, y, contentW, supplyH)
        local labelW = (compact or contentW < 600) and 0 or 128
        result.sections.supplies = rect(pad + 8, y, labelW, supplyH)
        local sw = (contentW - labelW - gap * (supplies + 1)) / supplies
        for index = 1, supplies do
            result.cards[4 + index] =
                rect(pad + labelW + gap + (index - 1) * (sw + gap), y + 4, sw, supplyH - 8)
        end
    end
    if sideW > 0 then
        result.sidebar = rect(pad + contentW + gap, top, sideW, bodyH)
    end
    return result
end
function Layout.card(width, height, consumable)
    local small = height < 230
    if consumable then
        if height < 70 then
            local side = height - 6
            local x = side + 8
            local buyW = math.max(64, width * 0.29)
            local textW = width - x - buyW - 10
            return {
                inspect = rect(3, 3, side, side),
                model = rect(0, 0, side, side),
                name = rect(x, 3, textW, 18),
                level = rect(0, 0, 0, 0),
                price = rect(x, 24, textW, height - 27),
                purchase = rect(width - buyW - 3, (height - 44) / 2, buyW, 44),
                nameOnCard = true,
                short = true,
            }
        end
        local pad = 5
        local side = math.min(height - pad * 2, width * 0.3)
        local rightX = side + pad * 2
        local rightW = width - rightX - pad
        local buyW = math.max(64, rightW * 0.48)
        local actionY = height - pad - 44
        return {
            inspect = rect(pad, pad, side, height - pad * 2),
            model = rect(0, 0, side, height - pad * 2),
            name = rect(rightX, pad, rightW, actionY - pad - 4),
            level = rect(0, 0, 0, 0),
            price = rect(rightX, actionY, rightW - buyW - 5, 44),
            purchase = rect(width - pad - buyW, actionY, buyW, 44),
            nameOnCard = true,
            short = true,
        }
    end
    if height < 145 then
        local inspectH = height - 52
        local modelW = math.min(width * 0.48, inspectH * 1.3)
        local holdW = math.max(44, width * 0.32)
        return {
            inspect = rect(3, 3, width - 6, inspectH),
            model = rect(0, 0, modelW, inspectH),
            name = rect(modelW + 2, 0, width - modelW - 10, inspectH - 13),
            level = rect(modelW + 2, inspectH - 13, width - modelW - 10, 13),
            price = rect(3, inspectH + 3, width - 6, 0),
            purchase = rect(3, height - 47, width - holdW - 12, 44),
            hold = rect(width - holdW - 3, height - 47, holdW, 44),
            short = true,
        }
    end
    local inset, buttonH = small and 5 or 10, small and 44 or 52
    local titleH, priceH = small and 20 or 42, small and 0 or 32
    local actionY = height - inset - buttonH
    local priceY = actionY - priceH - 4
    local holdW = math.max(44, (width - inset * 2 - 6) * 0.34)
    local inspectH = priceY - 5
    return {
        inspect = rect(inset, inset, width - inset * 2, inspectH - inset),
        name = rect(3, 0, width - inset * 2 - 6, titleH),
        model = rect(0, titleH, width - inset * 2, math.max(12, inspectH - inset - titleH)),
        level = rect(4, titleH + 2, width - inset * 2 - 8, small and 16 or 22),
        price = rect(inset, priceY, width - inset * 2, priceH),
        purchase = rect(inset, actionY, width - inset * 2 - holdW - 6, buttonH),
        hold = rect(width - inset - holdW, actionY, holdW, buttonH),
        short = small,
    }
end

function Layout.compactCost(width, height, digits)
    local captionH = 18
    local priceH = height - captionH - 4
    local icon = math.min(22, priceH)
    local numberW = math.min(width - icon - 10, math.max(16, digits * 12))
    local x = (width - numberW - icon) / 2
    return {
        caption = rect(3, 1, width - 6, captionH),
        price = rect(x, captionH + 2, numberW, priceH),
        coin = rect(x + numberW, captionH + 2, icon, icon),
    }
end

function Layout.equations(width, height, count, showTitle)
    count = math.max(0, count)
    local compact = height < 20 + count * 64
    local titleH = showTitle == false and 0 or (compact and 13 or 20)
    local result = { title = rect(0, 0, width, count > 0 and titleH or 0), rows = {} }
    if count == 0 then
        return result
    end
    local rowH = (height - titleH) / count
    local statusH = compact and math.min(12, rowH - 11) or 17
    local symbolW = compact and 12 or 16
    local boxSize =
        math.floor(math.max(8, math.min(76, rowH - statusH - 3, (width - symbolW * 2 - 8) / 3)))
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
