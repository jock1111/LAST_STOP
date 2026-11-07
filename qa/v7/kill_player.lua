local Players = game:GetService("Players")
for _, player in ipairs(Players:GetPlayers()) do
    local character = player.Character
    if character then
        local humanoid = character:FindFirstChildOfClass("Humanoid")
        if humanoid then
            humanoid:TakeDamage(100)
        end
    end
end
return "damage applied"
