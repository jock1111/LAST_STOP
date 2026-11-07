-- Standalone Luau harness to run ProfileServiceSpec.lua outside Roblox Studio.
-- Mocks Roblox globals (game, task, Vector3, warn) and overrides `require` to
-- resolve Instance-like tables (script.Parent... / game.ReplicatedStorage...)
-- to already-loaded modules. Uses busy-wait for task.wait and synchronous
-- task.spawn; the renewal loop is suppressed during ProfileService construction
-- to avoid a 300s background loop blocking the test.

-- Save the real require before overriding.
local realRequire = require

-- ---- Mock Vector3 (used by GameConfig) ----
local Vector3 = { new = function(x, y, z) return { X = x, Y = y, Z = z } end }

-- ---- Mock task library ----
local task = {}
function task.wait(seconds)
	seconds = seconds or 0
	if seconds <= 0 then
		return
	end
	local start = os.clock()
	while os.clock() - start < seconds do
	end
end
function task.spawn(f)
	coroutine.wrap(f)()
end
function task.delay(seconds, f)
	task.wait(seconds or 0)
	f()
end

-- ---- Mock warn ----
local warn = print

-- ---- Mock game ----
local function makeHttpService()
	return {
		GenerateGUID = function()
			return "00000000-0000-0000-0000-000000000000"
		end,
	}
end

local game = {
	JobId = "test-job-" .. tostring(math.random(100000, 999999)),
	GetService = function(_, name)
		if name == "HttpService" then
			return makeHttpService()
		end
		return {}
	end,
	ReplicatedStorage = {
		Shared = {
			Config = {},
		},
	},
}

-- ---- Module cache for Instance-like require targets ----
local moduleCache = {}

-- ---- Override require ----
-- Handles both string paths (delegates to real require) and Instance-like
-- tables (returns cached module by Name).
require = function(obj)
	if type(obj) == "string" then
		return realRequire(obj)
	end
	local name = obj and obj.Name
	if name == "ProfileService" then
		return moduleCache.ProfileService
	elseif name == "GameConfig" then
		return moduleCache.GameConfig
	end
	error("require: unknown target " .. tostring(name))
end

-- ---- Build mock script hierarchy ----
-- script = ProfileServiceSpec (ModuleScript in ServerScriptService.Tests)
local profileServiceInst = { Name = "ProfileService" }
local servicesFolder = {
	Name = "Services",
	ProfileService = profileServiceInst,
}
local serverScriptService = {
	Name = "ServerScriptService",
	Services = servicesFolder,
}
local testsFolder = {
	Name = "Tests",
	Parent = serverScriptService,
}
script = {
	Name = "ProfileServiceSpec",
	Parent = testsFolder,
}

-- ---- Build mock game hierarchy ----
-- game.ReplicatedStorage.Shared.Config.GameConfig
local configFolder = { Name = "Config", GameConfig = { Name = "GameConfig" } }
local sharedFolder = { Name = "Shared", Config = configFolder }
game.ReplicatedStorage.Shared = sharedFolder
game.ReplicatedStorage.Shared.Config = configFolder

-- ---- Set globals that modules/spec reference as free variables ----
_G.game = game
_G.task = task
_G.Vector3 = Vector3
_G.warn = warn
_G.require = require
_G.script = script

-- ---- Load ProfileService (suppress renewal loop during construction) ----
local realSpawn = task.spawn
task.spawn = function() end -- no-op: prevent the 300s renewal loop from starting
local ProfileService = realRequire("./ServerScriptService/Services/ProfileService.lua")
task.spawn = realSpawn -- restore
moduleCache.ProfileService = ProfileService

-- ---- Load GameConfig ----
local GameConfig = realRequire("./ReplicatedStorage/Shared/Config/GameConfig.lua")
moduleCache.GameConfig = GameConfig

-- ---- Load and run the spec ----
local spec = realRequire("./ServerScriptService/Tests/ProfileServiceSpec.lua")
local ok, err = pcall(spec)
if not ok then
	error("ProfileServiceSpec FAILED: " .. tostring(err))
end
print("HARNESS: ProfileServiceSpec executed successfully.")
