local ok, err = pcall(function()
    require(game:GetService("ServerScriptService").Tests.GameplayRecoverySpec)()
end)
return { GameplayRecoverySpec = { pass = ok, error = ok and nil or tostring(err) } }
