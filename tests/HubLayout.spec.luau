local Layout = if script
    then require(game.Players.LocalPlayer.PlayerScripts.Client.HubLayout)
    else require("../src/client/HubLayout")

return function()
    local dimensionsToCheck = {
        { 320, 320 },
        { 390, 780 },
        { 640, 320 },
        { 800, 450 },
        { 1280, 720 },
        { 1920, 1080 },
        -- Root.AbsoluteSize already excludes the ScreenGui's safe insets.
        { 320 - 32, 320 - 40 },
        { 390 - 48, 780 - 72 },
        { 800 - 80, 450 - 48 },
    }
    local function inside(area, w, h, description)
        assert(area.w > 0 and area.h > 0, description .. " has positive dimensions")
        assert(area.x >= 0 and area.y >= 0, description .. " starts inside bounds")
        assert(
            area.x + area.w <= w + 0.001 and area.y + area.h <= h + 0.001,
            description .. " stays inside bounds"
        )
    end
    local function separate(a, b)
        return a.x + a.w <= b.x + 0.001
            or b.x + b.w <= a.x + 0.001
            or a.y + a.h <= b.y + 0.001
            or b.y + b.h <= a.y + 0.001
    end
    for _, dimensions in dimensionsToCheck do
        local w, h = dimensions[1], dimensions[2]
        local layout = Layout.compute(w, h)
        local panel, body = layout.panel, layout.body
        assert(panel.x >= 0 and panel.y >= 0, "Panel begins on screen")
        assert(panel.x + panel.w <= w and panel.y + panel.h <= h, "Panel remains on screen")
        assert(body.x >= 0 and body.y >= 0 and body.x + body.w <= panel.w, "Gallery fits panel")
        assert(body.y + body.h <= panel.h - 44, "Gallery leaves footer clear")
        assert(layout.pageSize >= 2 and layout.pageSize <= 6, "Model budget stays bounded")
        for _, name in { "brand", "crew", "dock", "notice" } do
            inside(layout[name], w, h, name)
        end
        assert(separate(layout.brand, layout.crew), "Header plates never overlap")
        assert(separate(layout.notice, layout.dock), "Notices stay above actions")
        assert(
            separate(layout.brand, layout.dock) and separate(layout.crew, layout.dock),
            "Header leaves the dock clear"
        )
        inside(layout.hint, layout.dock.w, layout.dock.h, "Dock hint")
        for name, control in layout.controls do
            inside(control, layout.dock.w, layout.dock.h, name)
            assert(control.h >= 42 and control.w >= 76, "Actions keep useful hit targets")
            assert(separate(control, layout.hint), "Hint never covers actions")
            for otherName, other in layout.controls do
                if name ~= otherName then
                    assert(separate(control, other), "Dock actions never overlap")
                end
            end
        end
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
    print(
        "PASS hub layout: six viewport sizes plus three safe-area sizes, bounded HUD/panels, nonoverlapping controls and models"
    )
end
