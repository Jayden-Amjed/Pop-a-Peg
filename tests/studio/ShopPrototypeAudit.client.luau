--!nonstrict
-- Opt-in Play Client audit; never mapped into the ordinary game or prototype.
-- Install only in the isolated RBX031 fixture. Real pointer/emulator QA is separate.
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local started = os.clock()
local controller
local report = { ok = false, fixture = true, checks = {}, modelChecks = 0, cornerChecks = 0 }
script:SetAttribute("Result", HttpService:JSONEncode({ running = true }))

local function waitFor(predicate, message, seconds)
    local deadline = math.min(started + 90, os.clock() + (seconds or 8))
    repeat
        if predicate() then
            return
        end
        task.wait(0.05)
    until os.clock() >= deadline
    error("Timed out: " .. message)
end

local function record(message)
    table.insert(report.checks, message)
end

local function rect(object)
    local p, s = object.AbsolutePosition, object.AbsoluteSize
    return { x = p.X, y = p.Y, w = s.X, h = s.Y }
end

local function inside(object, parent)
    local a, b = rect(object), rect(parent)
    assert(a.w > 0 and a.h > 0, object:GetFullName() .. " has no rendered area")
    assert(
        a.x >= b.x - 1
            and a.y >= b.y - 1
            and a.x + a.w <= b.x + b.w + 1
            and a.y + a.h <= b.y + b.h + 1,
        object:GetFullName() .. " escaped " .. parent.Name
    )
end

local function separate(a, b)
    local ar, br = rect(a), rect(b)
    assert(
        ar.x + ar.w <= br.x + 1
            or br.x + br.w <= ar.x + 1
            or ar.y + ar.h <= br.y + 1
            or br.y + br.h <= ar.y + 1,
        a.Name .. " overlaps " .. b.Name
    )
end

local function touchControl(control)
    local size = control.AbsoluteSize
    assert(size.X >= 43.5 and size.Y >= 43.5, control.Name .. " is below 44px touch size")
end

local function ready()
    waitFor(function()
        local view = controller.view
        if not view or not view.shop or not view.overlay.Visible or #view.shop.cards ~= 6 then
            return false
        end
        for _, card in view.shop.cards do
            local mounted = view.models[card.viewport]
            if not mounted then
                return false
            end
            local info = mounted.handle:inspect()
            assert(info.backend == "Blender", "Shop model fell back from Blender")
            assert(info.loadState ~= "Failed", "Shop model failed to load")
            if info.loadState ~= "Ready" or card.viewport.AbsoluteSize.Y <= 0 then
                return false
            end
        end
        return true
    end, "six actual Blender shop models", 20)
    task.wait()
end

local function reset(scenario)
    controller.reset(scenario)
    ready()
end

local function action(kind, payload, rejected)
    local count = controller.actions
    controller.view:_send(kind, payload)
    waitFor(function()
        return controller.actions > count
    end, "fixture action " .. kind)
    if rejected then
        assert(controller.lastFailure ~= nil, "Expected rejection: " .. kind)
    else
        assert(controller.lastFailure == nil, tostring(controller.lastFailure))
    end
    task.wait()
end

local function cameraCorners(card)
    local handle = controller.view.models[card.viewport].handle
    local info = handle:inspect()
    assert(info.backend == "Blender" and info.loadState == "Ready", "Actual model unavailable")
    local camera = assert(card.viewport.CurrentCamera, "Missing preview camera")
    local size = card.viewport.AbsoluteSize
    local vertical = math.tan(math.rad(camera.FieldOfView / 2))
    local horizontal = vertical * size.X / size.Y
    local corners = 0
    for _, part in handle.model:GetDescendants() do
        if part:IsA("BasePart") and part.Transparency < 0.99 then
            for _, x in { -1, 1 } do
                for _, y in { -1, 1 } do
                    for _, z in { -1, 1 } do
                        local world =
                            part.CFrame:PointToWorldSpace(part.Size * Vector3.new(x, y, z) / 2)
                        local point = camera.CFrame:PointToObjectSpace(world)
                        local depth = -point.Z
                        assert(depth > 0, "Preview geometry crossed behind its camera")
                        assert(
                            math.abs(point.X) <= depth * horizontal * 1.02
                                and math.abs(point.Y) <= depth * vertical * 1.02,
                            card.card.Name .. " model clips its viewport"
                        )
                        corners += 1
                    end
                end
            end
        end
    end
    assert(corners > 0, "No rendered model geometry")
    report.cornerChecks += corners
    report.modelChecks += 1
