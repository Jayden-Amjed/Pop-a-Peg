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
        Feedback.Limits.total <= 240 and Feedback.Limits.total - Feedback.Limits.decoration >= 48,
        "Decorations may starve score and reward flights"
    )
    assert(Feedback.burst("unknown", false, false) == nil, "Unknown signature produced FX")
    print(
        "PASS feedback signatures: "
            .. count
            .. " distinct motifs, thirteen evolutions, bounded/reduced bursts and reward capacity"
    )
end
