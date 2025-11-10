local ReplicatedStorage = game:GetService('ReplicatedStorage')

local net = require(ReplicatedStorage.client.net)
local sync_client = require(ReplicatedStorage.packages.luau.attr_sync_client)

-- events
net.game.world.entity_added.on(sync_client.create_server_id)
net.game.world.entity_removed.on(sync_client.destroy_server_id)
net.game.world.attribute_changed.on(sync_client.change_attribute)
net.game.world.attribute_removed.on(sync_client.remove_attribute)

-- module
return table.freeze { server_id = sync_client.server_id }
