local Players = game:GetService("Players")
local player = Players.LocalPlayer
local result = {playerScripts = {}, camera = tostring(game.Workspace.CurrentCamera and game.Workspace.CurrentCamera.ClassName), starterPlayerCameraMode = tostring(game:GetService("StarterPlayer").CameraMode)}
if player and player.PlayerScripts then
    for _, child in ipairs(player.PlayerScripts:GetDescendants()) do
        table.insert(result.playerScripts, child:GetFullName() .. " (" .. child.ClassName .. ")")
    end
end
return result
