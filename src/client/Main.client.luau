--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local StarterGui = game:GetService("StarterGui")
local ContextActionService = game:GetService("ContextActionService")
local Presentation = require(script.Parent.Presentation)
local HubPresentation = require(script.Parent.HubPresentation)
local Theme = require(script.Parent.UiTheme)
local player = Players.LocalPlayer
local remotes = ReplicatedStorage:WaitForChild("PegRemotes")
local actionRemote = remotes:WaitForChild("Action")
local stateRemote = remotes:WaitForChild("State")

pcall(function()
    StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false)
    StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.PlayerList, false)
    StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Health, false)
end)

local view, mode, snapshot
local muted = false
local completedReceipt
local rememberedRunId
local controls
local function action(kind, payload)
    actionRemote:FireServer(kind, payload)
end

local function restoreCamera()
    local camera = workspace.CurrentCamera
    local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
    if camera then
        camera.CameraType = Enum.CameraType.Custom
        camera.FieldOfView = 70
        if humanoid then
            camera.CameraSubject = humanoid
        end
    end
end

local function setMovement(inRun)
    if inRun then
        ContextActionService:BindActionAtPriority(
            "PegRunMovement",
            function()
                return Enum.ContextActionResult.Sink
            end,
            false,
            3000,
            Enum.PlayerActions.CharacterForward,
            Enum.PlayerActions.CharacterBackward,
            Enum.PlayerActions.CharacterLeft,
            Enum.PlayerActions.CharacterRight
        )
        if controls then
            controls:Disable()
        end
    else
        ContextActionService:UnbindAction("PegRunMovement")
        if controls then
            controls:Enable()
        end
        restoreCamera()
    end
end

task.spawn(function()
    local playerScripts = player:WaitForChild("PlayerScripts")
    local playerModule = playerScripts:WaitForChild("PlayerModule", 15)
    if playerModule then
        local ok, result = pcall(function()
            return require(playerModule):GetControls()
        end)
        if ok then
            controls = result
            setMovement(mode == "run")
        end
    end
end)

player.CharacterAdded:Connect(function(character)
    character:WaitForChild("Humanoid", 10)
    if mode ~= "run" then
        restoreCamera()
    end
end)

local returnGui = Theme.make("ScreenGui", {
    Name = "PopAPegSession",
    ResetOnSpawn = false,
    IgnoreGuiInset = true,
    DisplayOrder = 50,
    Enabled = false,
}, player:WaitForChild("PlayerGui"))
local returnButton = Theme.button(returnGui, "Arcade", "ARCADE", Theme.colors.paper, function()
    if
        mode == "run"
        and snapshot
        and snapshot.phase ~= "flight"
        and snapshot.phase ~= "settling"
        and not view.busy
    then
        action("enterHub", {})
    end
end, 5)
returnButton.AnchorPoint = Vector2.new(1, 0)
returnButton.Position = UDim2.new(1, -14, 0, 6)
returnButton.Size = UDim2.fromOffset(126, 30)
returnButton.TextSize = 16
returnButton.TextColor3 = Theme.colors.ink
returnButton.TextStrokeTransparency = 1

local function changeMode(nextMode)
    if mode == nextMode then
        return
    end
    if view then
        if mode == "run" then
            muted = view.muted == true
            completedReceipt = view.feedback.completedReceipt
        end
        view:destroy()
    end
    mode = nextMode
    setMovement(mode == "run")
    if mode == "run" then
        view = Presentation.new(action)
        view.muted = muted
        view.feedback:setMuted(muted)
        -- A paused shop may still carry its last settlement receipt. Do not replay
        -- rewards or send a second continue request when its board is remounted.
        view.feedback.completedReceipt = completedReceipt
    else
        view = HubPresentation.new(action)
    end
    returnGui.Enabled = mode == "run"
end

local received = false
local lastSequence = 0
stateRemote.OnClientEvent:Connect(function(nextSnapshot)
    if type(nextSnapshot) ~= "table" or (nextSnapshot.sequence or 0) <= lastSequence then
        return
    end
    received = true
    lastSequence = nextSnapshot.sequence
    snapshot = nextSnapshot
    if snapshot.sessionView ~= "hub" and snapshot.runId ~= rememberedRunId then
        rememberedRunId = snapshot.runId
        completedReceipt = nil
        if mode == "run" then
            view.feedback.completedReceipt = nil
        end
    end
    changeMode(snapshot.sessionView == "hub" and "hub" or "run")
    view:update(snapshot)
    if snapshot.notice and view.setNotice then
        view:setNotice(snapshot.notice)
    end
end)
RunService.RenderStepped:Connect(function(dt)
    if view then
        view:step(math.min(dt, 0.1))
        if mode == "run" then
            local enabled = snapshot.phase ~= "flight"
                and snapshot.phase ~= "settling"
                and not view.busy
            if enabled ~= returnButton.Active then
                Theme.setEnabled(returnButton, enabled, Theme.colors.paper)
                returnButton.Text = enabled and "ARCADE" or "FINISH SHOT"
            end
        end
    end
end)
task.spawn(function()
    repeat
        actionRemote:FireServer("ready")
        task.wait(1)
    until received
end)

print("[Pop a Peg] Arcade and board controls ready")
