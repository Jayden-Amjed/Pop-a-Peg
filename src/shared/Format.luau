local Format = {}

local SUFFIXES = { "", "K", "M", "B", "T", "Qa", "Qi" }

local function special(value)
    if type(value) ~= "number" or value ~= value then
        return "—"
    elseif value == math.huge then
        return "∞"
    elseif value == -math.huge then
        return "−∞"
    end
    return nil
end

local function decimal(value, places)
    local result = string.format("%." .. places .. "f", value)
    if places > 0 then
        result = result:gsub("0+$", ""):gsub("%.$", "")
    end
    return result
end

function Format.number(value)
    local replacement = special(value)
    if replacement then
        return replacement
    end
    local sign = if value < 0 then "−" else ""
    local magnitude = math.abs(value)
    if magnitude < 1000 then
        return sign
            .. decimal(magnitude, if magnitude < 10 then 2 elseif magnitude < 100 then 1 else 0)
    end
    local tier = math.floor(math.log10(magnitude) / 3)
    if tier >= #SUFFIXES then
        return string.format("%.2e", value):gsub("e%+0*", "e"):gsub("e%-0*", "e-")
    end
    local scaled = magnitude / 1000 ^ tier
    local places = if scaled < 10 then 2 elseif scaled < 100 then 1 else 0
    local text = decimal(scaled, places)
    if tonumber(text) >= 1000 then
        tier += 1
        if tier >= #SUFFIXES then
            return string.format("%.2e", value):gsub("e%+0*", "e")
        end
        text = "1"
    end
    return sign .. text .. SUFFIXES[tier + 1]
end

function Format.integer(value)
    local replacement = special(value)
    if replacement then
        return replacement
    end
    if math.abs(value) >= 1e15 then
        return Format.number(value)
    end
    local digits = string.format("%.0f", math.floor(math.abs(value) + 0.5))
    digits = digits:reverse():gsub("(%d%d%d)", "%1,"):reverse():gsub("^,", "")
    return (if value < 0 then "−" else "") .. digits
end

return Format
