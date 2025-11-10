local ReplicatedStorage = game:GetService('ReplicatedStorage')

local attr = require(ReplicatedStorage.packages.luau.attr)
local items = require(ReplicatedStorage.config.items)
local sync = require(ReplicatedStorage.packages.luau.attr_sync_server)
local w = require(ReplicatedStorage.shared.world)

-- functions
local function new_item(prefab_id: string)
	local id = attr.id()
	w.item_prefab:set(id, prefab_id)
	return id
end
local function drop_item(item: attr.key, cframe: CFrame, power: number)
	w.item_state.placed:remove(item)
	w.item_state.owned:remove(item)
	w.item_state.dropped:set(item, { cframe = cframe, power = power })
end
local function give_item(player: Player, item: attr.key)
	w.item_state.dropped:remove(item)
	w.item_state.placed:remove(item)
	w.item_state.owned:set(item, player)
end
local function place_item(item: attr.key, base: BasePart, offset: CFrame)
	w.item.build:assert(item)
	w.item_state.dropped:remove(item)
	w.item_state.owned:remove(item)
	w.item_state.placed:set(item, { base = base, offset = offset })
end

-- sync
sync.sync_attribute(w.item_state.dropped)
sync.sync_attribute(w.item_state.placed)
sync.sync_attribute(w.item_state.owned)
sync.sync_attribute(w.item_handler)
sync.sync_attribute(w.item_prefab)
sync.sync_attribute(w.material)
sync.sync_attribute(w.health)

attr.on_add(w.item_state.owned, function(id, owner): ()
	sync.group:set(id, owner)
	w.item_handler:remove(id)
end)
attr.on_remove(w.item_state.owned, function(id): ()
	w.item_handler:remove(id)
end)

attr.on_add(w.item_state.dropped, function(id, physics): ()
	sync.group:set(id, sync.everyone)
end)
attr.on_add(w.item_state.placed, function(id, physics): ()
	sync.group:set(id, sync.everyone)
end)

-- events
attr.on_add(w.item_prefab, function(id, prefab_id): ()
	for attribute, data in items[prefab_id] do
		w.item[attribute]:set(id, data)
	end
end)
attr.on_change(w.health + w.item_state.placed, function(id, health, placed): ()
	if health > 0 then return end
	w.health:remove(id)

	local world_pos = placed.base.CFrame * placed.offset
	drop_item(id, CFrame.lookAlong(world_pos.Position, Vector3.yAxis), 10)
end)

-- module
return table.freeze {
	new = new_item,
	drop = drop_item,
	give = give_item,
	place = place_item,
}
