local Selection = if script
    then require(game:GetService("Players").LocalPlayer.PlayerScripts.Client.InventorySelection)
    else require("../src/client/InventorySelection")

return function()
    local items = { { id = "a" }, { id = "b" }, { id = "" }, { id = "c" } }
    local selected, request = Selection.click(nil, 1, items, 4, "aim", false)
    assert(selected == 1 and request == nil, "First click must only select")
    selected, request = Selection.click(selected, 1, items, 4, "aim", false)
    assert(selected == nil and request == nil, "Same slot must deselect without swapping")
    selected, request = Selection.click(1, 2, items, 4, "shop", false)
    assert(
        selected == nil and request.from == 1 and request.to == 2,
        "Swap must clear both selections"
    )
    selected, request = Selection.click(selected, 4, items, 4, "shop", false)
    assert(selected == 4 and request == nil, "Next click after swap must start a fresh selection")
    selected, request = Selection.click(1, 3, items, 4, "aim", false)
    assert(selected == nil and request.to == 3, "Occupied item must move into an empty slot")
    for _, phase in { "flight", "result", "perk", "event", "gameover", "victory" } do
        selected, request = Selection.click(1, 2, items, 4, phase, false)
        assert(selected == nil and request == nil, "Invalid phase emitted a swap: " .. phase)
    end
    selected, request = Selection.click(1, 2, items, 4, "aim", true)
    assert(selected == nil and request == nil, "Busy state emitted a swap")
    for _, index in { 0, 5, 1.5 } do
        selected, request = Selection.click(1, index, items, 4, "aim", false)
        assert(selected == 1 and request == nil, "Locked or invalid destination emitted a swap")
    end
    assert(
        Selection.reconcile(3, items, 4, "aim", false) == nil,
        "Empty selected slot survived reconciliation"
    )
    print(
        "PASS inventory selection: select, deselect, cleared swap, empty target, invalid phase and busy guards"
    )
end
