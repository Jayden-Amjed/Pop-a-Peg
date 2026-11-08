-- ViewportFrame has directional shading, not world cast shadows. Keep one shared
-- rig so the inspection lab and the game's item cards show comparable materials.
local PreviewLighting = {}

PreviewLighting.presets = table.freeze({
    Balanced = table.freeze({
        ambient = Color3.fromRGB(105, 132, 151),
        light = Color3.fromRGB(231, 241, 246),
        direction = Vector3.new(-0.8, -0.7, -0.5),
        background = Color3.fromRGB(177, 208, 220),
    }),
    Original = table.freeze({
        ambient = Color3.fromRGB(185, 214, 232),
        light = Color3.fromRGB(255, 252, 244),
        direction = Vector3.new(-0.7, -1, -0.6),
        background = Color3.fromRGB(211, 235, 240),
    }),
})

function PreviewLighting.apply(viewport, presetName)
    local preset = PreviewLighting.presets[presetName or "Balanced"]
        or PreviewLighting.presets.Balanced
    viewport.Ambient = preset.ambient
    viewport.LightColor = preset.light
    viewport.LightDirection = preset.direction
    return preset
end

return PreviewLighting
