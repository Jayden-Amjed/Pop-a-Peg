--!strict

local Selection = {}

local function occupied(inventory, index)
    local item = inventory[index]
    return item ~= nil and item.id ~= ""
end

function Selection.reconcile(selected, inventory, slots, phase, busy)
    if busy or (phase ~= "aim" and phase ~= "shop") then
        return nil
    end
    if selected and selected >= 1 and selected <= slots and occupied(inventory, selected) then
        return selected
    end
    return nil
end

function Selection.click(selected, index, inventory, slots, phase, busy)
    selected = Selection.reconcile(selected, inventory, slots, phase, busy)
    if busy or (phase ~= "aim" and phase ~= "shop") then
        return nil, nil
    end
    if index % 1 ~= 0 or index < 1 or index > slots then
        return selected, nil
    end
    if selected == index then
        return nil, nil
    end
    if selected then
        return nil, { from = selected, to = index }
    end
    return occupied(inventory, index) and index or nil, nil
end

local function itemKey(item)
    return (item and item.id or "") .. ":" .. tostring(item and item.level or 0)
end

function Selection.beginMove(move, snapshot, now, maxLevel)
    local source, target = snapshot.inventory[move.from], snapshot.inventory[move.to]
    local cap = maxLevel or 2
    local merges = source.id ~= ""
        and source.id == target.id
        and source.level < cap
        and target.level < cap
    return {
        from = move.from,
        to = move.to,
        expectedFrom = if merges then itemKey(nil) else itemKey(target),
        expectedTo = if merges then itemKey({ id = source.id, level = cap }) else itemKey(source),
        phase = snapshot.phase,
        sequence = snapshot.sequence,
        expiresAt = now + 3,
    }
end

function Selection.reconcileMove(pending, snapshot, now)
    if not pending then
        return nil
    end
    if now >= pending.expiresAt or snapshot.phase ~= pending.phase then
        return nil
    end
    if pending.sequence and snapshot.sequence and snapshot.sequence <= pending.sequence then
        return pending
    end
    if snapshot.notice then
        return nil
    end
    if
        itemKey(snapshot.inventory[pending.from]) == pending.expectedFrom
        and itemKey(snapshot.inventory[pending.to]) == pending.expectedTo
    then
        return nil
    end
    return pending
end

return Selection
