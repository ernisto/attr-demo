local ReplicatedStorage = game:GetService('ReplicatedStorage')

local delta_by_keys = require(ReplicatedStorage.shared.vide.delta_by_keys)
local flags = require(ReplicatedStorage.shared.vide.flags)
local graph = require(ReplicatedStorage.shared.vide.graph)
local vide = require(ReplicatedStorage.packages.vide)

local push_child_to_scope = graph.push_child_to_scope
local update_descendants = graph.update_descendants
local evaluate_node = graph.evaluate_node
local create_node = graph.create_node

-- functions
local function is_similar(a: any, b: any)
	return a == b and (type(a) ~= 'table' or table.isfrozen(a))
end

export type pair_source<K, V> = (() -> { [K]: V }) & ((K) -> V?)

-- module
type processor<K, IV, OV> = graph.Node<OV?> & { key: K, value: IV, outdate: () -> () }
local function map_values<K, IV, OV>(
	subject: vide.source<{ [K]: IV }>,
	pair_computer: (value: IV, key: K) -> OV
): pair_source<K, OV>
	type _processor = processor<K, IV, OV>
	type _value = { [K]: OV }

	local node = create_node(graph.assert_stable_scope(), false, false)
	local output_node = create_node(node, false, {})
	local output_delta = create_node(node, false, { changes = {}, removes = {} })
	local input_delta = delta_by_keys.get(subject)

	local changes = {}
	local removes: { [K]: any } = {}
	local output: _value = {}
	local is_processing_multiples = true

	local free_processors = {} -- TODO: outlives check
	local processors = {}

	local function new_processor(): _processor
		local processor = create_node(node, false :: any, false) :: _processor
		function processor.effect(): OV?
			local input_value = processor.value
			if input_value == nil then return nil end

			local key = processor.key
			local success, new_value = xpcall(pair_computer, debug.traceback, input_value, key)

			if not success then
				warn(`error occurred while processing key '{key}':\n{new_value}`)
				new_value = nil :: any
			end

			if is_similar(new_value, processor.cache) then return new_value end

			if new_value == nil then
				removes[key] = true
			else
				changes[key] = new_value
			end
			output[key] = new_value :: any

			if not is_processing_multiples then
				output_delta.cache = { changes = changes, removes = removes }
				changes = {}
				removes = {}
				update_descendants(output_node)
				update_descendants(output_delta)
			end
			return new_value
		end
		return processor
	end

	function output_node.effect()
		local update_id = output_node.higher_parent_update_id
		local delta = if update_id == -1 then { changes = table.clone(subject()), removes = {} } else input_delta()

		removes = table.clone(delta.removes)
		changes = {}

		local prev_free_processors_amount = #free_processors
		local already_batching = flags.batch
		is_processing_multiples = true
		flags.batch = true

		-- free unused processors
		for key in removes do
			local processor = processors[key]
			if processor then
				table.insert(free_processors, processor)
				processors[key] = nil
			else
				removes[key] = nil
			end
			output[key] = nil
		end

		-- process changes
		for key, new_value in delta.changes :: any do
			local processor: _processor = processors[key]
			if not processor then
				processor = table.remove(free_processors) or new_processor()
				processors[key] = assert(processor)
				processor.cache = nil
				processor.key = key
			end
			processor.higher_parent_update_id = update_id
			processor.value = new_value
			evaluate_node(processor)
		end

		-- clear new freed processors
		for i = prev_free_processors_amount + 1, #free_processors do
			local processor = free_processors[i]
			processor.higher_parent_update_id = update_id
			processor.value = nil
			evaluate_node(processor)
		end

		-- end
		if not already_batching then flags.batch = false end
		is_processing_multiples = false

		if next(removes) or next(changes) then
			output_delta.cache = { changes = changes, removes = removes }
			changes = {}
			removes = {}
			update_descendants(output_delta)
		end
		return output
	end

	local function values(key: K?)
		if key then
			local processor = processors[key]
			if processor then
				evaluate_node(processor)
				push_child_to_scope(processor)
			else
				evaluate_node(output_node)
				push_child_to_scope(output_node)
			end
			return output[key] :: any
		else
			evaluate_node(output_node)
			push_child_to_scope(output_node)
			return output
		end
	end
	local function delta()
		evaluate_node(output_node)
		push_child_to_scope(output_delta)
		return output_delta.cache
	end

	evaluate_node(output_node)
	delta_by_keys.cache[values :: any] = delta

	return values :: any
end

return map_values
