local results = {}
local specs = {
    "VerticalSliceSpec",
    "ProfileServiceSpec",
    "SubwayCycleSpec",
    "RouteVariantSpec",
    "InteractionOcclusionSpec",
    "FloorTimerSpec",
    "PrefabLifecycleSpec",
    "GameplayRecoverySpec",
    "TrainHazardSpec",
}
for _, name in ipairs(specs) do
    local ok, err = pcall(function()
        require(game:GetService("ServerScriptService").Tests[name])()
    end)
    results[name] = { pass = ok, error = ok and nil or tostring(err) }
end
return results
