--!strict

local Progress = {}

function Progress.compute(score, quota, maxRestocks, layerCount)
    score = if type(score) == "number" and score == score then math.max(0, score) else 0
    quota = if type(quota) == "number"
            and quota == quota
            and quota > 0
            and quota < math.huge
        then math.max(1, quota)
        else 1
    local limit = if type(maxRestocks) == "number" and maxRestocks == maxRestocks
        then math.clamp(math.floor(maxRestocks), 1, 1000000)
        else 10000
    local layers = if type(layerCount) == "number" and layerCount == layerCount
        then math.clamp(math.floor(layerCount), 1, 64)
        else 5
    local ratio = score / quota
    -- Score can legitimately exceed integer precision by hundreds of orders of
    -- magnitude. Bound it before integer conversion or palette modulo.
    local capped = ratio >= limit
    local completed = if capped then limit else math.floor(ratio)
    -- Subtract only bounded quota counts. Large-value floating modulo can return
    -- negative remainders; the fractional ratio stays in a safe, small range.
    local fraction = if capped then 1 else math.clamp(ratio - completed, 0, 1)
    return {
        completed = completed,
        capped = capped,
        fraction = fraction,
        remainder = if capped then 0 else fraction * quota,
        previousLayer = if completed > 0 then ((completed - 1) % layers) + 1 else 0,
        nextLayer = (completed % layers) + 1,
    }
end

return Progress
