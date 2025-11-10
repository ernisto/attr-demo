local ReplicatedStorage = game:GetService('ReplicatedStorage')

local graph = require(ReplicatedStorage.shared.vide.graph)
local vide = require(ReplicatedStorage.packages.vide)
local catcher = graph.create_node(false, table.pack, false :: any)

-- functions
local function iterator(current: graph.Node, last: graph.Node?): graph.Node?
	if last then
		graph.pop_scope()
		return nil
	else
		graph.push_scope(current)
		return current
	end
end

local function scope(node: graph.Node<any>?): any
	return iterator, node or graph.create_node(false, false, false)
end

local function get_source_node<T>(subject: vide.source<T>): graph.Node<T>
	graph.push_scope(catcher)
	subject()

	local node = catcher.parents[1]
	graph.pop_scope()

	graph.destroy(catcher)
	return node :: any
end

local function last_value(): any
	return assert(graph.get_scope()).cache
end

-- module
return table.freeze {
	scope = scope,
	get_source_node = get_source_node,
	last_value = last_value,
}
