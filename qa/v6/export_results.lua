local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local results = ReplicatedStorage:WaitForChild("QA_V6_Results", 15)
return HttpService:JSONDecode(results.Value)
