-- Studio-only controlled elimination coverage. Outside the Rojo project.
local player = game.Players.LocalPlayer
local evidence = Instance.new("Folder", workspace)
evidence.Name = "V5DeathRequeue"
task.spawn(function()
    local trace = {}
    local function hud() return player.PlayerGui.LastStopHUD.SafeArea end
    local function record(cycle, event)
        table.insert(trace, {
            cycle = cycle, event = event, brand = hud().Mission.Brand.Text,
            boardVisible = hud().Play.Visible,
            health = player.Character.Humanoid.Health,
            snapshot = player:GetAttribute("LastStopSnapshot"),
        })
        evidence:SetAttribute("Trace", game.HttpService:JSONEncode(trace))
    end
    local ok, err = xpcall(function()
        for cycle = 1, 3 do
            task.wait(1.5)
            assert(hud().Play.Visible, "Board control missing before queue")
            hud().Play.Visible = false
            game.ReplicatedStorage.Remotes.RequestState:FireServer()
            task.wait(.5)
            assert(hud().Play.Visible, "Authoritative HUD resync failed")
            record(cycle, "Results restored by RequestState")
            game.ReplicatedStorage.Remotes.RequestQueue:FireServer()
            local deadline = os.clock() + 35
            repeat task.wait(.1) until hud().Mission.Brand.Text:find("BOARDING") or os.clock() > deadline
            assert(hud().Mission.Brand.Text:find("BOARDING"), "Requeue did not start Boarding")
            local oldCharacter = player.Character
            record(cycle, "Requeue reached Boarding")
            deadline = os.clock() + 15
            repeat task.wait(.1) until player.Character ~= oldCharacter or os.clock() > deadline
            assert(player.Character ~= oldCharacter, "Respawn did not create a new Character")
            repeat task.wait(.1) until (player.Character:FindFirstChildOfClass("Humanoid") and player.Character.Humanoid.Health > 0 and hud().Play.Visible) or os.clock() > deadline
            assert(hud().Play.Visible and hud().Mission.Brand.Text:find("RESULTS"), "Death HUD did not recover")
            record(cycle, "New Character and Results recovered")
        end
    end, debug.traceback)
    evidence:SetAttribute("Pass", ok)
    evidence:SetAttribute("Error", not ok and tostring(err) or "")
end)
return "Three death/respawn/requeue cycles started"
