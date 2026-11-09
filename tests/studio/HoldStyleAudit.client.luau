--!nonstrict
-- Opt-in unpublished UI-PREVIEW audit. Calls presentation APIs, never input or remotes.
local Http = game:GetService("HttpService")
local Theme = require(game:GetService("Players").LocalPlayer.PlayerScripts.Client.UiTheme)
local C = Theme.colors
local started, controller, reference = os.clock(), nil, nil
local report =
    { ok = false, screens = {}, surfaces = 0, targets = 0, blockedAnchors = 0, rackCases = {} }
script:SetAttribute("Result", Http:JSONEncode({ running = true }))

local function waitFor(predicate, message)
    local deadline = math.min(started + 120, os.clock() + 8)
    repeat
        if predicate() then
            return
        end
        task.wait(0.04)
    until os.clock() >= deadline
    error("Hold style timeout: " .. message)
end

local function inside(object, parent)
    local p, s, origin, size =
        object.AbsolutePosition, object.AbsoluteSize, parent.AbsolutePosition, parent.AbsoluteSize
    assert(s.X > 0 and s.Y > 0, "Empty inspection region")
    assert(
        p.X >= origin.X - 1
            and p.Y >= origin.Y - 1
            and p.X + s.X <= origin.X + size.X + 1
            and p.Y + s.Y <= origin.Y + size.Y + 1,
        "Inspection escaped the safe root"
    )
end

local function selectScreen(name)
    controller.select(name)
    waitFor(function()
        local host = controller.view or controller.hub
        return host and host.root.AbsoluteSize.X > 0 and (host.viewport or host.geometry)
    end, name)
    task.wait(0.08)
    return controller.view or controller.hub
end

local function matchingGradient(actual)
    local a, b = actual.Color.Keypoints, reference.gradient.Color.Keypoints
    assert(
        actual.Rotation == reference.gradient.Rotation and #a == #b,
        "Surface lost Hold gradient"
    )
    for index, point in a do
        assert(
            point.Time == b[index].Time and point.Value == b[index].Value,
            "Surface uses a different gradient from Hold"
        )
    end
end

local function stateOutline(host, object, color)
    if color == C.ink then
        return true
    end
    for index, cell in host.itemSlots or {} do
        if object == cell.button then
            return color == C.gold and (cell.flash or 0) > 0
                or color == C.aqua and host.selectedSlot == index
        end
    end
    for id, cell in host.perkCells or {} do
        if object == cell.button then
            return color == C.gold and (cell.flash or 0) > 0
                or color == C.aqua and host.selectedPerk == id
        end
    end
    for index, speed in host.speedButtons or {} do
        if object == speed then
            return color == C.aqua and (host.snapshot.speed or 1) == ({ 1, 2, 4 })[index]
        end
    end
    if host.shop then
        for index, cell in host.shop.cards do
            if object == cell.card then
                return color == C.aqua
                    and (host.selectedOffer or (host.shop.preview and 1)) == index
            elseif cell.hold and object == cell.hold.Skin then
                local offer = host.snapshot.shopOffers[index]
                return color == C.aqua and offer.frozen == true and not offer.sold
            end
        end
    end
    return false
end

local function surface(host, object, targeted)
    assert(object and object:IsA("GuiObject"), "Required styled surface is missing")
    assert(
        object:GetAttribute("PearlSurface") == true,
        "Unstyled surface: " .. object:GetFullName()
    )
    local disabled = object:IsA("GuiButton") and not object.Active
        or object.Parent:IsA("GuiButton") and not object.Parent.Active
    assert(
        object.BackgroundColor3 == reference.base
            or disabled and object.BackgroundColor3 == Color3.fromRGB(191, 210, 217),
        "Surface lost Hold's pale base: " .. object:GetFullName()
    )
    matchingGradient(assert(object:FindFirstChildWhichIsA("UIGradient")))
    local outline = assert(object:FindFirstChildWhichIsA("UIStroke"))
    assert(
        stateOutline(host, object, outline.Color),
        "Non-state outline is not ink: " .. object:GetFullName()
    )
    assert(
        outline.ApplyStrokeMode == Enum.ApplyStrokeMode.Border and outline.Thickness >= 2,
        "Surface outline is missing or applied to text"
    )
    local round = assert(object:FindFirstChildWhichIsA("UICorner"))
    local depth = assert(object:FindFirstChild("Depth"))
    assert(
        depth.BackgroundColor3 == C.ink
            and depth.BackgroundTransparency == reference.depth.BackgroundTransparency
            and depth.Position == reference.depth.Position
            and depth.Size == reference.depth.Size
            and depth.ZIndex < object.ZIndex,
        "Surface lost its contained offset depth"
    )
    assert(
        depth:FindFirstChildWhichIsA("UICorner").CornerRadius == round.CornerRadius,
        "Depth corners no longer follow the surface"
    )
    if targeted then
        report.targets += 1
    else
        report.surfaces += 1
    end
