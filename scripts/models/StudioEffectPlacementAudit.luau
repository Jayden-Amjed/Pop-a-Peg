-- Real-engine placement/transform checks; artistic placement is reviewed in images.
return function(first, last)
    local library = game.ReplicatedStorage.CatalogLibrary
    local Motion, Effects = require(library.CatalogMotion), require(library.CatalogEffects)
    local Choreography = require(library.BlenderChoreography)
    local catalog = require(library.CatalogInfo)
    local host = Instance.new("ViewportFrame")
    host.Name, host.Parent = "EffectPlacementAudit", game.Players.LocalPlayer.PlayerGui
    local report = { checked = 0, passed = 0, samples = 0, failures = {}, items = {} }
    local root = CFrame.new(3, -1, 2) * CFrame.Angles(0.27, -0.63, 0.18)
    for index = first or 1, math.min(last or #catalog, #catalog) do
        local id = catalog[index].id
        local model = game.ReplicatedStorage.CatalogAssets[id]:Clone()
        model.Parent = host
        local motion, effects = Motion.new(model), nil
        local item = { id = id, maxRootError = 0, maxPlateError = 0, samples = 0 }
        local ok, failure = pcall(function()
            effects = Effects.new(model, id)
            item.mode, item.group, item.note =
                effects.placement.mode, effects.placement.group, effects.placement.note
            local parts = effects.model:GetChildren()
            table.sort(parts, function(a, b)
                return a.Name < b.Name
            end)
            local center
            for _, part in model:GetChildren() do
                if part:IsA("BasePart") then
                    center = part:GetAttribute("AuthoredPosition") - part.Position
                    break
                end
            end
            for _, strength in { 0.25, 1, 2 } do
                for _, t in { 0.27, 0.48, 0.72 } do
                    motion:apply(t, strength, CFrame.identity)
                    effects:apply(t, strength, CFrame.identity)
                    local frames, sizes = {}, {}
                    for i, part in parts do
                        frames[i], sizes[i] = part.CFrame, part.Size
                    end
                    motion:apply(t, strength, root)
                    effects:apply(t, strength, root)
                    for i, part in parts do
                        if part.Transparency >= 0.998 then
                            continue
                        end
                        local expected = root * frames[i]
                        local error = (part.Position - expected.Position).Magnitude
                        item.maxRootError = math.max(item.maxRootError, error)
                        assert(error < 0.0001, "Emitter lost/doubled root transform")
                        assert(
                            (part.Size - sizes[i]).Magnitude < 0.0001,
                            "Root changed effect scale"
                        )
                        assert(
                            (part.CFrame.UpVector - expected.UpVector).Magnitude < 0.0001,
                            "Emitter lost orientation"
                        )
                        if id == "quota_bonus" and i <= 12 and t < 0.6 then
                            local body = Choreography.bodySample(id, t, strength)
                            local size = motion.restSize
                            local bodyRoot = root
                                * CFrame.new(body.x * size.X, body.y * size.Y, body.z * size.Z)
                                * CFrame.Angles(body.rx, body.ry, body.rz)
                            local sourcePoint = bodyRoot:PointToObjectSpace(part.Position)
                                    / body.scale
                                + center
                            local errorY = math.abs(sourcePoint.Y - 0.46)
                            item.maxPlateError = math.max(item.maxPlateError, errorY)
                            assert(errorY < 0.0001, "Quota shock left the contact plate plane")
                        end
                    end
                    item.samples += 1
                end
            end
        end)
        item.ok = ok
        report.checked += 1
        report.samples += item.samples
        if ok then
            report.passed += 1
        else
            table.insert(report.failures, id .. ": " .. tostring(failure))
        end
        table.insert(report.items, item)
        if effects then
            effects:destroy()
        end
        model:Destroy()
        task.wait()
    end
    host:Destroy()
    report.ok = #report.failures == 0
    return report
end
