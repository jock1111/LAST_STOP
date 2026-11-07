local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local payload = { state = "Floor", floorName = "Abandoned Subway / The Last Train", objective = "Take the signal relay.", message = "Something is moving in the dark.", progress = 0, target = 5, unbanked = 0, banked = 0, depth = 1 }
for _, player in ipairs(Players:GetPlayers()) do
    ReplicatedStorage.Remotes.StateChanged:FireClient(player, payload)
end
return "fired Floor"
