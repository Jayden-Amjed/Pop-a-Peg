--!nonstrict
-- Opt-in structural/visibility audit for the annotated RBX-031 UI retouch.
-- Install only in the unpublished UI-PREVIEW Play Client. No profile/remotes are used.
local Http = game:GetService("HttpService")
local Catalog = require(game:GetService("ReplicatedStorage").Shared.Catalog)
local player = game:GetService("Players").LocalPlayer
local Theme = require(player.PlayerScripts.Client.UiTheme)
local started = os.clock()
local controller
local report = { ok = false, checks = {}, screens = {}, models = 0 }
script:SetAttribute("Result", Http:JSONEncode({ running = true }))

local function waitFor(predicate, message, limit)
    local deadline = math.min(started + 150, os.clock() + (limit or 10))
    repeat
        if predicate() then
            return
        end
        task.wait(0.04)
    until os.clock() >= deadline
    error("Retouch timeout: " .. message)
end

local function rect(object)
    local p, s = object.AbsolutePosition, object.AbsoluteSize
    return { x = p.X, y = p.Y, w = s.X, h = s.Y }
end

local function contains(a, b, margin)
    margin = margin or -1
    return a.x >= b.x + margin
        and a.y >= b.y + margin
        and a.x + a.w <= b.x + b.w - margin
        and a.y + a.h <= b.y + b.h - margin
end

local function inside(object, parent, margin)
    local a, b = rect(object), rect(parent)
    assert(a.w > 0 and a.h > 0, object:GetFullName() .. " has no rendered area")
    assert(contains(a, b, margin), object:GetFullName() .. " escaped " .. parent:GetFullName())
end

local function separate(a, b, message)
    a, b = rect(a), rect(b)
    assert(
        a.x + a.w <= b.x + 1 or b.x + b.w <= a.x + 1 or a.y + a.h <= b.y + 1 or b.y + b.h <= a.y + 1,
        message
    )
end

local function below(object, above, message)
    assert(
        object.AbsolutePosition.Y >= above.AbsolutePosition.Y + above.AbsoluteSize.Y - 1,
        message
    )
end

local function visible(object)
    while object and object ~= player.PlayerGui do
        if object:IsA("GuiObject") and not object.Visible then
            return false
        end
        if object:IsA("ScreenGui") and not object.Enabled then
            return false
        end
        object = object.Parent
    end
    return true
end

local function noBevel(root)
    for _, object in root:GetDescendants() do
        assert(
            not (object:IsA("GuiObject") and object.Name == "Bevel"),
            "Unaligned white bevel remains: " .. object:GetFullName()
        )
    end
end

local function modelBoxFor(viewport, card)
    for _, object in card:GetDescendants() do
        if
            object:IsA("Frame")
            and object.BackgroundTransparency < 1
            and visible(object)
            and contains(rect(viewport), rect(object))
            and contains(rect(object), rect(card), 2)
        then
            return object
        end
    end
    error("No inset model window in " .. card:GetFullName())
end

local function modelsReady()
    waitFor(function()
        local entries = controller.view and controller.view.models or controller.hub.models
        local ready = true
        for _, entry in entries do
            local info = entry.handle:inspect()
            assert(info.backend == "Blender", "Preview fell back to a native model")
            assert(info.loadState ~= "Failed", "A catalog model failed to load")
            ready = ready and info.loadState == "Ready"
        end
        return ready
    end, "Blender model loading", 20)
    for _ in controller.view and controller.view.models or controller.hub.models do
        report.models += 1
    end
end

local function choose(name)
    controller.select(name)
    waitFor(function()
        local host = controller.view or controller.hub
        return host and host.root.AbsoluteSize.X > 0 and (host.viewport or host.geometry)
    end, name .. " layout")
    task.wait(0.08)
    local host = controller.view or controller.hub
    noBevel(host.root)
    table.insert(report.screens, name)
    return host
end

local function passed(name)
    table.insert(report.checks, name)
end

