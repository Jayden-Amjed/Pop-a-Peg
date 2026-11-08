local Shared = if script then game:GetService("ReplicatedStorage").Shared else nil
local Catalog = if Shared then require(Shared.Catalog) else require("../src/shared/Catalog")

return function()
    local count = 0
    for _, category in ipairs({ Catalog.Items, Catalog.Perks }) do
        for id in pairs(category) do
            for level = 1, 2 do
                local detail = Catalog.detail(id, level)
                assert(
                    detail.name and detail.trigger and #detail.effects > 0,
                    "Incomplete detail: " .. id
                )
                assert(#detail.effects <= 3 and #detail.partners <= 3, "Unbounded detail: " .. id)
                for _, row in ipairs(detail.effects) do
                    assert(
                        row.tone == "positive" or row.tone == "negative" or row.tone == "neutral",
                        "Unknown effect tone: " .. id
                    )
                    assert(
                        not string.find(row.text, "Tradeoff")
                            and not string.find(row.text, "Use now"),
                        "Redundant explanation: " .. id
                    )
                    if level == 2 then
                        assert(
                            not string.find(row.text, "↑"),
                            "Max-level stats show another upgrade"
                        )
                    end
                end
                local seen = {}
                for _, partner in ipairs(detail.partners) do
                    assert(
                        Catalog.Items[partner] and partner ~= id and not seen[partner],
                        "Invalid pair: " .. id
                    )
                    seen[partner] = true
                end
            end
            count += 1
        end
    end
    local gain = Catalog.detail("gain_dial", 1)
    assert(gain.trigger == "Every 15 pops", "Gain Dial trigger changed")
    assert(
        gain.effects[1].text == "Gain 15% (↑ 30%) score" and gain.effects[1].tone == "positive",
        "Gain Dial base/upgrade gain missing"
    )
    assert(
        gain.effects[2].text == "Halve the highest peg once" and gain.effects[2].tone == "negative",
        "Gain Dial cost missing"
    )
    local upgraded = Catalog.detail("gain_dial", 2)
    assert(upgraded.effects[1].text == "Gain 30% score", "Max-level gain incorrect")
    assert(upgraded.effects[2].text == gain.effects[2].text, "Fixed cost changed with item level")
    local burst = Catalog.detail("burst_capsule", 2)
    assert(
        burst.effects[1].tone == "positive" and burst.effects[2].text == "Pop 4 nearest other pegs",
        "Burst gain order/count changed"
    )
    assert(burst.effects[3].tone == "negative", "Ordered burst cost omitted")
    assert(Catalog.detail("reserve_pack").trigger == "On purchase", "Supply trigger wording")
    assert(
        Catalog.detail("tuning_oil").effects[2].text == "If none qualify: gain 4 coins",
        "Oil fallback missing"
    )
    assert(Catalog.owns({ { id = "seed_bank", level = 2 } }, "seed_bank"), "Owned item not found")
    assert(
        not Catalog.owns({ { id = "seed_bank", level = 2 } }, "goldfish"),
        "Missing item marked owned"
    )
    gain.partners[1] = "changed"
    assert(Catalog.detail("gain_dial").partners[1] ~= "changed", "Inspection mutated catalog")
    assert(Catalog.detail("unknown") == nil, "Unknown item must not display stats")
    print(
        "PASS catalog inspection: "
            .. count
            .. " entries, ordered typed effects, levels and ownership"
    )
end
