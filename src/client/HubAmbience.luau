--!nonstrict
-- Cosmetic client-only motion. No physics, gameplay RNG, or replicated updates.
local HubAmbience = {}
HubAmbience.__index = HubAmbience

function HubAmbience.new(worldModel)
    local self = setmetatable({ groups = {}, elapsed = 0, destroyed = false }, HubAmbience)
    if not worldModel then
        return self
    end
    for _, model in worldModel:GetDescendants() do
        if model:IsA("Model") and #self.groups < 10 then
            local kind = model:GetAttribute("HubMotion")
            if kind == "fish" or kind == "bubbles" then
                local pivot = model:GetPivot()
                local group = {
                    model = model,
                    kind = kind,
                    pivot = pivot,
                    phase = model:GetAttribute("MotionPhase") or 0,
                    scale = model:GetAttribute("MotionScale") or 1,
                    parts = {},
                }
                for _, object in model:GetDescendants() do
                    if object:IsA("BasePart") then
                        table.insert(group.parts, {
                            object = object,
                            cframe = object.CFrame,
                            relative = pivot:ToObjectSpace(object.CFrame),
                            transparency = object.Transparency,
                            fin = object.Name == "TailFin",
                        })
                    end
                end
                table.insert(self.groups, group)
            end
        end
    end
    return self
end

function HubAmbience:step(dt)
    if self.destroyed then
        return
    end
    self.elapsed += math.clamp(dt, 0, 0.1)
    local blend = 1 - math.exp(-self.elapsed * 4)
    for _, group in self.groups do
        if group.model.Parent then
            local phase = self.elapsed * 0.85 + group.phase
            if group.kind == "fish" then
                local motion = CFrame.new(
                    math.sin(phase) * 0.65 * group.scale * blend,
                    math.sin(phase * 1.3) * 0.23 * blend,
                    math.cos(phase * 0.7) * 0.28 * blend
                ) * CFrame.Angles(
                    0,
                    math.sin(phase) * 0.1 * blend,
                    math.sin(phase * 1.4) * 0.04 * blend
                )
                local pivot = group.pivot * motion
                group.model:PivotTo(pivot)
                for _, entry in group.parts do
                    if entry.fin and entry.object.Parent then
                        entry.object.CFrame = pivot
                            * entry.relative
                            * CFrame.Angles(
                                0,
                                math.sin(self.elapsed * 5 + group.phase) * 0.16 * blend,
                                0
                            )
                    end
                end
            else
                group.model:PivotTo(
                    group.pivot
                        * CFrame.new(
                            math.sin(phase * 0.8) * 0.16 * blend,
                            math.sin(phase) * 0.42 * blend,
                            math.cos(phase) * 0.12 * blend
                        )
                )
                for _, entry in group.parts do
                    if entry.object.Parent then
                        entry.object.Transparency = entry.transparency
                            + (1 - entry.transparency)
                                * 0.12
                                * (0.5 + math.sin(phase) * 0.5)
                                * blend
                    end
                end
            end
        end
    end
end

function HubAmbience:destroy()
    if self.destroyed then
        return
    end
    self.destroyed = true
    for _, group in self.groups do
        if group.model.Parent then
            group.model:PivotTo(group.pivot)
            -- Restore original parts explicitly: fin articulation must not remain
            -- in the model's pivot cache when the hub is opened again.
            for _, entry in group.parts do
                if entry.object.Parent then
                    entry.object.CFrame = entry.cframe
                    entry.object.Transparency = entry.transparency
                end
            end
        end
    end
    table.clear(self.groups)
end

return HubAmbience
