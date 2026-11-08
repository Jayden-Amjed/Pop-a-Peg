-- Local station guidance; server ownership/proximity checks remain authoritative.
local Theme = require(script.Parent.UiTheme)
local HubGuide = {}
HubGuide.__index = HubGuide

function HubGuide.new(player)
    local self = setmetatable({ player = player, prompts = {}, visible = true }, HubGuide)
    self.marker = Theme.make("BillboardGui", {
        Name = "PopAPegStationGuide",
        Size = UDim2.fromOffset(184, 54),
        StudsOffsetWorldSpace = Vector3.new(0, 2.4, 0),
        AlwaysOnTop = true,
        MaxDistance = 120,
        ResetOnSpawn = false,
        ZIndexBehavior = Enum.ZIndexBehavior.Global,
        Enabled = false,
    }, player:WaitForChild("PlayerGui"))
    local plate = Theme.plate(self.marker, "Plate", Theme.colors.paper, 3)
    plate.Size = UDim2.fromScale(1, 1)
    local border = plate:FindFirstChildWhichIsA("UIStroke")
    border.Color, border.Thickness = Theme.colors.gold, 3
    self.title = Theme.label(plate, "Station", "", 20, Theme.colors.ink, 5)
    self.title.Position, self.title.Size = UDim2.fromOffset(7, 5), UDim2.new(1, -14, 0, 24)
    self.title.TextXAlignment, self.title.TextStrokeTransparency = Enum.TextXAlignment.Center, 1
    self.detail = Theme.label(plate, "Action", "PLAY HERE", 16, Theme.colors.positive, 5)
    self.detail.Position, self.detail.Size = UDim2.fromOffset(7, 28), UDim2.new(1, -14, 0, 20)
    self.detail.TextXAlignment, self.detail.TextStrokeTransparency = Enum.TextXAlignment.Center, 1
    self.highlight = Theme.make("Highlight", {
        Name = "YourArcadeOutline",
        FillTransparency = 1,
        OutlineColor = Theme.colors.gold,
        OutlineTransparency = 0.15,
        DepthMode = Enum.HighlightDepthMode.Occluded,
        Enabled = false,
    }, self.marker)
    self.connection = workspace.DescendantAdded:Connect(function(object)
        if object:IsA("ProximityPrompt") and object.Name == "PlayArcade" then
            self:_track(object)
        elseif object.Name == "ControlDeck" then
            self:_attach()
        end
    end)
    for _, object in workspace:GetDescendants() do
        if object:IsA("ProximityPrompt") and object.Name == "PlayArcade" then
            self:_track(object)
        end
    end
    return self
end

function HubGuide:_track(prompt)
    if self.prompts[prompt] then
        return
    end
    local model = prompt:FindFirstAncestorWhichIsA("Model")
    if not model or type(model:GetAttribute("Station")) ~= "number" then
        return
    end
    self.prompts[prompt] = { enabled = prompt.Enabled, station = model:GetAttribute("Station") }
    prompt.Enabled = self.visible and self.station == self.prompts[prompt].station
end

function HubGuide:_attach()
    local world = workspace:FindFirstChild("AquariumArcade")
    local cabinet = world and self.station and world:FindFirstChild("ArcadeStation" .. self.station)
    local anchor = cabinet and cabinet:FindFirstChild("ControlDeck")
    if anchor and anchor:IsA("BasePart") then
        self.marker.Adornee = anchor
        self.highlight.Adornee = cabinet
    end
    self.marker.Enabled = self.visible and self.marker.Adornee ~= nil
    self.highlight.Enabled = self.marker.Enabled
end

function HubGuide:update(station, canResume)
    if self.destroyed then
        return
    end
    self.station = station
    self.title.Text = string.format("YOUR CABINET · %02d", station)
    self.detail.Text = if canResume then "RESUME HERE" else "PLAY HERE"
    for prompt, entry in self.prompts do
        if prompt.Parent then
            prompt.Enabled = self.visible and entry.station == station
            if entry.station == station then
                prompt.ActionText = if canResume then "Resume" else "Play"
            end
        else
            self.prompts[prompt] = nil
        end
    end
    self:_attach()
end

function HubGuide:setVisible(visible)
    if self.destroyed or visible == self.visible then
        return
    end
    self.visible = visible
    for prompt, entry in self.prompts do
        if prompt.Parent then
            prompt.Enabled = visible and entry.station == self.station
        end
    end
    self:_attach()
end

function HubGuide:destroy()
    if self.destroyed then
        return
    end
    self.destroyed = true
    self.connection:Disconnect()
    for prompt, entry in self.prompts do
        if prompt.Parent then
            prompt.Enabled = entry.enabled
        end
    end
    self.marker:Destroy()
    table.clear(self.prompts)
end

return HubGuide
