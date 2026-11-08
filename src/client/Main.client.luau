--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local StarterGui = game:GetService("StarterGui")
local ContextActionService = game:GetService("ContextActionService")
local GuiService = game:GetService("GuiService")
local Presentation = require(script.Parent.Presentation)
local HubPresentation = require(script.Parent.HubPresentation)
local HubGuide = require(script.Parent.HubGuide)
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
local movementBlocked = false
local transitionPending, transitionStarted
local function action(kind, payload)
    if kind == "startRun" or kind == "enterHub" then
        if transitionPending then
            return
        end
        transitionPending = if kind == "startRun" then "run" else "hub"
        transitionStarted = os.clock()
        if view and view.setTransitionPending then
            view:setTransitionPending(true)
        end
    end
    actionRemote:FireServer(kind, payload)
end

local loadingGui = Theme.make("ScreenGui", {
    Name = "PopAPegLoading",
    ResetOnSpawn = false,
    IgnoreGuiInset = false,
    DisplayOrder = 70,
    ZIndexBehavior = Enum.ZIndexBehavior.Global,
}, player:WaitForChild("PlayerGui"))
local loadingPanel = Theme.plate(loadingGui, "Connection", Theme.colors.paper, 3)
loadingPanel.AnchorPoint = Vector2.new(0.5, 0.5)
loadingPanel.Position = UDim2.fromScale(0.5, 0.5)
loadingPanel.Size = UDim2.new(0.86, 0, 0, 112)
Theme.make("UISizeConstraint", { MaxSize = Vector2.new(420, 112) }, loadingPanel)
local loadingTitle =
    Theme.label(loadingPanel, "Title", "WELCOME TO THE ARCADE", 23, Theme.colors.ink, 5)
loadingTitle.Position, loadingTitle.Size = UDim2.fromOffset(16, 14), UDim2.new(1, -32, 0, 34)
loadingTitle.TextScaled, loadingTitle.TextStrokeTransparency = true, 1
Theme.make("UITextSizeConstraint", { MinTextSize = 15, MaxTextSize = 23 }, loadingTitle)
local loadingDetail =
    Theme.label(loadingPanel, "Detail", "Getting your station ready…", 19, Theme.colors.ink, 5)
loadingDetail.Position, loadingDetail.Size = UDim2.fromOffset(16, 52), UDim2.new(1, -32, 0, 42)
loadingDetail.TextWrapped, loadingDetail.TextStrokeTransparency = true, 1
local guide

local function restoreCamera()
    local camera = workspace.CurrentCamera
    local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
    local rootPart = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
    if camera then
        camera.CameraType = Enum.CameraType.Custom
        camera.FieldOfView = 70
        if humanoid then
            camera.CameraSubject = humanoid
        end
        if rootPart and rootPart:IsA("BasePart") then
            local look = rootPart.CFrame.LookVector
            local heading = Vector3.new(look.X, 0, look.Z)
            if heading.Magnitude < 0.01 then
                heading = Vector3.new(0, 0, -1)
            else
                heading = heading.Unit
            end
            local focus = rootPart.Position + Vector3.new(0, 2.5, 0)
            camera.CFrame = CFrame.lookAt(focus - heading * 18 + Vector3.new(0, 8, 0), focus)
            camera.Focus = CFrame.new(focus)
        end
    end
end

local function setMovement(blocked, orientCamera)
    movementBlocked = blocked == true
    if blocked then
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
        if orientCamera ~= false then
            restoreCamera()
        end
    end
    if blocked and mode ~= "run" then
        ContextActionService:BindActionAtPriority("PegHubModalJump", function()
            return Enum.ContextActionResult.Sink
        end, false, 3000, Enum.PlayerActions.CharacterJump)
    else
        ContextActionService:UnbindAction("PegHubModalJump")
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
            -- Loading the controls module late must not rotate an active hub camera.
            setMovement(
                mode == "run" or (view and view.isModalOpen and view:isModalOpen()) == true,
                false
            )
        end
    end
end)

player.CharacterAdded:Connect(function(character)
    character:WaitForChild("Humanoid", 10)
    character:WaitForChild("HumanoidRootPart", 10)
    if mode ~= "run" then
        restoreCamera()
    end
end)

local returnGui = Theme.make("ScreenGui", {
    Name = "PopAPegSession",
    ResetOnSpawn = false,
    IgnoreGuiInset = false,
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
        and not transitionPending
    then
        action("enterHub", {})
    end
end, 5)
returnButton.AnchorPoint = Vector2.zero
returnButton.Position = UDim2.new(1, -14, 0, 6)
returnButton.Size = UDim2.fromOffset(126, 30)
returnButton.TextSize = 16
returnButton.TextColor3 = Theme.colors.ink
returnButton.TextStrokeTransparency = 1
returnButton.TextScaled = true
Theme.make("UITextSizeConstraint", { MinTextSize = 11, MaxTextSize = 16 }, returnButton)

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
    if guide then
        guide:destroy()
        guide = nil
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
        guide = HubGuide.new(player)
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
    loadingGui.Enabled = false
    local nextMode = if snapshot.sessionView == "hub" then "hub" else "run"
    if transitionPending and (nextMode == transitionPending or snapshot.notice) then
        transitionPending = nil
        if view and view.setTransitionPending then
            view:setTransitionPending(false)
        end
    end
    if snapshot.sessionView ~= "hub" and snapshot.runId ~= rememberedRunId then
        rememberedRunId = snapshot.runId
        completedReceipt = nil
        if mode == "run" then
            view.feedback.completedReceipt = nil
        end
    end
    changeMode(snapshot.sessionView == "hub" and "hub" or "run")
    view:update(snapshot)
    if guide and snapshot.hub then
        guide:update(snapshot.hub.station, snapshot.hub.canResume)
    end
    if snapshot.notice and view.setNotice then
        view:setNotice(snapshot.notice)
    end
end)
RunService.RenderStepped:Connect(function(dt)
    if view then
        view:step(math.min(dt, 0.1))
        local blocked = mode == "run" or (view.isModalOpen and view:isModalOpen()) == true
        if blocked ~= movementBlocked then
            setMovement(blocked, false)
        end
        if transitionPending and os.clock() - transitionStarted > 8 then
            transitionPending = nil
            if view.setTransitionPending then
                view:setTransitionPending(false)
            end
            view:setNotice("Connection is taking longer than usual. Please try again.")
        end
        if guide then
            guide:setVisible(not blocked)
        end
        if mode == "run" then
            local navigation = view.sessionNavigation
            if navigation then
                local inset = GuiService:GetInsetArea(Enum.ScreenInsets.CoreUISafeInsets).Min
                    - GuiService:GetInsetArea(Enum.ScreenInsets.None).Min
                Theme.rect(
                    returnButton,
                    navigation.x - inset.X,
                    navigation.y - inset.Y,
                    navigation.w,
                    navigation.h
                )
            end
            local enabled = snapshot.phase ~= "flight"
                and snapshot.phase ~= "settling"
                and not view.busy
                and not transitionPending
            local caption = if transitionPending
                then "RETURNING…"
                elseif enabled then "ARCADE"
                else "FINISH SHOT"
            if enabled ~= returnButton.Active then
                Theme.setEnabled(returnButton, enabled, Theme.colors.paper)
            end
            returnButton.Text = caption
        end
    end
end)
task.spawn(function()
    local started = os.clock()
    repeat
        actionRemote:FireServer("ready")
        if os.clock() - started > 5 then
            loadingDetail.Text = "Still connecting to your station…"
        end
        task.wait(1)
    until received
end)

print("[Pop a Peg] Arcade and board controls ready")
