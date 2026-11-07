local ReplicatedStorage = game:GetService("ReplicatedStorage")
local remotes = ReplicatedStorage:WaitForChild("Remotes")
local queue = remotes:FindFirstChild("RequestQueue")
if queue then
    queue:FireServer()
    return {fired = true}
end
return {error = "no RequestQueue remote"}
