--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local StarterGui = game:GetService("StarterGui")
local Presentation = require(script.Parent.Presentation)
local remotes = ReplicatedStorage:WaitForChild("PegRemotes")
local actionRemote = remotes:WaitForChild("Action")
local stateRemote = remotes:WaitForChild("State")

pcall(function()
    StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false)
    StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.PlayerList, false)
    StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Health, false)
end)

local view = Presentation.new(function(kind, payload)
    actionRemote:FireServer(kind, payload)
end)
local received = false
local lastSequence = 0
stateRemote.OnClientEvent:Connect(function(snapshot)
    if type(snapshot) ~= "table" or (snapshot.sequence or 0) <= lastSequence then
        return
    end
    received = true
    lastSequence = snapshot.sequence
    view:update(snapshot)
    if snapshot.notice and view.setNotice then
        view:setNotice(snapshot.notice)
    end
end)
RunService.RenderStepped:Connect(function(dt)
    view:step(math.min(dt, 0.1))
end)
task.spawn(function()
    repeat
        actionRemote:FireServer("ready")
        task.wait(1)
    until received
end)

print("[Pop a Peg] Board controls ready")
