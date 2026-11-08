-- Run only in the coordinator's gallery Client DataModel. The audit clones its
-- targets and removes whole-body motion before measuring actual mechanism parts.
-- Bounds/contact checks supplement visual inspection; they do not prove topology.
return function()
    local started, deadline = os.clock(), os.clock() + 30
    local report = {
        schema = 1,
        ok = false,
        checked = 0,
        passed = 0,
        failed = 0,
        requested = 4,
        samples = 0,
        assertions = 0,
        failures = {},
        items = {},
        handleProbes = {},
        strengths = { 1, 2 },
        phaseSteps = 100,
        scope = "Actual native/Blender press contact, anchored axial coin squash, fixed crank support, rigid removable cap, restoration and native animation lifetime.",
    }
    local cleanup = {}
    local function fail(context, detail)
        report.failed += 1
        if #report.failures < 30 then
            table.insert(report.failures, context .. ": " .. tostring(detail))
        end
    end
    local function check(condition, context, detail)
        report.assertions += 1
        if not condition then
            fail(context, detail)
        end
    end
    local function finish()
        for _, object in cleanup do
            pcall(function()
                object:Destroy()
            end)
        end
        report.elapsedSeconds = os.clock() - started
        report.ok = report.failed == 0 and report.checked == report.requested
        return report
    end
    if not game:GetService("RunService"):IsClient() then
        fail("context", "Run in the gallery Client DataModel")
        return finish()
    end
    local storage = game:GetService("ReplicatedStorage")
    local library, assets =
        storage:FindFirstChild("CatalogLibrary"), storage:FindFirstChild("CatalogAssets")
    if not library or not assets then
        fail("context", "CatalogLibrary/CatalogAssets unavailable")
        return finish()
    end
    local loaded, Models, Motion, Adapter = pcall(function()
        return require(library.ItemModels),
            require(library.ItemMotion),
            require(library.CatalogMotion)
    end)
    if not loaded then
        fail("modules", Models)
        return finish()
    end
    local function records(model)
        local result = {}
        for _, part in model:GetDescendants() do
            if part:IsA("BasePart") then
                table.insert(result, {
                    part = part,
                    frame = part.CFrame,
                    size = part.Size,
                    color = part.Color,
                    group = part:GetAttribute("MotionGroup") or "Fixed",
                    pivot = part:GetAttribute("MotionPivot"),
                })
            end
        end
        return result
    end
    local function frameError(a, b)
        return math.max(
            (a.Position - b.Position).Magnitude,
            (a.RightVector - b.RightVector).Magnitude,
            (a.UpVector - b.UpVector).Magnitude,
            (a.LookVector - b.LookVector).Magnitude
        )
    end
    local function halfExtents(frame, size)
        local function abs(v)
            return Vector3.new(math.abs(v.X), math.abs(v.Y), math.abs(v.Z))
        end
        return (
            abs(frame.RightVector) * size.X
            + abs(frame.UpVector) * size.Y
            + abs(frame.LookVector) * size.Z
        ) / 2
    end
    local function groupBounds(states, group)
        local low, high =
            Vector3.new(math.huge, math.huge, math.huge),
            Vector3.new(-math.huge, -math.huge, -math.huge)
        local count = 0
        for _, state in states do
            if state.group == group then
                local half = halfExtents(state.frame, state.size)
                local a, b = state.frame.Position - half, state.frame.Position + half
                low = Vector3.new(math.min(low.X, a.X), math.min(low.Y, a.Y), math.min(low.Z, a.Z))
                high =
                    Vector3.new(math.max(high.X, b.X), math.max(high.Y, b.Y), math.max(high.Z, b.Z))
                count += 1
            end
        end
        assert(count > 0, "Missing group " .. group)
        return low, high, count
    end
    local function mechanismPose(base, body, restSize)
        local bodyRoot = CFrame.new(body.x * restSize.X, body.y * restSize.Y, body.z * restSize.Z)
            * CFrame.Angles(body.rx, body.ry, body.rz)
        local result = {}
        for _, record in base do
            local localFrame = bodyRoot:ToObjectSpace(record.part.CFrame)
            table.insert(result, {
                part = record.part,
                group = record.group,
                pivot = record.pivot,
                frame = CFrame.new(localFrame.Position / body.scale) * localFrame.Rotation,
                size = record.part.Size / body.scale,
            })
        end
        return result
    end
    for _, source in { "native", "blender" } do
        for _, id in { "coin_press", "burst_capsule" } do
            if os.clock() >= deadline then
                fail("deadline", "Unrun " .. source .. "/" .. id)
                return finish()
            end
            local item = {
                source = source,
                id = id,
                ok = false,
                samples = 0,
                maxAnchorDrift = 0,
                maxContactError = 0,
                minimumThicknessRatio = 1,
                maxCrankYDrift = 0,
                maxRigidError = 0,
                maxReseatError = 0,
            }
            table.insert(report.items, item)
            local failedBefore = report.failed
            local successful, reason = pcall(function()
                local model = if source == "native"
                    then Models.create(id, 5)
                    else assert(assets:FindFirstChild(id), id):Clone()
                table.insert(cleanup, model)
                local base = records(model)
                local _, restSize = model:GetBoundingBox()
                local controller = if source == "native"
                    then Motion.new(model, id)
                    else Adapter.new(model)
                item.duration, item.parts = controller.duration, #base
                local coinLow, coinHigh, crankLow, crankHigh, capRest, capPivot
                local thickness, contact, travel
                if id == "coin_press" then
                    coinLow, coinHigh, item.coinParts = groupBounds(base, "MintCoin")
                    crankLow, crankHigh, item.crankParts = groupBounds(base, "Crank")
                    thickness = coinHigh.Y - coinLow.Y
                    local dieLow = groupBounds(base, "PressScrew")
                    contact, travel =
                        dieLow.Y - coinHigh.Y, dieLow.Y - coinHigh.Y + thickness * 0.74
                    item.restCoinThickness, item.restContactGap = thickness, contact
                    check(
                        math.abs(thickness - 0.135) < 0.0001,
                        source .. "/coin-thickness",
                        thickness
                    )
                    check(contact > 0, source .. "/press-gap", contact)
                    local crankPivot
                    for _, record in base do
                        if record.group == "MintCoin" and source == "blender" then
                            check(
                                math.abs(record.frame.UpVector.Y) > 0.9999,
                                source .. "/coin-local-Y",
                                record.part.Name
                            )
                        elseif record.group == "Crank" then
                            crankPivot = record.pivot
                        end
                    end
                    assert(crankPivot, "Crank has no pivot")
                    if source == "native" then
                        crankPivot -= model:GetAttribute("ArtCenter") or Vector3.zero
                    end
                    local supportGap = math.huge
                    for _, record in base do
                        if record.group == "Fixed" then
                            local half = halfExtents(record.frame, record.size)
                            local low, high =
                                record.frame.Position - half, record.frame.Position + half
                            if
                                crankPivot.X >= low.X - 0.001
                                and crankPivot.X <= high.X + 0.001
                                and crankPivot.Z >= low.Z - 0.001
                                and crankPivot.Z <= high.Z + 0.001
                                and low.Y < crankPivot.Y
                                and high.Y <= crankPivot.Y + 0.01
                            then
                                supportGap =
                                    math.min(supportGap, math.max(0, crankPivot.Y - high.Y))
                            end
                        end
                    end
                    item.crankSupportGap = if supportGap < math.huge then supportGap else nil
                    check(
                        supportGap <= 0.081,
                        source .. "/crank-support",
                        "Fixed support gap " .. tostring(supportGap)
                    )
                else
                    capRest = {}
                    for _, record in base do
                        if record.group == "BurstCap" then
                            assert(record.pivot, "Cap has no explicit pivot")
                            capPivot = capPivot or record.pivot
                            check(
                                (record.pivot - capPivot).Magnitude < 0.00001,
                                source .. "/cap-pivot",
                                record.part.Name
                            )
                            table.insert(capRest, record)
                        end
                    end
                    item.capParts = #capRest
                    assert(#capRest >= 2, "Cap material/neck assembly missing")
                end
                for _, strength in report.strengths do
                    for step = 0, 100 do
                        if step % 25 == 0 then
                            task.wait()
                            assert(os.clock() < deadline, "30-second audit budget reached")
                        end
                        local t = step / 100
                        controller:apply(t, strength)
                        local states =
                            mechanismPose(base, Motion.bodySample(id, t, strength), restSize)
                        item.samples += 1
                        report.samples += 1
                        if id == "coin_press" then
                            local low, high = groupBounds(states, "MintCoin")
                            local dieLow = groupBounds(states, "PressScrew")
                            local crankA, crankB = groupBounds(states, "Crank")
                            local ratio, gap = (high.Y - low.Y) / thickness, dieLow.Y - high.Y
                            local anchorDrift = math.abs(low.Y - coinLow.Y)
                            item.maxAnchorDrift = math.max(item.maxAnchorDrift, anchorDrift)
                            item.minimumGap = math.min(item.minimumGap or gap, gap)
                            item.minimumThicknessRatio = math.min(item.minimumThicknessRatio, ratio)
                            local crankDrift = math.max(
                                math.abs(crankA.Y - crankLow.Y),
                                math.abs(crankB.Y - crankHigh.Y)
                            )
                            item.maxCrankYDrift = math.max(item.maxCrankYDrift, crankDrift)
                            check(anchorDrift < 0.0001, source .. "/coin-anchor", t)
                            check(gap >= -0.0001, source .. "/coin-penetration", gap)
                            check(
                                ratio >= 0.2599 and ratio <= 1.0001,
                                source .. "/coin-compression",
                                ratio
                            )
                            check(
                                crankDrift < 0.0001,
                                source .. "/crank-vertical-travel",
                                crankDrift
                            )
                            check(
                                math.abs((high.X - low.X) - (coinHigh.X - coinLow.X)) < 0.0001
                                    and math.abs((high.Z - low.Z) - (coinHigh.Z - coinLow.Z))
                                        < 0.0001,
                                source .. "/coin-diameter",
                                t
                            )
                            local stroke = Motion.sample(id, "MintCoin", t, strength, 0, 0, 0).press
                            if stroke * travel > contact + 0.00001 then
                                item.maxContactError = math.max(item.maxContactError, math.abs(gap))
                                check(math.abs(gap) < 0.0001, source .. "/press-contact", gap)
                            end
                        else
                            local cap = {}
                            for _, state in states do
                                if state.group == "BurstCap" then
                                    table.insert(cap, state)
                                end
                            end
                            for index, state in cap do
                                local relative = cap[1].frame:ToObjectSpace(state.frame)
                                local original =
                                    capRest[1].frame:ToObjectSpace(capRest[index].frame)
                                local error = frameError(relative, original)
                                item.maxRigidError = math.max(item.maxRigidError, error)
                                check(error < 0.0001, source .. "/cap-rigid", state.part.Name)
                                check(
                                    (state.size - capRest[index].size).Magnitude < 0.0001,
                                    source .. "/cap-size",
                                    state.part.Name
                                )
                                if t >= 0.76 or t == 0 then
                                    local seatError = frameError(state.frame, capRest[index].frame)
                                    item.maxReseatError = math.max(item.maxReseatError, seatError)
                                    check(
                                        seatError < 0.0001,
                                        source .. "/cap-reseat",
                                        state.part.Name
                                    )
                                end
                            end
                        end
                        if step == 0 or step == 100 then
                            for _, record in base do
                                check(
                                    frameError(record.part.CFrame, record.frame) < 0.0001
                                        and (record.part.Size - record.size).Magnitude < 0.0001
                                        and record.part.Color == record.color,
                                    source .. "/endpoint",
                                    record.part.Name
                                )
                            end
                        end
                    end
                end
                if id == "coin_press" then
                    check(
                        math.abs(item.minimumThicknessRatio - 0.26) < 0.0001,
                        source .. "/full-squash",
                        item.minimumThicknessRatio
                    )
                else
                    item.minimumGap = nil
                end
            end)
            report.checked += 1
            if not successful then
                fail(source .. "/" .. id, reason)
            end
            item.ok = successful and failedBefore == report.failed
            if item.ok then
                report.passed += 1
            end
        end
    end
    local player = game:GetService("Players").LocalPlayer
    local gui = player and player:FindFirstChildOfClass("PlayerGui")
    if gui and os.clock() < deadline then
        local screen = Instance.new("ScreenGui")
        screen.Name = "ReviewMechanicsAuditTemporary"
        screen.DisplayOrder = -10000
        screen.Parent = gui
        table.insert(cleanup, screen)
        for _, id in { "coin_press", "burst_capsule", "chest_legendary" } do
            local viewport = Instance.new("ViewportFrame")
            viewport.Size = UDim2.fromOffset(240, 240)
            viewport.Position = UDim2.fromOffset(-12000, -12000)
            viewport.Parent = screen
            task.wait()
            local handle
            local ok, reason = pcall(function()
                assert(os.clock() < deadline, "30-second audit budget reached")
                handle = Models.mount(viewport, id, 5, { animate = false })
                local probe = { id = id, available = type(handle.isAnimating) == "function" }
                table.insert(report.handleProbes, probe)
                if not probe.available then
                    return
                end
                check(not handle:isAnimating(), "handle/rest", id)
                handle:pulse(1)
                check(handle:isAnimating(), "handle/start", id)
                local duration = Motion.Profiles[id].duration
                local elapsed = 0
                while elapsed + 0.05 < duration * 0.9 do
                    handle:step(0.05)
                    elapsed += 0.05
                    check(handle:isAnimating(), "handle/premature-end", id)
                end
                probe.activeThroughSeconds = elapsed
                for _ = 1, math.ceil((duration - elapsed) / 0.05) + 2 do
                    handle:step(0.05)
                end
                probe.completed = not handle:isAnimating()
                check(probe.completed, "handle/completion", id)
                handle:destroy()
                check(not handle:isAnimating(), "handle/destroy", id)
            end)
            if handle then
                handle:destroy()
            end
            viewport:Destroy()
            if not ok then
                fail("handle/" .. id, reason)
            end
        end
    else
        fail("handle/context", "PlayerGui unavailable or audit deadline reached")
    end
    return finish()
end
