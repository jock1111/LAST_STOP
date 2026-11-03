local Maid = {}
Maid.__index = Maid

function Maid.new()
	return setmetatable({ _tasks = {} }, Maid)
end

function Maid:Give(task)
	table.insert(self._tasks, task)
	return task
end

function Maid:Clean()
	for _, task in ipairs(self._tasks) do
		local kind = typeof(task)
		if kind == "RBXScriptConnection" then
			task:Disconnect()
		elseif kind == "Instance" then
			task:Destroy()
		elseif type(task) == "function" then
			task()
		elseif type(task) == "table" and task.Destroy then
			task:Destroy()
		end
	end
	table.clear(self._tasks)
end

function Maid:Destroy()
	self:Clean()
end

return Maid
