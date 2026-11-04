-- Studio-only forced death coordinator. Outside the Rojo project.
assert(game.RunService:IsStudio())
local evidence = Instance.new("Folder", workspace)
evidence.Name = "V5DeathCoordinator"
local trace = {}
for cycle = 1, 3 do
    local deadline = os.clock() + 45
    local ready
    repeat
        task.wait(.1)
        ready = true
        for _, player in game.Players:GetPlayers() do
            local data = game.HttpService:JSONDecode(player:GetAttribute("LastStopSnapshot") or "{}")
            if data.state ~= "Boarding" then ready = false end
        end
    until ready or os.clock() > deadline
    assert(ready, "Clients did not both reach Boarding")
    task.wait(.5)
    for _, player in game.Players:GetPlayers() do
        player.Character.Humanoid.Health = 0
    end
    table.insert(trace, {cycle = cycle, event = "Both real clients forcibly eliminated during Boarding"})
    evidence:SetAttribute("Trace", game.HttpService:JSONEncode(trace))
    task.wait(6)
end
evidence:SetAttribute("Pass", true)
