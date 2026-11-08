local Layout = if script
    then require(game:GetService("Players").LocalPlayer.PlayerScripts.Client.ShopLayout)
    else require("../src/client/ShopLayout")

return function()
    local function overlap(a, b)
        return a.x < b.x + b.w and b.x < a.x + a.w and a.y < b.y + b.h and b.y < a.y + a.h
    end
    for _, dimensions in { { 366, 678 }, { 820, 234 }, { 1022, 368 }, { 1100, 518 }, { 1100, 680 } } do
        for _, supplies in { 0, 2 } do
            local w, h = dimensions[1], dimensions[2]
            local layout = Layout.compute(w, h, supplies)
            assert(#layout.cards == 4 + supplies, "Every offer must be present simultaneously")
            local regions = { layout.title, layout.detail, layout.footer }
            for _, section in layout.sections do
                table.insert(regions, section)
            end
            for _, card in layout.cards do
                assert(
                    card.w >= 120 and card.h >= 86,
                    "An offer cannot fit its name, model and controls"
                )
                table.insert(regions, card)
            end
            for i, region in regions do
                assert(
                    region.x >= 0
                        and region.y >= 0
                        and region.x + region.w <= w + 0.01
                        and region.y + region.h <= h + 0.01,
                    "Visible shop content escaped modal bounds"
                )
                for j = i + 1, #regions do
                    assert(not overlap(region, regions[j]), "Shop regions overlap")
                end
            end
        end
    end
    print(
        "PASS shop layout: all six offers fit without scrolling across portrait, short and desktop sizes"
    )
end
