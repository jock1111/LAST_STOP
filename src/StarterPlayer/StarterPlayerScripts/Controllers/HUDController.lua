-- Responsive, code-built HUD: no external assets and no decorative controls.
local TweenService = game:GetService("TweenService")

local HUDController = {}
HUDController.__index = HUDController

local CYAN = Color3.fromRGB(73, 212, 210)
local RED = Color3.fromRGB(220, 67, 67)
local PANEL = Color3.fromRGB(18, 24, 31)

local function rounded(instance, radius)
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, radius or 8)
	corner.Parent = instance
end

local function makeLabel(parent, name, text, size, position, font, textSize)
	local label = Instance.new("TextLabel")
	label.Name = name
	label.BackgroundTransparency = 1
	label.Size = size
	label.Position = position
	label.Font = font or Enum.Font.Gotham
	label.TextSize = textSize or 16
	label.TextColor3 = Color3.fromRGB(230, 238, 242)
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.TextYAlignment = Enum.TextYAlignment.Center
	label.TextWrapped = true
	label.Text = text
	label.Parent = parent
	return label
end

local function makeButton(parent, name, text, color)
	local button = Instance.new("TextButton")
	button.Name = name
	button.AutoButtonColor = true
	button.BackgroundColor3 = color
	button.BorderSizePixel = 0
	button.Size = UDim2.fromOffset(140, 46)
	button.Font = Enum.Font.GothamBold
	button.TextSize = 16
	button.TextColor3 = Color3.fromRGB(8, 14, 17)
	button.Text = text
	rounded(button, 8)
	button.Parent = parent
	return button
end

function HUDController.new(player, callbacks)
	local gui = Instance.new("ScreenGui")
	gui.Name = "LastStopHUD"
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = false
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	gui.Parent = player:WaitForChild("PlayerGui")
	local self = setmetatable({ player = player, callbacks = callbacks, gui = gui, state = "Lobby", connections = {} }, HUDController)
	self:_build()
	self:_watchHealth()
	return self
end

