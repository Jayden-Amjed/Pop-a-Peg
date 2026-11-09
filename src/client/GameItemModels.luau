-- Gameplay adopts the reviewed Blender catalog through this adapter. The native
-- builders/choreography remain a frozen comparison and an explicit load fallback.
local storage = game:GetService("ReplicatedStorage")
local content = game:GetService("ContentProvider")
local assets = storage:WaitForChild("CatalogAssets")
local library = storage:WaitForChild("CatalogLibrary")
local Catalog = require(library.CatalogInfo)
local Motion = require(library.CatalogMotion)
local Effects = require(library.CatalogEffects)
local Idle = require(script.Parent.ItemMotion)
local Native = require(script.Parent.ItemModels)
local Lighting = require(script.Parent.PreviewLighting)
local Playback = require(script.Parent.GameModelPlayback)
local GameItemModels = {}

local aliases = {
    ball = "life",
    coins = "coin",
    grow = "event_growth",
    repair = "event_repair",
    upgrade = "event_upgrade",
    overtime = "event_overtime",
}
local metadata, ids, loads, envelopes = {}, {}, {}, {}
for _, entry in Catalog do
    metadata[entry.id] = entry
    table.insert(ids, entry.id)
end
GameItemModels.Ids = table.freeze(ids)
local activeMounts = setmetatable({}, { __mode = "k" })
local loadQueue, loading = {}, 0
local pumpLoads

local function canonicalId(id)
    return aliases[id] or id
end

local function requestLoad(id)
    local current = loads[id]
    if current then
        return current
    end
    current = { state = "Loading", failures = {} }
    loads[id] = current
    table.insert(loadQueue, id)
    pumpLoads()
    return current
end

pumpLoads = function()
    -- Limit simultaneous remote preload jobs; all instances of an ID share one.
    while loading < 4 and #loadQueue > 0 do
        local id = table.remove(loadQueue, 1)
        local result = loads[id]
        loading += 1
        task.spawn(function()
            local template = assets:FindFirstChild(id)
            local ok, failure = pcall(function()
                assert(template, "Missing catalog template: " .. id)
                content:PreloadAsync({ template }, function(assetId, status)
                    if status ~= Enum.AssetFetchStatus.Success then
                        table.insert(result.failures, tostring(assetId) .. ": " .. tostring(status))
                    end
                end)
            end)
            if not ok then
                table.insert(result.failures, tostring(failure))
            end
            result.state = if ok and #result.failures == 0 then "Ready" else "Failed"
            if result.state == "Failed" then
                warn("[Blender models] " .. id .. " could not load; using frozen native fallback")
            end
            loading -= 1
            pumpLoads()
        end)
    end
end

function GameItemModels.preload(requested)
    for _, id in requested or ids do
        id = canonicalId(id)
        assert(metadata[id], "Unknown item model: " .. tostring(id))
        requestLoad(id)
    end
end

function GameItemModels.loadStatus(id)
    local result = loads[canonicalId(id)]
    return if result then result.state else "NotRequested"
end

function GameItemModels.create(id, level)
    local canonical = canonicalId(id)
    local entry = assert(metadata[canonical], "Unknown item model: " .. tostring(id))
    local template =
        assert(assets:FindFirstChild(canonical), "Missing catalog template: " .. canonical)
    local model = template:Clone()
    model.Name = "Item_" .. id
    model:SetAttribute("ItemId", canonical)
    model:SetAttribute("RequestedItemId", id)
    local numericLevel = tonumber(level)
    if not numericLevel or numericLevel ~= numericLevel then
        numericLevel = 1
    end
    model:SetAttribute(
        "ItemLevel",
        if entry.category == "evolved" then 5 else math.clamp(math.floor(numericLevel), 1, 5)
    )
    model:SetAttribute("Category", entry.category)
    model:SetAttribute("RenderBackend", "Blender")
    model:SetAttribute("RenderLoadState", requestLoad(canonical).state)
    model.WorldPivot = CFrame.identity
    return model
end

local function measure(model, motion, canonical, reduced)
    local key = canonical .. (if reduced then ":reduced" else ":full")
    if envelopes[key] then
        return envelopes[key]
    end
    local frame, size = model:GetBoundingBox()
    local low, high = frame.Position - size / 2, frame.Position + size / 2
    if not reduced then
        -- One temporary pool and envelope per ID, not one sweep per coin/card.
        local effects = Effects.new(model, canonical)
        for sample = 0, 40 do
            local t = sample / 40
            motion:apply(t, 2, CFrame.identity)
            effects:apply(t, 2, CFrame.identity)
            frame, size = model:GetBoundingBox()
            low, high = low:Min(frame.Position - size / 2), high:Max(frame.Position + size / 2)
            local effectLow, effectHigh = effects:bounds()
            if effectLow then
                low, high = low:Min(effectLow), high:Max(effectHigh)
            end
        end
        motion:apply(0, 1, CFrame.identity)
        effects:destroy()
    end
    local envelope = { focus = (low + high) / 2, radius = (high - low).Magnitude / 2 }
    envelopes[key] = envelope
    return envelope
