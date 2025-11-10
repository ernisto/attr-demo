local ReplicatedStorage = game:GetService('ReplicatedStorage')
local RunService = game:GetService('RunService')

local attr = require(ReplicatedStorage.packages.luau.attr)
local materials = require(ReplicatedStorage.config.materials)
local sync = require(ReplicatedStorage.packages.luau.attr_sync)

export type character = typeof(ReplicatedStorage.assets.models.starter_character)
export type material = typeof(materials.copper)

-- helpers
local function find_key<K, V>(tab: { [K]: V }, value: V): K?
	for k, kv in tab do
		if kv == value then return k end
	end
	return nil
end

-- defs
local d = nil :: any
local material = attr.any(d :: material)
local health = attr.any(100)

sync.sync_attribute(material, {
	serialize = function(material: material): string?
		return find_key(materials, material)
	end,
	deserialize = function(name): material
		return materials[name]
	end,
})

-- player
local player = attr.any(d :: Player)
local humanoid = attr.any(d :: character)
local player_character, character_controller = attr.xref()
local handling_item, item_handler = attr.xref()

-- item
local item_prefab = attr.any('unknown')
local prefab_attrs = table.freeze {
	display = attr.any(''),
	attack = attr.any { damage = 1, cooldown = 1 },
	build = attr.any {},
	chop = attr.any { efficiency = 1 },
}

local item_owner, owned_items = attr.ref()
local item_state = table.freeze {
	dropped = attr.any(d :: { cframe: CFrame, power: number }),
	placed = attr.any(d :: { base: BasePart, offset: CFrame }),
	owned = item_owner,
}

-- connections
RunService.Heartbeat:Connect(attr.gc_step)

-- module
return table.freeze {
	materials = materials,
	material = material,
	health = health,

	player = player,
	player_character = player_character,
	owned_items = owned_items,

	character_controller = character_controller,
	handling_item = handling_item,
	humanoid = humanoid,

	item = prefab_attrs,
	item_handler = item_handler,
	item_prefab = item_prefab,
	item_state = item_state,
	item_owner = item_owner,
}
