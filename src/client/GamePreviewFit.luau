-- Camera-space support points allow a tight fixed camera without an enclosing
-- sphere's unused corner/depth padding. Pure math; positions use camera +Z back.
local Fit = {}

function Fit.new(points, padding)
    assert(#points > 0, "Camera fit requires bounds points")
    padding = padding or { 0, 0, 0 }
    local low, high = { math.huge, math.huge, math.huge }, { -math.huge, -math.huge, -math.huge }
    for _, point in points do
        for axis = 1, 3 do
            low[axis], high[axis] =
                math.min(low[axis], point[axis]), math.max(high[axis], point[axis])
        end
    end
    local center = { (low[1] + high[1]) / 2, (low[2] + high[2]) / 2, (low[3] + high[3]) / 2 }
    local fitter = { center = center, points = points, padding = padding }
    function fitter:distance(aspect, fieldOfView, margin)
        if type(aspect) ~= "number" or aspect ~= aspect or aspect <= 0 or aspect >= math.huge then
            aspect = 1
        end
        margin = math.clamp(margin or 0.03, 0, 0.2)
        local vertical = math.tan(math.rad(fieldOfView / 2)) * (1 - margin * 2)
        local horizontal = vertical * aspect
        local result = 0.05
        for _, point in points do
            local x = math.abs(point[1] - center[1]) + padding[1]
            local y = math.abs(point[2] - center[2]) + padding[2]
            local z = point[3] - center[3] + padding[3]
            result = math.max(result, z + math.max(x / horizontal, y / vertical, 0.05))
        end
        return result + 0.001
    end
    return fitter
end

return Fit
