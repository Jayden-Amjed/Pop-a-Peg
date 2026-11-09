--!nonstrict
-- Opt-in unpublished UI-PREVIEW audit. Calls presentation APIs, never input or remotes.
local Http = game:GetService("HttpService")
local Catalog = require(game:GetService("ReplicatedStorage").Shared.Catalog)
local Theme = require(game:GetService("Players").LocalPlayer.PlayerScripts.Client.UiTheme)
local C = Theme.colors
local started, controller, reference = os.clock(), nil, nil
local report = {
    ok = false,
    screens = {},
    surfaces = 0,
    targets = 0,
    blockedAnchors = 0,
    rackCases = {},
    explicitDetails = 0,
    semanticColors = 0,
    tones = { positive = 0, negative = 0, trigger = 0 },
}
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
            return color == C.gold and ((cell.flash or 0) > 0 or host.selectedSlot == index)
                or color == C.aqua and host.selectedSlot == index
        end
    end
    for id, cell in host.perkCells or {} do
        if object == cell.button then
            return color == C.gold and ((cell.flash or 0) > 0 or host.selectedPerk == id)
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
    if host.progression and color == C.aqua then
        local panel = host.progression
        if host.openPanel == "chests" and panel.mode == "chests" then
            if object == host.body:FindFirstChild("Tier_" .. panel.tier) then
                return true
            end
        elseif host.openPanel == "leaderboards" then
            if object == host.body:FindFirstChild("Board_" .. panel.category) then
                return true
            end
        end
    end
    for index, row in host.rosterRows or {} do
        if object == row.card then
            return color == C.aqua
                and host.openPanel == "crew"
                and index == host.snapshot.hub.station
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
    local base = object:GetAttribute("SurfaceColor")
    assert(typeof(base) == "Color3", "Surface lost its intended color: " .. object:GetFullName())
    assert(
        object.BackgroundColor3 == (disabled and Color3.fromRGB(191, 210, 217) or base),
        "Surface lost its semantic or disabled color: " .. object:GetFullName()
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

local function semanticSurface(host, object, expected)
    surface(host, object, true)
    assert(
        object:GetAttribute("SurfaceColor") == expected,
        "Wrong semantic surface color: " .. object:GetFullName()
    )
    report.semanticColors += 1
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

local function detailSurfaces(host, card, referenceRecipe)
    assert(card, "Shared inspection card missing")
    for _, object in { card.modelBox, card.nameBox, card.recipeBox } do
        surface(host, object, true)
    end
    semanticSurface(host, card.nameBox, C.aqua)
    local lines = { { text = card.detail.trigger, tone = "trigger" } }
    for _, line in card.detail.effects do
        table.insert(lines, line)
    end
    assert(#card.rows >= #lines, "Inspection omitted semantic text rows")
    for index, row in card.rows do
        surface(host, row.box, true)
        local line = lines[index]
        if line then
            assert(
                row.box.Visible
                    and row.text.Text == line.text
                    and row.text.TextColor3 == (C[line.tone] or C.ink),
                "Inspection lost trigger/benefit/cost text color"
            )
            if report.tones[line.tone] then
                report.tones[line.tone] += 1
            end
        end
    end
    local equations = 0
    for _, row in card.evolutions.rows do
        local state = host.snapshot or {}
        local status = row.ids[3]
            and Catalog.evolutionState(state.inventory or {}, state.slots or 0, row.ids[3])
        for column, box in row.boxes do
            surface(host, box, true)
            if status then
                local ready = referenceRecipe or (status.levels[column] or 0) >= Catalog.MaxLevel
                local color = column == 3 and C.gold:Lerp(C.paper, 0.7)
                    or ready and C.mint:Lerp(C.paper, 0.78)
                    or C.paper
                semanticSurface(host, box, color)
                assert(
                    box:FindFirstChildWhichIsA("UIStroke").Color == C.ink,
                    "Evolution state replaced the navy outline"
                )
            end
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
    return full
end

local function explicitDetails(view, full)
    -- Compact layouts put owned perks inside STATS. A hidden anchor correctly
    -- closes its inspector, so expose the real drawer before testing selection.
    local wasOpen, previousTab = view.detailsOpen, view.detailsTabMode
    view.detailsOpen, view.detailsTabMode = true, "perks"
    view:_layout()
    task.wait(0.05)
    local inspector, perkId = view.inspector, view.snapshot.perks[1]
    local anchor = assert(view.perkCells[perkId]).button
    local parent = anchor
    while parent and parent ~= view.root do
        assert(not parent:IsA("GuiObject") or parent.Visible, "Explicit detail anchor is hidden")
        parent = parent.Parent
    end
    assert(parent == view.root, "Explicit detail anchor is detached")
    assert(not inspector.rackAnchors[anchor], "Explicit detail case uses a rack anchor")
    assert(inspector.resolvers[anchor]() == perkId, "Explicit perk binding cannot resolve its item")
    inspector:show(perkId, 1, anchor, true)
    task.wait(0.05)
    assert(
        inspector.panel.Visible
            and inspector.pinned
            and inspector.close.Visible
            and (inspector.panel.AbsoluteSize - full).Magnitude <= 1,
        "Explicit non-rack details lost the full reading area"
    )
    inside(inspector.panel, view.root)
    report.explicitDetails += 1
    inspector:hide()
    view.detailsOpen, view.detailsTabMode = wasOpen, previousTab
    view:_layout()
end

local function gameplayColors(view)
    semanticSurface(view, view.primary, C.mint)
    semanticSurface(view, view.jumbleButton, C.aqua)
    for _, title in { view.statsTitle, view.scoreCaption, view.restockCaption } do
        semanticSurface(view, title, C.aqua)
    end
    -- Render an active flight without sending actions or advancing the run.
    local original = view.snapshot
    local flight = table.clone(original)
    flight.phase, flight.ball = "flight", { active = true }
    view.snapshot = flight
    view:_renderControls()
    assert(view.primary.Text == "END SHOT" and view.primary.Active, "Flight action is unavailable")
    semanticSurface(view, view.primary, C.gold)
    view.snapshot = original
    view:_renderControls()
    semanticSurface(view, view.primary, C.mint)
    view.inspector:show("gain_dial", 1, view.itemSlots[1].button, true)
    detailSurfaces(view, view.inspector.card)
    view.inspector:hide()
end

local function shopColors(view)
    local shop = view.shop
    semanticSurface(view, shop.title.Parent, C.aqua)
    semanticSurface(view, shop.continue.Skin, C.mint)
    assert(shop.continue.Active, "Shop continuation must retain its active color")
    for index, cell in shop.cards do
        semanticSurface(view, cell.nameBox, C.aqua)
        semanticSurface(view, cell.buy.Skin, C.mint)
        local selected = view.selectedOffer or (shop.preview and 1)
        semanticSurface(view, cell.card, index == selected and C.ice or C.paper)
        if cell.hold then
            semanticSurface(view, cell.hold.Skin, C.ice)
        end
    end
    -- Exercise held and unaffordable rendering with a display-only snapshot.
    local original = view.snapshot
    local held = table.clone(original)
    held.shopOffers = table.clone(original.shopOffers)
    held.shopOffers[1] = table.clone(original.shopOffers[1])
    held.shopOffers[1].frozen, held.coins = true, 0
    view.snapshot = held
    view:_refreshShop(held)
    semanticSurface(view, shop.cards[1].hold.Skin, C.gold)
    assert(shop.cards[1].hold.Active, "Holding an unsold item became disabled")
    semanticSurface(view, shop.cards[1].buy.Skin, C.mint)
    assert(not shop.cards[1].buy.Active, "Unaffordable item did not enter disabled state")
    view.snapshot = original
    view:_refreshShop(original)
    semanticSurface(view, shop.cards[1].hold.Skin, C.ice)
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
                local full = rackSizing(host, "Aim")
                explicitDetails(host, full)
                gameplayColors(host)
            elseif name == "Shop" then
                local shop = host.shop
                surface(host, shop.title.Parent, true)
                assert(
                    shop.title.TextColor3 == C.paper and shop.title.TextStrokeTransparency < 1,
                    "Shop title lost its contrasting text/outline"
                )
                shopColors(host)
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
                semanticSurface(host, host.modal.Title, C.aqua)
                if name == "Perks" or name == "Event" then
                    local choices = 0
                    for _, card in host.modal.Content:GetChildren() do
                        if card.Name:match("^Choice%d+$") then
                            choices += 1
                            for _, key in { "Name", "ModelBox", "EffectBox1", "Choose" } do
                                surface(host, card:FindFirstChild(key), true)
                            end
                            semanticSurface(host, card:FindFirstChild("Name"), C.aqua)
                            semanticSurface(host, card.Choose, C.mint)
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
            semanticSurface(host, host.play, C.mint)
            semanticSurface(host, host.wallet, C.gold)
            semanticSurface(host, host.titleBand, C.aqua)
            if name == "Recipe" then
                assert(
                    detailSurfaces(host, host.recipeDetail, true) >= 3,
                    "Recipe equation styles untested"
                )
            elseif name == "Collection" or name == "Workshop" then
                local cards = 0
                for _, card in host.body:GetChildren() do
                    if card.Name:match("^Evolution_") or card.Name:match("^Unlock_") then
                        surface(host, card, true)
                        semanticSurface(host, card:FindFirstChild("NameBand"), C.aqua)
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
    for tone, count in report.tones do
        assert(count > 0, "Missing semantic text coverage: " .. tone)
    end
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
