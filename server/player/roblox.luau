local Players = game:GetService('Players')
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local ServerScriptService = game:GetService('ServerScriptService')

local attr = require(ReplicatedStorage.packages.luau.attr)
local net = require(ServerScriptService.server.net)
local sync = require(ReplicatedStorage.packages.luau.attr_sync_server)
local w = require(ReplicatedStorage.shared.world)

-- setup
sync.commands.attribute_changed = net.game.world.attribute_changed.fire_list :: any
sync.commands.attribute_removed = net.game.world.attribute_removed.fire_list :: any
sync.commands.entity_removed = net.game.world.entity_removed.fire_list :: any
sync.commands.entity_added = net.game.world.entity_added.fire_list :: any

sync.sync_attribute(w.player_character)
sync.sync_attribute(w.humanoid)
sync.sync_attribute(w.player)

-- listeners
local function process(player: Player)
	w.player:set(player, player)
	sync.client:set(player, player)

	sync.group:set(player, sync.everyone)
	sync.bind_group(player)

	sync.receivers:add(player, player)
	sync.receivers:add(sync.everyone, player)

	player.CharacterAdded:Connect(function(character)
		while character:FindFirstChildOfClass('Humanoid') == nil do
			character.ChildAdded:Wait()
		end
		w.player_character:set(player, character)
		w.humanoid:set(character, character :: any)
		sync.group:set(character, sync.everyone)
	end)
	player.CharacterRemoving:Connect(function(character)
		local id = attr.find_id(character)
		if id then attr.destroy(character) end
	end)
end

Players.PlayerAdded:Connect(process)
for _, player in Players:GetPlayers() do
	task.spawn(process, player)
end

-- end
return nil
