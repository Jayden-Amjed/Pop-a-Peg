local ReceiptBoard = if script
    then require(game:GetService("StarterPlayer").StarterPlayerScripts.Client.ReceiptBoard)
    else require("../src/client/ReceiptBoard")

return function()
    local live, restored, seeded = { 0, 3, 1 }, { 2, 4, 1 }, { 4, 4, 2 }
    local receipt = { id = 7, finalValues = restored, nextShotValues = seeded }
    local snapshot = { phase = "shop", values = live, settlementReceipt = receipt }
    for _, phase in { "shop", "perk", "event", "result", "victory", "gameover" } do
        snapshot.phase = phase
        local values, overridden, continueResult = ReceiptBoard.resolve(snapshot, 7)
        assert(values == seeded and overridden, phase .. " must resume its completed seeded board")
        assert(continueResult == (phase == "result"), "Only completed result resumes continuation")
        receipt.nextShotValues = nil
        values, overridden = ReceiptBoard.resolve(snapshot, 7)
        assert(values == restored and overridden, phase .. " must restore older unseeded receipts")
        receipt.nextShotValues = seeded
        values, overridden, continueResult = ReceiptBoard.resolve(snapshot, nil)
        assert(not continueResult, "Uncompleted receipt cannot auto-advance")
        assert(
            values == live and not overridden,
            "Uncompleted receipt must play the normal settlement"
        )
        values, overridden, continueResult = ReceiptBoard.resolve(snapshot, 6)
        assert(not continueResult, "A different receipt cannot auto-advance")
        assert(
            values == live and not overridden,
            "A different receipt must not reuse the prior board"
        )
    end

    for _, phase in { "aim", "flight", "settling" } do
        snapshot.phase = phase
        local values, overridden, continueResult = ReceiptBoard.resolve(snapshot, 7)
        assert(not continueResult, "Live phase cannot auto-advance")
        assert(
            values == live and not overridden,
            phase .. " must use current values despite the completed receipt"
        )
    end
    -- A between-shot growth reward can make current aim values larger than the
    -- recorded seed preview. Resuming must not roll that reward back.
    snapshot.phase, snapshot.values = "aim", { 8, 4, 2 }
    local values, overridden = ReceiptBoard.resolve(snapshot, 7)
    assert(values[1] == 8 and not overridden, "Resume preserves post-receipt gardening growth")
    snapshot.phase, snapshot.values = "flight", { 7, 2, 0 }
    values, overridden = ReceiptBoard.resolve(snapshot, 7)
    assert(values[3] == 0 and not overridden, "Live pops cannot be resurrected by an old receipt")

    snapshot.phase, snapshot.values = "shop", live
    snapshot.settlementReceipt = nil
    values, overridden = ReceiptBoard.resolve(snapshot, 7)
    assert(values == live and not overridden, "Missing receipt uses current state")
    snapshot.settlementReceipt = { nextShotValues = seeded }
    values, overridden = ReceiptBoard.resolve(snapshot, nil)
    assert(values == live and not overridden, "Two missing identities do not count as completed")
    snapshot.settlementReceipt = { id = 7 }
    values, overridden = ReceiptBoard.resolve(snapshot, 7)
    assert(values == live and not overridden, "Incomplete receipt does not blank the board")
    assert(
        live[1] == 0 and restored[1] == 2 and seeded[1] == 4,
        "Resolution never mutates board values"
    )
    print(
        "PASS receipt board: completed settled-phase restoration, seeded/legacy previews, fresh receipts, live aim/flight and gardening"
    )
end
