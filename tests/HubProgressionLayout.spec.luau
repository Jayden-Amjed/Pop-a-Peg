local HubLayout = if script
    then require(game.Players.LocalPlayer.PlayerScripts.Client.HubLayout)
    else require("../src/client/HubLayout")
local Layout = if script
    then require(game.Players.LocalPlayer.PlayerScripts.Client.HubProgressionLayout)
    else require("../src/client/HubProgressionLayout")

return function()
    local function inside(r, w, h)
        assert(r.w > 0 and r.h > 0 and r.x >= 0 and r.y >= 0, "positive in-bounds region")
        assert(r.x + r.w <= w + 0.01 and r.y + r.h <= h + 0.01, "region fits safe area")
    end
    local function separate(a, b)
        return a.x + a.w <= b.x + 0.01
            or b.x + b.w <= a.x + 0.01
            or a.y + a.h <= b.y + 0.01
            or b.y + b.h <= a.y + 0.01
    end
    for _, size in
        {
            { 288, 280 },
            { 342, 568 },
            { 342, 772 },
            { 756, 310 },
            { 720, 402 },
            { 1024, 700 },
            {
                1920,
                1080,
            },
        }
    do
        local hub = HubLayout.compute(size[1], size[2])
        local w, h = hub.body.w, hub.body.h
        local chest = Layout.chest(w, h)
        for _, tab in chest.tabs do
            inside(tab, w, h)
            assert(tab.h >= 44, "tier touch target")
        end
        for _, key in { "model", "title", "action" } do
            inside(chest[key], w, h)
        end
        assert(chest.action.h >= 44, "opening touch target")
        assert(separate(chest.title, chest.action), "chest title leaves action clear")
        assert(separate(chest.model, chest.title), "portrait model leaves heading clear")
        if chest.showDetail then
            inside(chest.detail, w, h)
            assert(
                separate(chest.title, chest.detail) and separate(chest.detail, chest.action),
                "chest description remains readable"
            )
        end
        local items = Layout.catalog(w, h)
        inside(items.back, w, h)
        inside(items.currency, w, h)
        assert(separate(items.back, items.currency), "workshop header")
        for _, cell in items.cells do
            inside(cell, w, h)
            assert(cell.w >= 100 and cell.h >= 60, "usable discovery cards")
        end
        local item = Layout.item(w, h)
        for _, r in item do
            inside(r, w, h)
        end
        assert(
            separate(item.model, item.stats) and separate(item.stats, item.action),
            "item effects and action do not overlap"
        )
        local board = Layout.leaders(w, h)
        for _, tab in board.tabs do
            inside(tab, w, h)
            assert(tab.h >= 44, "ranking touch targets")
        end
        for _, row in board.rows do
            inside(row, w, h)
        end
    end
    print(
        "PASS hub progression layout: seven safe areas, chest opening, research grid/details and paginated rankings"
    )
end
