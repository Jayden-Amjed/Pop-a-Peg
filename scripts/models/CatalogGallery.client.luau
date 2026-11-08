-- A review tool: only the selected model and its optional native comparison mount.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local ContentProvider = game:GetService("ContentProvider")
local libraries = ReplicatedStorage:WaitForChild("CatalogLibrary")
local assets = ReplicatedStorage:WaitForChild("CatalogAssets")
local ItemModels = require(libraries.ItemModels)
local ItemMotion = require(libraries.ItemMotion)
local CatalogMotion = require(libraries.CatalogMotion)
local PreviewLighting = require(libraries.PreviewLighting)
local catalog = {}
for index, metadata in require(libraries.CatalogInfo) do
    local entry = table.clone(metadata)
    entry.index = index
    table.insert(catalog, entry)
end

local C = {
    ink = Color3.fromRGB(24, 51, 68),
    muted = Color3.fromRGB(81, 112, 129),
    pearl = Color3.fromRGB(242, 249, 252),
    panel = Color3.fromRGB(220, 236, 243),
    teal = Color3.fromRGB(35, 120, 148),
    aqua = Color3.fromRGB(64, 162, 184),
    navy = Color3.fromRGB(36, 72, 94),
    gold = Color3.fromRGB(238, 181, 59),
    line = Color3.fromRGB(135, 176, 195),
    red = Color3.fromRGB(167, 46, 48),
}
local gui = Instance.new("ScreenGui")
gui.Name = "CatalogInspector"
gui.IgnoreGuiInset = true
gui.ResetOnSpawn = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Global
gui:SetAttribute("SelectedId", "")
gui:SetAttribute("Pose", -1)
gui:SetAttribute("CurrentPose", 0)
gui:SetAttribute("Speed", 1)
gui:SetAttribute("Strength", 1)
gui:SetAttribute("Loop", false)
gui:SetAttribute("Paused", false)
gui:SetAttribute("Ready", false)
gui:SetAttribute("LoadedCount", 0)
gui:SetAttribute("Failures", "")
gui:SetAttribute("CameraView", "Three-quarter")
gui:SetAttribute("Zoom", 1)
gui:SetAttribute("LightingPreset", "Balanced")
gui:SetAttribute("NativeComparison", false)
gui:SetAttribute("TotalCount", #catalog)
gui:SetAttribute("CompletedCycles", 0)
gui:SetAttribute("MountedModels", 0)
gui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")

local function make(className, parent, properties)
    local object = Instance.new(className)
    for key, value in properties do
        object[key] = value
    end
    object.Parent = parent
    return object
end
local function round(object, radius)
    make("UICorner", object, { CornerRadius = UDim.new(0, radius or 10) })
end
local function stroke(object, color, thickness)
    return make("UIStroke", object, {
        Color = color or C.line,
        Thickness = thickness or 1,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
    })
end
local function text(parent, name, value, size, color)
    return make("TextLabel", parent, {
        Name = name,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Text = value,
        Font = Enum.Font.GothamMedium,
        TextSize = size or 14,
        TextColor3 = color or C.ink,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Center,
        ZIndex = 5,
    })
end
local function rect(object, x, y, width, height)
    object.Position, object.Size = UDim2.fromOffset(x, y), UDim2.fromOffset(width, height)
end
local function button(parent, name, value, callback)
    local object = make("TextButton", parent, {
        Name = name,
        Text = value,
        BackgroundColor3 = C.teal,
        BorderSizePixel = 0,
        Font = Enum.Font.GothamBold,
        TextSize = 13,
        TextColor3 = C.pearl,
        AutoButtonColor = true,
        ZIndex = 5,
    })
    round(object, 7)
    object.Activated:Connect(callback)
    return object
end
local root = make("Frame", gui, {
    Name = "Root",
    Size = UDim2.fromScale(1, 1),
    BackgroundColor3 = Color3.fromRGB(185, 215, 225),
    BorderSizePixel = 0,
})
make("UIGradient", root, {
    Color = ColorSequence.new(Color3.fromRGB(239, 250, 252), Color3.fromRGB(168, 202, 219)),
    Rotation = 90,
})
local function panel(name)
    local frame = make(
        "Frame",
        root,
        { Name = name, BackgroundColor3 = C.pearl, BorderSizePixel = 0, ZIndex = 2 }
    )
    round(frame, 13)
    stroke(frame, C.line, 1)
    local depth = make("Frame", frame, {
        Name = "PanelShadow",
        BackgroundColor3 = C.navy,
        BackgroundTransparency = 0.7,
        Position = UDim2.fromOffset(0, 4),
        Size = UDim2.fromScale(1, 1),
        BorderSizePixel = 0,
        ZIndex = 1,
    })
    round(depth, 13)
    return frame
end
local header = text(root, "Title", "POP A PEG  /  MODEL INSPECTOR", 24)
header.Font = Enum.Font.GothamBold
local subtitle = text(
    root,
    "Subtitle",
    "Choose an item, slow its animation, and tag the exact pose for feedback.",
    13,
    C.muted
)
local libraryPanel, viewerPanel, controlsPanel =
    panel("Library"), panel("Viewer"), panel("Controls")
local libraryTitle = text(libraryPanel, "LibraryTitle", "MODEL LIBRARY", 14)
libraryTitle.Font = Enum.Font.GothamBold
local search = make("TextBox", libraryPanel, {
    Name = "Search",
    Text = "",
    PlaceholderText = "Search name or ID",
    ClearTextOnFocus = false,
    BackgroundColor3 = C.panel,
    BorderSizePixel = 0,
    Font = Enum.Font.GothamMedium,
    TextSize = 14,
    TextColor3 = C.ink,
    PlaceholderColor3 = C.muted,
    ZIndex = 5,
})
round(search, 7)
local categoryIndex = 1
local categories = {
    { "all", "All types" },
    { "equipment", "Equipment" },
    { "evolved", "Evolutions" },
    { "perk", "Perks" },
    { "consumable", "Supplies" },
    { "utility", "Utility / chests" },
}
local filterList
local category = button(libraryPanel, "Category", "All types  ›", function()
    categoryIndex = categoryIndex % #categories + 1
    filterList()
end)
category.BackgroundColor3 = C.navy
local list = make("ScrollingFrame", libraryPanel, {
    Name = "ModelList",
    BackgroundTransparency = 1,
    BorderSizePixel = 0,
    ScrollBarThickness = 5,
    ScrollBarImageColor3 = C.teal,
    CanvasSize = UDim2.fromOffset(0, 0),
    AutomaticCanvasSize = Enum.AutomaticSize.Y,
    ScrollingDirection = Enum.ScrollingDirection.Y,
    ZIndex = 4,
})
make("UIListLayout", list, { Padding = UDim.new(0, 5), SortOrder = Enum.SortOrder.LayoutOrder })
make("UIPadding", list, {
    PaddingTop = UDim.new(0, 3),
    PaddingLeft = UDim.new(0, 3),
    PaddingRight = UDim.new(0, 7),
    PaddingBottom = UDim.new(0, 5),
})

local title = text(viewerPanel, "ModelName", "Loading catalog…", 23)
title.Font = Enum.Font.GothamBold
local identity = text(viewerPanel, "ModelIdentity", "", 12, C.muted)
local trigger = text(viewerPanel, "Trigger", "", 13, C.teal)
local previewArea =
    make("Frame", viewerPanel, { Name = "PreviewArea", BackgroundTransparency = 1, ZIndex = 3 })
local function viewport(name)
    local view = make("ViewportFrame", previewArea, {
        Name = name,
        BackgroundColor3 = PreviewLighting.presets.Balanced.background,
        BorderSizePixel = 0,
        ZIndex = 3,
    })
    round(view, 10)
    local caption = text(
        view,
        "SourceCaption",
        if name == "BlenderViewport" then "BLENDER" else "CURRENT NATIVE",
        11,
        C.navy
    )
    caption.Position, caption.Size = UDim2.fromOffset(10, 6), UDim2.new(1, -20, 0, 18)
    return view
end
local blenderView, nativeView = viewport("BlenderViewport"), viewport("NativeViewport")
nativeView.Visible = false
local loadStatus = text(previewArea, "LoadStatus", "Loading…", 16, C.red)
loadStatus.TextXAlignment = Enum.TextXAlignment.Center
loadStatus.TextWrapped, loadStatus.ZIndex = true, 7
loadStatus.Size = UDim2.fromScale(1, 1)
local zoomButton = button(previewArea, "ZoomFit", "ZOOM 100% · FIT", function()
    gui:SetAttribute("Zoom", 1)
end)
zoomButton.AnchorPoint = Vector2.new(1, 0)
zoomButton.Position, zoomButton.Size = UDim2.new(1, -8, 0, 5), UDim2.fromOffset(128, 26)
zoomButton.TextSize, zoomButton.ZIndex = 11, 8
local zoomHint =
    text(previewArea, "ZoomHint", "Mouse wheel to zoom · Click zoom to fit", 11, C.navy)
zoomHint.Position, zoomHint.Size = UDim2.new(0, 8, 1, -22), UDim2.new(1, -16, 0, 18)
zoomHint.TextXAlignment, zoomHint.ZIndex = Enum.TextXAlignment.Center, 8
local cameraButtons = {}
local cameraNames = { "Front", "Three-quarter", "Side", "Rear" }
local directions = {
    Front = Vector3.new(0, 0.16, 1),
    ["Three-quarter"] = Vector3.new(0.72, 0.43, 1),
    Side = Vector3.new(1, 0.2, 0),
    Rear = Vector3.new(0, 0.2, -1),
}
for _, name in cameraNames do
    cameraButtons[name] = button(
        viewerPanel,
        name .. "Camera",
        if name == "Three-quarter" then "3/4" else name,
        function()
            gui:SetAttribute("CameraView", name)
        end
    )
end
local stats = text(viewerPanel, "GeometryStats", "", 12, C.muted)
local frameTag = text(viewerPanel, "FrameTag", "", 12, C.ink)
frameTag.Font = Enum.Font.Code
local navigation = text(root, "Navigation", "", 14, C.muted)
navigation.TextXAlignment = Enum.TextXAlignment.Center

local byId, rows, filtered = {}, {}, {}
local selected, mounts = nil, {}
local epoch = 0
local loadedIds, loadedCount = {}, 0
local notes, changingNote = {}, false
local noteBox
local playing, elapsed, cooldown = false, 0, 0
local hover = ItemMotion.newHover(true)
local hoverPose = ItemMotion.idleSample(0)
local currentPose = 0
local function numberAttribute(name, default, minimum, maximum)
    local value = gui:GetAttribute(name)
    if type(value) ~= "number" or value ~= value then
        return default
    end
    return math.clamp(value, minimum, maximum)
end
local function clearMounts()
    for _, mount in mounts do
        mount.model:Destroy()
        mount.camera:Destroy()
    end
    table.clear(mounts)
    blenderView.CurrentCamera, nativeView.CurrentCamera = nil, nil
    gui:SetAttribute("MountedModels", 0)
end
local function includeBounds(model, lower, upper)
    local frame, size = model:GetBoundingBox()
    for _, x in { -1, 1 } do
        for _, y in { -1, 1 } do
            for _, z in { -1, 1 } do
                local corner = frame:PointToWorldSpace(size * Vector3.new(x, y, z) / 2)
                lower, upper = lower:Min(corner), upper:Max(corner)
            end
        end
    end
    return lower, upper
end
local function makeMount(view, model, id, isBlender)
    model.Parent = view
    local camera = make("Camera", view, { Name = "ModelCamera", FieldOfView = 30 })
    view.CurrentCamera = camera
    -- Register ownership before creating the controller so failed mounts clean up.
    local mount = { model = model, camera = camera, view = view }
    table.insert(mounts, mount)
    assert(model:FindFirstChildWhichIsA("BasePart", true), "Model contains no renderable pieces")
    local motion = if isBlender then CatalogMotion.new(model) else ItemMotion.new(model, id)
    local _, restSize = model:GetBoundingBox()
    local lower, upper = includeBounds(model, Vector3.one * math.huge, -Vector3.one * math.huge)
    for step = 0, 40 do
        motion:apply(step / 40, 2, CFrame.new())
        lower, upper = includeBounds(model, lower, upper)
    end
    for _, pose in { 0.0773, 0.2426 } do
        motion:apply(pose, 2, CFrame.new())
        lower, upper = includeBounds(model, lower, upper)
    end
    motion:apply(0, 1, CFrame.new())
    mount.motion, mount.size, mount.lower, mount.upper = motion, restSize, lower, upper
    return mount
end
local function startAt(pose)
    gui:SetAttribute("Pose", -1)
    gui:SetAttribute("Paused", false)
    elapsed = (mounts[1] and mounts[1].motion.duration or 1) * (pose or 0)
    playing, cooldown = true, 0
end
local function changeSelection(id, preservePlayback)
    local entry = byId[id]
    if not entry then
        gui:SetAttribute("Ready", false)
        gui:SetAttribute("Failures", "Unknown item ID: " .. tostring(id))
        loadStatus.Text, loadStatus.Visible = "Unknown item ID: " .. tostring(id), true
        return
    end
    if selected and noteBox and not changingNote then
        notes[selected.id] = noteBox.Text
    end
    selected = entry
    epoch += 1
    local request = epoch
    clearMounts()
    gui:SetAttribute("Ready", false)
    gui:SetAttribute("Failures", "")
    if not preservePlayback then
        gui:SetAttribute("Pose", -1)
        gui:SetAttribute("Paused", false)
        playing, elapsed, cooldown, currentPose = false, 0, 0, 0
        hover, hoverPose = ItemMotion.newHover(true), ItemMotion.idleSample(0)
    end
    title.Text = entry.name
    identity.Text = entry.id .. "  •  " .. entry.category
    trigger.Text = tostring(entry.trigger or "Activation preview")
    navigation.Text = string.format("%02d / %02d", entry.index, #catalog)
    changingNote = true
    if noteBox then
        noteBox.Text = notes[id] or ""
    end
    changingNote = false
    for rowId, row in rows do
        local active = rowId == id
        row.button.BackgroundColor3 = if active then Color3.fromRGB(255, 245, 215) else C.panel
        row.border.Color, row.border.Thickness =
            if active then C.gold else C.line, if active then 3 else 1
    end
    loadStatus.Text, loadStatus.Visible = "Loading meshes…", true
    task.spawn(function()
        if request ~= epoch then
            return
        end
        local source = assets:FindFirstChild(id)
        if not source then
            gui:SetAttribute("Failures", "Missing model: " .. id)
            loadStatus.Text = "Missing Blender model: " .. id
            return
        end
        local model = source:Clone()
        local ok, failure = pcall(function()
            makeMount(blenderView, model, id, true)
            if gui:GetAttribute("NativeComparison") then
                makeMount(nativeView, ItemModels.create(id, 1), id, false)
            end
        end)
        if not ok then
            if request == epoch then
                clearMounts()
                gui:SetAttribute("Failures", tostring(failure))
                loadStatus.Text = "Model animation failed to mount. See Output."
                warn("[RBX-021] " .. id .. ": " .. tostring(failure))
            end
            return
        end
        local failures = {}
        local content = {}
        for _, mount in mounts do
            table.insert(content, mount.model)
        end
        local preloadOk, preloadError = pcall(function()
            ContentProvider:PreloadAsync(content, function(assetId, status)
                if status ~= Enum.AssetFetchStatus.Success then
                    table.insert(failures, tostring(assetId))
                end
            end)
        end)
        if request ~= epoch then
            return
        end
        if not preloadOk then
            table.insert(failures, tostring(preloadError))
        end
        if #failures > 0 then
            gui:SetAttribute("Failures", table.concat(failures, ", "))
            loadStatus.Text = "Mesh load failed. Check asset access, then select again."
            return
        end
        if not loadedIds[id] then
            loadedIds[id] = true
            loadedCount += 1
        end
        stats.Text = string.format(
            "%s triangles  •  %s mesh pieces  •  %s",
            tostring(source:GetAttribute("TriangleCount") or "?"),
            tostring(source:GetAttribute("PartCount") or #source:GetChildren()),
            tostring(ItemMotion.Profiles[id].name)
        )
        gui:SetAttribute("LoadedCount", loadedCount)
        gui:SetAttribute("MountedModels", #mounts)
        gui:SetAttribute("Ready", true)
        loadStatus.Visible = false
        if not preservePlayback and gui:GetAttribute("Loop") then
            startAt(0)
        end
    end)
end
for index, entry in catalog do
    byId[entry.id] = entry
    local row = button(list, "Item_" .. entry.id, entry.name, function()
        if gui:GetAttribute("SelectedId") == entry.id then
            if not gui:GetAttribute("Ready") then
                changeSelection(entry.id)
            end
        else
            gui:SetAttribute("SelectedId", entry.id)
        end
    end)
    row.LayoutOrder, row.Size = index, UDim2.new(1, 0, 0, 36)
    row.TextColor3, row.BackgroundColor3, row.TextSize = C.ink, C.panel, 13
    row.TextXAlignment = Enum.TextXAlignment.Left
    make("UIPadding", row, { PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 5) })
    row.TextTruncate = Enum.TextTruncate.AtEnd
    rows[entry.id] = { button = row, border = stroke(row) }
end
filterList = function()
    table.clear(filtered)
    local query, kind = string.lower(search.Text), categories[categoryIndex][1]
    category.Text = categories[categoryIndex][2] .. "  ›"
    for _, entry in catalog do
        local matches = (kind == "all" or entry.category == kind)
            and (
                query == ""
                or string.find(string.lower(entry.name .. " " .. entry.id), query, 1, true)
                    ~= nil
            )
        rows[entry.id].button.Visible = matches
        if matches then
            table.insert(filtered, entry)
        end
    end
    libraryTitle.Text = string.format("MODEL LIBRARY  %d / %d", #filtered, #catalog)
    list.CanvasPosition = Vector2.zero
end
search:GetPropertyChangedSignal("Text"):Connect(filterList)
local function advance(delta)
    if #filtered == 0 then
        return
    end
    local index = 0
    for i, entry in filtered do
        if selected and entry.id == selected.id then
            index = i
            break
        end
    end
    gui:SetAttribute("SelectedId", filtered[(index - 1 + delta) % #filtered + 1].id)
end
local previous = button(root, "Previous", "‹ PREV", function()
    advance(-1)
end)
local nextButton = button(root, "Next", "NEXT ›", function()
    advance(1)
end)

local animationTitle = text(controlsPanel, "AnimationTitle", "ANIMATION", 14)
animationTitle.Font = Enum.Font.GothamBold
local triggerButton = button(controlsPanel, "Trigger", "TRIGGER", function()
    startAt(0)
end)
local pauseButton = button(controlsPanel, "Pause", "PAUSE", function()
    local pose = numberAttribute("Pose", -1, -1, 1)
    if pose >= 0 then
        startAt(pose)
    else
        gui:SetAttribute("Paused", not gui:GetAttribute("Paused"))
    end
end)
local loopButton = button(controlsPanel, "Loop", "LOOP OFF", function()
    gui:SetAttribute("Loop", not gui:GetAttribute("Loop"))
end)
local compareButton = button(controlsPanel, "Compare", "COMPARE NATIVE", function()
    gui:SetAttribute("NativeComparison", not gui:GetAttribute("NativeComparison"))
end)
local speedLabel = text(controlsPanel, "SpeedLabel", "PLAYBACK SPEED", 11, C.muted)
local speedButtons = {}
for _, speed in { 0.25, 0.5, 1, 2 } do
    speedButtons[speed] = button(
        controlsPanel,
        "Speed" .. tostring(speed),
        tostring(speed) .. "×",
        function()
            gui:SetAttribute("Speed", speed)
        end
    )
end
local strengthButton = button(controlsPanel, "Strength", "STRENGTH 1×", function()
    gui:SetAttribute("Strength", if gui:GetAttribute("Strength") == 1 then 2 else 1)
end)
local lightButton = button(controlsPanel, "Lighting", "LIGHT: BALANCED", function()
    gui:SetAttribute(
        "LightingPreset",
        if gui:GetAttribute("LightingPreset") == "Balanced" then "Original" else "Balanced"
    )
end)
local poseLabel = text(controlsPanel, "PoseLabel", "POSE  0.000", 12)
local restButton = button(controlsPanel, "Rest", "REST", function()
    gui:SetAttribute("Pose", 0)
end)
local track = make("TextButton", controlsPanel, {
    Name = "PoseTrack",
    Text = "",
    BackgroundColor3 = C.navy,
    BorderSizePixel = 0,
    AutoButtonColor = false,
    ZIndex = 5,
})
round(track, 6)
local fill = make("Frame", track, {
    Name = "Fill",
    Size = UDim2.fromScale(0, 1),
    BackgroundColor3 = C.aqua,
    BorderSizePixel = 0,
    ZIndex = 6,
})
round(fill, 6)
local knob = make("Frame", track, {
    Name = "Knob",
    AnchorPoint = Vector2.new(0.5, 0.5),
    Position = UDim2.fromScale(0, 0.5),
    Size = UDim2.fromOffset(18, 18),
    BackgroundColor3 = C.gold,
    BorderSizePixel = 0,
    ZIndex = 7,
})
round(knob, 9)
local dragInput, dragging = nil, false
local function scrub(position)
    gui:SetAttribute(
        "Pose",
        math.clamp(
            (position.X - track.AbsolutePosition.X) / math.max(1, track.AbsoluteSize.X),
            0,
            1
        )
    )
end
track.InputBegan:Connect(function(input)
    if
        input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch
    then
        dragging, dragInput = true, input
        scrub(input.Position)
    end
end)
UserInputService.InputChanged:Connect(function(input)
    if
        dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input == dragInput)
    then
        scrub(input.Position)
    end
end)
UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input == dragInput then
        dragging, dragInput = false, nil
    end
end)
local noteTitle = text(controlsPanel, "NotesTitle", "FEEDBACK FOR THIS ITEM", 11, C.muted)
noteBox = make("TextBox", controlsPanel, {
    Name = "Notes",
    Text = "",
    PlaceholderText = "Shape, clipping, motion, lighting…",
    ClearTextOnFocus = false,
    MultiLine = true,
    TextWrapped = true,
    TextXAlignment = Enum.TextXAlignment.Left,
    TextYAlignment = Enum.TextYAlignment.Top,
    BackgroundColor3 = C.panel,
    BorderSizePixel = 0,
    Font = Enum.Font.GothamMedium,
    TextSize = 12,
    TextColor3 = C.ink,
    PlaceholderColor3 = C.muted,
    ZIndex = 5,
})
round(noteBox, 7)
make("UIPadding", noteBox, {
    PaddingLeft = UDim.new(0, 7),
    PaddingRight = UDim.new(0, 7),
    PaddingTop = UDim.new(0, 6),
    PaddingBottom = UDim.new(0, 6),
})
noteBox:GetPropertyChangedSignal("Text"):Connect(function()
    if selected and not changingNote then
        notes[selected.id] = noteBox.Text
    end
end)
local function contextTag()
    return string.format(
        "%s | pose %.3f | %s× | strength %s | %s | zoom %.4f× | %s",
        selected and selected.id or "none",
        currentPose,
        tostring(gui:GetAttribute("Speed")),
        tostring(gui:GetAttribute("Strength")),
        tostring(gui:GetAttribute("CameraView")),
        numberAttribute("Zoom", 1, 0.6, 2.5),
        tostring(gui:GetAttribute("LightingPreset"))
    )
end
local tagButton = button(controlsPanel, "TagPose", "TAG POSE", function()
    noteBox.Text = noteBox.Text
        .. (if noteBox.Text == "" then "" else "\n")
        .. "["
        .. contextTag()
        .. "]\n"
    noteBox:CaptureFocus()
    noteBox.CursorPosition = #noteBox.Text + 1
end)
local exportModal = make("Frame", gui, {
    Name = "FeedbackExport",
    Visible = false,
    BackgroundColor3 = C.pearl,
    BorderSizePixel = 0,
    ZIndex = 50,
    AnchorPoint = Vector2.new(0.5, 0.5),
    Position = UDim2.fromScale(0.5, 0.5),
    Size = UDim2.fromScale(0.75, 0.72),
})
round(exportModal, 14)
stroke(exportModal, C.teal, 3)
local exportTitle = text(exportModal, "Title", "COPY YOUR FEEDBACK", 19)
exportTitle.ZIndex, exportTitle.Position, exportTitle.Size =
    51, UDim2.fromOffset(18, 12), UDim2.new(1, -36, 0, 30)
local exportText = make("TextBox", exportModal, {
    Name = "ExportText",
    Text = "",
    ClearTextOnFocus = false,
    MultiLine = true,
    TextWrapped = true,
    TextXAlignment = Enum.TextXAlignment.Left,
    TextYAlignment = Enum.TextYAlignment.Top,
    Font = Enum.Font.Code,
    TextSize = 14,
    TextColor3 = C.ink,
    BackgroundColor3 = C.panel,
    BorderSizePixel = 0,
    Position = UDim2.fromOffset(18, 52),
    Size = UDim2.new(1, -36, 1, -108),
    ZIndex = 51,
})
round(exportText, 7)
local exportHint = text(
    exportModal,
    "Hint",
    "Select and copy this text. Notes clear when this Play session stops.",
    12,
    C.muted
)
exportHint.ZIndex, exportHint.Position, exportHint.Size =
    51, UDim2.new(0, 18, 1, -49), UDim2.new(1, -130, 0, 34)
local closeExport = button(exportModal, "Close", "CLOSE", function()
    exportModal.Visible = false
end)
closeExport.ZIndex, closeExport.Position, closeExport.Size =
    52, UDim2.new(1, -100, 1, -44), UDim2.fromOffset(82, 30)
local exportButton = button(controlsPanel, "ExportNotes", "COPY NOTES", function()
    local lines = { "Pop a Peg model review", "Viewer at export: [" .. contextTag() .. "]", "" }
    for _, entry in catalog do
        local note = notes[entry.id]
        if note and note:match("%S") then
            table.insert(lines, entry.name .. " (" .. entry.id .. ")\n" .. note .. "\n")
        end
    end
    exportText.Text, exportModal.Visible = table.concat(lines, "\n"), true
    exportText:CaptureFocus()
    exportText.CursorPosition, exportText.SelectionStart = #exportText.Text + 1, 1
end)
local sessionHint =
    text(controlsPanel, "SessionHint", "Notes stay in this Play session.", 10, C.muted)

local function layout()
    local width, height = root.AbsoluteSize.X, root.AbsoluteSize.Y
    local gap, pad = 12, 12
    local left = math.clamp(width * 0.205, 164, 250)
    local right = math.clamp(width * 0.235, 224, 280)
    local middle = width - left - right - gap * 2 - pad * 2
    local top, contentHeight = 70, math.max(390, height - 82)
    rect(header, 16, 10, width - 320, 28)
    rect(subtitle, 16, 40, width - 32, 19)
    rect(previous, width - 284, 15, 82, 29)
    rect(navigation, width - 195, 15, 90, 29)
    rect(nextButton, width - 100, 15, 84, 29)
    rect(libraryPanel, pad, top, left, contentHeight)
    rect(viewerPanel, pad + left + gap, top, middle, contentHeight)
    rect(controlsPanel, width - pad - right, top, right, contentHeight)
    rect(libraryTitle, 12, 10, left - 24, 22)
    rect(search, 12, 40, left - 24, 32)
    rect(category, 12, 80, left - 24, 28)
    rect(list, 8, 117, left - 16, contentHeight - 129)
    rect(title, 14, 11, middle - 28, 30)
    rect(identity, 14, 43, middle - 28, 18)
    rect(trigger, 14, 64, middle - 28, 20)
    trigger.TextTruncate = Enum.TextTruncate.AtEnd
    rect(previewArea, 12, 92, middle - 24, contentHeight - 184)
    local compare = gui:GetAttribute("NativeComparison")
    nativeView.Visible = compare
    if compare then
        blenderView.Position, blenderView.Size = UDim2.fromScale(0, 0), UDim2.new(0.5, -4, 1, 0)
        nativeView.Position, nativeView.Size = UDim2.new(0.5, 4, 0, 0), UDim2.new(0.5, -4, 1, 0)
    else
        blenderView.Position, blenderView.Size = UDim2.fromScale(0, 0), UDim2.fromScale(1, 1)
    end
    local cameraWidth = (middle - 42) / 4
    for index, name in cameraNames do
        rect(
            cameraButtons[name],
            12 + (index - 1) * (cameraWidth + 6),
            contentHeight - 81,
            cameraWidth,
            28
        )
    end
    rect(stats, 14, contentHeight - 49, middle - 28, 18)
    stats.TextTruncate = Enum.TextTruncate.AtEnd
    rect(frameTag, 14, contentHeight - 28, middle - 28, 18)
    frameTag.TextTruncate = Enum.TextTruncate.AtEnd
    local half = (right - 30) / 2
    rect(animationTitle, 12, 10, right - 24, 22)
    rect(triggerButton, 12, 41, half, 32)
    rect(pauseButton, 18 + half, 41, half, 32)
    rect(loopButton, 12, 81, half, 28)
    rect(compareButton, 18 + half, 81, half, 28)
    compareButton.TextSize = 11
    rect(speedLabel, 12, 121, right - 24, 18)
    for index, speed in { 0.25, 0.5, 1, 2 } do
        rect(
            speedButtons[speed],
            12 + (index - 1) * ((right - 42) / 4 + 6),
            145,
            (right - 42) / 4,
            28
        )
    end
    rect(strengthButton, 12, 184, half, 29)
    rect(lightButton, 18 + half, 184, half, 29)
    strengthButton.TextSize, lightButton.TextSize = 10, 10
    rect(poseLabel, 12, 223, right - 100, 23)
    rect(restButton, right - 77, 221, 65, 26)
    rect(track, 20, 259, right - 40, 11)
    rect(noteTitle, 12, 282, right - 24, 18)
    rect(noteBox, 12, 306, right - 24, math.max(30, contentHeight - 367))
    rect(tagButton, 12, contentHeight - 53, half, 28)
    rect(exportButton, 18 + half, contentHeight - 53, half, 28)
    tagButton.TextSize, exportButton.TextSize = 11, 11
    rect(sessionHint, 12, contentHeight - 21, right - 24, 16)
end
local function appearance()
    local presetName = gui:GetAttribute("LightingPreset")
    for _, view in { blenderView, nativeView } do
        local preset = PreviewLighting.apply(view, presetName)
        view.BackgroundColor3 = preset.background
    end
    loopButton.Text = if gui:GetAttribute("Loop") then "LOOP ON" else "LOOP OFF"
    loopButton.BackgroundColor3 = if gui:GetAttribute("Loop") then C.aqua else C.teal
    compareButton.Text = if gui:GetAttribute("NativeComparison")
        then "HIDE NATIVE"
        else "COMPARE NATIVE"
    strengthButton.Text = "STRENGTH " .. tostring(gui:GetAttribute("Strength")) .. "×"
    lightButton.Text = "LIGHT: " .. string.upper(tostring(presetName))
    zoomButton.Text =
        string.format("ZOOM %.0f%% · FIT", numberAttribute("Zoom", 1, 0.6, 2.5) * 100)
    for speed, b in speedButtons do
        local active = speed == gui:GetAttribute("Speed")
        b.BackgroundColor3, b.TextColor3 =
            if active then C.gold else C.teal, if active then C.ink else C.pearl
    end
    for name, b in cameraButtons do
        local active = name == gui:GetAttribute("CameraView")
        b.BackgroundColor3, b.TextColor3 =
            if active then C.gold else C.teal, if active then C.ink else C.pearl
    end
end
gui:GetAttributeChangedSignal("SelectedId"):Connect(function()
    changeSelection(gui:GetAttribute("SelectedId"))
end)
gui:GetAttributeChangedSignal("NativeComparison"):Connect(function()
    layout()
    appearance()
    if selected then
        changeSelection(selected.id, true)
    end
end)
for _, name in { "LightingPreset", "CameraView", "Speed", "Strength" } do
    gui:GetAttributeChangedSignal(name):Connect(appearance)
end
gui:GetAttributeChangedSignal("Zoom"):Connect(function()
    local normalized = numberAttribute("Zoom", 1, 0.6, 2.5)
    if gui:GetAttribute("Zoom") ~= normalized then
        gui:SetAttribute("Zoom", normalized)
    else
        appearance()
    end
end)
gui:GetAttributeChangedSignal("Loop"):Connect(function()
    appearance()
    if gui:GetAttribute("Loop") and not playing and numberAttribute("Pose", -1, -1, 1) < 0 then
        startAt(0)
    end
end)
root:GetPropertyChangedSignal("AbsoluteSize"):Connect(layout)
UserInputService.InputChanged:Connect(function(input)
    if input.UserInputType ~= Enum.UserInputType.MouseWheel or exportModal.Visible then
        return
    end
    local mouse = UserInputService:GetMouseLocation()
    local origin, size = previewArea.AbsolutePosition, previewArea.AbsoluteSize
    if
        mouse.X >= origin.X
        and mouse.X <= origin.X + size.X
        and mouse.Y >= origin.Y
        and mouse.Y <= origin.Y + size.Y
    then
        gui:SetAttribute(
            "Zoom",
            math.clamp(numberAttribute("Zoom", 1, 0.6, 2.5) * 1.16 ^ input.Position.Z, 0.6, 2.5)
        )
    end
end)
UserInputService.InputBegan:Connect(function(input, processed)
    if processed or UserInputService:GetFocusedTextBox() or exportModal.Visible then
        return
    end
    if input.KeyCode == Enum.KeyCode.Right then
        advance(1)
    elseif input.KeyCode == Enum.KeyCode.Left then
        advance(-1)
    elseif input.KeyCode == Enum.KeyCode.Space then
        startAt(0)
    end
end)
layout()
appearance()
filterList()
gui:SetAttribute("SelectedId", catalog[1] and catalog[1].id or "")
local labelClock = 0
RunService.RenderStepped:Connect(function(dt)
    if not gui:GetAttribute("Ready") or #mounts == 0 then
        return
    end
    local explicit = numberAttribute("Pose", -1, -1, 1)
    local speed = numberAttribute("Speed", 1, 0.1, 4)
    local paused = gui:GetAttribute("Paused") == true
    local delta = math.min(dt, 0.1) * speed
    if explicit >= 0 then
        currentPose = explicit
    elseif not paused then
        if playing then
            elapsed += delta
            if elapsed >= mounts[1].motion.duration then
                playing, cooldown = false, 0
                gui:SetAttribute("CompletedCycles", (gui:GetAttribute("CompletedCycles") or 0) + 1)
            end
        elseif gui:GetAttribute("Loop") then
            cooldown += delta
            if cooldown >= 0.6 then
                playing, elapsed, cooldown = true, 0, 0
            end
        end
        currentPose = if playing then math.clamp(elapsed / mounts[1].motion.duration, 0, 1) else 0
        hoverPose = ItemMotion.stepHover(hover, delta, playing)
    end
    -- Both comparison views use one camera fit, preserving a fair size comparison.
    local lower, upper = mounts[1].lower, mounts[1].upper
    for _, mount in mounts do
        lower, upper = lower:Min(mount.lower), upper:Max(mount.upper)
    end
    local target, radius = (lower + upper) / 2, (upper - lower).Magnitude / 2
    for _, mount in mounts do
        local dimensions = mount.view.AbsoluteSize
        local aspect = dimensions.X / math.max(1, dimensions.Y)
        local halfFov = math.rad(15)
        local limiting = math.min(halfFov, math.atan(math.tan(halfFov) * aspect))
        local direction = directions[gui:GetAttribute("CameraView")] or directions["Three-quarter"]
        local distance = radius * 1.13 / math.sin(limiting) / numberAttribute("Zoom", 1, 0.6, 2.5)
        mount.camera.CFrame = CFrame.lookAt(target + direction.Unit * distance, target)
        local rootPose = CFrame.new()
        if explicit < 0 then
            rootPose = CFrame.new(
                mount.camera.CFrame.RightVector * hoverPose.x * mount.size.X
                    + mount.camera.CFrame.UpVector * hoverPose.y * mount.size.Y
            ) * CFrame.Angles(hoverPose.pitch, hoverPose.yaw, hoverPose.roll)
        end
        mount.motion:apply(currentPose, numberAttribute("Strength", 1, 0, 2), rootPose)
    end
    fill.Size, knob.Position = UDim2.fromScale(currentPose, 1), UDim2.fromScale(currentPose, 0.5)
    gui:SetAttribute("CurrentPose", currentPose)
    pauseButton.Text = if paused or explicit >= 0 then "RESUME" else "PAUSE"
    labelClock += dt
    if labelClock >= 0.05 then
        labelClock = 0
        poseLabel.Text = string.format("POSE  %.3f", currentPose)
        frameTag.Text = string.format(
            "%s  |  pose %.3f  |  %s×",
            selected.id,
            currentPose,
            tostring(gui:GetAttribute("Speed"))
        )
    end
end)
print(
    string.format(
        "[RBX-021] Inspector catalog ready: %d entries; selected-model loading is tracked separately",
        #catalog
    )
)
