local ReplicatedStorage = game:GetService('ReplicatedStorage')
local ServerScriptService = game:GetService('ServerScriptService')

local item = require(ServerScriptService.server.item)
local rng = require(ReplicatedStorage.packages.rng)
local w = require(ReplicatedStorage.shared.world)

task.spawn(function()
	while task.wait(5) do
		local ore = item.new('ore')
		local material = w.materials[rng.key(w.materials)]
		w.material:set(ore, material)
		w.health:set(ore, material.durability)

		local pos = rng.vector(100, 0, 100) - vector.create(50, 0, 50)
		w.item_state.placed:set(ore, { base = workspace.Baseplate, offset = CFrame.new(pos.x, 8, pos.z) })
	end
end)

task.spawn(function()
	while task.wait(2) do
		item.drop(
			item.new(rng.value { 'sword', 'axe' }),
			CFrame.lookAlong(rng.vector(100, 0, 100) :: any, rng.direction() :: any),
			rng.range(5, 10)
		)
	end
end)

-- end
return nil
