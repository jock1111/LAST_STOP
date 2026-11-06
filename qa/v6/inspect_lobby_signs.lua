local Workspace = game:GetService("Workspace")
local world = Workspace:FindFirstChild("LastStopWorld")
local runtime = world and world:FindFirstChild("Runtime")
local lobby = runtime and runtime:FindFirstChild("Lobby")
assert(lobby, "no lobby")
local signs = {}
for _, value in ipairs(lobby:GetDescendants()) do
	if value:IsA("BasePart") then
		local gui = value:FindFirstChildOfClass("SurfaceGui")
		if gui then
			local label = gui:FindFirstChildOfClass("TextLabel")
			table.insert(signs, {
				name = value.Name,
				position = tostring(value.Position),
				size = tostring(value.Size),
				text = label and label.Text or "",
			})
		end
	end
end
return signs
