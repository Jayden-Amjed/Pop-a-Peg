-- Run in the dedicated gallery's Client DataModel after it reports Ready.
local storage = game:GetService("ReplicatedStorage")
local PilotMotion = require(storage.PilotLibraries.PilotMotion)
local ItemMotion = require(storage.PilotLibraries.ItemMotion)
local results = {}
local expected = { spring_coil = 7, seed_bank = 8, chest_common = 10 }
for _, template in storage.BlenderPilots:GetChildren() do
    local model = template:Clone()
    model.Parent = workspace
    local controller = PilotMotion.new(model)
    local baseline = {}
    local count, triangles = 0, 0
    for _, part in model:GetChildren() do
        assert(part:IsA("MeshPart"), "Pilot must contain direct MeshParts")
        assert(
            part.Anchored and not part.CanCollide and not part.CanTouch and not part.CanQuery,
            "Unsafe preview collision flags"
        )
        assert(
            part.MeshId ~= "" and #part:GetAttribute("GeometrySHA256") == 64,
            "Missing mesh provenance"
        )
        assert(part.CFrame.UpVector:Dot(Vector3.yAxis) > 0.9999, "Local mesh Y must remain upright")
        count += 1
        triangles += part:GetAttribute("TriangleCount")
        baseline[part] = { part.CFrame, part.Size, part.Color }
    end
    assert(count == expected[model.Name], "Unexpected part count")
    local rootPose = CFrame.new(2, 3, -4) * CFrame.Angles(0.12, 0.3, -0.04)
    for _ = 1, 12 do
        for _, t in { 0, 0.0773, 0.2426, 0.28, 0.5, 0.67, 0.9, 1 } do
            controller:apply(t, 2, rootPose)
            for part in baseline do
                assert(
                    part.Position.Magnitude < 100 and part.Size.Magnitude < 10,
                    "Unbounded motion"
                )
            end
        end
    end
    for part, original in baseline do
        assert(part.CFrame:FuzzyEq(rootPose * original[1], 0.00001), "Rest transform drift")
        assert((part.Size - original[2]).Magnitude < 0.00001, "Rest size drift")
        assert(part.Color == original[3], "Rest color drift")
    end
    local hover = ItemMotion.newHover(true, 0.7)
    ItemMotion.stepHover(hover, 0.1, false)
    local phase = hover.phase
    for _ = 1, 60 do
        ItemMotion.stepHover(hover, 1 / 60, true)
    end
    assert(hover.phase == phase, "Idle must freeze on activation")
    ItemMotion.stepHover(hover, 1 / 60, false)
    assert(hover.phase == phase and hover.handoffs == 1, "Idle handoff jumped")
    for _ = 1, 60 do
        ItemMotion.stepHover(hover, 1 / 60, false)
    end
    assert(hover.phase ~= phase, "Idle did not resume")
    table.insert(results, {
        id = model.Name,
        pieces = count,
        triangles = triangles,
        cycles = 12,
        posesPerCycle = 8,
        completeRestoration = true,
        hoverHandoff = true,
    })
    model:Destroy()
end
assert(#results == 3, "Missing pilot")
return results
