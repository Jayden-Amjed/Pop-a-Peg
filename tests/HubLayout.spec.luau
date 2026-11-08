local Layout = if script
    then require(game.Players.LocalPlayer.PlayerScripts.Client.HubLayout)
    else require("../src/client/HubLayout")

return function()
    for _, dimensions in
        { { 320, 320 }, { 390, 780 }, { 640, 320 }, { 800, 450 }, { 1280, 720 }, { 1920, 1080 } }
    do
        local w, h = dimensions[1], dimensions[2]
        local layout = Layout.compute(w, h)
        local panel, body = layout.panel, layout.body
        assert(panel.x >= 0 and panel.y >= 0, "Panel begins on screen")
        assert(panel.x + panel.w <= w and panel.y + panel.h <= h, "Panel remains on screen")
        assert(body.x >= 0 and body.y >= 0 and body.x + body.w <= panel.w, "Gallery fits panel")
        assert(body.y + body.h <= panel.h - 44, "Gallery leaves footer clear")
        assert(layout.pageSize >= 2 and layout.pageSize <= 6, "Model budget stays bounded")
        for i, cell in layout.cells do
            assert(cell.w >= 100 and cell.h >= 80, "Model card stays usable")
            assert(cell.x >= 0 and cell.y >= 0, "Card begins inside gallery")
            assert(cell.x + cell.w <= body.w + 0.001, "Card fits gallery width")
            assert(cell.y + cell.h <= body.h + 0.001, "Card fits gallery height")
            for j, other in layout.cells do
                if i < j then
                    assert(
                        cell.x + cell.w <= other.x + 0.001
                            or other.x + other.w <= cell.x + 0.001
                            or cell.y + cell.h <= other.y + 0.001
                            or other.y + other.h <= cell.y + 0.001,
                        "Model cards never overlap"
                    )
                end
            end
        end
    end
    print("PASS hub layout: six viewport sizes, bounded panels, nonoverlapping model gallery")
end
