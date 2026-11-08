-- Run in the dedicated catalog Client DataModel, in bounded index batches.
-- This exercises the actual native builders/controller/mounts without touching
-- the visible inspector. Geometry intersections and visual appeal need review.
return function(first, last)
    local started = os.clock()
    local deadline = started + 50
    local report = {
        schema = 1,
        ok = false,
        checked = 0,
        passed = 0,
        failed = 0,
        requested = 0,
        items = {},
        failures = {},
        unrun = {},
        cyclesPerStrength = 3,
        strengths = { 1, 2 },
        phaseSteps = 24,
        previewSizes = { { 160, 112 }, { 300, 260 } },
        scope = "Real native motion, restoration, root covariance, reduced motion, Fixed bodies, preview queue continuity and actual camera frustum corners.",
    }
    local function finish()
        report.elapsedSeconds = os.clock() - started
        report.ok = report.checked == report.requested
            and report.failed == 0
            and #report.failures == 0
            and #report.unrun == 0
        return report
    end
    local runService = game:GetService("RunService")
    local player = game:GetService("Players").LocalPlayer
    if not runService:IsClient() or not player then
        table.insert(report.failures, "Run in the dedicated catalog Client DataModel")
        return finish()
    end
    local library = game:GetService("ReplicatedStorage"):FindFirstChild("CatalogLibrary")
    if not library then
        table.insert(report.failures, "Missing ReplicatedStorage.CatalogLibrary")
        return finish()
    end
    local loaded, Models, Motion, catalog = pcall(function()
        return require(library.ItemModels),
            require(library.ItemMotion),
            require(library.CatalogInfo)
    end)
    if not loaded then
        table.insert(
            report.failures,
            "Cannot load native catalog dependencies: " .. tostring(Models)
        )
        return finish()
    end
    local function index(value, fallback)
        if type(value) ~= "number" or value ~= value or math.abs(value) == math.huge then
            return fallback
        end
        return math.clamp(math.floor(value), 1, #catalog)
    end
    first, last = index(first, 1), index(last, #catalog)
    if first > last then
        table.insert(report.failures, "first must not exceed last")
        return finish()
    end
    report.first, report.last, report.requested = first, last, last - first + 1
    local playerGui = player:FindFirstChildOfClass("PlayerGui")
    if not playerGui then
        table.insert(report.failures, "Client PlayerGui is unavailable")
        return finish()
    end
    local screen = Instance.new("ScreenGui")
    screen.Name = "NativeMotionAuditTemporary"
    screen.ResetOnSpawn = false
    screen.IgnoreGuiInset = true
    screen.DisplayOrder = -10000
    screen.Parent = playerGui
    local function finite(value)
        return value == value and math.abs(value) < math.huge
    end
    local function vectorNear(a, b, tolerance)
        return (a - b).Magnitude <= (tolerance or 0.00001)
    end
    local function frameNear(a, b, tolerance)
        local epsilon = tolerance or 0.00001
        return vectorNear(a.Position, b.Position, epsilon)
            and vectorNear(a.RightVector, b.RightVector, epsilon)
            and vectorNear(a.UpVector, b.UpVector, epsilon)
            and vectorNear(a.LookVector, b.LookVector, epsilon)
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
                })
            end
        end
        return result
    end
    for catalogIndex = first, last do
        if os.clock() >= deadline then
            for remaining = catalogIndex, last do
                table.insert(report.unrun, catalog[remaining].id)
            end
            break
        end
        local id = catalog[catalogIndex].id
        local item = {
            id = id,
            index = catalogIndex,
            ok = false,
            failures = {},
            failureCount = 0,
            parts = 0,
            fixedParts = 0,
            finitePartChecks = 0,
            restPartChecks = 0,
            rootPartChecks = 0,
            reducedPartChecks = 0,
            reducedMaximumScale = 1,
            fixedPartChecks = 0,
            cornerChecks = 0,
            queueChecks = 0,
            previews = {},
        }
        local seenFailures, cleanup = {}, {}
        local function fail(key, detail)
            item.failureCount += 1
            if not seenFailures[key] then
                seenFailures[key] = true
                if #item.failures < 24 then
                    table.insert(item.failures, key .. ": " .. tostring(detail))
                end
            end
        end
        local function assertRest(base, context)
            for _, rest in base do
                item.restPartChecks += 1
                if
                    not frameNear(rest.part.CFrame, rest.frame)
                    or not vectorNear(rest.part.Size, rest.size)
                    or rest.part.Color ~= rest.color
                then
                    fail("rest/" .. context, rest.part.Name)
                end
            end
        end
        local function checkFinite(base)
            for _, rest in base do
                local part = rest.part
                item.finitePartChecks += 1
                local good = true
                for _, value in { part.CFrame:GetComponents() } do
                    good = good and finite(value) and math.abs(value) < 1000
                end
                local size = part.Size
                good = good
                    and finite(size.X)
                    and finite(size.Y)
                    and finite(size.Z)
                    and math.min(size.X, size.Y, size.Z) > 0
                    and math.max(size.X, size.Y, size.Z) < 128
                if not good then
                    fail("finite/bounded", part.Name)
                end
            end
        end
        local ok, failure = pcall(function()
            local model = Models.create(id, 5)
            table.insert(cleanup, model)
            local base = records(model)
            item.parts = #base
            assert(#base > 0, "Native builder produced no parts")
            local _, restSize = model:GetBoundingBox()
            local controller = Motion.new(model, id)
            item.duration = controller.duration
            local movedFixed = {}
            for _, rest in base do
                if rest.group == "Fixed" then
                    item.fixedParts += 1
                end
            end
            for _, strength in report.strengths do
                for cycle = 1, report.cyclesPerStrength do
                    for step = 0, report.phaseSteps do
                        local t = step / report.phaseSteps
                        controller:apply(t, strength)
                        checkFinite(base)
                        if step == 0 or step == report.phaseSteps then
                            assertRest(base, "cycle" .. tostring(cycle))
                        else
                            local body = Motion.bodySample(id, t, strength)
                            local root = CFrame.new(
                                body.x * restSize.X,
                                body.y * restSize.Y,
                                body.z * restSize.Z
                            ) * CFrame.Angles(body.rx, body.ry, body.rz)
                            for _, rest in base do
                                if rest.group == "Fixed" then
                                    item.fixedPartChecks += 1
                                    local expected = root
                                        * CFrame.new(rest.frame.Position * body.scale)
                                        * rest.frame.Rotation
                                    if
                                        not frameNear(rest.part.CFrame, expected, 0.0001)
                                        or not vectorNear(
                                            rest.part.Size,
                                            rest.size * body.scale,
                                            0.0001
                                        )
                                    then
                                        fail("fixed/body", rest.part.Name)
                                    end
                                    if not frameNear(rest.part.CFrame, rest.frame) then
                                        movedFixed[rest.part] = true
                                    end
                                end
                            end
                        end
                    end
                end
            end
            for _, rest in base do
                if rest.group == "Fixed" and not movedFixed[rest.part] then
                    fail("fixed/never-moved", rest.part.Name)
                end
            end
            local externalRoot = CFrame.new(5.25, -2.75, 8.5) * CFrame.Angles(0.37, -0.62, 0.24)
            for _, t in { 0, 0.13, 0.31, 0.57, 0.81, 1 } do
                controller:apply(t, 2)
                local localPose = records(model)
                controller:apply(t, 2, externalRoot)
                for _, rest in localPose do
                    item.rootPartChecks += 1
                    if
                        not frameNear(rest.part.CFrame, externalRoot * rest.frame, 0.0001)
                        or not vectorNear(rest.part.Size, rest.size)
                    then
                        fail("root/covariance", rest.part.Name)
                    end
                end
            end
            controller:apply(1, 1)
            assertRest(base, "root-return")
            local reduced = Motion.new(model, id, { reducedMotion = true })
            for step = 0, report.phaseSteps do
                local t = step / report.phaseSteps
                reduced:apply(t, 2, externalRoot)
                local commonScale
                for _, rest in base do
                    item.reducedPartChecks += 1
                    local relative = externalRoot:ToObjectSpace(rest.part.CFrame)
                    local ratio = rest.part.Size.X / rest.size.X
                    if finite(ratio) then
                        item.reducedMaximumScale = math.max(item.reducedMaximumScale, ratio)
                    end
                    local uniform = vectorNear(rest.part.Size, rest.size * ratio, 0.0001)
                    commonScale = commonScale or ratio
                    if
                        ratio < 0.99999
                        or ratio > 1.04001
                        or math.abs(ratio - commonScale) > 0.0001
                        or not uniform
                        or not frameNear(relative.Rotation, rest.frame.Rotation, 0.0001)
                        or not vectorNear(relative.Position, rest.frame.Position * ratio, 0.0001)
                    then
                        fail("reduced/uniform-four-percent", rest.part.Name)
                    end
                end
            end
            reduced:apply(1, 2)
            assertRest(base, "reduced-return")
            if item.reducedMaximumScale < 1.038 then
                fail("reduced/missing-pop", item.reducedMaximumScale)
            end
            for _, dimensions in report.previewSizes do
                local viewport = Instance.new("ViewportFrame")
                viewport.Name = "Audit_" .. id
                viewport.Size = UDim2.fromOffset(dimensions[1], dimensions[2])
                viewport.Position = UDim2.fromOffset(-12000, -12000)
                viewport.Parent = screen
                table.insert(cleanup, viewport)
                task.wait()
                assert(
                    vectorNear(
                        Vector3.new(viewport.AbsoluteSize.X, viewport.AbsoluteSize.Y, 0),
                        Vector3.new(dimensions[1], dimensions[2], 0),
                        0.01
                    ),
                    "Preview AbsoluteSize not initialized"
                )
                local handle = Models.mount(viewport, id, 5, { animate = false })
                local previewBase = records(handle.model)
                local preview = {
                    width = dimensions[1],
                    height = dimensions[2],
                    queuePlayed = false,
                    cornerChecks = 0,
                    maximumFrustumRatio = 0,
                }
                table.insert(item.previews, preview)
                local function corners()
                    local camera = viewport.CurrentCamera
                    assert(camera, "Mounted preview has no CurrentCamera")
                    local tangent = math.tan(math.rad(camera.FieldOfView / 2))
                    local aspect = viewport.AbsoluteSize.X / viewport.AbsoluteSize.Y
                    for _, part in viewport:GetDescendants() do
                        if part:IsA("BasePart") then
                            local half = part.Size / 2
                            for _, x in { -1, 1 } do
                                for _, y in { -1, 1 } do
                                    for _, z in { -1, 1 } do
                                        local point = camera.CFrame:PointToObjectSpace(
                                            part.CFrame:PointToWorldSpace(
                                                Vector3.new(half.X * x, half.Y * y, half.Z * z)
                                            )
                                        )
                                        local depth = -point.Z
                                        local ratio = if depth > 0
                                            then math.max(
                                                math.abs(point.Y) / (depth * tangent),
                                                math.abs(point.X) / (depth * tangent * aspect)
                                            )
                                            else 1e6
                                        item.cornerChecks += 1
                                        preview.cornerChecks += 1
                                        preview.maximumFrustumRatio = math.max(
                                            preview.maximumFrustumRatio,
                                            if finite(ratio) then ratio else 1e6
                                        )
                                        if not finite(ratio) or ratio > 1.0001 then
                                            fail(
                                                "preview/frustum/" .. tostring(dimensions[1]),
                                                part.Name .. " ratio=" .. tostring(ratio)
                                            )
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
                corners()
                handle:pulse(2, { direction = Vector2.new(1, 0.7) })
                local delta = controller.duration / 40
                for step = 1, 122 do
                    handle:step(delta)
                    if step % 2 == 0 then
                        corners()
                    end
                    if step == 20 then
                        local before = records(handle.model)
                        handle:pulse(2, { direction = Vector2.new(-1, 0.3) })
                        assertRest(before, "queued-pulse-immediate")
                        handle:step(0)
                        assertRest(before, "queued-pulse-zero-step")
                        item.queueChecks += 2
                    elseif step == 60 then
                        for _, rest in previewBase do
                            if
                                not frameNear(rest.part.CFrame, rest.frame)
                                or not vectorNear(rest.part.Size, rest.size)
                            then
                                preview.queuePlayed = true
                            end
                        end
                    end
                end
                if not preview.queuePlayed then
                    fail("preview/queue-not-played", dimensions[1])
                end
                assertRest(previewBase, "preview-bounded-finish")
                handle:destroy()
                viewport:Destroy()
            end
        end)
        if not ok then
            fail("exception", failure)
        end
        for _, instance in cleanup do
            pcall(function()
                instance:Destroy()
            end)
        end
        item.ok = item.failureCount == 0
        table.insert(report.items, item)
        report.checked += 1
        if item.ok then
            report.passed += 1
        else
            report.failed += 1
        end
        task.wait()
    end
    screen:Destroy()
    return finish()
end
