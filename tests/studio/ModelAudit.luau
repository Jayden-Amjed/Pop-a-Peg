-- Read-only geometry/activation audit. Execute in an isolated Studio DataModel
-- after installing the exact production modules. Creates only unparented models.
local Client = game:GetService("StarterPlayer").StarterPlayerScripts.Client
local Models = require(Client.ItemModels)
local Motion = require(Client.ItemMotion)
local report = { models = 0, parts = 0, maxParts = 0, categories = {}, distinctGeometry = 0 }
local signatures = {}
local function rounded(value)
    return string.format("%.4f", value)
end
for _, id in Models.Ids do
    local model = Models.create(id, 1)
    local category = model:GetAttribute("Category")
    report.categories[category] = (report.categories[category] or 0) + 1
    report.models += 1
    local entries, original, groups = {}, {}, {}
    local _, bounds = model:GetBoundingBox()
    assert(
        bounds.X > 0 and bounds.Y > 0 and bounds.Z > 0 and bounds.Magnitude < 12,
        "Invalid model bounds: " .. id
    )
    for _, object in model:GetChildren() do
        assert(object:IsA("BasePart"), "Unexpected generated descendant")
        assert(
            object.Anchored
                and not object.CanCollide
                and not object.CanTouch
                and not object.CanQuery,
            "Preview physics leak: " .. id
        )
        local components = { object.CFrame:GetComponents() }
        local values = { object.ClassName, object:IsA("Part") and object.Shape.Name or "Wedge" }
        for _, n in { object.Size.X, object.Size.Y, object.Size.Z } do
            assert(n > 0 and n < 12, "Invalid part dimensions: " .. id)
            table.insert(values, rounded(n))
        end
        for _, n in components do
            assert(n == n and math.abs(n) < 12, "Nonfinite or excessive geometry: " .. id)
            table.insert(values, rounded(n))
        end
        table.insert(entries, table.concat(values, ","))
        groups[object:GetAttribute("MotionGroup")] = true
        original[object] = { frame = object.CFrame, size = object.Size, color = object.Color }
    end
    assert(#entries > 3 and #entries < 256, "Model part budget exceeded: " .. id)
    report.parts += #entries
    report.maxParts = math.max(report.maxParts, #entries)
    table.sort(entries)
    -- Geometry excludes name, color, material and motion tags: recolors do not
    -- satisfy the distinct-object requirement.
    local signature = table.concat(entries, ";")
    assert(
        not signatures[signature],
        "Repeated geometry: " .. id .. " / " .. tostring(signatures[signature])
    )
    signatures[signature] = id
    report.distinctGeometry += 1
    assert(
        model:GetAttribute("MotionProfile") == Motion.Profiles[id].name,
        "Missing motion identity: " .. id
    )
    for _, group in Motion.Profiles[id].groups or {} do
        assert(groups[group], "Declared motion group absent: " .. id .. "/" .. group)
    end
    local animation = Motion.new(model, id)
    animation:apply(0.37, 1, CFrame.new())
    animation:apply(1, 1, CFrame.new())
    for object, rest in original do
        assert(
            (object.Position - rest.frame.Position).Magnitude < 0.0001,
            "Activation failed to restore position: " .. id
        )
        assert(
            object.Size == rest.size and object.Color == rest.color,
            "Activation failed to restore appearance: " .. id
        )
    end
    model:Destroy()
    local upgraded = Models.create(id, 5)
    local _, upgradedSize = upgraded:GetBoundingBox()
    assert(upgradedSize.Magnitude < 12, "Max-level model bounds invalid: " .. id)
    upgraded:Destroy()
end
assert(report.models == 78, "Expected 78 unique model identities")
assert(
    report.categories.equipment == 40 and report.categories.perk == 8,
    "Equipment/perk coverage incomplete"
)
assert(
    report.categories.evolved == 13 and report.categories.utility == 14,
    "Evolution/reward coverage incomplete"
)
return report