end

local function scan(host)
    for _, object in host.root:GetDescendants() do
        assert(
            not (object:IsA("GuiObject") and object.Name == "Bevel"),
            "White Bevel strip remains"
        )
        if object:GetAttribute("PearlSurface") then
            surface(host, object, false)
        end
    end
end

local function detailSurfaces(host, card)
    assert(card, "Shared inspection card missing")
    for _, object in { card.modelBox, card.nameBox, card.recipeBox } do
        surface(host, object, true)
    end
    for _, row in card.rows do
        surface(host, row.box, true)
    end
    local equations = 0
    for _, row in card.evolutions.rows do
        for _, box in row.boxes do
            surface(host, box, true)
            equations += 1
        end
    end
    return equations
end

local function rackRegistry(view)
    local inspector, expected, count = view.inspector, {}, 0
    for _, slot in view.itemSlots do
        expected[slot.button] = true
        assert(inspector.rackAnchors[slot.button] == true, "Rack slot lost passive inspection")
    end
    for anchor, enabled in inspector.rackAnchors do
        assert(enabled == true and expected[anchor], "Non-rack element gained passive inspection")
        count += 1
    end
    assert(count == 7, "Passive hover registry must contain exactly seven rack slots")
    local function reject(anchor)
        inspector:hide()
        inspector:show("goldfish", 1, anchor, false)
        assert(not inspector.panel.Visible, "Non-rack passive inspection opened")
        report.blockedAnchors += 1
    end
    for anchor in inspector.resolvers do
        if not expected[anchor] then
            reject(anchor)
        end
    end
    reject(view.coinModel) -- Unbound UI must not bypass the show() guard either.
    if view.shop then
        for _, cell in view.shop.cards do
            reject(cell.inspect)
        end
    end
end

local function rackSizing(view, label)
    local inspector, slot = view.inspector, view.itemSlots[1].button
    local id, level = inspector.resolvers[slot]()
    assert(id, "Occupied rack slot cannot resolve its inspection item")
    inspector:show(id, level, slot, true)
    task.wait(0.05)
    assert(
        inspector.panel.Visible and inspector.pinned and inspector.close.Visible,
        "Pinned detail did not open"
    )
    inside(inspector.panel, view.root)
    inside(inspector.close, inspector.panel)
    assert(
        inspector.close.AbsoluteSize.X >= 43.5 and inspector.close.AbsoluteSize.Y >= 43.5,
        "Pinned close target shrank below44px"
    )
    local full = inspector.panel.AbsoluteSize
    local perkId = view.snapshot.perks[1]
    local explicitAnchor = assert(view.perkCells[perkId]).button
    inspector:show(perkId, 1, explicitAnchor, true)
    task.wait(0.05)
    assert(
        inspector.panel.Visible
            and inspector.pinned
            and inspector.close.Visible
            and (inspector.panel.AbsoluteSize - full).Magnitude <= 1,
        "Explicit non-rack details lost the full reading area"
    )
    inspector:show(id, level, slot, false)
    task.wait(0.05)
    assert(inspector.panel.Visible and not inspector.pinned, "Rack passive inspection did not open")
    inside(inspector.panel, view.root)
    local small = inspector.panel.AbsoluteSize
    assert(
        math.abs(small.X - full.X * 0.6) <= 1 and math.abs(small.Y - full.Y * 0.6) <= 1,
        "Passive rack card is not40% smaller"
    )
    detailSurfaces(view, inspector.card)
    inspector:show(id, level, slot, true)
    task.wait(0.05)
    assert(
        (inspector.panel.AbsoluteSize - full).Magnitude <= 1 and inspector.close.Visible,
        "Pinning did not restore full detail size"
    )
    table.insert(
        report.rackCases,
        { name = label, full = { full.X, full.Y }, passive = { small.X, small.Y } }
    )
    inspector:hide()
end

