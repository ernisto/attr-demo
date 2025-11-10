local ReplicatedStorage = game:GetService('ReplicatedStorage')

local attr = require(ReplicatedStorage.packages.luau.attr)
local render_items = require(ReplicatedStorage.client.item.render_items)
local vide = require(ReplicatedStorage.packages.vide)
local vide_attr = require(ReplicatedStorage.shared.vide_attr)
local w = require(ReplicatedStorage.shared.world)

local health_sources = vide_attr.to_sources(w.health)

local function create_healthbar(health)
	return vide.create 'BillboardGui' {
		StudsOffset = Vector3.new(0, 3, 0),
		Size = UDim2.new(10, 0, 1, 0),
		vide.create 'TextLabel' {
			Size = UDim2.new(1, 0, 1, 0),
			TextScaled = true,
			Text = function()
				return `health: {health()}`
			end,
		},
	}
end

attr.on_add(health_sources + render_items.placed_model, function(id, health, model): ()
	return vide.mount(function()
		local scale, set_scale = vide.spring(vide.source(1), 1 / 4)
		vide.effect(function()
			health()
			set_scale { impulse = -25 }
		end)
		vide.effect(function()
			if model:IsA('Model') then
				model:ScaleTo(scale())
			elseif model:IsA('BasePart') then
				model.Size = Vector3.new(1, 1, 1) * scale()
			end
		end)
		return create_healthbar(health)
	end, model)
end)

return nil
