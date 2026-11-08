-- Require this module in the dedicated gallery's Client DataModel, then call it.
-- options.ids can bound a batch; no visible inspector model is touched.
-- This checks imported runtime behavior, not visual quality or intersections
-- between intended attachments. Camera framing is a separate inspector check.
return function(options)
    options = options or {}
    local storage = game:GetService("ReplicatedStorage")
    local content = game:GetService("ContentProvider")
    local started = os.clock()
    local function bounded(value, fallback, lower, upper)
        if type(value) ~= "number" or value ~= value then
            return fallback
        end
        return math.clamp(value, lower, upper)
    end
    local budget = bounded(options.budgetSeconds, 120, 1, 240)
    local preloadTimeout = bounded(options.preloadTimeoutSeconds, 5, 0.1, 15)
    local deadline = started + budget
    local report = {
        schema = 1,
        ok = false,
        expected = 0,
        templates = 0,
        requested = 0,
        checked = 0,
        passed = 0,
        failed = 0,
        items = {},
        unrun = {},
        failures = {},
        cyclesPerStrength = 12,
        strengths = { 1, 2 },
        phases = { 0, 0.0773, 0.2426, 0.28, 0.5, 0.67, 0.75, 1 },
        limits = { partDimension = 20, modelDimension = 32, positionMagnitude = 100 },
        scope = "Client asset loading, bounded motion, root transform, restoration and real geometry movement; visual quality and camera fit are separate checks.",
    }
    local function finish()
        report.elapsedSeconds = os.clock() - started
        report.ok = #report.failures == 0
            and report.failed == 0
            and #report.unrun == 0
            and report.checked == report.requested
        return report
    end
    if not game:GetService("RunService"):IsClient() then
        table.insert(report.failures, "Run this audit in the gallery Client DataModel")
        return finish()
    end
    local assets, libraries =
        storage:FindFirstChild("CatalogAssets"), storage:FindFirstChild("CatalogLibrary")
    if
        not assets
        or not libraries
        or not libraries:FindFirstChild("CatalogInfo")
        or not libraries:FindFirstChild("CatalogMotion")
    then
        table.insert(
            report.failures,
            "Missing CatalogAssets or CatalogLibrary/CatalogInfo/CatalogMotion"
        )
        return finish()
    end
    local loaded, catalog, Motion = pcall(function()
        return require(libraries.CatalogInfo), require(libraries.CatalogMotion)
    end)
    if not loaded then
        table.insert(report.failures, "Catalog modules failed to load: " .. tostring(catalog))
        return finish()
    end
    local byId, sources = {}, {}
    for _, entry in catalog do
        if type(entry.id) ~= "string" or byId[entry.id] then
            table.insert(
                report.failures,
                "Missing or duplicate CatalogInfo ID: " .. tostring(entry.id)
            )
        else
            byId[entry.id] = entry
            report.expected += 1
        end
    end
    for _, source in assets:GetChildren() do
        if not source:IsA("Model") then
            table.insert(
                report.failures,
                "Unexpected catalog child class: " .. source.Name .. "/" .. source.ClassName
            )
        else
            report.templates += 1
            if sources[source.Name] then
                table.insert(report.failures, "Duplicate model: " .. source.Name)
            end
            if not byId[source.Name] then
                table.insert(report.failures, "Model absent from CatalogInfo: " .. source.Name)
            end
            sources[source.Name] = source
        end
    end
    if report.expected ~= report.templates then
        table.insert(
            report.failures,
            string.format(
                "Catalog count mismatch: %d entries, %d models",
                report.expected,
                report.templates
            )
        )
    end
    for id in byId do
        if not sources[id] then
            table.insert(report.failures, "Missing catalog model: " .. id)
        end
    end
    local selected, seen = {}, {}
    for _, candidate in (options.ids or catalog) do
        local id = if type(candidate) == "table" then candidate.id else candidate
        if type(id) ~= "string" or not byId[id] then
            table.insert(report.failures, "Requested unknown catalog ID: " .. tostring(id))
        elseif not seen[id] then
            seen[id] = true
            table.insert(selected, id)
        end
    end
    report.requested = #selected
    if #selected == 0 then
        table.insert(report.failures, "No models selected")
        return finish()
    end

    local container = Instance.new("WorldModel")
    container.Name = "CatalogAuditTemporary"
    container.Parent = storage
    local function preload(model)
        local result = {
            ok = false,
            callbacks = 0,
            successful = 0,
            failureCount = 0,
            failures = {},
            timedOut = false,
        }
        local done, active = false, true
        local taskThread = task.spawn(function()
            local ok, failure = pcall(function()
                content:PreloadAsync({ model }, function(assetId, status)
                    if not active then
                        return
                    end
                    result.callbacks += 1
                    if status == Enum.AssetFetchStatus.Success then
                        result.successful += 1
                    else
                        result.failureCount += 1
                        if #result.failures < 12 then
                            table.insert(
                                result.failures,
                                tostring(assetId) .. ": " .. tostring(status)
                            )
                        end
                    end
                end)
            end)
            if active and not ok then
                result.failureCount += 1
                table.insert(result.failures, tostring(failure))
            end
            done = true
        end)
        local stop = math.min(deadline, os.clock() + preloadTimeout)
        while not done and os.clock() < stop do
            task.wait(0.03)
        end
        active = false
        if not done then
            result.timedOut = true
            pcall(task.cancel, taskThread)
        end
        result.checkedMeshAssets = 0
        if done then
            local seenAssets = {}
            for _, object in model:GetDescendants() do
                if
                    object:IsA("MeshPart")
                    and object.MeshId ~= ""
                    and not seenAssets[object.MeshId]
                then
                    seenAssets[object.MeshId] = true
                    result.checkedMeshAssets += 1
                    local statusOk, status = pcall(function()
                        return content:GetAssetFetchStatus(object.MeshId)
                    end)
                    if not statusOk or status ~= Enum.AssetFetchStatus.Success then
                        result.failureCount += 1
                        if #result.failures < 12 then
                            table.insert(result.failures, object.MeshId .. ": " .. tostring(status))
                        end
                    end
                end
            end
        end
        result.ok = done and result.failureCount == 0 and result.checkedMeshAssets > 0
        return result
    end
    local function finite(number)
        return number == number and math.abs(number) < math.huge
    end
    local function finiteVector(vector)
        return finite(vector.X) and finite(vector.Y) and finite(vector.Z)
    end
    local function frameFinite(frame)
        for _, component in { frame:GetComponents() } do
            if not finite(component) then
                return false
            end
        end
        return true
    end
    local function sameColor(a, b)
        return math.abs(a.R - b.R) < 0.000001
            and math.abs(a.G - b.G) < 0.000001
            and math.abs(a.B - b.B) < 0.000001
    end
    local function sameFrame(a, b)
        return a:FuzzyEq(b, 0.00002)
    end
    local rootPose = CFrame.new(2, 3, -4) * CFrame.Angles(0.12, 0.3, -0.04)
    local rootInverse = rootPose:Inverse()
    local completed, fatal = pcall(function()
        for index, id in selected do
            if os.clock() >= deadline then
                for remaining = index, #selected do
                    table.insert(report.unrun, selected[remaining])
                end
                break
            end
            local result = {
                id = id,
                ok = false,
                parts = 0,
                triangles = 0,
                groups = {},
                movedGroups = {},
                movedParts = 0,
                failures = {},
                posesChecked = 0,
                completedCycles = 0,
                maxPartDimension = 0,
                maxModelDimension = 0,
                maxPositionMagnitude = 0,
                restored = false,
                rootTransform = false,
                deterministic = false,
            }
            local issueSet = {}
            local function expect(condition, message)
                if not condition and not issueSet[message] then
                    issueSet[message] = true
                    table.insert(result.failures, message)
                end
            end
            local model
            local itemOk, itemError = pcall(function()
                local source = assert(sources[id], "Missing model")
                model = source:Clone()
                model.Parent = container
                expect(model:GetAttribute("ItemId") == id, "ItemId does not match catalog ID")
                expect(
                    model:GetAttribute("Category") == byId[id].category,
                    "Category does not match CatalogInfo"
                )
                local baseline, moved, nonFixed = {}, {}, 0
                for _, object in model:GetDescendants() do
                    if object:IsA("LuaSourceContainer") then
                        error("Preview model contains executable source")
                    end
                    if not object:IsA("BasePart") then
                        continue
                    end
                    result.parts += 1
                    expect(
                        object:IsA("MeshPart"),
                        "Catalog contains a primitive instead of an imported MeshPart"
                    )
                    if object:IsA("MeshPart") then
                        expect(object.MeshId ~= "", "MeshPart has no MeshId")
                    end
                    expect(
                        object.Anchored
                            and not object.CanCollide
                            and not object.CanTouch
                            and not object.CanQuery,
                        "Unsafe preview collision flags"
                    )
                    local group = object:GetAttribute("MotionGroup")
                    expect(type(group) == "string", "Missing MotionGroup")
                    group = group or "Missing"
                    result.groups[group] = (result.groups[group] or 0) + 1
                    if group ~= "Fixed" then
                        nonFixed += 1
                    end
                    local pivot, authored =
                        object:GetAttribute("MotionPivot"), object:GetAttribute("AuthoredPosition")
                    expect(
                        typeof(pivot) == "Vector3" and finiteVector(pivot),
                        "Missing/nonfinite centered pivot"
                    )
                    expect(
                        typeof(authored) == "Vector3" and finiteVector(authored),
                        "Missing/nonfinite source position"
                    )
                    local triangles = object:GetAttribute("TriangleCount")
                    expect(
                        type(triangles) == "number" and triangles > 0,
                        "Missing part triangle count"
                    )
                    result.triangles += if type(triangles) == "number" then triangles else 0
                    baseline[object] = {
                        frame = object.CFrame,
                        size = object.Size,
                        color = object.Color,
                        group = group,
                    }
                end
                assert(result.parts > 0, "Model has no mesh pieces")
                expect(
                    result.parts == model:GetAttribute("PartCount"),
                    "PartCount does not match imported pieces"
                )
                expect(
                    result.triangles == model:GetAttribute("TriangleCount"),
                    "TriangleCount does not match imported pieces"
                )
                expect(nonFixed > 0, "Model has no non-Fixed motion group")
                result.preload = preload(model)
                expect(
                    result.preload.ok,
                    if result.preload.timedOut
                        then "Asset preload timed out"
                        else "Asset preload failed"
                )
                local motion = Motion.new(model)
                result.profile, result.duration = motion.profile, motion.duration
                local function checkPose(t, poseRoot)
                    result.posesChecked += 1
                    for part, original in baseline do
                        assert(
                            frameFinite(part.CFrame) and finiteVector(part.Size),
                            "Nonfinite part transform/size"
                        )
                        assert(
                            part.Size.X > 0 and part.Size.Y > 0 and part.Size.Z > 0,
                            "Nonpositive part size"
                        )
                        local dimension = math.max(part.Size.X, part.Size.Y, part.Size.Z)
                        result.maxPartDimension = math.max(result.maxPartDimension, dimension)
                        result.maxPositionMagnitude =
                            math.max(result.maxPositionMagnitude, part.Position.Magnitude)
                        expect(
                            dimension <= report.limits.partDimension,
                            "Part dimension exceeded bounded preview envelope"
                        )
                        expect(
                            part.Position.Magnitude <= report.limits.positionMagnitude,
                            "Part position exceeded bounded preview envelope"
                        )
                        local relativeFrame = poseRoot:Inverse() * part.CFrame
                        local geometricChange = not sameFrame(relativeFrame, original.frame)
                            or (part.Size - original.size).Magnitude > 0.00002
                        if original.group ~= "Fixed" and geometricChange then
                            moved[part] = true
                            result.movedGroups[original.group] = true
                        end
                        if t == 0 or t == 1 or original.group == "Fixed" then
                            expect(
                                sameFrame(relativeFrame, original.frame),
                                "Rest/fixed transform drift"
                            )
                            expect(
                                (part.Size - original.size).Magnitude < 0.00002,
                                "Rest/fixed size drift"
                            )
                            expect(sameColor(part.Color, original.color), "Rest/fixed color drift")
                        end
                    end
                    local bounds, size = model:GetBoundingBox()
                    assert(frameFinite(bounds) and finiteVector(size), "Nonfinite model bounds")
                    local dimension = math.max(size.X, size.Y, size.Z)
                    result.maxModelDimension = math.max(result.maxModelDimension, dimension)
                    expect(
                        dimension <= report.limits.modelDimension,
                        "Model dimension exceeded bounded preview envelope"
                    )
                end
                for _, strength in report.strengths do
                    for _ = 1, report.cyclesPerStrength do
                        for _, t in report.phases do
                            motion:apply(t, strength, rootPose)
                            checkPose(t, rootPose)
                        end
                        result.completedCycles += 1
                    end
                end
                result.restored = not issueSet["Rest/fixed transform drift"]
                    and not issueSet["Rest/fixed size drift"]
                    and not issueSet["Rest/fixed color drift"]
                local samples = {}
                motion:apply(0.37, 2, CFrame.new())
                for part in baseline do
                    samples[part] = { part.CFrame, part.Size, part.Color }
                end
                motion:apply(0.37, 2, rootPose)
                for part, original in samples do
                    expect(
                        sameFrame(rootInverse * part.CFrame, original[1]),
                        "Root rotation/translation applied incorrectly"
                    )
                    expect(
                        (part.Size - original[2]).Magnitude < 0.00002
                            and sameColor(part.Color, original[3]),
                        "Root pose changed dimensions or color"
                    )
                end
                result.rootTransform = not issueSet["Root rotation/translation applied incorrectly"]
                    and not issueSet["Root pose changed dimensions or color"]
                motion:apply(0.89, 1, rootPose)
                motion:apply(0.37, 2, CFrame.new())
                for part, original in samples do
                    expect(
                        sameFrame(part.CFrame, original[1])
                            and (part.Size - original[2]).Magnitude < 0.00002
                            and sameColor(part.Color, original[3]),
                        "Re-sampling same pose accumulated transforms"
                    )
                end
                result.deterministic = not issueSet["Re-sampling same pose accumulated transforms"]
                for _ in moved do
                    result.movedParts += 1
                end
                expect(result.movedParts > 0, "No non-Fixed part showed geometric movement")
                motion:apply(0, 1, CFrame.new())
            end)
            if model then
                model:Destroy()
            end
            if not itemOk then
                table.insert(result.failures, tostring(itemError))
            end
            result.ok = #result.failures == 0
            report.checked += 1
            if result.ok then
                report.passed += 1
            else
                report.failed += 1
            end
            table.insert(report.items, result)
            task.wait()
        end
    end)
    container:Destroy()
    if not completed then
        table.insert(report.failures, "Audit interrupted: " .. tostring(fatal))
    end
    return finish()
end