function HUDController:_build()
	local safe = Instance.new("Frame")
	safe.Name = "SafeArea"
	safe.BackgroundTransparency = 1
	safe.Size = UDim2.fromScale(1, 1)
	safe.Parent = self.gui
	local scale = Instance.new("UIScale")
	scale.Scale = 1
	scale.Parent = safe

	local top = Instance.new("Frame")
	top.Name = "RunPanel"
	top.BackgroundColor3 = PANEL
	top.BackgroundTransparency = 0.1
	top.BorderSizePixel = 0
	top.Position = UDim2.fromOffset(18, 18)
	top.Size = UDim2.new(0.44, 0, 0, 130)
	rounded(top, 10)
	top.Parent = safe
	self.runPanel = top
	self.title = makeLabel(top, "Title", "LAST STOP  •  LOBBY", UDim2.new(1, -24, 0, 28), UDim2.fromOffset(12, 8), Enum.Font.GothamBold, 17)
	self.title.TextColor3 = CYAN
	self.objective = makeLabel(top, "Objective", "Queue for an expedition.", UDim2.new(1, -24, 0, 46), UDim2.fromOffset(12, 38), Enum.Font.Gotham, 15)
	self.coins = makeLabel(top, "Coins", "SECURED 0    AT RISK 0", UDim2.new(1, -24, 0, 24), UDim2.fromOffset(12, 92), Enum.Font.GothamBold, 14)
	self.coins.TextColor3 = Color3.fromRGB(255, 211, 99)

	local healthPanel = Instance.new("Frame")
	healthPanel.Name = "HealthPanel"
	healthPanel.BackgroundColor3 = PANEL
	healthPanel.BackgroundTransparency = 0.1
	healthPanel.BorderSizePixel = 0
	healthPanel.AnchorPoint = Vector2.new(1, 0)
	healthPanel.Position = UDim2.new(1, -18, 0, 18)
	healthPanel.Size = UDim2.fromOffset(180, 46)
	rounded(healthPanel, 10)
	healthPanel.Parent = safe
	self.health = makeLabel(healthPanel, "Health", "HEALTH 100 / 100", UDim2.new(1, -20, 1, 0), UDim2.fromOffset(10, 0), Enum.Font.GothamBold, 14)
	self.health.TextColor3 = Color3.fromRGB(130, 255, 166)

	local actions = Instance.new("Frame")
	actions.Name = "Actions"
	actions.BackgroundTransparency = 1
	actions.AnchorPoint = Vector2.new(0.5, 1)
	actions.Position = UDim2.new(0.5, 0, 1, -26)
	actions.Size = UDim2.fromOffset(300, 58)
	actions.Parent = safe
	local actionLayout = Instance.new("UIListLayout")
	actionLayout.FillDirection = Enum.FillDirection.Horizontal
	actionLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	actionLayout.Padding = UDim.new(0, 10)
	actionLayout.Parent = actions
	self.playButton = makeButton(actions, "Play", "PLAY", CYAN)
	self.medkitButton = makeButton(actions, "Medkit", "MEDKIT (1)", Color3.fromRGB(126, 238, 164))
	self.medkitButton.Visible = false
	self.playButton.Activated:Connect(function()
		self.callbacks.queue()
	end)
	self.medkitButton.Activated:Connect(function()
		self.callbacks.medkit()
	end)

	local decision = Instance.new("Frame")
	decision.Name = "BankDecision"
	decision.BackgroundColor3 = PANEL
	decision.BorderSizePixel = 0
	decision.AnchorPoint = Vector2.new(0.5, 0.5)
	decision.Position = UDim2.fromScale(0.5, 0.52)
	decision.Size = UDim2.fromOffset(440, 220)
	decision.Visible = false
	rounded(decision, 12)
	decision.Parent = safe
	self.decision = decision
	local heading = makeLabel(decision, "Heading", "SECURE OR RISK?", UDim2.new(1, -30, 0, 34), UDim2.fromOffset(15, 16), Enum.Font.GothamBold, 22)
	heading.TextColor3 = CYAN
	local explain = makeLabel(decision, "Explain", "BANK secures all at-risk coins and returns you to the lobby. CONTINUE carries them into the next floor; death or a missed elevator loses them.", UDim2.new(1, -30, 0, 70), UDim2.fromOffset(15, 55), Enum.Font.Gotham, 15)
	local bank = makeButton(decision, "Bank", "BANK", Color3.fromRGB(255, 211, 99))
	bank.Position = UDim2.fromOffset(48, 148)
	local continueButton = makeButton(decision, "Continue", "CONTINUE", CYAN)
	continueButton.Position = UDim2.new(1, -188, 0, 148)
	bank.Activated:Connect(function()
		self.callbacks.decision("Bank")
	end)
	continueButton.Activated:Connect(function()
		self.callbacks.decision("Continue")
	end)

	local toast = Instance.new("TextLabel")
	toast.Name = "Toast"
	toast.BackgroundColor3 = Color3.fromRGB(8, 12, 17)
	toast.BackgroundTransparency = 0.15
	toast.BorderSizePixel = 0
	toast.AnchorPoint = Vector2.new(0.5, 0)
	toast.Position = UDim2.new(0.5, 0, 0, 164)
	toast.Size = UDim2.new(0.55, 0, 0, 42)
	toast.Font = Enum.Font.GothamMedium
	toast.TextSize = 15
	toast.TextColor3 = Color3.fromRGB(235, 243, 246)
	toast.TextWrapped = true
	toast.Visible = false
	rounded(toast, 8)
	toast.Parent = safe
	self.toast = toast

	local tutorial = Instance.new("Frame")
	tutorial.Name = "Tutorial"
	tutorial.BackgroundColor3 = Color3.fromRGB(8, 12, 17)
	tutorial.BackgroundTransparency = 0.1
	tutorial.BorderSizePixel = 0
	tutorial.AnchorPoint = Vector2.new(0.5, 0)
	tutorial.Position = UDim2.new(0.5, 0, 0, 220)
	tutorial.Size = UDim2.fromOffset(400, 78)
	rounded(tutorial, 10)
	tutorial.Parent = safe
	self.tutorial = tutorial
	self.tutorialText = makeLabel(tutorial, "Text", "1/4  Enter the elevator: press PLAY or use the terminal.", UDim2.new(1, -100, 1, 0), UDim2.fromOffset(14, 0), Enum.Font.GothamMedium, 14)
	local skip = makeButton(tutorial, "Skip", "SKIP", Color3.fromRGB(117, 130, 143))
	skip.AnchorPoint = Vector2.new(1, 0.5)
	skip.Position = UDim2.new(1, -12, 0.5, 0)
	skip.Size = UDim2.fromOffset(74, 34)
	skip.TextSize = 12
	skip.Activated:Connect(function()
		tutorial.Visible = false
	end)
