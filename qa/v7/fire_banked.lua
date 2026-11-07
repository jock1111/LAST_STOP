-- Inject a BANKED results state to verify the results UI renders correctly.
-- This tests the client-side results panel with realistic data.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local player = Players:GetPlayers()[1]
if not player then return {error = "no player"} end

local remotes = ReplicatedStorage:WaitForChild("Remotes")
local stateChanged = remotes:FindFirstChild("StateChanged")
if not stateChanged then return {error = "no StateChanged remote"} end

local payload = {
    state = "Results",
    result = "BANKED",
    floorName = "Pelagic / Flooded Laboratory",
    objective = "Deliver specimen",
    progress = 5,
    target = 5,
    unbanked = 0,
    banked = 150,                       -- total secured balance (cumulative)
    secured = 85,                       -- coins secured this expedition
    earned = 85,                        -- coins at risk this expedition
    xpEarned = 25,                      -- XP awarded this expedition
    depth = 1,
    message = "Secured 150 coins.",
}
stateChanged:FireClient(player, payload)
return {fired = true, payload = payload}
