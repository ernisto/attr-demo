local ReplicatedStorage = game:GetService('ReplicatedStorage')
local ServerScriptService = game:GetService('ServerScriptService')

local attr = require(ReplicatedStorage.packages.luau.attr)
local attr_save = require(ReplicatedStorage.packages.luau.attr_save)
local item = require(ServerScriptService.server.item)
local net = require(ServerScriptService.server.net)
local player_save = require(ServerScriptService.server.player.save)
local sync = require(ReplicatedStorage.packages.luau.attr_sync)
local w = require(ReplicatedStorage.shared.world)

-- traits
local player_item_save = player_save.include_ids(w.owned_items, 'owneds')
player_save.include_id(w.handling_item, 'handling')

attr_save.include_attr(player_item_save, w.item_prefab, 'prefab')
attr_save.include_attr(player_item_save, w.material, 'material', sync.serde:assert(w.material))
attr_save.include_attr(player_item_save, w.health, 'health')

-- client functions
net.game.inventory.pickup_item.on(function(player, item_id)
	w.item_state.dropped:assert(item_id)
	item.give(player, item_id)
end)
net.game.inventory.place_item.on(function(player, item_id, base, offset)
	w.owned_items:assert(player, item_id)
	item.place(item_id, base, offset)
end)
net.game.inventory.hit_block.on(function(player, block)
	local char = w.player_character:assert(player)
	local item = w.handling_item:assert(char)
	local chop = w.item.chop:assert(item)

	local new_health = math.max(0, w.health:assert(block) - chop.efficiency)
	w.health:set(block, new_health)
end)
net.game.inventory.drop_item.on(function(player, item_id)
	w.owned_items:assert(player, item_id)

	local char = w.player_character:assert(player)
	local model = w.humanoid:assert(char)

	item.drop(item_id, model.HumanoidRootPart.CFrame, 10)
end)
net.game.inventory.handle_item.on(function(player, item)
	w.owned_items:assert(player, item)
	w.handling_item:set(w.player_character:assert(player), item)
end)

-- events
attr.on_remove(w.player, function(player): ()
	for item in w.owned_items:iter(player) do
		attr.destroy(item)
	end
end)

-- end
return nil
