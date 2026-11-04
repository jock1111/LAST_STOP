-- Invisible enemy collision bodies must not silently reject objective holds.
return function()
    local Room = require(script.Parent.Parent.Services.ObjectiveRoom)
    local model = Instance.new("Model", workspace)
    model.Name = "LastStopInteractionOcclusionQA"
    local origin = Vector3.new(5000, 100, 0)
    local function part(parent, name, position, size)
        local item = Instance.new("Part")
        item.Name, item.Anchored, item.Position, item.Size = name, true, origin + position, size
        item.Parent = parent
        return item
    end
    local character = Instance.new("Model", model)
    part(character, "HumanoidRootPart", Vector3.new(0, 3, 0), Vector3.one)
    part(character, "Head", Vector3.new(0, 4.5, 0), Vector3.one)
    local enemy = Instance.new("Model", model)
    enemy:SetAttribute("V4Stalker", true)
    local torso = part(enemy, "Torso", Vector3.new(4, 3.75, 0), Vector3.new(2, 4, 4))
    torso.Transparency = 1
    local target = part(model, "Objective", Vector3.new(8, 3, 0), Vector3.one)
    target.CanCollide = false
    local room = Room.new({}, {}, 1)
    room.model, room.context = model, {isPlayerActive = function() return true end}
    local player = {Character = character}
    local ok, err = pcall(function()
        assert(room:_valid(player, target), "Invisible enemy collider blocked a valid hold")
        part(model, "Wall", Vector3.new(4, 3.75, 0), Vector3.new(.5, 8, 8))
        assert(not room:_valid(player, target), "Wall line-of-sight check was bypassed")
        character.HumanoidRootPart.Position = origin + Vector3.new(-20, 3, 0)
        assert(not room:_valid(player, target), "Interaction distance check was bypassed")
    end)
    model:Destroy()
    assert(ok, err)
end
