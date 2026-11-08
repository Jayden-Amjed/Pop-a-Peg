-- Opt-in native comparison gallery. Destroy ModelRenderQA or stop Play afterward.
local Models = require(game.StarterPlayer.StarterPlayerScripts.Client.ItemModels)
local playerGui = game.Players.LocalPlayer.PlayerGui
assert(not playerGui:FindFirstChild("ModelRenderQA"), "Remove the previous diagnostic gallery")
local gui = Instance.new("ScreenGui")
gui.Name, gui.DisplayOrder, gui.IgnoreGuiInset = "ModelRenderQA", 100, true
gui.Parent = playerGui
local background = Instance.new("Frame")
background.Size, background.BackgroundColor3 = UDim2.fromScale(1, 1), Color3.fromRGB(231, 245, 249)
background.Parent = gui
local handles = {}
for row = 1, 2 do
    for column, id in { "fishbowl", "seed_bank", "biolume_jar" } do
        local card = Instance.new("Frame")
        card.Position = UDim2.fromScale((column - 1) / 3, (row - 1) / 2)
        card.Size, card.BackgroundTransparency = UDim2.fromScale(1 / 3, 1 / 2), 1
        card.Parent = background
        local label = Instance.new("TextLabel")
        label.Size, label.BackgroundTransparency = UDim2.new(1, 0, 0, 30), 1
        label.Text = id .. (row == 1 and " · DEFAULT" or " · OUTLINE OFF")
        label.Font, label.TextSize = Enum.Font.SourceSansBold, 18
        label.TextColor3 = Color3.fromRGB(18, 55, 72)
        label.Parent = card
        local viewport = Instance.new("ViewportFrame")
        viewport.Name = "Item_" .. row .. "_" .. column
        viewport.Size, viewport.Position = UDim2.new(1, -20, 1, -40), UDim2.fromOffset(10, 30)
        viewport.BackgroundTransparency, viewport.ZIndex = 1, 10
        viewport.Parent = card
        table.insert(
            handles,
            Models.mount(viewport, id, 5, { animate = false, outline = row == 1 })
        )
    end
end
gui.Destroying:Connect(function()
    for _, handle in handles do
        handle:destroy()
    end
end)
return "Native glass model comparison gallery ready"
