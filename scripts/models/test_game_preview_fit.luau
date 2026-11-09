local Fit = require("../../src/client/GamePreviewFit")
local function corners(x, y, z)
    local points = {}
    for _, a in { -1, 1 } do
        for _, b in { -1, 1 } do
            for _, c in { -1, 1 } do
                table.insert(points, { a * x, b * y, c * z })
            end
        end
    end
    return points
end
local comparisons, checked = {}, 0
for _, dimensions in
    { { 2, 0.5, 0.4 }, { 0.5, 2, 0.4 }, { 1, 1, 1 }, { 0.2, 0.3, 2 }, { 3, 2, 0.1 } }
do
    local points = corners(table.unpack(dimensions))
    local padding, margin = { 0.05, 0.06, 0.04 }, 0.03
    local framing = Fit.new(points, padding)
    for _, aspect in { 0.2, 0.5, 0.8, 1, 175 / 150, 1.5, 2, 4, 8 } do
        local distance = framing:distance(aspect, 30, margin)
        assert(
            distance == framing:distance(aspect, 30, margin),
            "Camera changes between identical frames"
        )
        local vertical = math.tan(math.rad(15))
        for _, point in points do
            for _, x in { -1, 1 } do
                for _, y in { -1, 1 } do
                    for _, z in { -1, 1 } do
                        local px = point[1] - framing.center[1] + x * padding[1]
                        local py = point[2] - framing.center[2] + y * padding[2]
                        local depth = distance - (point[3] - framing.center[3] + z * padding[3])
                        assert(depth > 0, "A padded corner passed through the camera")
                        assert(
                            math.abs(px) / (depth * vertical * aspect) <= 1 - 2 * margin,
                            "Horizontal corner clipped"
                        )
                        assert(
                            math.abs(py) / (depth * vertical) <= 1 - 2 * margin,
                            "Vertical corner clipped"
                        )
                        checked += 1
                    end
                end
            end
        end
        if aspect == 175 / 150 then
            local x, y, z = table.unpack(dimensions)
            local radius = math.sqrt(x * x + y * y + z * z)
            local limiting = math.min(math.rad(15), math.atan(math.tan(math.rad(15)) * aspect))
            table.insert(comparisons, radius * 1.13 / math.sin(limiting) / distance)
        end
    end
end
assert(
    comparisons[1] > 1.2 and comparisons[2] > 1.05,
    "Elongated model framing did not improve meaningfully"
)
local fixture = Fit.new(corners(1, 1, 1))
assert(
    fixture:distance(0 / 0, 30) == fixture:distance(1, 30),
    "Invalid viewport ratio poisoned fit"
)
print(
    string.format(
        "PASS fixed camera fit: %d padded corners across 9 aspects; elongated rack envelopes gain %.1f%%/%.1f%% linear size versus sphere",
        checked,
        (comparisons[1] - 1) * 100,
        (comparisons[2] - 1) * 100
    )
)
