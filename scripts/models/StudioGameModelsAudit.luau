-- Run only in a dedicated game Client. Exercises the actual gameplay adapter,
-- not the gallery adapter alone. No gameplay state, remotes or profiles change.
return function(first, last)
    first, last = first or 1, last or 78
    local playerGui = game.Players.LocalPlayer.PlayerGui
    local Client = game.Players.LocalPlayer.PlayerScripts:WaitForChild("Client")
    local Models = require(Client.GameItemModels)
    local Catalog = require(game.ReplicatedStorage.CatalogLibrary.CatalogInfo)
    local report = {
        ok = false,
        checked = 0,
        passed = 0,
        failures = {},
        items = {},
        corners = 0,
        minimumMargin = 1,
        maximumEffects = 0,
    }
    local started = os.clock()
    local gui = Instance.new("ScreenGui")
    gui.Name, gui.Enabled = "RBX029GameModelAudit", false
    gui.Parent = playerGui
    local viewport = Instance.new("ViewportFrame")
    viewport.Name, viewport.Size, viewport.Parent = "TestPreview", UDim2.fromOffset(192, 192), gui
    task.wait()

    local function checkCamera(handle)
        local detail = handle:inspect()
        local camera = detail.camera
        local halfFov = math.tan(math.rad(camera.FieldOfView / 2))
        local aspect = viewport.AbsoluteSize.X / math.max(1, viewport.AbsoluteSize.Y)
        for _, part in viewport:GetDescendants() do
            if not part:IsA("BasePart") or part.Transparency >= 0.998 then
                continue
            end
            local half = part.Size / 2
            for _, x in { -1, 1 } do
                for _, y in { -1, 1 } do
                    for _, z in { -1, 1 } do
                        local world = part.CFrame:PointToWorldSpace(
                            Vector3.new(x * half.X, y * half.Y, z * half.Z)
                        )
                        local projected = camera.CFrame:PointToObjectSpace(world)
                        assert(projected.Z < 0, "Visible geometry behind camera")
                        local dx = math.abs(projected.X / (-projected.Z * halfFov * aspect))
                        local dy = math.abs(projected.Y / (-projected.Z * halfFov))
                        local margin = (1 - math.max(dx, dy)) / 2
                        report.minimumMargin = math.min(report.minimumMargin, margin)
                        report.corners += 1
                        assert(margin >= -0.001, "Activation or effect clipped by camera")
                    end
                end
            end
        end
    end

    for index = first, math.min(last, #Catalog) do
        if os.clock() - started > 40 then
            table.insert(report.failures, "Audit time budget exceeded at index " .. index)
            break
        end
        local entry = Catalog[index]
        local handle, replacement
        local item = { id = entry.id, ok = false, poses = 0, effects = 0 }
        local ok, failure = pcall(function()
            viewport.Size = UDim2.fromOffset(192, 192)
            handle = Models.mount(viewport, entry.id, 5, { animate = true })
            assert(handle.model:GetAttribute("ItemId") == entry.id, "Wrong imported item identity")
            local deadline = os.clock() + 6
            repeat
                task.wait(0.02)
            until Models.loadStatus(entry.id) ~= "Loading" or os.clock() > deadline
            handle:step(0)
            assert(
                Models.loadStatus(entry.id) == "Ready",
                "Imported meshes did not load: " .. Models.loadStatus(entry.id)
            )
            assert(handle.backend == "Blender", "Known catalog ID silently fell back to native")
            assert(handle:inspect().effectParts == 0, "Idle card allocated persistent effect pool")
            local rest = {}
            for _, part in handle.model:GetDescendants() do
                if part:IsA("BasePart") then
                    assert(part:IsA("MeshPart"), "Native render geometry in imported model")
                    assert(
                        part.Anchored
                            and not part.CanCollide
                            and not part.CanTouch
                            and not part.CanQuery,
                        "Imported preview has physical interactions"
                    )
                    rest[part] = {
                        size = part.Size,
                        frame = handle:inspect().rootPose:ToObjectSpace(part.CFrame),
                    }
                end
            end
            assert(next(rest), "Empty imported model")
            checkCamera(handle)
            handle:pulse(2, { direction = Vector2.new(1, 1), effect = "audit" })
            assert(handle:isAnimating(), "Pulse did not start")
            for n = 1, 50 do
                handle:pulse(n / 20)
            end
            local frames, completions, previousPhase = 0, 0, 0
            while handle:isAnimating() do
                handle:step(0.1)
                local detail = handle:inspect()
                if detail.phase < previousPhase then
                    completions += 1
                end
                previousPhase = detail.phase
                item.effects = math.max(item.effects, detail.effectParts)
                report.maximumEffects = math.max(report.maximumEffects, detail.effectParts)
                assert(detail.effectParts <= 40, "Unbounded effect pool")
                if frames % 2 == 0 then
                    checkCamera(handle)
                    item.poses += 1
                end
                frames += 1
                assert(frames < 180, "Continuous procs prevented completion")
            end
            assert(completions <= 1, "More than one coalesced repeat")
            local detail = handle:inspect()
            assert(detail.visibleEffects == 0, "Effects persisted after completion")
            for part, initial in rest do
                assert(
                    (part.Size - initial.size).Magnitude < 0.0001,
                    "Completion retained squash/scale"
                )
                local relative = detail.rootPose:ToObjectSpace(part.CFrame)
                assert(
                    (relative.Position - initial.frame.Position).Magnitude < 0.0001,
                    "Completion retained articulation offset"
                )
                assert(
                    relative.LookVector:Dot(initial.frame.LookVector) > 0.9999,
                    "Completion retained rotation"
                )
            end
            handle:step(0.1)
            checkCamera(handle)

            -- One mount per viewport; replacement must dispose its predecessor.
            local previousModel = handle.model
            replacement = Models.mount(viewport, entry.id, 1, { reducedMotion = true })
            assert(
                previousModel.Parent == nil and not handle:isAnimating(),
                "Remount leaked its predecessor"
            )
            assert(#viewport:GetChildren() == 1, "Multiple preview roots/cameras remained")
            replacement:pulse(2)
            for _ = 1, 60 do
                replacement:step(0.1)
                assert(replacement:inspect().effectParts == 0, "Reduced motion spawned effects")
            end
            assert(not replacement:isAnimating(), "Reduced motion never completed")
            local removed = replacement.model
            replacement:destroy()
            replacement:destroy()
            assert(
                removed.Parent == nil
                    and viewport.CurrentCamera == nil
                    and #viewport:GetChildren() == 0,
                "Destroy leaked viewport content"
            )
            item.ok = true
        end)
        if handle then
            handle:destroy()
        end
        if replacement then
            replacement:destroy()
        end
        report.checked += 1
        if ok then
            report.passed += 1
        else
            table.insert(report.failures, entry.id .. ": " .. tostring(failure))
        end
        table.insert(report.items, item)
        task.wait()
    end
    gui:Destroy()
    report.elapsedSeconds = os.clock() - started
    report.ok = #report.failures == 0 and report.checked == math.min(last, #Catalog) - first + 1
    return report
end
