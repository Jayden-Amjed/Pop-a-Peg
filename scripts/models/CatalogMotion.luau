-- Blender inspection adapter. Geometry remains in its centered authored pose;
-- MotionPivot is centered too, while AuthoredPosition retains source coordinates.
local ItemMotion = if script
    then require(script.Parent.ItemMotion)
    else require("../../src/client/ItemMotion")
local CatalogMotion = {}

local function bounded(value, fallback, lower, upper)
    if type(value) ~= "number" or value ~= value then
        return fallback
    end
    return math.clamp(value, lower, upper)
end

function CatalogMotion.new(model, testTypes)
    -- The optional math types let the standalone contract test exercise this
    -- actual adapter; the gallery always uses Roblox's native value types.
    local V = if testTypes then testTypes.Vector3 else Vector3
    local CF = if testTypes then testTypes.CFrame else CFrame
    local Color = if testTypes then testTypes.Color3 else Color3
    local id = model:GetAttribute("ItemId")
    local profile = assert(ItemMotion.Profiles[id], "Unknown catalog motion: " .. tostring(id))
    local _, restSize = model:GetBoundingBox()
    local records, assemblies, byKey = {}, {}, {}
    for _, part in model:GetDescendants() do
        if not part:IsA("BasePart") then
            continue
        end
        local group = part:GetAttribute("MotionGroup") or "Fixed"
        local frame = part.CFrame
        local authored = part:GetAttribute("AuthoredPosition") or frame.Position
        local pivot = part:GetAttribute("MotionPivot") or frame.Position
        local key = string.format("%s:%.9g:%.9g:%.9g", group, pivot.X, pivot.Y, pivot.Z)
        local assembly = byKey[key]
        if not assembly then
            assembly = { group = group, pivot = pivot, authored = V.new(), count = 0 }
            byKey[key] = assembly
            table.insert(assemblies, assembly)
        end
        assembly.authored += authored
        assembly.count += 1
        table.insert(records, {
            part = part,
            frame = frame,
            rotation = frame - frame.Position,
            relative = frame.Position - pivot,
            size = part.Size,
            color = part.Color,
            assembly = assembly,
            span = part:GetAttribute("CompressionSpan") or 0,
        })
    end
    assert(#records > 0, "Catalog motion requires a model with renderable parts")
    for _, assembly in assemblies do
        -- Multi-material pieces of one connected assembly share a phase sample.
        -- Distinct pivots preserve individual plants, keys, drops and other beats.
        assembly.authored /= assembly.count
    end
    local controller = { duration = profile.duration, profile = profile.name, restSize = restSize }
    function controller:apply(t, strength, rootPose)
        t = bounded(t, 0, 0, 1)
        strength = bounded(strength, 1, 0, 2)
        rootPose = rootPose or CF.new()
        local resting = t <= 0 or t >= 1
        local body = ItemMotion.bodySample(id, t, strength)
        local bodyRoot = rootPose
            * CF.new(body.x * restSize.X, body.y * restSize.Y, body.z * restSize.Z)
            * CF.Angles(body.rx, body.ry, body.rz)
        if not resting then
            for _, assembly in assemblies do
                local p = assembly.authored
                local state = ItemMotion.sample(id, assembly.group, t, strength, p.X, p.Y, p.Z)
                assembly.state = state
                assembly.transform = CF.new(assembly.pivot + V.new(state.x, state.y, state.z))
                    * CF.Angles(state.rx, state.ry, state.rz)
            end
        end
        for _, record in records do
            local part, assembly = record.part, record.assembly
            if resting then
                part.CFrame, part.Size, part.Color =
                    rootPose * record.frame, record.size, record.color
                continue
            end
            local state = assembly.state
            local frame, dimensions
            if
                (
                    id == "spring_coil"
                    and (assembly.group == "SpringMesh" or assembly.group == "SpringGuide")
                ) or assembly.group == "EvolvedSpring"
            then
                -- Imported coil/guide meshes have upright local Y. Compress both
                -- center and height about their shared lower socket; preserve X/Z.
                local shift = V.new(0, record.relative.Y * (state.axial - 1), 0)
                frame = CF.new(shift) * record.frame
                dimensions = V.new(record.size.X, record.size.Y * state.axial, record.size.Z)
            elseif id == "spring_coil" and assembly.group == "Weight" then
                -- The cap, pad and bolts retain their authored spacing and move
                -- by the same measured spring span, not the native primitive span.
                frame = CF.new(0, (state.axial - 1) * record.span, 0) * record.frame
                dimensions = record.size
            else
                -- Scale positions as well as dimensions about the shared pivot.
                -- A rotated/scaled assembly must not separate into material layers.
                frame = assembly.transform * CF.new(record.relative * state.scale) * record.rotation
                dimensions = record.size * state.scale
            end
            part.CFrame = bodyRoot * CF.new(frame.Position * body.scale) * (frame - frame.Position)
            part.Size = dimensions * body.scale
            part.Color = record.color:Lerp(Color.new(1, 1, 1), math.clamp(state.glow, 0, 0.22))
        end
    end
    return controller
end

return CatalogMotion
