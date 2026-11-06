local ReplicatedStorage = game:GetService("ReplicatedStorage")
local control = ReplicatedStorage:WaitForChild("QA_V6_Control", 10)
if control then control:FireServer("kill") return "kill fired" end
return "no control"
