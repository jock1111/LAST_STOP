-- Explicit opt-in Studio test. Start a 2-player local server, then run from its
-- SERVER command bar: require(game.ServerScriptService.Tests.TwoPlayerRecoverySpec)()
-- Uses real local players and the real state machine; profiles are disposable
-- memory data, so this test never modifies a published player's saved balance.
return function()
	assert(game:GetService("RunService"):IsStudio(),"Studio test only")
	local players=game:GetService("Players"):GetPlayers()
	assert(#players==2,"Start Server & Clients with exactly two players first")
	table.sort(players,function(a,b) return a.UserId<b.UserId end)
	local services=script.Parent.Parent.Services
	local FloorService=require(services.FloorService)
	local Expedition=require(services.ExpeditionService)
	local Inventory=require(services.InventoryService)
	local Enemy=require(services.EnemyService)
	local Economy=require(services.EconomyService)
	local config=table.clone(require(game.ReplicatedStorage.Shared.Config.GameConfig))
	config.BoardingSeconds,config.TravelSeconds,config.EscapeSeconds,config.DecisionSeconds=1,1,12,10
	local memory={data={}}
	for _, player in ipairs(players) do memory.data[player]={Coins=0,XP=0,Level=1,Stats={Runs=0,Escapes=0,BestDepth=0,FirstEscapeClaimed=true}} end
	function memory:Get(player) return self.data[player] end
	function memory:Mutate(player,fn) fn(self.data[player]);return true end
	function memory:Save() return true end
	local floors=FloorService.new()
	floors:BuildWorld()
	local enemies=Enemy.new();enemies:Start()
	local inventory=Inventory.new()
	local economy=Economy.new(memory,config)
	local remotes={}
	for _, r in ipairs(game.ReplicatedStorage.Remotes:GetChildren()) do remotes[r.Name]=r end
	local expedition=Expedition.new(config,floors,enemies,economy,memory,inventory,remotes,function() end)
	local function waitFor(test,label,timeout)
		local deadline=os.clock()+(timeout or 20)
		repeat if test() then return end;task.wait(.1) until os.clock()>deadline
		error("[V3 TWO PLAYER] Timed out: "..label.."; state="..expedition.state)
	end
	local verifiedEnemy=false
	local function recoverRound(active)
		waitFor(function() return expedition.state=="Floor" end,"floor start")
		local room=expedition.floor
		if not verifiedEnemy then
			waitFor(function() return enemies._enemies[1] end,"Stalker spawn",10)
			local stalker=enemies._enemies[1]
			local initial=stalker.root.Position
			waitFor(function() return (stalker.root.Position-initial).Magnitude>2 end,"Stalker physics movement",10)
			local victim=active[1]
			victim.Character:PivotTo(CFrame.new(stalker.root.Position+Vector3.new(0,0,3)))
			local health=victim.Character.Humanoid.Health
			waitFor(function() return victim.Character.Humanoid.Health<health end,"Stalker windup damage",8)
			assert(health-victim.Character.Humanoid.Health==15,"Unexpected Stalker damage")
			victim.Character.Humanoid.Health=100
			victim.Character:PivotTo(room.spawnCFrame)
			verifiedEnemy=true
			print("[V3 TWO PLAYER] Stalker moved physically and dealt 15 damage after windup")
		end
		local keys={};for key in pairs(room.targets) do table.insert(keys,key) end;table.sort(keys)
		-- Check real navigation, rather than accepting proximity-only teleports as
		-- evidence that a wall/door layout is traversable.
		for _, key in ipairs(keys) do
			local target=room.targets[key]
			local path=game:GetService("PathfindingService"):CreatePath({AgentRadius=1.8,AgentHeight=5,AgentCanJump=false})
			for retry=1,5 do
				path:ComputeAsync(room.spawnCFrame.Position,target.Position+Vector3.new(0,0,3))
				if path.Status==Enum.PathStatus.Success then break end
				task.wait(.3) -- allow navigation tiles to rebuild after the last room clone
			end
			assert(path.Status==Enum.PathStatus.Success,"Record route blocked: "..key);path:Destroy()
		end
		local player=active[1]
		for index,key in ipairs(keys) do
			local target=room.targets[key]
			player.Character:PivotTo(CFrame.new(target.Position+Vector3.new(0,2,3)))
			task.wait(.2)
			if index==#keys then task.spawn(function() room:_attemptInteraction(player,key) end)
			else room:_attemptInteraction(player,key);room:_attemptInteraction(player,key) end
			waitFor(function() return target:GetAttribute("Used") end,"record accepted: "..key,2)
		end
		waitFor(function() return expedition.state=="Escape" end,"objective completion")
		assert(select(1,room:ObjectiveProgress())==3,"Duplicate record interaction changed objective count")
		for index,p in ipairs(active) do p.Character:PivotTo(room.escapeCFrame*CFrame.new((index-1)*3,0,0)) end
		waitFor(function() return expedition.state=="Decision" end,"return elevator")
		return room.model
	end
	local ok,err=xpcall(function()
		expedition:Start(players)
		local first=recoverRound(players)
		assert(expedition:RequestDecision(players[1],"Bank"))
		assert(expedition:RequestDecision(players[2],"Continue"))
		waitFor(function() return expedition.depth==2 and expedition.state=="Floor" end,"second round")
		assert(first.Parent==nil,"Previous hospital was not cleaned up")
		assert(economy:GetBankedCoins(players[1])==80 and economy:GetBankedCoins(players[2])==0,"Independent Bank/Continue balance failed")
		assert(expedition.unbanked[players[2]]==80,"Continuer lost at-risk reward")
		assert(not expedition:RequestDecision(players[1],"Bank"),"Banker can claim the same reward twice")
		local second=recoverRound({players[2]})
		assert(expedition:RequestDecision(players[2],"Bank"))
		waitFor(function() return not expedition:IsRunning() end,"final bank")
		assert(economy:GetBankedCoins(players[2])>80 and economy:GetBankedCoins(players[1])==80,"Second round accounting failed")
		assert(second.Parent==nil and game.ServerStorage.LastStopAssets.Floors.Hospital.Parent,"Source/clone lifecycle failed")
		print("[V3 TWO PLAYER] PASS: two real players, three reachable records, duplicate rejection, escape region, independent BANK/CONTINUE, two floor clones, teardown; disposable profiles only")
	end,debug.traceback)
	expedition:Destroy();enemies:Destroy()
	assert(ok,err)
end
