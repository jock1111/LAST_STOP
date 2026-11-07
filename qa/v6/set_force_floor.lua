local ReplicatedStorage = game:GetService("ReplicatedStorage")
local template = ... or "FloodedLaboratory"
ReplicatedStorage:SetAttribute("QA_ForceFloor", template)
return ReplicatedStorage:GetAttribute("QA_ForceFloor")
