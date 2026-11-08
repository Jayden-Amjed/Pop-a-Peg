--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Smoke = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Smoke"))

print(Smoke.message("server"))
