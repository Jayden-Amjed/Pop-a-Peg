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

return Selection
