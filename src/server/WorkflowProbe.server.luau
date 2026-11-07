--!strict

local TweenService = game:GetService("TweenService")

local ball = Instance.new("Part")
ball.Name = "WorkflowProbeBall"
ball.Shape = Enum.PartType.Ball
ball.Anchored = true
ball.CanCollide = false
ball.Position = Vector3.new(0, 6, -12)
ball.Size = Vector3.new(2, 2, 2)
ball.Color = Color3.fromRGB(255, 170, 60)
ball:SetAttribute("ProbeOwner", "RBX-001")
ball.Parent = workspace

print("[WorkflowProbe] start diameter=2")
local tween = TweenService:Create(ball, TweenInfo.new(2), { Size = Vector3.new(8, 8, 8) })
tween:Play()
tween.Completed:Wait()
ball:SetAttribute("ExpansionComplete", true)
print(string.format("[WorkflowProbe] complete diameter=%.1f", ball.Size.X))