end

function GameItemModels.mount(viewport, id, level, options)
    assert(viewport:IsA("ViewportFrame"), "GameItemModels.mount requires a ViewportFrame")
    options = options or {}
    local previous = activeMounts[viewport]
    if previous then
        previous:destroy()
    end
    local canonical = canonicalId(id)
    local model = GameItemModels.create(id, level)
    local load = loads[canonical]
    local container = Instance.new("Model")
    container.Name, container.Parent = "ItemDisplay", viewport
    model.Parent = container
    local camera = Instance.new("Camera")
    camera.Name, camera.FieldOfView, camera.Parent = "ItemCamera", 30, container
    viewport.CurrentCamera = camera
    Lighting.apply(viewport, options.lightingPreset)
    local motion = Motion.new(model)
    local size = motion.restSize
    local reduced = options.reducedMotion == true
    local envelope = measure(model, motion, canonical, reduced)
    local handle = { model = model, backend = "Blender" }
    local clock = Playback.new(motion.duration)
    local hover = Idle.newHover(options.animate ~= false and not reduced)
    local idleFrame, rootPose = CFrame.identity, CFrame.identity
    local aimAngle, aimFrom, currentAim = 0, 0, 0
    local effects, fallback, destroyConnection
    local destroyed, lastLoad = false, nil
    local lastWidth, lastHeight = -1, -1
    local phase = 0
    local rest = {}
    if reduced then
        for _, part in model:GetDescendants() do
            if part:IsA("BasePart") then
                table.insert(rest, { part = part, frame = part.CFrame, size = part.Size })
            end
        end
    end

    local function fit()
        local dimensions = viewport.AbsoluteSize
        if lastWidth == dimensions.X and lastHeight == dimensions.Y then
            return
        end
        lastWidth, lastHeight = dimensions.X, dimensions.Y
        local aspect = if dimensions.X > 0 and dimensions.Y > 0
            then dimensions.X / dimensions.Y
            else 1
        local half = math.rad(camera.FieldOfView / 2)
        local limiting = math.min(half, math.atan(math.tan(half) * aspect))
        local distance = envelope.radius * 1.13 / math.sin(limiting)
        camera.CFrame = CFrame.lookAt(
            envelope.focus + Vector3.new(0.72, 0.43, 1).Unit * distance,
            envelope.focus
        )
    end

    local function loadState()
        if load.state == lastLoad then
            return
        end
        lastLoad = load.state
        model:SetAttribute("RenderLoadState", load.state)
        viewport:SetAttribute("RenderLoadState", load.state)
        viewport:SetAttribute("RenderBackend", handle.backend)
    end

    local function begin()
        phase = 0
        aimFrom, aimAngle = currentAim, 0
        local params = clock.params
        if type(params) == "table" then
            local direction, angle = params.direction, nil
            if
                typeof(direction) == "Vector2"
                and direction.Magnitude > 0
                and direction.Magnitude < math.huge
            then
                angle = math.atan2(direction.Y, direction.X)
            elseif
                type(direction) == "number"
                and direction == direction
                and math.abs(direction) < math.huge
            then
                angle = direction
            end
            if angle then
                local up = idleFrame.UpVector
                local base =
                    math.atan2(-camera.CFrame.UpVector:Dot(up), camera.CFrame.RightVector:Dot(up))
                aimAngle = (angle - base + math.pi) % (math.pi * 2) - math.pi
                aimAngle = aimFrom + (aimAngle - aimFrom + math.pi) % (math.pi * 2) - math.pi
            end
            if type(params.effect) == "string" then
                model:SetAttribute("ActivationEffect", params.effect)
            end
        end
        if not reduced and not effects then
            -- Capture functional anchors in the same centered rest coordinates
            -- as the gallery, not from the currently rotated idle pose.
            model:PivotTo(CFrame.identity)
            effects = Effects.new(model, canonical)
            model:PivotTo(idleFrame)
        end
    end

    local function installFallback()
        local wasActive, strength, params = clock.active, clock.strength, clock.params
        local tint, uniform = nil, true
        for _, part in model:GetDescendants() do
            if part:IsA("BasePart") then
                if tint and part.Color ~= tint then
                    uniform = false
                end
                tint = tint or part.Color
            end
        end
        if effects then
            effects:destroy()
            effects = nil
        end
        container:Destroy()
        fallback = Native.mount(viewport, id, level, options)
        handle.model, handle.backend = fallback.model, "NativeFallback"
        handle.model:SetAttribute("RenderBackend", handle.backend)
        handle.model:SetAttribute("RenderLoadState", "Failed")
        viewport:SetAttribute("RenderBackend", handle.backend)
        viewport:SetAttribute("RenderLoadState", "Failed")
        if uniform and tint then
            for _, part in handle.model:GetDescendants() do
                if part:IsA("BasePart") then
                    part.Color = tint
                end
            end
        end
        clock:reset()
        if wasActive then
            fallback:pulse(strength, params)
        end
    end

    function handle:step(dt)
        if destroyed then
            return
        end
        if fallback then
            fallback:step(dt)
            return
        end
        loadState()
        if load.state == "Failed" then
            installFallback()
            return
        end
        fit()
        local delta = if type(dt) == "number" and dt == dt then math.clamp(dt, 0, 0.1) else 0
        local pose = Idle.stepHover(hover, delta, clock.active)
        idleFrame = CFrame.new(
            camera.CFrame.RightVector * pose.x * size.X + camera.CFrame.UpVector * pose.y * size.Y
        ) * CFrame.Angles(pose.pitch, pose.yaw, pose.roll)
        rootPose = idleFrame
        if not clock.active then
            -- Locked collection cards recolor the clone after mounting. Avoid
            -- restoring template colors on every idle frame.
            model:PivotTo(rootPose)
            return
        end
        local completed
        phase, completed = clock:step(delta)
        if canonical == "split_prism" and not reduced then
            local aim = if phase < 0.18
                then phase / 0.18
                elseif phase < 0.54 then 1
                else (1 - phase) / 0.46
            aim = aim * aim * (3 - 2 * aim)
            currentAim = if phase < 0.18
                then aimFrom + (aimAngle - aimFrom) * aim
                else aimAngle * aim
            rootPose = CFrame.new(idleFrame.Position)
                * CFrame.fromAxisAngle(camera.CFrame.LookVector, currentAim)
                * idleFrame.Rotation
        end
        model:PivotTo(rootPose)
        if reduced then
            -- Match the native accessibility behavior: a small scale pulse,
            -- without articulated spins, camera-facing aim or transient effects.
            local bump = math.sin(math.pi * phase) ^ 2
            local scale = 1 + 0.04 * bump
            for _, record in rest do
                record.part.CFrame = rootPose
                    * CFrame.new(record.frame.Position * scale)
                    * record.frame.Rotation
                record.part.Size = record.size * scale
            end
        else
            motion:apply(phase, clock.strength, rootPose)
            if effects then
                effects:apply(phase, clock.strength, rootPose)
            end
        end
        if completed and clock:dequeue() then
            begin()
        end
    end

    function handle:pulse(amount, params)
        if destroyed then
            return
        end
        if fallback then
            fallback:pulse(amount, params)
            return
        end
        if clock:pulse(amount, params) == "started" then
            begin()
        end
    end

    function handle:isAnimating()
        return not destroyed and (if fallback then fallback:isAnimating() else clock.active)
    end

    function handle:inspect()
        return {
            backend = self.backend,
            loadState = load.state,
            phase = phase,
            strength = clock.strength,
            active = self:isAnimating(),
            effectParts = if effects then #effects.model:GetChildren() else 0,
            visibleEffects = if effects then effects.activeCount else 0,
            rootPose = rootPose,
            camera = if fallback then viewport.CurrentCamera else camera,
        }
    end

    function handle:destroy()
        if destroyed then
            return
        end
        destroyed = true
        clock:reset()
        if destroyConnection then
            destroyConnection:Disconnect()
        end
        if activeMounts[viewport] == self then
            activeMounts[viewport] = nil
        end
        if fallback then
            fallback:destroy()
        end
        if effects then
            effects:destroy()
            effects = nil
        end
        if viewport.CurrentCamera == camera then
            viewport.CurrentCamera = nil
        end
        container:Destroy()
    end
    destroyConnection = viewport.Destroying:Connect(function()
        handle:destroy()
    end)
    activeMounts[viewport] = handle
    loadState()
    fit()
    handle:step(0)
    return handle
end

return GameItemModels
