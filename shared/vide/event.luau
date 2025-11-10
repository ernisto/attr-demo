local ReplicatedStorage = game:GetService('ReplicatedStorage')

local flags = require(ReplicatedStorage.shared.vide.flags)
local graph = require(ReplicatedStorage.shared.vide.graph)
local vide = require(ReplicatedStorage.packages.vide)

local function when<T...>(signal: RBXScriptSignal<T...>, listener: (T...) -> ())
	local conn = signal:Once(listener)
	vide.cleanup(function()
		conn:Disconnect()
	end)
end

local function derive<T...>(signal: RBXScriptSignal<T...>): () -> (boolean, T...)
	local parent = graph.assert_stable_scope()
	local node = graph.create_node(parent, false, false)

	local result
	local conn = signal:Connect(function(...)
		result = table.pack(...)

		graph.bump_update_id()
		graph.update_descendants(node)

		result = { n = 0 }
	end)
	vide.cleanup(conn)

	local function derived_event(): (boolean, T...)
		graph.push_child_to_scope(node)
		return result ~= nil, unpack(result or {} :: any)
	end
	return derived_event
end

local last_result = setmetatable({}, { __mode = 'k' })
local function track<T...>(signal: RBXScriptSignal<T...>): (boolean, T...)
	local scope = graph.get_scope()
	if scope and scope.effect then
		when(signal, function(...)
			last_result[signal] = table.pack(...)

			-- force eval
			scope.higher_parent_update_id = graph.bump_update_id()
			graph.evaluate_node(scope)
			if not flags.batch then graph.flush_update_queue(0) end

			last_result[signal] = nil
		end)
	end

	-- for some reason, signals have different hashcode, but still gives true when compared
	for d_signal, data in last_result :: any do
		if signal == d_signal then return true, unpack(data :: any, 1, data.n) end
	end
	return false
end

local function track_property(instance: Instance, property: string)
	track(instance:GetPropertyChangedSignal(property))
	return (instance :: any)[property]
end
local function derive_property(instance: Instance, property: string)
	local changed = derive(instance:GetPropertyChangedSignal(property))
	return vide.derive(function()
		changed()
		return (instance :: any)[property]
	end)
end

-- module
return table.freeze {
	derive_property = derive_property,
	track_property = track_property,

	derive = derive,
	track = track,

	when = when,
}
