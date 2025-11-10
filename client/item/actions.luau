local ContextActionService = game:GetService('ContextActionService')
local Players = game:GetService('Players')
local ReplicatedStorage = game:GetService('ReplicatedStorage')

local attr = require(ReplicatedStorage.packages.luau.attr)
local client_sync = require(ReplicatedStorage.client.client_sync)
local hover_item = require(ReplicatedStorage.client.item.hover)
local net = require(ReplicatedStorage.client.net)
local w = require(ReplicatedStorage.shared.world)

-- functions
local function handle_drop(_, state)
	if state ~= Enum.UserInputState.End then return end

	local item = w.owned_items:iter(Players.LocalPlayer)()
	net.game.inventory.drop_item.invoke(client_sync.server_id:assert(item))
end
ContextActionService:BindAction('drop-item', handle_drop, false, Enum.KeyCode.Q)

local function handle_hit_block(_, state)
	if state ~= Enum.UserInputState.End then return end

	local ore = hover_item.get_hover_ore()
	if not ore then return end

	net.game.inventory.hit_block.invoke(client_sync.server_id:assert(ore))
end
ContextActionService:BindAction('hit-block', handle_hit_block, false, Enum.UserInputType.MouseButton1)

-- events
attr.on_add(w.owned_items:of(Players.LocalPlayer), function(item): ()
	local char = w.player_character:find(Players.LocalPlayer)
	if char and w.handling_item:find(char) then return end

	net.game.inventory.handle_item.invoke(client_sync.server_id:assert(item))
end)

-- end
return nil
