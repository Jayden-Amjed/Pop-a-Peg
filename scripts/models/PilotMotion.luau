-- Isolated Blender pilot adapter. Production ItemModels remains authoritative.
local ItemMotion = require(script.Parent.ItemMotion)
local PilotMotion = {}

function PilotMotion.new(model)
    local id = model:GetAttribute("ItemId")
    local records = {}
    for _, part in model:GetChildren() do
        if part:IsA("BasePart") then
            table.insert(records, {
                part = part,
                frame = part.CFrame,
                size = part.Size,
                color = part.Color,
                group = part:GetAttribute("MotionGroup"),
                pivot = part:GetAttribute("MotionPivot"),
                span = part:GetAttribute("CompressionSpan") or 0,
            })
        end
    end
    local controller = { duration = ItemMotion.Profiles[id].duration }
    function controller:apply(t, strength, rootPose)
        for _, record in records do
            local part, frame = record.part, record.frame
            if t <= 0 or t >= 1 then
                part.CFrame, part.Size, part.Color = rootPose * frame, record.size, record.color
                continue
            end
            local p = frame.Position
            local state = ItemMotion.sample(id, record.group, t, strength, p.X, p.Y, p.Z)
            local pivot = record.pivot or p
            local transform = CFrame.new(pivot)
                * CFrame.Angles(state.rx, state.ry, state.rz)
                * CFrame.new(-pivot)
            local offset = Vector3.new(state.x, state.y, state.z)
            if id == "spring_coil" then
                if record.group == "SpringMesh" or record.group == "SpringGuide" then
                    -- The continuous mesh uses upright local Y. This pilot scales its
                    -- wire cross-section too; a future skinned coil can preserve it.
                    offset = Vector3.new(0, (p.Y - pivot.Y) * (state.axial - 1), 0)
                    part.Size =
                        Vector3.new(record.size.X, record.size.Y * state.axial, record.size.Z)
                else
                    if record.group == "Weight" then
                        offset = Vector3.new(0, (state.axial - 1) * record.span, 0)
                    end
                    part.Size = record.size
                end
            elseif id == "seed_bank" and record.group == "Seed" then
                -- One common seed-bed pivot keeps stems connected to their pods.
                offset += (p - pivot) * (state.scale - 1)
                part.Size = record.size * state.scale
            else
                part.Size = record.size * state.scale
            end
            part.CFrame = rootPose * CFrame.new(offset) * transform * frame
            part.Color = record.color:Lerp(Color3.new(1, 1, 1), math.min(0.65, state.glow))
        end
    end
    return controller
end

return PilotMotion
