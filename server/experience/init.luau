local Players = game:GetService('Players')
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local RunService = game:GetService('RunService')
local ServerScriptService = game:GetService('ServerScriptService')
local TeleportService = game:GetService('TeleportService')

local config = require(ReplicatedStorage.config.game)
local experience = require(ReplicatedStorage.shared.experience)
local memory = require(ServerScriptService.server.experience.memory)
local player_save = require(ServerScriptService.server.player.save)
local promise = require(ReplicatedStorage.packages.promise)
export type place = experience.place

local current_place = {}
local player_joined_listeners = {}
local queued_players_store = memory.get_hashmap('queued_players')

-- functions
local function on_player_join(listener: (Player) -> ())
	table.insert(player_joined_listeners, listener)
	if not RunService:IsStudio() then Players.PlayerAdded:Connect(listener) end
end
local function await_teleport(
	place: experience.place,
	players: { Player },
	options: TeleportOptions?,
	private_server_id: string?
)
	if private_server_id then
		assert(options and options.ReservedServerAccessCode ~= '', `you arent teleporting to a private server`)
		memory.await_set(queued_players_store, private_server_id, #players, 30 + config.teleport_timeout)
	end

	if RunService:IsStudio() then
		for _, player in players do
			-- task.delay(math.random(3, 5), function()
			current_place[player] = place
			for _, listener in player_joined_listeners do
				task.spawn(listener, player)
			end
			-- end)
		end
		return
	end

	local promises = {}
	for _, player in players do
		local profile = player_save.find(player)
		if not profile then continue end

		local promise = promise
			.new(function(resolve)
				profile.OnSessionEnd:Connect(resolve)
			end)
			:timeout(config.teleport_timeout)
			:catch(function()
				player:Kick(`failed to teleport`)
			end)

		table.insert(promises, promise)
		profile:EndSession()
	end
	promise.all(promises :: any):await()
	return TeleportService:TeleportAsync(place.id, players, options)
end
local function await_queued_players_amount(): number?
	while task.wait(1) do
		local queued_players = memory.await_get(queued_players_store, game.PrivateServerId)
		if queued_players then return queued_players end
	end
	return
end
local function await_reserve_server(place: experience.place)
	return unpack(
		if RunService:IsStudio()
			then { 'debugcodeofawaitreserveserver', game.PrivateServerId }
			else { TeleportService:ReserveServer(place.id) }
	)
end
local function get_players(place: experience.place)
	if not RunService:IsStudio() then return Players:GetPlayers() end

	local players = {}
	for player, player_place in current_place do
		if place == player_place then table.insert(players, player) end
	end
	return players
end

-- module
return table.freeze {
	await_queued_players_amount = await_queued_players_amount,
	await_reserve_server = await_reserve_server,
	on_player_join = on_player_join,
	await_teleport = await_teleport,
	get_players = get_players,
	places = experience.places,
	memory = memory,
}
