-- Visual QA only. Run in the isolated catalog Client; six live/held performances.
-- options.page covers the whole catalog, or options.ids selects a showcase.
return function(options)
    options = options or {}
    local library = game.ReplicatedStorage.CatalogLibrary
    local catalog = require(library.CatalogInfo)
    local Motion, Lighting = require(library.CatalogMotion), require(library.PreviewLighting)
    local playerGui = game.Players.LocalPlayer.PlayerGui
    local previous = playerGui:FindFirstChild("MotionVisualSheet")
    if previous then
        previous:Destroy()
    end
    local gui = Instance.new("ScreenGui")
    gui.Name, gui.IgnoreGuiInset, gui.DisplayOrder = "MotionVisualSheet", true, 2000
    gui:SetAttribute("Pose", options.pose or 0)
    gui:SetAttribute("Loop", options.loop == true)
    local function label(parent, text, position, size, fontSize)
        local object = Instance.new("TextLabel")
        object.Text, object.Position, object.Size = text, position, size
        object.TextColor3, object.BackgroundTransparency = Color3.fromRGB(20, 51, 69), 1
        object.Font, object.TextSize, object.TextWrapped =
            Enum.Font.SourceSansSemibold, fontSize, true
        object.Parent = parent
        return object
    end
    local bg = Instance.new("Frame")
    bg.Size, bg.BackgroundColor3, bg.BorderSizePixel =
        UDim2.fromScale(1, 1), Color3.fromRGB(229, 243, 248), 0
    bg.Parent = gui
    label(
        bg,
        "POP A PEG  /  EXPRESSIVE TRIGGER STUDY",
        UDim2.fromOffset(8, 3),
        UDim2.new(1, -16, 0, 27),
        23
    )
    local stage = Instance.new("Frame")
    stage.Position, stage.Size, stage.BackgroundTransparency =
        UDim2.fromOffset(0, 34), UDim2.new(1, 0, 1, -34), 1
    stage.Parent = bg
    local selected = {}
    if options.ids then
        for _, id in options.ids do
            for _, entry in catalog do
                if entry.id == id then
                    table.insert(selected, entry)
                end
            end
        end
    else
        for index = ((options.page or 1) - 1) * 6 + 1, math.min((options.page or 1) * 6, #catalog) do
            table.insert(selected, catalog[index])
        end
    end
    local mounts = {}
    for index, entry in selected do
        local card = Instance.new("Frame")
        card.Position = UDim2.new((index - 1) % 3 / 3, 5, math.floor((index - 1) / 3) / 2, 5)
        card.Size, card.BackgroundColor3, card.BorderSizePixel =
            UDim2.new(1 / 3, -10, 1 / 2, -10), Color3.fromRGB(171, 201, 214), 0
        card.Parent = stage
        local viewport = Instance.new("ViewportFrame")
        viewport.Position, viewport.Size, viewport.BackgroundTransparency =
            UDim2.fromOffset(0, 28), UDim2.new(1, 0, 1, -62), 1
        Lighting.apply(viewport)
        viewport.Parent = card
        local model = game.ReplicatedStorage.CatalogAssets[entry.id]:Clone()
        model.Parent = viewport
        local controller = Motion.new(model)
        local low, high = Vector3.one * math.huge, -Vector3.one * math.huge
        for sample = 0, 40 do
            controller:apply(sample / 40, 1, CFrame.new())
            local frame, size = model:GetBoundingBox()
            low, high = low:Min(frame.Position - size / 2), high:Max(frame.Position + size / 2)
        end
        controller:apply(0, 1, CFrame.new())
        local camera = Instance.new("Camera")
        camera.FieldOfView, camera.Parent, viewport.CurrentCamera = 30, viewport, camera
        label(card, entry.name, UDim2.fromOffset(4, 0), UDim2.new(1, -8, 0, 28), 21)
        label(card, controller.profile, UDim2.new(0, 5, 1, -32), UDim2.new(1, -10, 0, 30), 14)
        table.insert(mounts, {
            view = viewport,
            model = model,
            motion = controller,
            camera = camera,
            center = (low + high) / 2,
            radius = (high - low).Magnitude / 2,
        })
    end
    gui.Parent = playerGui
    local age, connection = 0, nil
    connection = game:GetService("RunService").RenderStepped:Connect(function(dt)
        if not gui.Parent then
            connection:Disconnect()
            return
        end
        age += math.min(dt, 0.1)
        for _, mount in mounts do
            local aspect = mount.view.AbsoluteSize.X / math.max(1, mount.view.AbsoluteSize.Y)
            local limiting = math.min(math.rad(15), math.atan(math.tan(math.rad(15)) * aspect))
            mount.camera.CFrame = CFrame.lookAt(
                mount.center
                    + Vector3.new(0.72, 0.43, 1).Unit * mount.radius * 1.05 / math.sin(limiting),
                mount.center
            )
            local t = if gui:GetAttribute("Loop")
                then math.min((age % (mount.motion.duration + 0.4)) / mount.motion.duration, 1)
                else gui:GetAttribute("Pose") or 0
            mount.motion:apply(t, 1, CFrame.new())
        end
    end)
    return {
        ids = options.ids or selected,
        models = #mounts,
        mode = if options.loop then "live" else "held",
    }
end
