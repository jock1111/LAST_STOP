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
	return self
end

function InputController:Destroy()
	ContextActionService:UnbindAction("LastStopMedkit")
end

return InputController
