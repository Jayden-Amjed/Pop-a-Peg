-- Successive restocks cost twice as much. All consumers use this same curve.
local RestockCurve = {}
RestockCurve.Max = 12

function RestockCurve.limit(round)
    if round <= 15 then
        return 6
    elseif round <= 40 then
        return 8
    elseif round <= 65 then
        return 10
    end
    return RestockCurve.Max
end

function RestockCurve.compute(score, quota, limit)
    score = if type(score) == "number" and score == score then math.max(0, score) else 0
    quota = if type(quota) == "number"
            and quota == quota
            and quota > 0
            and quota < math.huge
        then math.max(1, quota)
        else 1
    limit = if type(limit) == "number" and limit == limit
        then math.clamp(math.floor(limit), 1, RestockCurve.Max)
        else RestockCurve.Max
    local ratio = score / quota
    local completed, previous, cost = 0, 0, 1
    while completed < limit and ratio >= previous + cost do
        completed += 1
        previous += cost
        cost *= 2
    end
    local capped = completed == limit
    local fraction = if capped then 1 else math.clamp((ratio - previous) / cost, 0, 1)
    return {
        completed = completed,
        capped = capped,
        fraction = fraction,
        remainder = if capped then 0 else fraction * quota * cost,
        nextQuota = quota * cost,
        threshold = quota * (previous + cost),
    }
end

return RestockCurve
