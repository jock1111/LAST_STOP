local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local control = ReplicatedStorage:WaitForChild("QA_V6_Control", 15)
local results = ReplicatedStorage:WaitForChild("QA_V6_Results", 15)

control:FireServer("regressions")
local deadline = os.clock() + 240
while os.clock() < deadline do
	local ok, data = pcall(function()
		return HttpService:JSONDecode(results.Value)
	end)
	if ok and data.regressions and data.regressions.finished then
		return data.regressions
	end
	task.wait(1)
end
return { timeout = true, value = results.Value }
