local sss = game:GetService("ServerScriptService")
local svc = sss:FindFirstChild("Services") and sss.Services:FindFirstChild("EnvironmentService")
if not svc then return {err = "not found"} end
local ok, err = pcall(function()
    svc.Source = svc.Source .. "\n-- probe"
end)
if ok then
    -- revert
    pcall(function() svc.Source = svc.Source:gsub("\n%-%- probe", "") end)
end
return {ok = ok, err = tostring(err), class = svc.ClassName}
