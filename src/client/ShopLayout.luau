--!strict

local Layout = {}
local function rect(x, y, w, h)
    return { x = x, y = y, w = w, h = h }
end

-- All offers remain visible; descriptions share one inspection area.
function Layout.compute(width, height, supplies)
    supplies = math.clamp(supplies, 0, 2)
    local portrait = width < 650
    local gap, margin = height < 300 and 6 or 8, height < 300 and 8 or 10
    local footerH = height < 300 and 32 or 44
    local titleH = height < 300 and 24 or 34
    local detailH = height < 300 and 54 or (portrait and 152 or 88)
    local footerY = height - margin - footerH
    local detailY = footerY - gap - detailH
    local sectionH = height < 300 and 18 or 23
    local cardsTop = titleH + (supplies > 0 and sectionH or 7)
    local bodyBottom = detailY - gap
    local result = {
        title = rect(margin, 0, width - margin * 2, titleH),
        detail = rect(margin, detailY, width - margin * 2, detailH),
        footer = rect(margin, footerY, width - margin * 2, footerH),
        cards = {},
        sections = {},
    }
    if portrait then
        local rows = supplies > 0 and 3 or 2
        local sectionGap = supplies > 0 and 23 or 0
        local cardH = (bodyBottom - cardsTop - gap * (rows - 1) - sectionGap) / rows
        local cardW = (width - margin * 2 - gap) / 2
        if supplies > 0 then
            result.sections.items = rect(margin, titleH, width - margin * 2, 21)
            result.sections.supplies =
                rect(margin, cardsTop + (cardH + gap) * 2, width - margin * 2, 21)
        end
        for index = 1, 4 + supplies do
            local row = math.floor((index - 1) / 2)
            result.cards[index] = rect(
                margin + ((index - 1) % 2) * (cardW + gap),
                cardsTop + row * (cardH + gap) + (index > 4 and sectionGap or 0),
                cardW,
                cardH
            )
        end
    else
        local count = 4 + supplies
        local cardW = (width - margin * 2 - gap * (count - 1)) / count
        for index = 1, count do
            result.cards[index] =
                rect(margin + (index - 1) * (cardW + gap), cardsTop, cardW, bodyBottom - cardsTop)
        end
        if supplies > 0 then
            result.sections.items = rect(margin, titleH, 4 * cardW + 3 * gap, sectionH)
            result.sections.supplies =
                rect(margin + 4 * (cardW + gap), titleH, 2 * cardW + gap, sectionH)
        end
    end
    return result
end

return Layout
