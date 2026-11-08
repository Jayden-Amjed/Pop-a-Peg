local Layout = if script
    then require(game:GetService("Players").LocalPlayer.PlayerScripts.Client.ChoiceLayout)
    else require("../src/client/ChoiceLayout")

return function()
    local function inside(a, b)
        return a.w > 0
            and a.h >= 0
            and a.x >= b.x
            and a.y >= b.y
            and a.x + a.w <= b.x + b.w + 0.01
            and a.y + a.h <= b.y + b.h + 0.01
    end
    local function overlaps(a, b)
        return a.h > 0
            and b.h > 0
            and a.x < b.x + b.w
            and b.x < a.x + a.w
            and a.y < b.y + b.h
            and b.y < a.y + a.h
    end
    for _, size in
        { { 512, 128 }, { 788, 124 }, { 990, 212 }, { 334, 470 }, { 1124, 488 }, { 1124, 610 } }
    do
        for _, perk in { false, true } do
            local cards = Layout.compute(size[1], size[2], 2)
            assert(#cards == 2 and not overlaps(cards[1], cards[2]), "Choices must remain separate")
            for _, card in cards do
                assert(
                    inside(card, { x = 0, y = 0, w = size[1], h = size[2] }),
                    "Choice escaped its visible body"
                )
                local layout = Layout.card(card.w, card.h, perk)
                local regions =
                    { layout.model, layout.name, layout.trigger, layout.effect, layout.choose }
                for index, region in regions do
                    assert(
                        inside(region, { x = 0, y = 0, w = card.w, h = card.h }),
                        "Choice content escaped card"
                    )
                    for other = index + 1, #regions do
                        assert(
                            not overlaps(region, regions[other]),
                            "Choice model, stats or CTA overlap"
                        )
                    end
                end
                assert(
                    layout.choose.h >= 32 and layout.effect.h >= 24,
                    "Choice stats or CTA too small"
                )
            end
        end
    end
    print("PASS choice layout: two visible cards, bounded stats and CTAs without scrolling")
end