end

local ok, failure = xpcall(function()
    assert(RunService:IsStudio() and game.GameId == 0, "Unpublished Studio fixture required")
    waitFor(function()
        -- selene: allow(global_usage)
        controller = shared.RBX031ShopPrototype
        return controller and controller.view and controller.run
    end, "RBX031 fixture initialization", 15)
    reset("standard")
    local view, run = controller.view, controller.run
    report.safeArea = { width = view.viewport.X, height = view.viewport.Y }
    inside(view.modal, view.root)
    for index, card in view.shop.cards do
        inside(card.card, view.modal)
        inside(card.inspect, card.card)
        inside(card.viewport, card.inspect)
        inside(card.name, card.inspect)
        inside(card.buy, card.card)
        touchControl(card.buy)
        separate(card.buy, card.inspect)
        if card.hold then
            inside(card.hold, card.card)
            touchControl(card.hold)
            separate(card.buy, card.hold)
        end
        for other = index + 1, #view.shop.cards do
            separate(card.card, view.shop.cards[other].card)
        end
    end
    for _, control in { view.shop.reroll, view.shop.rack, view.shop.continue } do
        inside(control, view.modal)
        touchControl(control)
    end
    if view.shop.preview then
        inside(view.shop.preview, view.shop.preview.Parent)
        inside(view.shop.detailBody, view.shop.detailBody.Parent)
        separate(view.shop.detailBody, view.shop.detailButton)
    end
    record(
        "Six offers, contained models/text, separate controls, 44px purchase/hold/footer targets"
    )
    for _ = 1, 3 do
        task.wait(0.08)
        for _, card in view.shop.cards do
            cameraCorners(card)
        end
    end
    record("Blender/Ready and visible model corner containment at three idle samples")

    local modal = view.modal
    local cameras = {}
    for index, card in view.shop.cards do
        cameras[index] = card.viewport.CurrentCamera
    end
    view.selectedOffer = 2
    view:_refreshShop(run:snapshot())
    for index, card in view.shop.cards do
        assert(card.viewport.CurrentCamera == cameras[index], "Selection rebuilt a shop model")
    end
    action("freeze", { offer = 2, itemId = run.shopOffers[2].id })
    assert(run.shopOffers[2].frozen, "Hold did not stick")
    for index, card in view.shop.cards do
        assert(card.viewport.CurrentCamera == cameras[index], "Hold rebuilt a shop model")
    end
    local before = run.coins
    action("buy", { offer = 1, itemId = "seed_bank" })
    assert(run.inventory[1].level == 3 and run.coins == before - 6, "Upgrade cost or level differs")
    assert(view.modal == modal, "Upgrade rebuilt the modal")
    for index = 2, 6 do
        assert(
            view.shop.cards[index].viewport.CurrentCamera == cameras[index],
            "Upgrade rebuilt an unchanged offer"
        )
    end
    record(
        "Selection/hold preserve cameras; six-coin Seed Bank upgrade reaches L3 with other cameras stable"
    )
    before = run.coins
    local slots = run.slots
    action("buy", { offer = 5, itemId = "reserve_pack" })
    assert(run.coins == before - 8 and run.reserves == 5, "Supply cost/effect differs")
    assert(
        run.slots == slots and #run.inventory == slots and run.inventory[4].id == "",
        "Supply consumed a rack slot"
    )
    record("Reserve Pack uses eight coins, restores balls, and consumes no rack slot")
    local heldId, heldPrice = run.shopOffers[2].id, run.shopOffers[2].price
    before = run.coins
    action("reroll")
    assert(run.coins == before - 1 and run.rerollsLeft == 0, "Reroll cost/count differs")
    local held
    for _, entry in run.shopOffers do
        if entry.frozen then
            held = entry
        end
    end
    assert(
        held and held.id == heldId and held.price == heldPrice,
        "Reroll lost held offer or price"
    )
    record("Reroll charges one coin and retains the held offer and price")

    reset("full")
    view, run = controller.view, controller.run
    before = run.coins
    assert(
        not view.shop.cards[2].buy.Active and not view.shop.cards[3].buy.Active,
        "Full/max buttons stayed enabled"
    )
    action("buy", { offer = 2, itemId = "aurora_kite" }, true)
    assert(run.coins == before and run.slots == 7, "Rejected full-rack purchase mutated resources")
    action("buy", { offer = 1, itemId = "seed_bank" })
    assert(
        run.inventory[1].level == 3 and run.coins == before - 6 and run.slots == 7,
        "Full rack blocked an owned upgrade"
    )
    record("Full rack blocks new items and capped items, but permits an owned upgrade")

    reset("evolution")
    run = controller.run
    before = run.coins
    action("buy", { offer = 1, itemId = "aurora_aquarium" })
    assert(run.coins == before, "Evolution charged coins")
    assert(
        run.inventory[1].id == "aurora_aquarium" and run.inventory[1].level == 5,
        "Evolution result differs"
    )
    assert(
        run.inventory[2].id == "" and run.inventory[3].id == "seed_bank",
        "Evolution did not consume exactly its two ingredients"
    )
    record("Free Aurora Aquarium consumes both L5 ingredients and frees their second slot")

    reset("standard")
    view, run = controller.view, controller.run
    view.shopRackOpen = true
    view:_layout()
    view:_updateModal()
    task.wait()
    assert(view.shop.drawer.Visible and view.inventory.Visible, "Rack drawer failed to open")
    inside(view.inventory, view.shop.drawer)
    for _, cell in view.itemSlots do
        inside(cell.button, view.inventory)
        inside(cell.viewport, cell.button)
    end
    for _, control in { view.shop.sell, view.shop.slot, view.shop.closeRack } do
        inside(control, view.shop.drawer)
        touchControl(control)
        separate(control, view.inventory)
    end
    before = run.coins
    action("buySlot")
    assert(run.slots == 6 and run.coins == before - 5, "Slot purchase differs")
    view.selectedSlot = 1
    view:_updateInventory()
    view:_updateModal()
    assert(view.shop.sell.Active, "Selected item cannot be sold")
    before = run.coins
    action("sell", { slot = 1 })
    assert(run.inventory[1].id == "" and run.coins == before + 3, "Sale refund/removal differs")
    record(
        "Rack drawer contains seven slots and actions; slot purchase and selected-item sale work"
    )
end, debug.traceback)

if not ok then
    report.failure = tostring(failure)
end
local restored, restoreFailure = pcall(function()
    if controller then
        controller.reset("standard")
        ready()
    end
end)
report.restoredStandard = restored and controller ~= nil
if not restored then
    report.restoreFailure = tostring(restoreFailure)
end
report.ok = ok and report.restoredStandard
report.elapsedSeconds = os.clock() - started
script:SetAttribute("Result", HttpService:JSONEncode(report))
if report.ok then
    print(
        "[RBX-031] PASS shop prototype audit: "
            .. #report.checks
            .. " checks; standard shop restored"
    )
else
    warn(
        "[RBX-031] FAIL shop prototype audit: " .. tostring(report.failure or report.restoreFailure)
    )
end
