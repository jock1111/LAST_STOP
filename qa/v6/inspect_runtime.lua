local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local result = ReplicatedStorage:FindFirstChild("QA_V6_Results")
local world = Workspace:FindFirstChild("LastStopWorld")
local tree = {}
local function walk(instance, depth)
	if depth > 3 then return end
	for _, child in ipairs(instance:GetChildren()) do
		table.insert(tree, string.rep("  ", depth) .. child.ClassName .. " / " .. child.Name)
		walk(child, depth + 1)
	end
end
if world then walk(world, 0) end
return {
	results = result and result.Value or nil,
	worldChildren = world and #world:GetChildren() or nil,
	tree = table.concat(tree, "\n"),
}
