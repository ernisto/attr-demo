local ReplicatedStorage = game:GetService('ReplicatedStorage')

local graph = require(ReplicatedStorage.shared.vide.graph)
local misc = require(ReplicatedStorage.shared.vide.misc)
local vide = require(ReplicatedStorage.packages.vide)

export type delta<K, V> = { changes: { [K]: V }, removes: { [K]: V } }

-- module
local cache = setmetatable({}, { __mode = 'k' })
local function delta_by_key<K, V>(subject: vide.source<{ [K]: V }>): vide.source<(delta<K, V>)>
	if cache[subject] then return cache[subject] end

	local subject_node = misc.get_source_node(subject) :: any
	local node: any =
		graph.create_node(subject_node.effect and subject_node or graph.assert_stable_scope(), false, false)

	graph.push_cleanup(subject_node, function()
		cache[subject] = nil
	end)

	local weak_subject = setmetatable({ subject }, { __mode = 'v' })
	local last_cloned_input = {}

	function node.effect(last)
		local subject = weak_subject[1]
		if not subject then return { changes = {}, removes = {} } end

		local new_input = subject()
		assert(typeof(new_input) == 'table')

		local removes = last_cloned_input
		local changes = {}

		for index, value in new_input do
			if last_cloned_input[index] ~= value then changes[index] = value end
			removes[index] = nil
		end
		last_cloned_input = table.clone(new_input)
		return { changes = changes, removes = removes }
	end

	local function delta()
		graph.evaluate_node(node)
		graph.push_child_to_scope(node)
		return node.cache
	end
	graph.evaluate_node(node)
	cache[subject] = delta
	return delta
end

return table.freeze {
	get = delta_by_key,
	cache = cache,
}
