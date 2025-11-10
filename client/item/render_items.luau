local ReplicatedStorage = game:GetService('ReplicatedStorage')

local attr = require(ReplicatedStorage.packages.luau.attr)
local client_sync = require(ReplicatedStorage.client.client_sync)
local net = require(ReplicatedStorage.client.net)
local vide = require(ReplicatedStorage.packages.vide)
local w = require(ReplicatedStorage.shared.world)

-- events
local d = attr.on_add(w.item_prefab + w.item_state.dropped, function(id, prefab_id, drop)
	local asset = ReplicatedStorage.assets.models.items:FindFirstChild(prefab_id) or error('cannot be dropped')
	local model = asset:Clone() :: PVInstance
	model:SetAttribute('id', id)
	model:AddTag(prefab_id)
	model:AddTag('dropped')

	model:PivotTo(drop.cframe)
	vide.apply(model) {
		Parent = workspace,
		vide.create 'ProximityPrompt' {
			RequiresLineOfSight = false,
			Triggered = function()
				net.game.inventory.pickup_item.invoke(client_sync.server_id:assert(id))
			end,
		},
	}

	return function()
		model:Destroy()
	end
end)
vide.cleanup(d)

local d2 = attr.on_add(w.item_prefab + w.item_handler, function(id, prefab_id, handler)
	local asset = ReplicatedStorage.assets.models.items:FindFirstChild(prefab_id) or error('cannot be handled')
	local model = asset:Clone() :: BasePart
	model:SetAttribute('id', id)
	model:AddTag(prefab_id)
	model:AddTag('handled')

	local handler_model = w.humanoid:assert(handler)

	model.Parent = handler_model
	model:PivotTo(handler_model.RightHand.CFrame)

	vide.create 'WeldConstraint' {
		Parent = model,
		Part0 = handler_model.RightHand,
		Part1 = if model:IsA('Model') then model.PrimaryPart else model,
	}

	return function()
		model:Destroy()
	end
end)
vide.cleanup(d2)

local placed_model = attr.any((nil :: any) :: PVInstance)
local d3 = attr.on_add(w.item_prefab + w.item_state.placed, function(id, prefab_id, placement)
	local asset = ReplicatedStorage.assets.models.builds:FindFirstChild(prefab_id) or error('cannot be placed')
	local model = asset:Clone() :: PVInstance
	model:SetAttribute('id', id)
	model:AddTag(prefab_id)
	model:AddTag('placed')

	model.Parent = workspace
	model:PivotTo(placement.base.CFrame * placement.offset)

	local material = w.material:find(id)
	if material then
		local color = Color3.fromRGB(unpack(material.color))
		-- for _, part in model:QueryDescendants('Model >> .metal_part') :: any do
		for _, part: BasePart in model:GetDescendants() :: any do
			if part:HasTag('metal_part') then part.Color = color end
		end
	end

	placed_model:set(id, model)
	return function()
		placed_model:remove(id)
		model:Destroy()
	end
end)
vide.cleanup(d3)

-- module
return table.freeze {
	placed_model = placed_model,
}