local ok, failure = xpcall(function()
    assert(
        game:GetService("RunService"):IsStudio() and game.GameId == 0,
        "Use an unpublished preview"
    )
    waitFor(function()
        -- selene: allow(global_usage)
        controller = shared.RBX031UiPreview
        return controller ~= nil
    end, "UI preview fixture")
    controller.toolbar.Enabled = false
    local shopView = selectScreen("Shop")
    local hold = shopView.shop.cards[1].hold.Skin
    reference = {
        base = hold.BackgroundColor3,
        gradient = assert(hold:FindFirstChildWhichIsA("UIGradient")):Clone(),
        depth = assert(hold:FindFirstChild("Depth")):Clone(),
    }
    assert(
        reference.base == C.ice and hold:FindFirstChildWhichIsA("UIStroke").Color == C.ink,
        "Fixture needs an ordinary unselected Hold reference"
    )
    for _, name in controller.screens do
        local host = selectScreen(name)
        if controller.view then
            rackRegistry(host)
            for _, object in
                {
                    host.wallet,
                    host.reservePlate,
                    host.statsTitle,
                    host.scoreCaption,
                    host.restockCaption,
                    host.controls,
                    host.primary,
                    host.jumbleButton,
                    host.speedGroup,
                    host.soundButton,
                }
            do
                surface(host, object, true)
            end
            if name == "Aim" then
                rackSizing(host, "Aim")
            elseif name == "Shop" then
                local shop = host.shop
                surface(host, shop.title.Parent, true)
                assert(shop.title.TextColor3 == C.ink, "Shop title lacks contrast on Hold surface")
                for _, cell in shop.cards do
                    for _, object in
                        { cell.card, cell.modelBox, cell.nameBox, cell.priceBox, cell.buy.Skin }
                    do
                        surface(host, object, true)
                    end
                    if cell.hold then
                        surface(host, cell.hold.Skin, true)
                    end
                end
                if shop.detailCard then
                    detailSurfaces(host, shop.detailCard)
                end
                host.shopRackOpen = true
                host:_layout()
                host:_updateModal()
                task.wait(0.05)
                assert(
                    host.inventory.Visible and host.shop.drawer.Visible,
                    "Shop rack drawer did not open"
                )
                rackSizing(host, "Shop drawer")
                host.shopRackOpen = false
                host:_layout()
                host:_updateModal()
            else
                surface(host, host.modal.Title, true)
                if name == "Perks" or name == "Event" then
                    local choices = 0
                    for _, card in host.modal.Content:GetChildren() do
                        if card.Name:match("^Choice%d+$") then
                            choices += 1
                            for _, key in { "Name", "ModelBox", "EffectBox1", "Choose" } do
                                surface(host, card:FindFirstChild(key), true)
                            end
                            if name == "Perks" then
                                surface(host, card.TriggerBox, true)
                            end
                        end
                    end
                    assert(choices == 2, "Choice style coverage missing")
                end
            end
        else
            for _, object in { host.brand, host.wallet, host.dock, host.panel, host.titleBand } do
                surface(host, object, true)
            end
            if name == "Recipe" then
                assert(
                    detailSurfaces(host, host.recipeDetail) >= 3,
                    "Recipe equation styles untested"
                )
            elseif name == "Collection" or name == "Workshop" then
                local cards = 0
                for _, card in host.body:GetChildren() do
                    if card.Name:match("^Evolution_") or card.Name:match("^Unlock_") then
                        surface(host, card, true)
                        surface(host, card:FindFirstChild("NameBand"), true)
                        cards += 1
                    end
                end
                assert(cards > 0, "Gallery/workshop name-band coverage missing")
            end
        end
        scan(host)
        table.insert(report.screens, name)
    end
    assert(#report.screens == 15, "Expected all15 UI screens")
end, debug.traceback)
report.ok, report.failure = ok, not ok and tostring(failure) or nil
local restored, restoreFailure = pcall(function()
    if controller then
        controller.select("Aim")
        controller.toolbar.Enabled = true
    end
end)
report.restored = restored
if not restored then
    report.ok, report.restoreFailure = false, tostring(restoreFailure)
end
if reference then
    reference.gradient:Destroy()
    reference.depth:Destroy()
end
report.elapsedSeconds = os.clock() - started
script:SetAttribute("Result", Http:JSONEncode(report))
if report.ok then
    print("[RBX-031] PASS Hold surfaces and rack-only passive inspection")
else
    warn("[RBX-031] FAIL Hold style audit: " .. tostring(report.failure or report.restoreFailure))
end
