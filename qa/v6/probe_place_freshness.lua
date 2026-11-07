local out = {}
local function probe(path)
    local node = game
    for part in string.gmatch(path, "[^%.]+") do
        node = node and node:FindFirstChild(part)
    end
    if not node then return {path = path, found = false} end
    local src = node.Source or ""
    return {
        path = path,
        found = true,
        len = #src,
        hasLegacy = src:find("BuildLaboratoryLegacy", 1, true) ~= nil,
        hasEnsureCam = src:find("EnsureGameplayCamera", 1, true) ~= nil,
        head = src:sub(1, 60),
    }
end
out[#out+1] = probe("ServerScriptService.Services.EnvironmentService")
out[#out+1] = probe("StarterPlayer.StarterPlayerScripts.Controllers.HUDController")
local env = game:GetService("ServerStorage"):FindFirstChild("LastStopAssets")
local lib = env and env:FindFirstChild("Environment")
out[#out+1] = {path = "ServerStorage.LastStopAssets.Environment", found = lib ~= nil, children = lib and #lib:GetChildren() or 0, meshParts = lib and #lib:GetDescendants() or 0}
return out
