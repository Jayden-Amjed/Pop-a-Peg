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
    local stacked, tight = height >= 320, height < 178
    local pad = tight and 3 or 10
    local buttonH = stacked and 48 or 44
    local buttonY = height - buttonH - pad
    local nameH = stacked and 40 or (height < 135 and 18 or (tight and 24 or 34))
    local modelY = pad + nameH + (tight and 3 or 8)
    local result = {
        choose = rect(pad, buttonY, width - pad * 2, buttonH),
        name = rect(pad, pad, width - pad * 2, nameH),
        stacked = stacked,
        tight = tight,
        nameFont = stacked and 31 or (tight and 19 or 25),
        triggerFont = tight and 15 or 21,
        effectFont = tight and 15 or 21,
    }
    if stacked then
        local modelH = height - (perk and 246 or 204)
        result.model = rect(pad, modelY, width - pad * 2, modelH)
        local y = modelY + modelH + 8
        result.trigger = rect(pad, y, width - pad * 2, perk and 34 or 0)
        y += perk and 42 or 0
        result.effect = rect(pad, y, width - pad * 2, buttonY - y - 8)
    else
        local contentH = buttonY - modelY - (tight and 3 or 8)
        local modelW = math.min(136, width * 0.34)
        local textX = pad + modelW + (tight and 4 or 8)
        local textW = width - textX - pad
        result.model = rect(pad, modelY, modelW, contentH)
        local triggerH = perk and math.min(tight and 24 or 36, math.max(14, contentH * 0.34)) or 0
        result.trigger = rect(textX, modelY, textW, triggerH)
        local effectY = modelY + (perk and triggerH + (tight and 3 or 6) or 0)
        result.effect = rect(textX, effectY, textW, modelY + contentH - effectY)
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
