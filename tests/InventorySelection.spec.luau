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
    local before = {
        phase = "shop",
        sequence = 8,
        inventory = { { id = "a", level = 1 }, { id = "b", level = 2 } },
    }
    local pending = Selection.beginMove({ from = 1, to = 2 }, before, 10)
    assert(
        Selection.reconcileMove(pending, before, 10.1) == pending,
        "Old snapshot prematurely acknowledged a swap"
    )
    before.notice = "Earlier unrelated rejection"
    assert(
        Selection.reconcileMove(pending, before, 10.1) == pending,
        "Stale notice cleared a newer pending swap"
    )
    before.notice = nil
    local heartbeat = { phase = "shop", sequence = 9, inventory = before.inventory }
    assert(
        Selection.reconcileMove(pending, heartbeat, 10.2) == pending,
        "Heartbeat without moved items prematurely acknowledged a swap"
    )
    local moved = {
        phase = "shop",
        sequence = 10,
        inventory = { { id = "b", level = 2 }, { id = "a", level = 1 } },
    }
    assert(
        Selection.reconcileMove(pending, moved, 10.3) == nil,
        "Matching authoritative swap did not unlock the rack"
    )
    assert(
        Selection.reconcileMove(pending, heartbeat, 13) == nil,
        "Dropped action left rack locked indefinitely"
    )
    heartbeat.notice = "Move rejected"
    assert(
        Selection.reconcileMove(pending, heartbeat, 10.4) == nil,
        "Rejected move left rack locked"
    )
    heartbeat.notice, heartbeat.phase = nil, "aim"
    assert(
        Selection.reconcileMove(pending, heartbeat, 10.4) == nil,
        "Phase transition left rack locked"
    )
    local duplicates = {
        phase = "shop",
        sequence = 20,
        inventory = { { id = "a", level = 1 }, { id = "a", level = 1 } },
    }
    local merge = Selection.beginMove({ from = 1, to = 2 }, duplicates, 20, 2)
    local merged = {
        phase = "shop",
        sequence = 21,
        inventory = { { id = "", level = 0 }, { id = "a", level = 2 } },
    }
    assert(
        Selection.reconcileMove(merge, merged, 20.1) == nil,
        "Confirmed duplicate merge did not unlock rack immediately"
    )
    assert(
        duplicates.inventory[1].id == "a" and duplicates.inventory[2].level == 1,
        "Merge expectation mutated the authoritative snapshot"
    )
    duplicates.inventory[1].level = 2
    local capped = Selection.beginMove({ from = 1, to = 2 }, duplicates, 20, 2)
    local swapped = {
        phase = "shop",
        sequence = 21,
        inventory = { { id = "a", level = 1 }, { id = "a", level = 2 } },
    }
    assert(
        Selection.reconcileMove(capped, swapped, 20.1) == nil,
        "Capped copy must swap instead of merging"
    )
    print(
        "PASS inventory selection: select, deselect, cleared swap, empty target, invalid phase and busy guards"
    )
end
