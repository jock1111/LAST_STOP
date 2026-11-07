local ok, err = pcall(function()
    require(game:GetService("ServerScriptService").Tests.ProfileServiceSpec)()
end)
return { ProfileServiceSpec = { pass = ok, error = ok and nil or tostring(err) } }
