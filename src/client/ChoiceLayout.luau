--!strict

local Layout = {}
local function rect(x, y, w, h)
    return { x = x, y = y, w = w, h = h }
end

function Layout.compute(width, height, count)
    local columns = (width >= 620 or (width >= 400 and height < 300)) and 2 or 1
    local rows = math.max(1, math.ceil(count / columns))
    local gap, pad = 12, 4
    local cw = (width - pad * 2 - gap * (columns - 1)) / columns
    local ch = (height - pad * 2 - gap * (rows - 1)) / rows
    local result = {}
    for index = 1, count do
        result[index] = rect(
            pad + ((index - 1) % columns) * (cw + gap),
            pad + math.floor((index - 1) / columns) * (ch + gap),
            cw,
            ch
        )
    end
    return result
end

function Layout.card(width, height, perk)
    local stacked, tight = height >= 360, height < 178
    local buttonH = stacked and 48 or 44
    local buttonY = height - buttonH - (tight and 5 or 10)
    local result = {
        choose = rect(tight and 6 or 12, buttonY, width - (tight and 12 or 24), buttonH),
        stacked = stacked,
        tight = tight,
        nameFont = stacked and 33 or (tight and 19 or 27),
        triggerFont = tight and 16 or 22,
        effectFont = tight and 15 or 22,
    }
    if stacked then
        local model = height - 236
        result.model = rect(12, 4, width - 24, model)
        result.name = rect(12, model + 8, width - 24, 44)
        result.trigger = rect(14, model + 56, width - 28, perk and 38 or 0)
        local y = model + (perk and 98 or 56)
        result.effect = rect(14, y, width - 28, buttonY - y - 8)
    else
        local model = tight and math.min(96, buttonY - 14, width * 0.27)
            or math.min(128, height - 62, width * 0.31)
        local textX = model + (tight and 14 or 18)
        local textW = width - textX - 8
        result.model = rect(tight and 5 or 8, tight and 7 or 8, model, model)
        result.name = rect(textX, 2, textW, tight and 20 or 40)
        result.trigger = rect(textX, tight and 22 or 46, textW, perk and (tight and 16 or 38) or 0)
        local y = perk and (tight and 40 or 88) or (tight and 26 or 50)
        result.effect = rect(textX, y, textW, buttonY - y - (tight and 3 or 6))
    end
    return result
end

function Layout.result(width, height)
    local model = math.min(220, height - 12, width * 0.28)
    local x, textW = model + 24, width - model - 36
    local roundH = math.min(58, height * 0.28)
    local recordsH = math.min(84, height * 0.34)
    return {
        model = rect(6, (height - model) / 2, model, model),
        round = rect(x, 4, textW, roundH),
        records = rect(x, roundH + 10, textW, recordsH),
        unlocks = rect(x, roundH + recordsH + 16, textW, height - roundH - recordsH - 20),
    }
end

return Layout
