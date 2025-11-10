local Players = game:GetService('Players')
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local ServerScriptService = game:GetService('ServerScriptService')

local attr = require(ReplicatedStorage.packages.luau.attr)
local attr_save = require(ReplicatedStorage.packages.luau.attr_save)
local attr_save_profile = require(ServerScriptService.server.attr_save_profile)

-- vars
local player_save = attr_save_profile.handle('player')
local profiles = attr.any((nil :: any) :: attr_save_profile.profile)
export type data = {}

-- functions
local function process_player(player: Player): ()
	local profile = attr_save_profile.await_load(player_save, tostring(player.UserId), player)
	if not profile then return player:Kick(`couldnt possible load your data`) end

	profile:AddUserId(player.UserId)
end
local function await_global_update(player_id: number, message: attr_save_profile.message)
	return attr_save_profile.await_global_update(player_save, tostring(player_id), message)
end

local function await_assert(player: Player): attr_save_profile.profile
	return profiles:assert_await(player)
end
local function assert(player: Player): attr_save_profile.profile
	return profiles:assert(player)
end
local function find(player: Player): attr_save_profile.profile?
	return profiles:find(player)
end

local function include_attr<T>(attribute: attr.attr<T>, key: string, serde: attr_save.serde_impl<T>)
	attr_save.include_attr(player_save, attribute, key, serde)
end
local function include_ids(attribute: attr.linkN_attr, key: string)
	return attr_save.include_ids(player_save, attribute, key)
end
local function include_id(attribute: attr.link1_attr, key: string)
	return attr_save.include_id(player_save, attribute, key)
end

-- listener
Players.PlayerRemoving:Connect(attr.destroy)
Players.PlayerAdded:Connect(process_player)
for _, player in Players:GetPlayers() do
	task.spawn(process_player, player)
end

-- end
return table.freeze {
	await_global_update = await_global_update,
	await_assert = await_assert,
	assert = assert,
	find = find,

	include_attr = include_attr,
	include_ids = include_ids,
	include_id = include_id,
}
