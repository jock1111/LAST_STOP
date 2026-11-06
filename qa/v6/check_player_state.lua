local Players = game:GetService("Players")
local player = Players.LocalPlayer

local result = {
    attributes = {},
    characterPosition = "none",
}

if player then
    for key, value in pairs(player:GetAttributes()) do
        result.attributes[key] = tostring(value)
    end
    if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
        result.characterPosition = tostring(player.Character.HumanoidRootPart.Position)
    end
end

return result
