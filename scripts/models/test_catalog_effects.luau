-- Standalone contracts cover choreography data and pose-addressable descriptors.
-- StudioEffectsAudit separately checks the real pooled Roblox renderer and camera.
local Native = require("../../src/client/ItemMotion")
local Catalog = require("./CatalogInfo")
local function encode(value, geometryOnly)
    if type(value) == "number" then
        return string.format("%.8g", value)
    end
    if type(value) ~= "table" then
        return tostring(value)
    end
    local keys, chunks = {}, {}
    for key in value do
        if not geometryOnly or (key ~= "color" and key ~= "alpha") then
            table.insert(keys, key)
        end
    end
    table.sort(keys, function(a, b)
        return tostring(a) < tostring(b)
    end)
    for _, key in keys do
        table.insert(chunks, tostring(key) .. "=" .. encode(value[key], geometryOnly))
    end
    return "{" .. table.concat(chunks, ",") .. "}"
end
local nativeBefore = encode(Native.Profiles)
local nativePoses = {}
for _, item in Catalog do
    nativePoses[item.id] = encode(Native.bodySample(item.id, 0.37, 1.4))
end
local Blender = require("./BlenderChoreography")
local Effects = require("./CatalogEffectProfiles")
local names, signatures, count, totalSamples = {}, {}, 0, 0
for _, item in Catalog do
    local id = item.id
    local profile = assert(Effects.entries[id], "Missing effect: " .. id)
    assert(not names[profile.name], "Duplicate authored direction: " .. id)
    names[profile.name] = true
    count += 1
    local visible, signature = false, {}
    for _, strength in { 0, 0.25, 1, 2 } do
        for step = 0, 40 do
            local t = step / 40
            local accents = Effects.sample(id, t, strength)
            assert(#accents <= Effects.MaxParts, "Pool overflow: " .. id)
            assert(
                encode(accents) == encode(Effects.sample(id, t, strength)),
                "Pose is not deterministic: " .. id
            )
            if step == 0 or step == 40 or strength == 0 then
                assert(#accents == 0, "Effect leaks at rest: " .. id)
            end
            visible = visible or #accents > 0
            for _, accent in accents do
                assert(
                    accent.kind == "ball" or accent.kind == "line",
                    "Unsupported primitive: " .. id
                )
                assert(accent.radius > 0 and accent.radius < 0.5, "Invalid effect radius: " .. id)
                assert(accent.alpha >= 0 and accent.alpha <= 1, "Invalid effect opacity: " .. id)
                for _, q in { accent.a, accent.b, accent.color } do
                    for _, value in q do
                        assert(
                            value >= -4 and value <= 4,
                            "Unbounded/nonfinite effect coordinate: " .. id
                        )
                    end
                end
            end
            totalSamples += 1
        end
    end
    assert(visible, "Effect never appears: " .. id)
    for _, t in { 0.3, 0.5, 0.7 } do
        table.insert(signature, encode(Effects.sample(id, t, 1), true))
    end
    local shape = table.concat(signature, "|")
    assert(
        not signatures[shape],
        "Identical effect geometry across IDs: " .. id .. "/" .. tostring(signatures[shape])
    )
    signatures[shape] = id
    local pose = Effects.sample(id, 0.6, 1, { offset = { 0.1, -0.2, 0.3 } })
    Effects.sample(id, 0.2, 2)
    assert(
        encode(pose) == encode(Effects.sample(id, 0.6, 1, { offset = { 0.1, -0.2, 0.3 } })),
        "Backward scrub changed effect: " .. id
    )
    assert(
        nativePoses[id] == encode(Native.bodySample(id, 0.37, 1.4)),
        "Native body mutated: " .. id
    )
end
assert(count == 78 and #Catalog == 78, "Expected every catalog entry")
local entryCount = 0
for _ in Effects.entries do
    entryCount += 1
end
assert(entryCount == count, "Unregistered effects")
assert(nativeBefore == encode(Native.Profiles), "Native profile table mutated")
assert(Blender.Profiles ~= Native.Profiles, "Gallery aliases the native profile map")

local neutral = { x = 0, y = 0, z = 0, rx = 0, ry = 0, rz = 0, scale = 1 }
for _, id in { "relay", "lagoon_synth" } do
    for i = 0, 40 do
        assert(
            encode(Blender.bodySample(id, i / 40, 2)) == encode(neutral),
            "Fixed frame moved: " .. id
        )
    end
end
local off = Blender.sample("dew_lantern", "LanternDrop", 0, 1, 0, 1.1, 0)
local on = Blender.sample("dew_lantern", "LanternDrop", 0.5, 1, 0, 1.1, 0)
assert(off.lamp == 0 and on.lamp > 0.95 and on.scale > 1.1, "Lantern does not visibly turn on")
assert(Blender.sample("relay", "WindingX", 0.45, 1, 0, 1.04, 0).rx > math.pi, "Coil did not rotate")
local waveA, waveB =
    Effects.sample("lagoon_synth", 0.35, 1), Effects.sample("lagoon_synth", 0.55, 1)
assert(
    waveA[1].a[1] == waveB[1].a[1] and waveA[28].b[1] == waveB[28].b[1],
    "Wave display envelope moved"
)
assert(math.abs(waveA[8].a[2] - waveB[8].a[2]) > 0.005, "Wave phase did not travel")
for _, id in { "bubble_wand", "burst_capsule", "coin_press", "chest_common", "chest_legendary" } do
    assert(
        encode(Blender.bodySample(id, 0.48, 1)) == encode(Native.bodySample(id, 0.48, 1)),
        "Prior review mechanism changed: " .. id
    )
end
print(
    string.format(
        "PASS catalog effects: %d IDs, %d deterministic samples, unique geometry, 40-part bound, exact rest, native freeze, fixed mounts, light switch and travelling waveform",
        count,
        totalSamples
    )
)