local function detailCard(card, id, level, recipes)
    assert(card and card.frame.Visible, "Missing complete inspection card")
    local detail = Catalog.detail(id, level)
    assert(detail and card.name.Text == detail.name, "Inspection name does not match item")
    local lines = { { text = detail.trigger, tone = "trigger" } }
    for _, line in detail.effects do
        table.insert(lines, line)
    end
    local canvasH = card.frame.CanvasSize.Y.Offset
    local canvas = rect(card.frame)
    canvas.y -= card.frame.CanvasPosition.Y
    canvas.h = math.max(canvas.h, canvasH)
    local regions = { card.modelBox, card.nameBox }
    assert(card.viewport.Parent == card.modelBox, "Model escaped its inspection window")
    inside(card.viewport, card.modelBox, 2)
    below(card.nameBox, card.modelBox, "Inspection name should follow the model")
    for index, line in lines do
        local actual = card.rows[index]
        assert(actual and actual.box.Visible, "Inspection omitted an effect or trigger")
        assert(actual.text.Text == line.text, "Inspection changed catalog effect wording")
        assert(actual.text.TextColor3 == Theme.colors[line.tone], "Inspection lost effect tone")
        inside(actual.text, actual.box)
        assert(
            actual.text.TextBounds.Y <= actual.text.AbsoluteSize.Y + 1,
            "Inspection text clips vertically"
        )
        table.insert(regions, actual.box)
    end
    for index = #lines + 1, #card.rows do
        assert(not card.rows[index].box.Visible, "Stale effect row remains visible")
    end
    recipes = recipes or Catalog.evolutionsFor(id)
    assert(card.recipeBox.Visible == (#recipes > 0), "Recipe compartment visibility is wrong")
    if #recipes > 0 then
        table.insert(regions, card.recipeBox)
        local equationCount = 0
        for index, row in card.evolutions.rows do
            if row.boxes[1].Visible then
                equationCount += 1
                local recipe = recipes[index]
                assert(recipe, "Unexpected stale recipe")
                local expected = { recipe.ingredients[1], recipe.ingredients[2], recipe.id }
                for column, box in row.boxes do
                    assert(row.ids[column] == expected[column], "Recipe model order is wrong")
                    inside(box, card.recipeBox)
                    inside(row.viewports[column], box)
                    assert(row.statuses[column].Text ~= "", "Recipe readiness is missing")
                end
                assert(
                    row.symbols[1].Text == "+" and row.symbols[2].Text == "=",
                    "Recipe equation operators missing"
                )
            end
        end
        assert(equationCount == #recipes, "Inspection omitted an evolution recipe")
    end
    for index, object in regions do
        assert(contains(rect(object), canvas), "Detail content escaped its scrollable canvas")
        for other = index + 1, #regions do
            separate(object, regions[other], "Inspection compartments overlap")
        end
    end
    if card.layout.contentHeight > card.frame.AbsoluteSize.Y + 1 then
        assert(card.frame.ScrollingEnabled, "Long inspection content cannot be reached")
        local previous = card.frame.CanvasPosition
        card.frame.CanvasPosition = Vector2.new(0, canvasH - card.frame.AbsoluteSize.Y)
        task.wait(0.05)
        assert(card.frame.CanvasPosition.Y > 0, "Inspection scroll did not move")
        card.frame.CanvasPosition = previous
    end
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
    local view = choose("Aim")
    local root = view.root
    report.width, report.height = root.AbsoluteSize.X, root.AbsoluteSize.Y
    local desktop = not view.compact
    inside(view.controls, root)
    inside(view.speedGroup, root)
    inside(view.soundButton, root)
    assert(
        view.soundButton.AbsoluteSize.X >= 43.5 and view.soundButton.AbsoluteSize.Y >= 43.5,
        "Music toggle is below touch size"
    )
    assert(view.controls.BackgroundTransparency < 1, "Launch/Jumble lack a containing panel")
    assert(view.speedGroup.BackgroundTransparency < 1, "Speed dials lack a containing panel")
    for _, control in { view.primary, view.jumbleButton } do
        inside(control, view.controls)
        assert(
            control.AbsoluteSize.X >= 43.5 and control.AbsoluteSize.Y >= 43.5,
            "Primary action is below touch size"
        )
    end
    for index, speed in view.speedButtons do
        inside(speed, view.speedGroup)
        assert(
            speed.AbsoluteSize.X >= 43.5 and speed.AbsoluteSize.Y >= 43.5,
            "Speed action is below touch size"
        )
        for other = index + 1, #view.speedButtons do
            separate(speed, view.speedButtons[other], "Speed targets overlap")
        end
    end
    separate(view.controls, view.speedGroup, "Primary actions overlap speed dials")
    separate(view.soundButton, view.controls, "Music toggle overlaps primary actions")
    separate(view.soundButton, view.speedGroup, "Music toggle overlaps speed dials")
    inside(view.quota, view.scorePlate)
    inside(view.progress, view.scorePlate)
    separate(view.quota, view.progress, "Target quota overlaps score progress meter")
    passed("Score target and meter remain readable")
    if view.shortWide and not view.foldHud then
        for _, panel in
            { view.inventory, view.wallet, view.reservePlate, view.scorePlate, view.perksPanel }
        do
            inside(panel, root)
            for _, controls in { view.controls, view.speedGroup, view.soundButton } do
                separate(panel, controls, "Medium landscape HUD overlaps controls")
            end
        end
        passed("Medium landscape controls stay touch-sized and clear of HUD")
    end
    local rackSizes = {}
    for index, cell in view.itemSlots do
        rackSizes[index] = cell.viewport.AbsoluteSize
    end
    if desktop then
        assert(
            math.abs(
                view.controls.AbsolutePosition.X
                    + view.controls.AbsoluteSize.X / 2
                    - root.AbsolutePosition.X
                    - root.AbsoluteSize.X / 2
            ) <= 1,
            "Primary action panel is not centered on screen"
        )
        local panels = {
            view.wallet,
            view.reservePlate,
            view.statsPanel,
            view.roundPlate,
            view.scorePlate,
            view.restockPlate,
            view.perksPanel,
        }
        for index, panel in panels do
            inside(panel, root)
            below(panel, view.inventory, "Side HUD runs into the rack")
            assert(
                panel.AbsolutePosition.Y + panel.AbsoluteSize.Y
                    <= view.speedGroup.AbsolutePosition.Y + 1,
                "Side HUD runs into bottom controls"
            )
            for other = index + 1, #panels do
                separate(panel, panels[other], "Side HUD panels overlap")
            end
        end
        assert(
            view.speedGroup.AbsolutePosition.X > root.AbsolutePosition.X + root.AbsoluteSize.X / 2,
            "Speed group is not on the right"
        )
    end
    assert(view.soundSlash, "Music mute slash missing")
    local muted = view.muted
    view.muted = true
    view:_renderControls()
    assert(view.soundSlash.Visible, "Muted icon does not show its slash")
    view.muted = false
    view:_renderControls()
    assert(not view.soundSlash.Visible, "Unmuted icon still has a slash")
    assert(
        not view.soundButton.Text:match("SOUND") and not view.soundButton.Text:match("OFF"),
        "Old text sound tab remains"
    )
    view.muted = muted
    view:_renderControls()
    modelsReady()
    passed("Aim groups, side HUD, and mute presentation")

    for _, name in { "Perks", "Event" } do
        view = choose(name)
        local subtitle = view.modal:FindFirstChild("Subtitle")
        assert(
            not subtitle or not subtitle.Visible or subtitle.Text == "",
            "Combo subtitle remains"
        )
        if desktop then
            for index, cell in view.itemSlots do
                assert(
                    (cell.viewport.AbsoluteSize - rackSizes[index]).Magnitude <= 1,
                    "Rack model shrinks during " .. name
                )
            end
        end
        local choices = 0
        for _, card in view.modal.Content:GetChildren() do
            if card:IsA("Frame") and card.Name:match("^Choice") then
                choices += 1
                local model = assert(card:FindFirstChild("Reward", true))
                local title = assert(card:FindFirstChild("Name", true))
                local chooseButton = assert(card:FindFirstChild("Choose", true))
                local effect = assert(card:FindFirstChild("Effect", true))
                inside(card, view.modal.Content)
                inside(chooseButton, card)
                local well = modelBoxFor(model, card)
                below(well, title, "Choice name should be above its model")
                below(chooseButton, well, "Choose action covers the model")
                separate(effect, well, "Choice effect covers model")
                separate(effect, chooseButton, "Choice effect covers action")
                assert(chooseButton.AbsoluteSize.Y >= 43.5, "Choice target below44px")
            end
        end
        assert(choices == 2, "Missing choice card")
        modelsReady()
        passed(name .. " card compartments and rack continuity")
    end

    view = choose("Shop")
    local shop = view.shop
    assert(shop and #shop.cards == 6, "Fixture must include equipment and Supplies")
    assert(not view.modal:FindFirstChild("InspectHint", true), "Tap-for-details hint remains")
    assert(shop.detailButton == nil, "Secondary all-details button remains")
    local coin = assert(shop.wallet.Parent:FindFirstChild("Coin"))
    assert(
        coin.AbsolutePosition.X >= shop.wallet.AbsolutePosition.X + shop.wallet.AbsoluteSize.X - 1,
        "Wallet coin is not after its number"
    )
    for index, cell in shop.cards do
        inside(cell.card, view.modal)
        inside(cell.modelBox, cell.card, 3)
        inside(cell.viewport, cell.modelBox)
        inside(cell.buy, cell.card)
        separate(cell.modelBox, cell.buy, "Purchase covers item window")
        if index > 4 then
            inside(cell.nameBox, cell.card)
            inside(cell.priceBox, cell.card)
            assert(
                cell.nameBox.AbsolutePosition.X
                    >= cell.modelBox.AbsolutePosition.X + cell.modelBox.AbsoluteSize.X - 1,
                "Supply name is not beside its model"
            )
            below(cell.priceBox, cell.nameBox, "Supply price is not below its name")
            below(cell.buy, cell.nameBox, "Supply Use is not below its name")
            separate(cell.priceBox, cell.buy, "Supply price overlaps Use")
        end
        if cell.price and cell.price.Visible and cell.priceCoin and cell.priceCoin.Visible then
            assert(
                cell.priceCoin.AbsolutePosition.X
                    >= cell.price.AbsolutePosition.X + cell.price.AbsoluteSize.X - 1,
                "Item price coin is not after its number"
            )
        end
    end
    if shop.detailCard then
        local offer = view.snapshot.shopOffers[view.selectedOffer or 1]
        detailCard(shop.detailCard, offer.id, view:_offerLevel(offer))
    end
    local recipeId, maxRecipes, effectId, maxEffects = nil, -1, nil, -1
    for _, ids in { Catalog.ItemIds, Catalog.EvolvedIds } do
        for _, id in ids do
            local data = Catalog.detail(id, 4)
            local count = #Catalog.evolutionsFor(id)
            if count > maxRecipes then
                recipeId, maxRecipes = id, count
            end
            if #data.effects > maxEffects then
                effectId, maxEffects = id, #data.effects
            end
        end
    end
    for _, id in { recipeId, effectId } do
        view.inspector:show(id, 4, view.modal, true)
        task.wait(0.08)
        inside(view.inspector.panel, view.root)
        detailCard(view.inspector.card, id, 4)
        modelsReady()
        view.inspector:hide()
    end
    report.largestRecipeCount, report.largestEffectCount = maxRecipes, maxEffects
    modelsReady()
    passed("Shop insets, Supplies, trailing coins, complete inspection")

    local hub = choose("Recipe")
    local recipe
    for _, entry in Catalog.Evolutions do
        if entry.id == hub.selected then
            recipe = entry
            break
        end
    end
    assert(recipe, "Selected gallery recipe missing")
    detailCard(hub.recipeDetail, recipe.id, Catalog.MaxLevel, { recipe })
    assert(hub.back.Visible and hub.back.Active, "Return to gallery unavailable")
    inside(hub.back, hub.panel)
    assert(hub.back.AbsoluteSize.Y >= 43.5, "Gallery return target below44px")
    modelsReady()
    passed("Gallery recipe uses complete item detail with return")

    hub = choose("Workshop")
    local cards = 0
    for _, card in hub.body:GetChildren() do
        if card.Name:match("^Unlock_") then
            cards += 1
            local name = assert(card:FindFirstChild("Name"))
            local model = assert(card:FindFirstChildWhichIsA("ViewportFrame"))
            inside(name, card)
            inside(model, card)
            below(model, name, "Workshop name is not above the model")
        end
    end
    assert(cards > 0, "Workshop cards missing")
    modelsReady()
    passed("Workshop names above model windows")

    for _, name in
        {
            "Defeat",
            "Victory",
            "Arcade",
            "Collection",
            "Records",
            "Help",
            "Chests",
            "Rankings",
            "Crew",
        }
    do
        choose(name)
    end
    passed("Shared highlight cleanup across all15 screens")
end, debug.traceback)

report.ok = ok
if not ok then
    report.failure = tostring(failure)
end
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
report.elapsedSeconds = os.clock() - started
script:SetAttribute("Result", Http:JSONEncode(report))
if report.ok then
    print("[RBX-031] PASS annotated UI retouch audit: " .. #report.checks .. " groups")
else
    warn(
        "[RBX-031] FAIL annotated UI retouch audit: "
            .. tostring(report.failure or report.restoreFailure)
    )
end
