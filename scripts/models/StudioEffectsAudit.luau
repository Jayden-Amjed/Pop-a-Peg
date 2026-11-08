-- Bounded real-engine verification. Artistic intent is reviewed separately.
return function(first, last)
    local library = game.ReplicatedStorage.CatalogLibrary
    local Motion, Effects = require(library.CatalogMotion), require(library.CatalogEffects)
    local catalog = require(library.CatalogInfo)
    local host = Instance.new("ViewportFrame")
    host.Name = "RBX027EffectsAudit"
    host.Parent = game.Players.LocalPlayer.PlayerGui
    local started = os.clock()
    local report = { checked = 0, passed = 0, failures = {}, items = {}, maxPool = 0, samples = 0 }
    local function finite(value)
        return value == value and math.abs(value) < 10000
    end
    for index = first, math.min(last, #catalog) do
        if os.clock() - started > 40 then
            table.insert(report.failures, "Audit time limit at index " .. index)
            break
        end
        local id = catalog[index].id
        local model = game.ReplicatedStorage.CatalogAssets[id]:Clone()
        model.Parent = host
        local fx
        local item = { id = id, maxVisible = 0, pool = 0, samples = 0 }
        local ok, failure = pcall(function()
            local motion = Motion.new(model)
            fx = Effects.new(model, id)
            assert(fx.model.Parent == host, "Effect pool must be a sibling of geometry")
            local parts = {}
            for _, p in fx.model:GetDescendants() do
                if p:IsA("BasePart") then
                    table.insert(parts, p)
                end
            end
            item.pool = #parts
            assert(#parts > 0 and #parts <= 40, "Effect pool budget")
            local identities = {}
            for _, p in parts do
                identities[p] = true
            end
            local root = CFrame.new(0.13, -0.1, 0.08) * CFrame.Angles(0.07, -0.06, 0.03)
            for _, strength in { 1, 2 } do
                for step = 0, 20 do
                    local t = step / 20
                    motion:apply(t, strength, root)
                    fx:apply(t, strength, root)
                    local visible, snapshot = 0, {}
                    for _, p in parts do
                        assert(p.Parent and identities[p], "Pool identity changed")
                        assert(
                            p.Anchored and not p.CanCollide and not p.CanTouch and not p.CanQuery,
                            "Effect physics flags"
                        )
                        assert(
                            finite(p.Transparency) and p.Transparency >= 0 and p.Transparency <= 1,
                            "Invalid opacity"
                        )
                        for _, value in { p.CFrame:GetComponents() } do
                            assert(finite(value), "Nonfinite frame")
                        end
                        for _, value in { p.Size.X, p.Size.Y, p.Size.Z } do
                            assert(finite(value) and value > 0, "Invalid size")
                        end
                        if p.Transparency < 1 then
                            visible += 1
                        end
                        snapshot[p] = { p.CFrame, p.Size, p.Color, p.Transparency }
                    end
                    if t == 0 or t == 1 then
                        assert(visible == 0, "Effect survives resting endpoint")
                    end
                    item.maxVisible = math.max(item.maxVisible, visible)
                    local low, high = fx:bounds()
                    assert((visible > 0) == (low ~= nil), "Visible bounds mismatch")
                    if low then
                        assert(
                            high.X >= low.X and high.Y >= low.Y and high.Z >= low.Z,
                            "Inverted bounds"
                        )
                    end
                    fx:apply(t, strength, root)
                    for _, p in parts do
                        local saved = snapshot[p]
                        assert(
                            (p.Position - saved[1].Position).Magnitude < 0.00001,
                            "Nondeterministic pose"
                        )
                        assert((p.Size - saved[2]).Magnitude < 0.00001, "Nondeterministic scale")
                        assert(
                            p.Color == saved[3] and p.Transparency == saved[4],
                            "Nondeterministic appearance"
                        )
                    end
                    item.samples += 1
                end
            end
            assert(item.maxVisible > 0, "Silent visual profile")
            local pool = fx.model
            fx:destroy()
            fx:destroy()
            assert(pool.Parent == nil, "Effect pool leaked after disposal")
        end)
        if fx then
            fx:destroy()
        end
        model:Destroy()
        item.ok = ok
        if not ok then
            item.failure = tostring(failure)
            table.insert(report.failures, id .. ": " .. tostring(failure))
        else
            report.passed += 1
        end
        report.checked += 1
        report.samples += item.samples
        report.maxPool = math.max(report.maxPool, item.pool)
        table.insert(report.items, item)
        task.wait()
    end
    host:Destroy()
    report.ok, report.elapsedSeconds = #report.failures == 0, os.clock() - started
    return report
end
