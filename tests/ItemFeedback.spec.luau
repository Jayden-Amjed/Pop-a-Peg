local Shared = if script then game:GetService("ReplicatedStorage").Shared else nil
local Catalog = if Shared then require(Shared.Catalog) else require("../src/shared/Catalog")
local Feedback = if Shared
    then require(Shared.ItemFeedback)
    else require("../src/shared/ItemFeedback")

return function()
    local signatures, count = {}, 0
    for _, category in ipairs({ Catalog.Items, Catalog.Perks }) do
        for id in pairs(category) do
            assert(Feedback.Profiles[id], "Missing item feedback: " .. id)
        end
    end
    local evolvedCount = 0
    local weights = { light = 0, rounded = 0, heavy = 0 }
    for id, profile in pairs(Feedback.Profiles) do
        assert(#profile.notes >= 2 and #profile.notes <= 4, "Unbounded sound motif")
        assert(#profile.notes == #profile.rhythm, "Missing note timing")
        assert(profile.duration > 0 and profile.duration <= 0.2, "Long tone tail")
        local signature = {}
        for index, note in ipairs(profile.notes) do
            assert(note >= -12 and note <= 24, "Tone outside soft register")
            assert(
                profile.rhythm[index] >= 0 and profile.rhythm[index] <= 0.25,
                "Note outside motif window"
            )
            table.insert(signature, note .. ":" .. profile.rhythm[index])
        end
        local key = table.concat(signature, "/")
        assert(not signatures[key], "Duplicate sound signatures: " .. id)
        signatures[key] = id
        weights[profile.weight] += 1
        local notes = Feedback.sound(id)
        assert(#notes <= 5, "Heavy impact escaped motif note budget")
        local hasBass = false
        for _, note in notes do
            assert(note.wait + note.duration <= 0.4, "Item audio outlived its short visual impact")
            local firstGain = Feedback.soundSample(note, 0)
            local finalGain = Feedback.soundSample(note, note.duration)
            assert(firstGain == 0 and finalGain == 0, "Hard attack/release can click")
            local previousPitch = note.pitch
            for frame = 0, 100 do
                local gain, pitch = Feedback.soundSample(note, frame / 100 * note.duration)
                assert(gain >= 0 and gain <= 0.13, "Individual note escaped the quiet mix")
                assert(
                    pitch >= 0.25 - 1e-9 and pitch <= 4 + 1e-9,
                    "Tone escaped 65Hz–1046Hz register: " .. id
                )
                if note.endPitch then
                    assert(pitch <= previousPitch + 1e-9, "Heavy impact pitch bounced upward")
                    previousPitch = pitch
                end
            end
            if note.endPitch then
                hasBass = true
                local _, settledPitch = Feedback.soundSample(note, note.slide)
                assert(
                    math.abs(settledPitch - note.endPitch) < 1e-9,
                    "Bass did not land on its root"
                )
                assert(note.endPitch * 261.63 < 100, "Heavy body has no low fundamental")
            end
        end
        assert(
            hasBass == (profile.weight == "heavy"),
            "Light and heavy timbres lost their contrast"
        )
        assert(type(profile.style) == "string" and #profile.style > 0, "Missing visual style")
        assert(#profile.color == 3, "Missing accent color")
        local normal = Feedback.burst(id, false, false)
        local impact = Feedback.burst(id, false, true)
        local reduced = Feedback.burst(id, true, false)
        assert(
            normal.count >= 12 and normal.count <= Feedback.Limits.burst,
            "Burst escaped particle budget"
        )
        assert(
            impact.count <= 8 and impact.reach < normal.reach,
            "Impacts overwhelmed activation bursts"
        )
        assert(
            reduced.count <= 3 and reduced.reach <= 18 and reduced.spin == 0 and not reduced.orbit,
            "Reduced motion retained orbit or large particle burst"
        )
        assert(normal.duration <= 0.7 and impact.duration <= 0.5, "Unbounded burst lifetime")
        assert(normal.reach <= 115 and math.abs(normal.spin) <= 3.5, "Unbounded burst motion")
        if profile.evolved then
            evolvedCount += 1
            assert(
                normal.count == 18 and #profile.notes == 4,
                "Evolution lacks its fuller signature"
            )
        end
        count += 1
    end
    assert(evolvedCount == 13, "Expected thirteen evolution feedback signatures")
    assert(
        weights.light >= 25 and weights.rounded >= 10 and weights.heavy >= 10,
        "Sound weights lost their variety"
    )
    for _, id in
        { "burst_capsule", "spring_coil", "moss_capacitor", "monsoon_loom", "bubble_reactor" }
    do
        assert(Feedback.Profiles[id].weight == "heavy", "Missing old/new/evolved low impact")
    end
    for _, id in { "resonator", "goldfish", "bubble_wand", "spectrum_reef" } do
        assert(Feedback.Profiles[id].weight == "light", "Bright glass/water item became too heavy")
    end
    for volume = 0, 12 do
        local total = volume * 0.13
        assert(
            total * Feedback.mixGain(total) <= Feedback.AudioLimits.mixVolume + 1e-9,
            "Dense chain exceeds item headroom"
        )
    end
    assert(Feedback.mixGain(0.1) == 1, "Sparse item cues are unnecessarily ducked")
    assert(Feedback.sound("unknown") == nil, "Unknown item produced sound")
    assert(
        Feedback.Limits.total <= 240 and Feedback.Limits.total - Feedback.Limits.decoration >= 48,
        "Decorations may starve score and reward flights"
    )
    assert(Feedback.burst("unknown", false, false) == nil, "Unknown signature produced FX")
    print(
        "PASS feedback signatures: "
            .. count
            .. " distinct motifs, light/rounded/heavy envelopes, bounded audio mix, thirteen evolutions and reduced bursts"
    )
end
