-- Dedicated Studio Client QA only. Uses an isolated Run and the real Presentation;
-- never fires a remote, touches a profile, or injects desktop input.
return function()
    assert(game:GetService("RunService"):IsStudio(), "Studio fixture only")
    local player = game:GetService("Players").LocalPlayer
    assert(player, "Run this audit in a Studio Client")
    local gui = player:FindFirstChildOfClass("PlayerGui")
    local client = player.PlayerScripts:FindFirstChild("Client")
    assert(gui and client, "Game Client must already be initialized")
    local shared = game:GetService("ReplicatedStorage").Shared
    local Run, Board, Catalog = require(shared.Run), require(shared.Board), require(shared.Catalog)
    local Presentation, Models = require(client.Presentation), require(client.GameItemModels)
    local started, view, run = os.clock(), nil, nil
    local report = { ok = false, fixture = true, stages = {}, failures = {}, modelChecks = 0 }
    local screenStates, previousGui, previousWorld, queued = {}, {}, {}, {}
    local camera = workspace.CurrentCamera
    local cameraState = camera and { camera.CFrame, camera.CameraType, camera.FieldOfView }
    for _, object in gui:GetChildren() do
        previousGui[object] = true
        if object:IsA("ScreenGui") then
            screenStates[object] = object.Enabled
        end
    end
    for _, object in workspace:GetChildren() do
        previousWorld[object] = true
    end
    local stage = "initialize"
    local function budget()
        assert(os.clock() - started < 25, "25-second audit budget exhausted")
    end
    local function snapshot()
        view:update(run:snapshot())
    end
    local function step(dt)
        budget()
        view:step(dt)
        while #queued > 0 do
            local action = table.remove(queued, 1)
            assert(action.kind == "continue", "Unexpected fixture UI action: " .. action.kind)
            local ok, failure = run:action(action.kind, action.payload)
            assert(ok, failure)
            snapshot()
        end
    end
    local function rect(object)
        local p, s = object.AbsolutePosition, object.AbsoluteSize
        return { x = p.X, y = p.Y, w = s.X, h = s.Y }
    end
    local function inside(object, parent)
        local a, b = rect(object), rect(parent)
        assert(a.w > 0 and a.h > 0, object.Name .. " has no rendered area")
        assert(
            a.x >= b.x - 1
                and a.y >= b.y - 1
                and a.x + a.w <= b.x + b.w + 1
                and a.y + a.h <= b.y + b.h + 1,
            object.Name .. " escaped " .. parent.Name
        )
        return a
    end
    local function separate(a, b)
        a, b = rect(a), rect(b)
        assert(
            a.x + a.w <= b.x + 1
                or b.x + b.w <= a.x + 1
                or a.y + a.h <= b.y + 1
                or b.y + b.h <= a.y + 1,
            "UI regions overlap"
        )
    end
    local function ready()
        repeat
            local waiting = false
            step(0.05)
            for _, mounted in view.models do
                local handle = mounted.handle
                local id = handle.model:GetAttribute("ItemId")
                local state = Models.loadStatus(id)
                assert(state ~= "Failed" and handle.backend == "Blender", "Model failed: " .. id)
                waiting = waiting or state ~= "Ready"
                if state == "Ready" then
                    handle:step(0)
                    assert(
                        handle.model:GetAttribute("RenderLoadState") == "Ready",
                        "Stale load state"
                    )
                    report.modelChecks += 1
                end
            end
            if not waiting then
                break
            end
            task.wait(0.03)
        until false
        task.wait()
    end
    local ok, failure = xpcall(function()
        for object in screenStates do
            object.Enabled = false
        end
        run = Run.new(29031)
        -- Explicit fixture equipment; no live inventory or currency is changed.
        run.inventory[1] = { id = "seed_bank", level = 2 }
        view = Presentation.new(function(kind, payload)
            table.insert(queued, { kind = kind, payload = payload })
        end)
        view.gui.Name, view.model.Name = "RBX029FlowAuditGui", "RBX029FlowAuditBoard"
        -- The test drives public actions itself. Its input listeners must never
        -- react to a person playing another Studio window during this audit.
        for _, connection in view.connections do
            connection:Disconnect()
        end
        view.feedback:setMuted(true)
        snapshot()
        report.safeArea = { w = view.viewport.X, h = view.viewport.Y }
        report.compact, report.folded = view.compact, view.foldHud
        ready()

        stage = "Seed Bank natural drain and automatic retry"
        assert(run:action("launch", { angle = 0 }))
        snapshot()
        -- Deterministic boundary fixture: Simulation.step itself detects drain;
        -- this does not call the private drain signal or manual endShot action.
        run.ball.y = Board.Geometry.bottom + 0.001
        run.ball.vx, run.ball.vy = 0, -10
        for _ = 1, 180 do
            run:step(1 / 60)
            snapshot()
            step(1 / 60)
            if run.phase ~= "flight" then
                break
            end
        end
        assert(
            run.phase == "result" and run.lastResult.reason == "drain",
            "Natural drain did not settle"
        )
        assert(
            run.drainCount == 1 and #run.nextShotSeeds == 8,
            "Level2 bank did not assign eight seeds"
        )
        local expected = run.settlementReceipt.nextShotValues
        local receiptId = run.settlementReceipt.id
        for index = 1, 360 do
            step(0.05)
            if run.phase == "aim" and not view.feedback:isBusy() then
                break
            end
            if index % 24 == 0 then
                task.wait()
            end
        end
        assert(
            run.phase == "aim" and #run.activeSeeds == 8,
            "Feedback did not advance to seeded aim"
        )
        assert(not view.busy and not view.boardOverride, "Seeded aim retained settlement override")
        assert(view.feedback.completedReceipt == receiptId, "Receipt timeline did not finish")
        for id, value in expected do
            assert(
                run.values[id] == value and view.pegs[id].value == value,
                "Seeded peg display differs from Run"
            )
        end
        assert(
            string.find(view.phaseLabel.Text, "8 SEEDED PEGS", 1, true),
            "Seed readiness label missing"
        )
        table.insert(report.stages, {
            name = stage,
            seeds = #run.activeSeeds,
            receipt = receiptId,
            drainFixture = "Launched normally, placed just above drain, then Simulation.step detected drain",
        })

        stage = "Full rack and owned perks at actual viewport"
        run.slots, run.coins = 7, 100
        local equipment = {
            "seed_bank",
            "tap_driver",
            "relay",
            "quota_bonus",
            "lagoon_synth",
            "spring_coil",
            "gain_dial",
        }
        for index, id in equipment do
            run.inventory[index] = { id = id, level = 2 }
        end
        run.perks =
            { Catalog.PerkIds[1], Catalog.PerkIds[2], Catalog.PerkIds[3], Catalog.PerkIds[4] }
        snapshot()
        view:_layout()
        ready()
        for index = 1, 7 do
            local slot = view.itemSlots[index]
            inside(slot.button, view.inventory)
            inside(slot.viewport, slot.button)
            if index > 1 then
                separate(slot.button, view.itemSlots[index - 1].button)
            end
        end
        local firstPerk = view.perkCells[run.perks[1]]
        for _, id in run.perks do
            local cell = view.perkCells[id]
            inside(cell.button, view.perksPanel)
            inside(cell.viewport, cell.button)
            if not view.compact then
                assert(
                    math.abs(cell.button.AbsolutePosition.Y - firstPerk.button.AbsolutePosition.Y)
                        < 1,
                    "Four desktop perks reserve an empty second row"
                )
            end
        end
        table.insert(report.stages, {
            name = stage,
            rackModel = rect(view.itemSlots[1].viewport),
            perkModel = rect(firstPerk.viewport),
        })

        stage = "Four equipment and two supplies shop fixture"
        -- Offer and route setup are fixtures, while purchasing/continuing use Run.action.
        run.phase, run.round, run.rerollsLeft = "shop", 10, 1
        run.shopOffers = {}
        for _, id in
            { "seed_bank", "relay", "quota_bonus", "lagoon_synth", "reserve_pack", "tuning_oil" }
        do
            table.insert(run.shopOffers, { id = id, price = 5, sold = false, frozen = false })
        end
        snapshot()
        ready()
        assert(
            view.overlay.Visible and view.shop and #view.shop.cards == 6,
            "4+2 shop is not visible"
        )
        local modal, unchanged = view.modal, view.shop.cards[2].viewport.CurrentCamera
        for index, card in view.shop.cards do
            inside(card.card, view.modal)
            inside(card.viewport, card.inspect)
            inside(card.buy, card.card)
            for other = index + 1, #view.shop.cards do
                separate(card.card, view.shop.cards[other].card)
            end
        end
        local shopModel = rect(view.shop.cards[1].viewport)
        assert(run:action("buy", { offer = 1, itemId = "seed_bank" }))
        snapshot()
        ready()
        assert(
            run.inventory[1].level == 3 and run.slots == 7,
            "Full rack blocked existing-item upgrade"
        )
        assert(
            view.modal == modal and view.shop.cards[2].viewport.CurrentCamera == unchanged,
            "Purchase rebuilt unrelated shop assets"
        )
        table.insert(
            report.stages,
            { name = stage, offers = 6, upgradedLevel = 3, model = shopModel }
        )

        stage = "Perk choice fixture and return to aim"
        run.routes = { { kind = "perk" } }
        assert(run:action("continue"))
        snapshot()
        ready()
        assert(run.phase == "perk" and view.overlay.Visible, "Perk choice is hidden")
        local body = assert(view.modal:FindFirstChild("Content"), "Missing choice content")
        assert(not body.ScrollingEnabled, "Perk choice unexpectedly requires scrolling")
        local a, b = body:FindFirstChild("Choice1"), body:FindFirstChild("Choice2")
        assert(a and b, "Two perk cards are required")
        inside(a, body)
        inside(b, body)
        separate(a, b)
        for _, card in { a, b } do
            inside(assert(card:FindFirstChild("Reward")), card)
            inside(assert(card:FindFirstChild("Choose")), card)
        end
        local reward = rect(a.Reward)
        assert(run:action("choosePerk", { index = 1 }))
        snapshot()
        step(0.05)
        assert(
            run.phase == "aim" and not view.overlay.Visible and not view.busy,
            "Choice failed to return to play"
        )
        table.insert(report.stages, { name = stage, model = reward, perks = #run.perks })
    end, debug.traceback)
    if not ok then
        table.insert(report.failures, stage .. ": " .. tostring(failure))
    end
    local clean, cleanupFailure = pcall(function()
        if view then
            view:destroy()
        end
    end)
    if not clean then
        table.insert(report.failures, "Presentation cleanup: " .. tostring(cleanupFailure))
    end
    -- Also recover constructor failure before its returned view was assigned.
    for _, object in gui:GetChildren() do
        if
            not previousGui[object]
            and (object.Name == "PopAPeg" or object.Name == "RBX029FlowAuditGui")
        then
            object:Destroy()
        end
    end
    for _, object in workspace:GetChildren() do
        if
            not previousWorld[object]
            and (object.Name == "PopAPegLocalBoard" or object.Name == "RBX029FlowAuditBoard")
        then
            object:Destroy()
        end
    end
    for object, enabled in screenStates do
        if object.Parent then
            object.Enabled = enabled
        end
    end
    if cameraState and workspace.CurrentCamera == camera then
        camera.CFrame, camera.CameraType, camera.FieldOfView = table.unpack(cameraState)
    end
    report.restored = true
    for object, enabled in screenStates do
        if object.Parent and object.Enabled ~= enabled then
            report.restored = false
        end
    end
    report.elapsedSeconds = os.clock() - started
    report.ok = #report.failures == 0 and report.restored and #report.stages == 4
    return report
end
