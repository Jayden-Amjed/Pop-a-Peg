-- A completed settlement is not replayed when a paused run returns from the
-- arcade. Its restored/seeded board still needs to replace spent-shot values.
local ReceiptBoard = {}
local settledPhases = {
    result = true,
    shop = true,
    perk = true,
    event = true,
    victory = true,
    gameover = true,
}

function ReceiptBoard.resolve(snapshot, completedReceipt)
    local receipt = snapshot.settlementReceipt
    if
        settledPhases[snapshot.phase]
        and type(receipt) == "table"
        and receipt.id ~= nil
        and receipt.id == completedReceipt
    then
        local values = if type(receipt.nextShotValues) == "table"
            then receipt.nextShotValues
            else receipt.finalValues
        if type(values) == "table" then
            return values, true, snapshot.phase == "result"
        end
    end
    -- Aim may include between-shot gardening rewards; flight contains live peg
    -- changes. Neither can be reconstructed from the previous receipt.
    return snapshot.values, false, false
end

return ReceiptBoard
