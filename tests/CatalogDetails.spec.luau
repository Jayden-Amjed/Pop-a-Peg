local Shared = if script then game:GetService("ReplicatedStorage").Shared else nil
local Catalog = if Shared then require(Shared.Catalog) else require("../src/shared/Catalog")

return function()
    local count = 0
    for _, category in ipairs({ Catalog.Items, Catalog.Perks }) do
        for id, definition in pairs(category) do
            for level = 1, Catalog.MaxLevel do
                local detail = Catalog.detail(id, level)
                assert(
                    detail.name and detail.trigger and #detail.effects > 0,
                    "Incomplete detail: " .. id
                )
                assert(#detail.effects <= 7 and #detail.evolutions <= 2, "Unbounded detail: " .. id)
                for _, row in ipairs(detail.effects) do
                    assert(
                        row.tone == "positive"
                            or row.tone == "negative"
                            or row.tone == "neutral"
                            or row.tone == "trigger",
                        "Unknown effect tone: " .. id
                    )
                    assert(
                        not string.find(row.text, "Tradeoff")
                            and not string.find(row.text, "Use now"),
                        "Redundant explanation: " .. id
                    )
                    if level == Catalog.MaxLevel or definition.evolved then
                        assert(
                            not string.find(row.text, "↑"),
                            "Max-level stats show another upgrade"
                        )
                    end
                end
                if definition.evolved or definition.consumable or Catalog.Perks[id] then
                    assert(#detail.evolutions == 0, "Non-base item must not expose recipes")
                elseif not table.find(Catalog.NewItemIds, id) then
                    assert(#detail.evolutions >= 1, "Base equipment has no evolution: " .. id)
                else
                    assert(
                        #detail.evolutions == 0,
                        "Discovery equipment has no recipe in this release"
                    )
                end
            end
            count += 1
        end
    end
    for level = 1, Catalog.MaxLevel do
        local gain = Catalog.detail("gain_dial", level)
        local expected = tostring(15 * level)
            .. "%"
            .. (
                if level < Catalog.MaxLevel
                    then " (↑ " .. tostring(15 * (level + 1)) .. "%)"
                    else ""
            )
        assert(
            gain.effects[1].text == "Gain " .. expected .. " score",
            "Gain Dial level preview incorrect"
        )
        assert(
            gain.effects[2].text == "Halve the highest peg once"
                and gain.effects[2].tone == "negative",
            "Fixed cost changed"
        )
    end
    local burst = Catalog.detail("burst_capsule", 5)
    assert(
        burst.effects[1].tone == "positive" and burst.effects[2].text == "Pop 10 nearest other pegs",
        "Burst max-level gain order/count"
    )
    assert(burst.effects[3].tone == "negative", "Ordered burst cost omitted")
    assert(Catalog.detail("reserve_pack").trigger == "On purchase", "Supply wording")
    assert(
        Catalog.detail("tuning_oil").effects[2].text == "If none qualify: gain 4 coins",
        "Oil fallback missing"
    )
    assert(Catalog.owns({ { id = "seed_bank", level = 2 } }, "seed_bank"), "Owned item not found")
    assert(
        not Catalog.owns({ { id = "seed_bank", level = 2 } }, "goldfish"),
        "Missing item marked owned"
    )
    local recipe = Catalog.detail("goldfish").evolutions[1]
    recipe.ingredients[1] = "changed"
    assert(
        Catalog.detail("goldfish").evolutions[1].ingredients[1] ~= "changed",
        "Inspection mutated catalog"
    )
    assert(Catalog.detail("unknown") == nil, "Unknown item must not display stats")
    print(
        "PASS catalog inspection: "
            .. count
            .. " entries, five levels, ordered effects and evolution recipes"
    )
end
