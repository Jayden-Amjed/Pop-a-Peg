local Shared = if script then game:GetService("ReplicatedStorage").Shared else nil
local Catalog = if Shared then require(Shared.Catalog) else require("../src/shared/Catalog")
local Feedback = if Shared
    then require(Shared.ItemFeedback)
    else require("../src/shared/ItemFeedback")

return function()
    local signatures, count = {}, 0
    for _, category in ipairs({ Catalog.Items, Catalog.Perks }) do
        for id in pairs(category) do
            local profile = Feedback.Profiles[id]
            assert(profile, "Missing item feedback: " .. id)
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
            count += 1
        end
    end
    print("PASS feedback signatures: " .. count .. " catalog entries, distinct bounded motifs")
end
