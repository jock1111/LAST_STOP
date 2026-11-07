local results = {}
local specs = {
    "VerticalSliceSpec",
    "SubwayCycleSpec",
    "RouteVariantSpec",
    "InteractionOcclusionSpec",
    "FloorTimerSpec",
    "PrefabLifecycleSpec",
}
local testsFolder = game:GetService("ServerScriptService").Tests
for _, name in ipairs(specs) do
    local ok, err = pcall(function()
        require(testsFolder[name])()
    end)
    results[name] = { pass = ok, error = ok and nil or tostring(err) }
end
return results
