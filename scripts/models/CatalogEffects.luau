-- A deterministic, bounded ViewportFrame renderer. No emitters, physics, clocks,
-- event connections or transient allocations are needed while scrubbing poses.
local Profiles = if script
    then require(script.Parent.CatalogEffectProfiles)
    else require("./CatalogEffectProfiles")
local Motion = if script
    then require(script.Parent.BlenderChoreography)
    else require("./BlenderChoreography")
local CatalogEffects = {}

-- Attach accents to the functional assembly rather than the model's base.
local attachments = {
    coin_press = "MintCoin",
    seed_bank = "Seed",
    survey_lens = "Lens",
    split_prism = "Prism",
    gain_dial = "Knob",
    clockwork = "MinuteHand",
    growth_array = "Coral",
    nectar_pump = "NectarDrop",
    rain_catcher = "RainWater",
    pulse_cell = "ChargeBar",
    goldfish = "FishTail",
    landing_fund = "CatchCoin",
    lily_pad = "LilyHeart",
    mist_fan = "PaperRotor",
    pearl_diver = "DiverPearl",
    ozone_orb = "OzoneShell",
    soft_saw = "Current",
    bubble_wand = "Bubble",
}
local function finite(value, fallback)
    return if type(value) == "number"
            and value >= -math.huge
            and value <= math.huge
        then value
        else fallback
