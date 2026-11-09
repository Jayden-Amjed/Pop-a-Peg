--!nonstrict
-- Opt-in audit installed in the UI preview Play Client, never production-mapped.
local Http = game:GetService("HttpService")
local started = os.clock()
local controller
local report = { ok = false, screens = {}, actions = {}, modelSamples = 0 }
script:SetAttribute("Result", Http:JSONEncode({ running = true }))
local function waitFor(predicate, message, limit)
    local deadline = math.min(started + 120, os.clock() + (limit or 8))
    repeat
        if predicate() then
            return
        end
        task.wait(0.04)
    until os.clock() >= deadline
    error("UI preview timeout: " .. message)
end
local function inside(object, parent)
    local p, s, pp, ps =
        object.AbsolutePosition, object.AbsoluteSize, parent.AbsolutePosition, parent.AbsoluteSize
    assert(s.X > 0 and s.Y > 0, object:GetFullName() .. " has no rendered area")
    assert(
        p.X >= pp.X - 1
            and p.Y >= pp.Y - 1
            and p.X + s.X <= pp.X + ps.X + 1
            and p.Y + s.Y <= pp.Y + ps.Y + 1,
        object:GetFullName() .. " escaped " .. parent:GetFullName()
    )
end
local function activeRoot()
    return controller.view and controller.view.root or controller.hub and controller.hub.root
end
local function chooseScreen(name)
    controller.select(name)
    waitFor(function()
        local root = activeRoot()
        return root
            and root.AbsoluteSize.X > 0
            and (
                controller.view and controller.view.viewport
                or controller.hub and controller.hub.geometry
            )
    end, name .. " initialization")
    task.wait(0.05)
end
local function action(kind, payload)
    local count = controller.actions
    controller.send(kind, payload or {})
    waitFor(function()
        return controller.actions > count
    end, kind)
    assert(controller.lastFailure == nil, tostring(controller.lastFailure))
    table.insert(report.actions, kind)
end
local function modelsReady()
    waitFor(function()
        local models = controller.view and controller.view.models or controller.hub.models
        local ready = true
        for _, entry in models do
            local info = entry.handle:inspect()
            assert(info.backend == "Blender", "UI preview used a model fallback")
            assert(info.loadState ~= "Failed", "UI model loading failed")
            ready = ready and info.loadState == "Ready"
        end
        return ready
    end, "Blender models", 20)
    for _ in controller.view and controller.view.models or controller.hub.models do
        report.modelSamples += 1
    end
end
local ok, failure = xpcall(function()
    assert(
        game:GetService("RunService"):IsStudio() and game.GameId == 0,
        "Unpublished preview required"
    )
    waitFor(function()
        -- selene: allow(global_usage)
        controller = shared.RBX031UiPreview
        return controller ~= nil
    end, "fixture")
    controller.toolbar.Enabled = false
    for _, name in controller.screens do
        chooseScreen(name)
        local view, hub = controller.view, controller.hub
        local root = activeRoot()
        if view then
            if name == "Aim" then
                assert(not view.overlay.Visible, "Aim is covered by a choice modal")
                inside(view.inventory, root)
                inside(view.controls, root)
            else
                assert(view.overlay.Visible and view.modal, "Missing run modal: " .. name)
                inside(view.modal, root)
                if view.shop then
                    assert(#view.shop.cards == 6, "Round11 shop missing Supplies")
                    for _, cell in view.shop.cards do
                        inside(cell.card, view.modal)
                        inside(cell.buy, cell.card)
                    end
                else
                    local content = view.modal:FindFirstChild("Content")
                    if content then
                        inside(content, view.modal)
                        if name == "Perks" or name == "Event" then
                            local choices = 0
                            for _, card in content:GetChildren() do
                                if card:IsA("Frame") and card.Name:match("^Choice") then
                                    choices += 1
                                    inside(card, content)
                                    inside(card.Reward, card)
                                    inside(card.Choose, card)
                                    assert(
                                        card.Choose.AbsoluteSize.Y >= 43.5,
                                        "Choice target is below44px"
                                    )
                                end
                            end
                            assert(choices == 2, "Expected two choices")
                        end
                    end
                end
            end
        else
            assert(hub, "Missing hub UI")
            if name == "Arcade" then
                inside(hub.dock, root)
                assert(not hub.panel.Visible, "Arcade opened an unexpected modal")
            else
                assert(hub.panel.Visible, "Hub panel missing: " .. name)
                inside(hub.panel, root)
                inside(hub.body, hub.panel)
                inside(hub.closeButton, hub.panel)
                assert(hub.title.Text ~= "", "Hub panel has no title")
            end
        end
        modelsReady()
        table.insert(
            report.screens,
            { name = name, width = root.AbsoluteSize.X, height = root.AbsoluteSize.Y }
        )
    end
    chooseScreen("Perks")
    local before = #controller.run.perks
    action("choosePerk", { index = 1 })
    assert(
        #controller.run.perks == before + 1 and controller.run.phase == "aim",
        "Perk did not return to aim"
    )
    chooseScreen("Event")
    action("chooseEvent", { index = 1 })
    assert(controller.run.phase == "aim", "Event did not return to aim")
    chooseScreen("Defeat")
    action("restart")
    assert(controller.run.phase == "aim", "Restart did not return to aim")
    chooseScreen("Victory")
    action("endless")
    assert(controller.run.endlessMode and controller.run.phase == "aim", "Endless failed")
    chooseScreen("Chests")
    local profile = controller.session.profile
    local count, credits = profile.chests.common, profile.restockCredits
    action("buyChest", { tier = "common", requestId = Http:GenerateGUID(false) })
    assert(
        profile.chests.common == count + 1 and profile.restockCredits == credits - 100,
        "Chest purchase failed"
    )
    local owned = #profile.itemUnlocks
    action("openChest", { tier = "common", requestId = Http:GenerateGUID(false) })
    assert(
        profile.chests.common == count and #profile.itemUnlocks == owned + 1,
        "Chest discovery failed"
    )
    chooseScreen("Arcade")
    action("startRun")
    assert(controller.view and controller.session.view == "run", "Hub Play did not open run")
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
    report.restoreFailure = tostring(restoreFailure)
    report.ok = false
end
report.elapsedSeconds = os.clock() - started
script:SetAttribute("Result", Http:JSONEncode(report))
if report.ok then
    print("[RBX-031] PASS full UI preview audit: " .. #report.screens .. " screens")
else
    warn(
        "[RBX-031] FAIL full UI preview audit: "
            .. tostring(report.failure or report.restoreFailure)
    )
end
