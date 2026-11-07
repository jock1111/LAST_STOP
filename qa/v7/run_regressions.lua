local TestRunner = {}
local results = {}

local function runSpec(name)
    local ok, specFn = pcall(function()
        return require(script.Parent.Parent.ServerScriptService.Tests[name])
    end)
    if not ok then
        results[name] = { pass = false, error = tostring(specFn) }
        return
    end
    local ran, value = pcall(specFn)
    results[name] = { pass = ran and type(value) == "table" and value.pass == true, error = tostring(value) }
end

runSpec("GameplayRecoverySpec")
runSpec("TrainHazardSpec")
runSpec("SubwayCycleSpec")
runSpec("FloorTimerSpec")
runSpec("InteractionOcclusionSpec")
runSpec("PrefabLifecycleSpec")
runSpec("RouteVariantSpec")
runSpec("VerticalSliceSpec")

return results
