local ContextActionService = game:GetService("ContextActionService")

local InputController = {}
InputController.__index = InputController

function InputController.new(onMedkit)
	local self = setmetatable({ _onMedkit = onMedkit }, InputController)
	ContextActionService:BindAction("LastStopMedkit", function(_, inputState)
		if inputState == Enum.UserInputState.Begin then
			self._onMedkit()
		end
		return Enum.ContextActionResult.Sink
	end, false, Enum.KeyCode.H, Enum.KeyCode.ButtonY)
	local sprintRemote = game:GetService("ReplicatedStorage"):WaitForChild("Remotes"):WaitForChild("RequestSprint")
	ContextActionService:BindAction("LastStopSprint", function(_, state)
		if state == Enum.UserInputState.Begin then sprintRemote:FireServer(true) end
		if state == Enum.UserInputState.End or state == Enum.UserInputState.Cancel then sprintRemote:FireServer(false) end
		return Enum.ContextActionResult.Sink
    end, false, Enum.KeyCode.LeftShift, Enum.KeyCode.ButtonL3)
	return self
end

function InputController:Destroy()
	ContextActionService:UnbindAction("LastStopMedkit")
	ContextActionService:UnbindAction("LastStopSprint")
end

return InputController
