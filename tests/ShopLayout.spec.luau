local Layout = if script
    then require(game:GetService("Players").LocalPlayer.PlayerScripts.Client.ShopLayout)
    else require("../src/client/ShopLayout")
local DetailLayout = if script
    then require(game:GetService("Players").LocalPlayer.PlayerScripts.Client.ItemDetailLayout)
    else require("../src/client/ItemDetailLayout")
return function()
    local function inside(a, b)
        assert(a.w >= 0 and a.h >= 0, "Negative shop region")
        assert(
            a.x >= b.x - 0.01
                and a.y >= b.y - 0.01
                and a.x + a.w <= b.x + b.w + 0.01
                and a.y + a.h <= b.y + b.h + 0.01,
            "Shop region escaped container"
        )
    end
    local function separate(a, b)
        assert(
            a.x + a.w <= b.x + 0.01
                or b.x + b.w <= a.x + 0.01
                or a.y + a.h <= b.y + 0.01
                or b.y + b.h <= a.y + 0.01,
            "Shop controls overlap"
        )
    end
    -- Core-safe sizes, including 667x375 after the Studio/Roblox top inset.
    for _, size in
        { { 1920, 1022 }, { 1366, 710 }, { 1046, 466 }, { 844, 332 }, { 667, 317 }, { 390, 750 } }
    do
        local window = Layout.window(size[1], size[2])
        inside(window, { x = 0, y = 0, w = size[1], h = size[2] })
        assert(window.y >= 40, "Shop covered session/test navigation")
        for supplies = 0, 2 do
            local layout = Layout.compute(window.w, window.h, supplies)
            assert(#layout.cards == 4 + supplies, "Missing offers")
            local bounds = { x = 0, y = 0, w = window.w, h = window.h }
            local groups = { layout.title, layout.groups.items, layout.footer }
            if layout.groups.supplies then
                assert(
                    layout.groups.supplies.y >= layout.groups.items.y + layout.groups.items.h,
                    "Supplies must be below equipment"
                )
                table.insert(groups, layout.groups.supplies)
            end
            if layout.sidebar then
                table.insert(groups, layout.sidebar)
            end
            for i, a in groups do
                inside(a, bounds)
                for j = i + 1, #groups do
                    separate(a, groups[j])
                end
            end
            for index, card in layout.cards do
                inside(card, index <= 4 and layout.groups.items or layout.groups.supplies)
                for j = index + 1, #layout.cards do
                    separate(card, layout.cards[j])
                end
                local content = Layout.card(card.w, card.h, index > 4)
                local localBounds = { x = 0, y = 0, w = card.w, h = card.h }
                inside(content.inspect, localBounds)
                inside(content.purchase, localBounds)
                assert(
                    content.purchase.h >= 44 and content.purchase.w >= 44,
                    "Purchase is not touch-sized"
                )
                separate(content.inspect, content.purchase)
                inside(
                    content.model,
                    { x = 0, y = 0, w = content.inspect.w, h = content.inspect.h }
                )
                inside(
                    content.name,
                    content.nameOnCard and localBounds
                        or { x = 0, y = 0, w = content.inspect.w, h = content.inspect.h }
                )
                if index > 4 then
                    inside(content.price, localBounds)
                    separate(content.price, content.purchase)
                    separate(content.price, content.inspect)
                    separate(content.name, content.purchase)
                    separate(content.name, content.price)
                    assert(content.name.h >= 18, "Supply heading became unreadable")
                end
                if content.hold then
                    inside(content.hold, localBounds)
                    assert(content.hold.h >= 44 and content.hold.w >= 44, "Hold is not touch-sized")
                    separate(content.hold, content.purchase)
                    separate(content.hold, content.inspect)
                    assert(content.model.h >= 24, "Equipment preview collapsed")
                    if content.short then
                        local cost = Layout.compactCost(content.purchase.w, content.purchase.h, 2)
                        for _, r in cost do
                            inside(
                                r,
                                { x = 0, y = 0, w = content.purchase.w, h = content.purchase.h }
                            )
                        end
                        separate(cost.caption, cost.price)
                        separate(cost.price, cost.coin)
                        assert(
                            cost.price.h >= 20 and cost.coin.h >= 20,
                            "Compact price or trailing coin collapsed"
                        )
                        assert(cost.coin.x >= cost.price.x + cost.price.w, "Coin must follow price")
                    end
                end
            end
        end
    end
    -- Shared recipe geometry must remain compatible with the inspector.
    for count = 0, 4 do
        local layout = Layout.equations(350, 20 + count * 80, count)
        assert(#layout.rows == count, "Missing recipe rows")
        for _, row in layout.rows do
            assert(#row.boxes == 3 and #row.symbols == 2, "Incomplete recipe equation")
            for _, group in { row.boxes, row.statuses, row.symbols } do
                for _, r in group do
                    inside(r, { x = 0, y = 0, w = 350, h = 20 + count * 80 })
                end
            end
        end
    end
    for _, size in { { 236, 620 }, { 340, 600 }, { 560, 244 }, { 1220, 650 } } do
        local layout = DetailLayout.compute(size[1], size[2], { 22, 44, 22, 44 }, 4)
        assert(#layout.effects == 4, "Detail card omitted effects")
        assert(layout.recipes.h >= 4 * 100, "Detail card omitted recipes")
        local bounds = { x = 0, y = 0, w = size[1], h = layout.contentHeight }
        local regions = { layout.model, layout.name, layout.recipes }
        for _, r in layout.effects do
            table.insert(regions, r)
        end
        for i, r in regions do
            inside(r, bounds)
            for j = i + 1, #regions do
                separate(r, regions[j])
            end
        end
    end
    print(
        "PASS shop: desktop/landscape/portrait bounds, four equipment plus Supplies below, 44px actions, preview area, recipe compatibility"
    )
end
