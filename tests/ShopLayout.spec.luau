local Layout = if script
    then require(game:GetService("Players").LocalPlayer.PlayerScripts.Client.ShopLayout)
    else require("../src/client/ShopLayout")

return function()
    local function overlap(a, b)
        return a.w > 0
            and a.h > 0
            and b.w > 0
            and b.h > 0
            and a.x < b.x + b.w
            and b.x < a.x + a.w
            and a.y < b.y + b.h
            and b.y < a.y + a.h
    end
    local function inside(inner, outer)
        return inner.x >= outer.x - 0.01
            and inner.y >= outer.y - 0.01
            and inner.x + inner.w <= outer.x + outer.w + 0.01
            and inner.y + inner.h <= outer.y + outer.h + 0.01
    end
    for _, dimensions in { { 366, 678 }, { 820, 228 }, { 1022, 362 }, { 1100, 502 }, { 1100, 680 } } do
        for _, supplies in { 0, 1, 2 } do
            local w, h = dimensions[1], dimensions[2]
            local layout = Layout.compute(w, h, supplies)
            assert(
                #layout.cards == 4 + supplies,
                "All four equipment offers and each supply must remain visible"
            )
            assert(
                layout.groups.items and layout.sections.items,
                "Equipment must have its own titled enclosure"
            )
            assert(
                (layout.groups.supplies ~= nil) == (supplies > 0),
                "Supply enclosure must match actual offers"
            )
            local regions = { layout.title, layout.detail, layout.footer }
            for _, group in layout.groups do
                table.insert(regions, group)
            end
            if layout.divider then
                table.insert(regions, layout.divider)
            end
            for i, region in regions do
                assert(
                    inside(region, { x = 0, y = 0, w = w, h = h }),
                    "Shop region escaped modal bounds"
                )
                for j = i + 1, #regions do
                    assert(
                        not overlap(region, regions[j]),
                        "Shop groups, detail, or controls overlap"
                    )
                end
            end
            for index, card in layout.cards do
                local group = index <= 4 and layout.groups.items or layout.groups.supplies
                local header = index <= 4 and layout.sections.items or layout.sections.supplies
                assert(
                    inside(card, group) and not overlap(card, header),
                    "An offer escaped its enclosure or covered the section heading"
                )
                assert(
                    card.w >= 119 and card.h >= 90,
                    "Offer too small for its model/name and buttons"
                )
                local controls = Layout.card(card.w, card.h, index > 4)
                assert(
                    controls.purchase.h >= 36 and controls.inspect.h >= 27,
                    "Purchase or model inspection area became too small"
                )
                local parts = { controls.inspect, controls.purchase, controls.hold }
                for a, item in parts do
                    assert(
                        inside(item, { x = 0, y = 0, w = card.w, h = card.h }),
                        "Offer control escaped card"
                    )
                    for b = a + 1, #parts do
                        assert(not overlap(item, parts[b]), "Offer controls overlap")
                    end
                end
            end
        end
    end
    print(
        "PASS shop layout: separate enclosures, 4+2 visible offers, larger purchase controls and no overlap across five sizes"
    )
end
