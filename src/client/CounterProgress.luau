--!strict
local RestockCurve = if script
    then require(game:GetService("ReplicatedStorage").Shared.RestockCurve)
    else require("../shared/RestockCurve")

local Progress = {}

function Progress.compute(score, quota, maxRestocks, layerCount)
    local result = RestockCurve.compute(score, quota, maxRestocks)
    local layers = if type(layerCount) == "number" and layerCount == layerCount
        then math.clamp(math.floor(layerCount), 1, 64)
        else 5
    result.previousLayer = if result.completed > 0 then ((result.completed - 1) % layers) + 1 else 0
    result.nextLayer = (result.completed % layers) + 1
    return result
end

return Progress
