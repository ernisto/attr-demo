local ReplicatedStorage = game:GetService('ReplicatedStorage')

local promise = require(ReplicatedStorage.packages.promise)

local TELEPORT_TIMEOUT = 10
local last_teleports: { [Player]: CFrame } = {}

-- functions
local function last_teleport(player: Player): CFrame?
	return last_teleports[player]
end
local function teleport_player(subject: Player, some_zone: { BasePart | CFrame })
	local humanoid
	repeat
		humanoid = subject.Character and subject.Character:FindFirstChildOfClass 'Humanoid' or (task.wait() and nil)
	until humanoid

	assert(humanoid and humanoid.RootPart)
	if humanoid.Health == 0 then return end

	local zone = some_zone[math.random(1, #some_zone)]
	local fields = if typeof(zone) == 'CFrame'
		then { Size = Vector3.zero, Position = zone.Position, Rotation = zone.Rotation }
		else { Size = zone.Size, Position = zone.Position, Rotation = zone.CFrame.Rotation }

	local random_pos = Vector3.new(math.random(), math.random(), math.random()) * fields.Size
		+ fields.Position
		- fields.Size / 2

	if workspace.StreamingEnabled then subject:RequestStreamAroundAsync(random_pos) end
	humanoid.RootPart.CFrame = CFrame.new(random_pos) * fields.Rotation
	last_teleports[subject] = humanoid.RootPart.CFrame
end
local function teleport_players(subjects: { Player }, some_zone: { BasePart | CFrame })
	assert(#some_zone > 0, `empty zones`)

	local teleported_players = {}
	local promises = {}

	for _, player in subjects do
		table.insert(
			promises,
			promise
				.try(teleport_player, player, some_zone)
				:andThenCall(table.insert, teleported_players, player)
				:timeout(TELEPORT_TIMEOUT)
		)
	end
	promise.all(promises):await()
	return table.freeze(teleported_players)
end

-- module
return table.freeze {
	player = teleport_player,
	players = teleport_players,
	last_teleport = last_teleport,
}
