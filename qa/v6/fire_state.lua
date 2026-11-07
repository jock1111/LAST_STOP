local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local state = ... -- not supported; read from attribute set by companion script
local wanted = game:GetService("ReplicatedStorage"):GetAttribute("QA_FireState") or "Decision"
local remotes = ReplicatedStorage:WaitForChild("Remotes")
local payloads = {
    Decision = { state = "Decision", objective = "BANK to secure your haul, or CONTINUE.", message = "BANK to secure your haul, or CONTINUE and keep it at risk.", decisionDeadline = os.time() + 25 },
    Escape = { state = "Escape", objective = "Return to the elevator.", message = "Objective complete. Return to the elevator.", unbanked = 120 },
    Boarding = { state = "Boarding", objective = "Board the elevator.", message = "Board the elevator. Departure is imminent." },
    Travel = { state = "Travel", objective = "Descending...", message = "Descending..." },
    Banked = { state = "Results", result = "BANKED", secured = 120, message = "Secured 120 coins." },
    Lobby = { state = "Lobby", floorName = "Terminus Concourse", objective = "Board an expedition.", message = "Welcome." },
}
local payload = payloads[wanted]
if not payload then return "unknown state " .. tostring(wanted) end
for _, player in ipairs(Players:GetPlayers()) do
    remotes.StateChanged:FireClient(player, payload)
end
return "fired " .. wanted
