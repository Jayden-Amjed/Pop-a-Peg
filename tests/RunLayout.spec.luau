local Layout = if script
    then require(game:GetService("Players").LocalPlayer.PlayerScripts.Client.RunLayout)
    else require("../src/client/RunLayout")
local Shop = if script
    then require(game:GetService("Players").LocalPlayer.PlayerScripts.Client.ShopLayout)
    else require("../src/client/ShopLayout")
local Choice = if script
    then require(game:GetService("Players").LocalPlayer.PlayerScripts.Client.ChoiceLayout)
    else require("../src/client/ChoiceLayout")

local function inside(a, w, h)
    return a.x >= 0
        and a.y >= 0
        and a.w > 0
        and a.h > 0
        and a.x + a.w <= w + 0.01
        and a.y + a.h <= h + 0.01
end

local function overlaps(a, b)
    return a.x < b.x + b.w and b.x < a.x + a.w and a.y < b.y + b.h and b.y < a.y + a.h
end

return function()
    for _, size in
        {
            { 315, 130, false, false },
            { 315, 174, false, false },
            { 262, 130, false, false },
            { 640, 88, true, false },
            { 430, 50, true, false },
            { 350, 170, true, true },
        }
    do
        for count = 0, 8 do
            local layout = Layout.perks(size[1], size[2], count, size[3], size[4])
            assert(#layout.cells == count, "Perk layout reserves invisible cards")
            for index, cell in layout.cells do
                assert(inside(cell.card, size[1], size[2]), "Owned perk escaped its panel")
                assert(inside(cell.model, cell.card.w, cell.card.h), "Perk model escaped its card")
                assert(inside(cell.count, cell.card.w, cell.card.h), "Perk count escaped its card")
                if cell.name.h > 0 then
                    assert(inside(cell.name, cell.card.w, cell.card.h), "Perk name escaped card")
                    assert(not overlaps(cell.model, cell.name), "Perk model covers its name")
                end
                for other = index + 1, #layout.cells do
                    assert(not overlaps(cell.card, layout.cells[other].card), "Owned perks overlap")
                end
            end
        end
    end
    local sparse = Layout.perks(315, 130, 4, false, false)
    assert(
        sparse.cells[1].model.h >= 80 and sparse.cells[4].card.y == sparse.cells[1].card.y,
        "Four desktop perks still lose half their height to an empty row"
    )
    local fullPerks = Layout.perks(315, 130, 8, false, false)
    assert(
        fullPerks.cells[5].card.y > fullPerks.cells[1].card.y,
        "Full perk pool did not retain two rows"
    )
    local cases = {
        { 360, 640, 0, 44, 0, 34, true },
        { 390, 844, 0, 59, 0, 34, true },
        { 844, 390, 59, 58, 59, 21, false },
        { 852, 393, 59, 54, 59, 21, false },
        { 768, 1024, 0, 24, 0, 20, true },
        { 568, 320, 0, 36, 0, 0, false },
        { 667, 375, 0, 36, 0, 0, false },
    }
    for _, case in cases do
        local safe = Layout.safeRect(table.unpack(case, 1, 6))
        local w, h = safe.w, safe.h
        local layout = case[7] and Layout.portrait(w, h) or Layout.landscape(w, h)
        local regions = {
            layout.round,
            layout.navigation,
            layout.rack,
            layout.resources,
            layout.score,
            layout.board,
            layout.controls,
        }
        for _, extra in layout.extras do
            table.insert(regions, extra)
            assert(extra.w >= 44 and extra.h >= 44, "Secondary touch action too small")
        end
        for index, region in regions do
            assert(inside(region, w, h), "Run HUD escaped core safe area")
            for other = index + 1, #regions do
                assert(
                    not overlaps(region, regions[other]),
                    "Run HUD obscures the board or another control"
                )
            end
        end
        assert(layout.board.h >= math.min(250, h - 50), "Small-screen board lost usable height")
        assert(layout.navigation.h >= 44 and layout.controls.h >= 44, "Primary action too small")
        assert(inside(layout.details, w, h), "Expandable stats/perks escaped safe area")
        assert(inside(layout.shop, w, h), "Shop escaped safe area")
        local physicalNavX = layout.navigation.x + safe.x
        local physicalNavY = layout.navigation.y + safe.y
        assert(
            physicalNavX - safe.x == layout.navigation.x
                and physicalNavY - safe.y == layout.navigation.y,
            "Return-button safe root conversion drifted"
        )
        for supplies = 0, 2 do
            local shop = Shop.compute(layout.shop.w, layout.shop.h, supplies)
            assert(#shop.cards == 4 + supplies, "Mobile shop hides offers")
            for index, card in shop.cards do
                assert(inside(card, layout.shop.w, layout.shop.h), "Mobile offer escaped modal")
                for recipes = 0, (index <= 4 and 2 or 0) do
                    local fields = Shop.card(card.w, card.h, index > 4, recipes)
                    assert(fields.purchase.h >= 44, "Mobile buy control is not touch sized")
                    assert(fields.inspect.h >= 27, "Mobile inspection name/model vanished")
                    assert(inside(fields.purchase, card.w, card.h), "Mobile purchase escaped card")
                    assert(inside(fields.inspect, card.w, card.h), "Mobile inspection escaped card")
                    assert(
                        not overlaps(fields.inspect, fields.purchase),
                        "Mobile purchase covers item"
                    )
                    if recipes > 0 then
                        assert(fields.evolutions.h >= 24, "Recipes have no usable inspection route")
                    end
                end
            end
        end
        -- Mirrors modal title/footer allocation, including the short landscape case.
        local modalW, modalH = math.min(1160, w - 28), math.min(680, h - 68)
        local tiny, shortWide = modalH < 280, not case[7]
        local bodyTop = tiny and 36 or (shortWide and 70 or 112)
        local footerY = modalH - (tiny and 44 or (shortWide and 54 or 67))
        local bodyH = footerY - bodyTop - (tiny and 8 or (shortWide and 10 or 13))
        for _, card in Choice.compute(modalW - 28, bodyH, 2) do
            local fields = Choice.card(card.w, card.h, true)
            assert(
                fields.choose.h >= 44 and fields.effect.h >= 24,
                "Phone perk text or choose action is cramped"
            )
            for _, field in
                { fields.model, fields.name, fields.trigger, fields.effect, fields.choose }
            do
                assert(inside(field, card.w, card.h), "Phone perk content escaped card")
            end
        end
    end
    -- An emulated cutout phone renders 873 px vertically but reports a
    -- 777 px Camera.ViewportSize. Fit in renderer space and project back to
    -- core-UI coordinates, where the playable board and touch controls live.
    for _, case in
        {
            {
                full = { x = 0, y = -120, w = 401, h = 873 },
                safe = { x = 0, y = 0, w = 401, h = 719 },
            },
            {
                full = { x = -59, y = -58, w = 844, h = 390 },
                safe = { x = 0, y = 0, w = 726, h = 311 },
            },
            {
                full = { x = 0, y = -36, w = 1920, h = 1080 },
                safe = { x = 0, y = 0, w = 1920, h = 1044 },
            },
        }
    do
        local safe, full = case.safe, case.full
        local board = safe.h > safe.w and Layout.portrait(safe.w, safe.h).board
            or Layout.landscape(safe.w, safe.h).board
        local camera = Layout.cameraFrame(full, safe, board)
        local pixelsPerStud = full.h / (2 * camera.z * math.tan(math.rad(17.5)))
        local function project(x, y)
            return full.x + full.w / 2 + (x - camera.x) * pixelsPerStud,
                full.y + full.h / 2 - (y - camera.y) * pixelsPerStud
        end
        local centerX, centerY = project(0, 11.7)
        assert(
            math.abs(centerX - (safe.x + board.x + board.w / 2)) < 0.001,
            "Board center X drifted"
        )
        assert(
            math.abs(centerY - (safe.y + board.y + board.h / 2)) < 0.001,
            "Board center Y drifted"
        )
        local left, top = project(-13.4, 11.7 + 17.25)
        local right, bottom = project(13.4, 11.7 - 17.25)
        assert(
            left >= safe.x + board.x - 0.001 and right <= safe.x + board.x + board.w + 0.001,
            "Board escaped horizontal safe slot"
        )
        assert(
            top >= safe.y + board.y - 0.001 and bottom <= safe.y + board.y + board.h + 0.001,
            "Board escaped vertical safe slot"
        )
    end
    print(
        "PASS run layout: seven safe-area cases, cutout-camera framing, touch actions, complete shops and perk choices"
    )
end
