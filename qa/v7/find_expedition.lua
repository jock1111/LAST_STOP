-- Try to find the running ExpeditionService through garbage collector.
local gc = getgc and getgc() or {}
local found = {}
for _, obj in ipairs(gc) do
    if type(obj) == "table" and obj._config and obj._broadcast then
        table.insert(found, {type = type(obj), hasStart = type(obj.Start) == "function", state = obj.state})
    end
end
return {found = found, count = #found}