end
function CatalogEffects.new(model, id)
    id = id or model:GetAttribute("ItemId")
    local profile = assert(Profiles.entries[id], "Unknown catalog effect: " .. tostring(id))
    local _, size = model:GetBoundingBox()
    local scale = math.min(size.X, size.Y, size.Z)
    scale = math.max(scale, math.max(size.X, size.Y, size.Z) * 0.35)
    local records, center = {}, Vector3.zero
    for _, part in model:GetDescendants() do
        if part:IsA("BasePart") then
            local authored = part:GetAttribute("AuthoredPosition") or part.Position
            if #records == 0 then
                center = authored - part.Position
            end
            table.insert(records, {
                part = part,
                frame = part.CFrame,
                authored = authored,
                group = part:GetAttribute("MotionGroup") or "Fixed",
            })
        end
    end
    local poolModel = Instance.new("Model")
    poolModel.Name = "CatalogEffects"
    poolModel:SetAttribute("CatalogEffect", true)
    poolModel:SetAttribute("ItemId", id)
    local pool = {}
    for i = 1, Profiles.MaxParts do
        local part = Instance.new("Part")
        part.Name = string.format("Accent%02d", i)
        part.Anchored, part.CanCollide, part.CanTouch, part.CanQuery = true, false, false, false
        part.CastShadow, part.Transparency = false, 1
        part.Material = Enum.Material.Neon
        part.Size = Vector3.new(0.01, 0.01, 0.01)
        part.Parent = poolModel
        pool[i] = part
    end
    poolModel.Parent = model.Parent
    local controller = { model = poolModel, profile = profile.name, activeCount = 0 }
    local disposed = false
    local function normalized(v)
        return { v.X / size.X, v.Y / size.Y, v.Z / size.Z }
    end
    function controller:apply(t, strength, rootPose)
        if disposed then
            return
        end
        t, strength = math.clamp(finite(t, 0), 0, 1), math.clamp(finite(strength, 1), 0, 2)
        rootPose = rootPose or CFrame.identity
        local body = Motion.bodySample(id, t, strength)
        local root = rootPose
            * CFrame.new(body.x * size.X, body.y * size.Y, body.z * size.Z)
            * CFrame.Angles(body.rx, body.ry, body.rz)
        local function localPoint(world)
            return normalized(root:PointToObjectSpace(world) / body.scale)
        end
        local function source(x, y, z)
            return normalized(Vector3.new(x, y, z) - center)
        end
        local function groupPoint(group, side, sourcePosition)
            local sum, count = Vector3.zero, 0
            for _, record in records do
                if
                    record.group == group and (not side or (record.authored.X < 0) == (side < 0))
                then
                    local position = record.part.Position
                    if sourcePosition then
                        position = record.part.CFrame:PointToWorldSpace(
                            record.frame:PointToObjectSpace(sourcePosition - center)
                        )
                    end
                    sum += position
                    count += 1
                end
            end
            return if count > 0 then localPoint(sum / count) else nil
        end
        local context = {}
        if id == "coral_fork" then
            context.left, context.right = groupPoint("CoralTip", -1), groupPoint("CoralTip", 1)
        elseif id == "relay" then
            -- The winding reaches +0.427 studs toward the camera. Put the
            -- discharge just in front of it, not inside the opaque core.
            context.left, context.right = source(-0.56, 1.04, 0.51), source(0.56, 1.04, 0.51)
            context.terminalLeft, context.terminalRight =
                source(-0.74, 0.55, 0.10), source(0.74, 0.55, 0.10)
        elseif id == "dew_lantern" then
            context.origin = groupPoint("LanternDrop")
        elseif id == "lagoon_synth" then
            context.low, context.high = source(-0.64, 0.96, -0.08), source(0.64, 0.96, -0.08)
            context.amplitude = 0.10 / size.Y
        elseif id == "encore" then
            context.left = groupPoint("Horn", -1, Vector3.new(-0.54, 1.52, 0.30))
            context.right = groupPoint("Horn", 1, Vector3.new(0.54, 1.52, 0.30))
        elseif attachments[id] then
            context.offset = groupPoint(attachments[id])
        end
        local accents = Profiles.sample(id, t, strength, context)
        self.activeCount = #accents
        local function world(q)
            return root:PointToWorldSpace(
                Vector3.new(q[1] * size.X, q[2] * size.Y, q[3] * size.Z) * body.scale
            )
        end
        for i, part in pool do
            local accent = accents[i]
            if not accent or accent.alpha < 0.002 then
                part.Transparency = 1
                continue
            end
            local diameter = math.max(0.008, accent.radius * scale * 2 * body.scale)
            local position = world(accent.a)
            if accent.kind == "ball" then
                part.Shape = Enum.PartType.Ball
                part.Size = Vector3.one * diameter
                part.CFrame = CFrame.new(position)
            else
                local target = world(accent.b)
                local distance = (target - position).Magnitude
                part.Shape = Enum.PartType.Block
                part.Size = Vector3.new(diameter, diameter, math.max(distance, 0.008))
                part.CFrame = if distance > 0.00001
                    then CFrame.lookAt((position + target) * 0.5, target)
                    else CFrame.new(position)
            end
            part.Color = Color3.new(accent.color[1], accent.color[2], accent.color[3])
            part.Transparency = 1 - accent.alpha
        end
    end
    function controller:bounds()
        if disposed then
            return nil, nil
        end
        local lower, upper
        for _, part in pool do
            if part.Transparency >= 0.998 then
                continue
            end
            local cf, half = part.CFrame, part.Size * 0.5
            local x, y, z = cf.RightVector, cf.UpVector, cf.LookVector
            local radius = Vector3.new(
                math.abs(x.X) * half.X + math.abs(y.X) * half.Y + math.abs(z.X) * half.Z,
                math.abs(x.Y) * half.X + math.abs(y.Y) * half.Y + math.abs(z.Y) * half.Z,
                math.abs(x.Z) * half.X + math.abs(y.Z) * half.Y + math.abs(z.Z) * half.Z
            )
            local lo, hi = part.Position - radius, part.Position + radius
            lower = if lower then lower:Min(lo) else lo
            upper = if upper then upper:Max(hi) else hi
        end
        return lower, upper
    end
    function controller:destroy()
        if disposed then
            return
        end
        disposed, self.activeCount = true, 0
        poolModel:Destroy()
        table.clear(records)
        table.clear(pool)
    end
    return controller
end
return CatalogEffects