end

function HUDController:_watchHealth()
	local function attach(character)
		local humanoid = character:WaitForChild("Humanoid", 5)
		if not humanoid then return end
		local function update()
			self.health.Text = string.format("HEALTH %d / %d", math.max(0, humanoid.Health), humanoid.MaxHealth)
			self.health.TextColor3 = humanoid.Health < humanoid.MaxHealth * 0.35 and RED or Color3.fromRGB(130, 255, 166)
		end
		update()
		table.insert(self.connections, humanoid.HealthChanged:Connect(update))
	end
	if self.player.Character then attach(self.player.Character) end
	table.insert(self.connections, self.player.CharacterAdded:Connect(attach))
	table.insert(self.connections, self.player:GetAttributeChangedSignal("LastStopMedkits"):Connect(function()
		self.medkitButton.Text = "MEDKIT (" .. tostring(self.player:GetAttribute("LastStopMedkits") or 0) .. ")"
	end))
end

function HUDController:ApplyState(data)
	self.state = data.state or self.state
	self.title.Text = "LAST STOP  •  " .. string.upper(self.state) .. (data.depth and data.depth > 0 and "  •  DEPTH " .. data.depth or "")
	self.objective.Text = data.objective or ""
	self.coins.Text = string.format("SECURED %d    AT RISK %d", data.banked or 0, data.unbanked or 0)
	self.decision.Visible = self.state == "Decision"
	self.playButton.Visible = self.state == "Lobby" or self.state == "Results" or self.state == "Ended"
	self.medkitButton.Visible = self.state == "Floor" or self.state == "Escape"
	if self.state == "Floor" and data.progress ~= nil then
		self.objective.Text = string.format("%s  (%d/%d)", data.objective or "Objective", data.progress, data.target or 0)
	end
	local tutorialSteps = {
		Lobby = "1/4  Enter the elevator: press PLAY or use the terminal.",
		Floor = "2/4  Complete the glowing objective stations.",
		Escape = "3/4  Return inside the marked elevator before its doors close.",
		Decision = "4/4  BANK to secure coins, or CONTINUE to risk them for more.",
	}
	if self.tutorial.Visible and tutorialSteps[self.state] then
		self.tutorialText.Text = tutorialSteps[self.state]
	end
	if data.message then self:ShowToast(data.message) end
end

function HUDController:ShowToast(message)
	self.toast.Text = tostring(message)
	self.toast.Visible = true
	self.toast.TextTransparency = 0
	local nonce = os.clock()
	self._toastNonce = nonce
	task.delay(3.2, function()
		if self._toastNonce == nonce and self.toast.Parent then
			TweenService:Create(self.toast, TweenInfo.new(0.35), { TextTransparency = 1, BackgroundTransparency = 1 }):Play()
			task.wait(0.4)
			if self._toastNonce == nonce then
				self.toast.Visible = false
				self.toast.BackgroundTransparency = 0.15
			end
		end
	end)
end

function HUDController:Destroy()
	for _, connection in ipairs(self.connections) do connection:Disconnect() end
	self.gui:Destroy()
end

return HUDController
