-- Optional visual QA helper. Run only in the isolated gallery Client DataModel.
-- Call with page (six models per page) and held activation pose 0..1.
return function(page, pose)
    local rs = game:GetService("ReplicatedStorage")
    local guiRoot = game.Players.LocalPlayer.PlayerGui
    local old = guiRoot:FindFirstChild("CatalogVisualSheet")
    if old then
        old:Destroy()
    end
    local gui = Instance.new("ScreenGui")
    gui.Name, gui.IgnoreGuiInset, gui.DisplayOrder = "CatalogVisualSheet", true, 2000
    local bg = Instance.new("Frame")
    bg.Size, bg.BackgroundColor3, bg.BorderSizePixel =
        UDim2.fromScale(1, 1), Color3.fromRGB(226, 240, 246), 0
    bg.Parent = gui
    local catalog = require(rs.CatalogLibrary.CatalogInfo)
    local Motion = require(rs.CatalogLibrary.CatalogMotion)
    local Lighting = require(rs.CatalogLibrary.PreviewLighting)
    local result = {}
    for slot = 1, 6 do
        local info = catalog[(page - 1) * 6 + slot]
        if not info then
            break
        end
        local card = Instance.new("Frame")
        card.Position = UDim2.new((slot - 1) % 3 / 3, 6, math.floor((slot - 1) / 3) / 2, 6)
        card.Size = UDim2.new(1 / 3, -12, 1 / 2, -12)
        card.BackgroundColor3, card.BorderSizePixel = Color3.fromRGB(157, 189, 204), 0
        card.Parent = bg
        local v = Instance.new("ViewportFrame")
        v.Size, v.BackgroundTransparency = UDim2.new(1, 0, 1, -40), 1
        Lighting.apply(v)
        v.Parent = card
        local m = rs.CatalogAssets[info.id]:Clone()
        m.Parent = v
        Motion.new(m):apply(pose or 0, 1, CFrame.new())
        local frame, size = m:GetBoundingBox()
        local cam = Instance.new("Camera")
        cam.FieldOfView = 32
        cam.CFrame = CFrame.lookAt(
            frame.Position
                + Vector3.new(0.72, 0.43, 1).Unit
                    * size.Magnitude
                    * 0.55
                    / math.sin(math.rad(16)),
            frame.Position
        )
        cam.Parent, v.CurrentCamera = v, cam
        local label = Instance.new("TextLabel")
        label.Size, label.Position = UDim2.new(1, -8, 0, 38), UDim2.new(0, 4, 1, -40)
        label.BackgroundTransparency, label.TextColor3 = 1, Color3.fromRGB(18, 49, 71)
        label.Font, label.TextSize = Enum.Font.SourceSansSemibold, 16
        label.Text = info.name .. "  /  " .. info.id
        label.TextWrapped, label.Parent = true, card
        table.insert(result, info.id)
    end
    gui.Parent = guiRoot
    return result
end
