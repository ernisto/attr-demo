--!nolint DeprecatedApi
-- we use getfenv to inject track_require in regular modules
-- so we can track modules without lose their exported types

local ReplicatedStorage = game:GetService('ReplicatedStorage')

local event = require(ReplicatedStorage.shared.vide.event)
local graph = require(ReplicatedStorage.shared.vide.graph)
local map_values = require(ReplicatedStorage.shared.vide.map_values)
local vide = require(ReplicatedStorage.packages.vide)

-- vars
local parents = {}
local modules = {}
local tracking_modules = vide.source(modules)

-- functions
local function load_descendants(root: Instance)
	for _, instance in root:GetDescendants() do
		if not instance:IsA('ModuleScript') then continue end
		if instance == script then continue end

		modules[instance:GetFullName()] = instance
		parents[instance:GetFullName()] = instance.Parent
	end
	tracking_modules(modules)
end

-- we must to create all nodes first, so require()'ing a `unloaded module`
-- will evaluate the `unloaded module` node, and we be able to track their updates
local is_creating_nodes = vide.source(true)
task.defer(is_creating_nodes :: any, false)

local was_required = {}
local required_modules = map_values(tracking_modules, function(mutable_module, path)
	if is_creating_nodes() then return nil end

	event.track(mutable_module.Changed)
	local fresh_module = mutable_module

	if was_required[mutable_module] then
		mutable_module.Parent = nil
		fresh_module = mutable_module:Clone()
		fresh_module.Parent = parents[path] :: any
		vide.cleanup(fresh_module)
	end

	was_required[mutable_module] = true
	return vide.untrack(function()
		return (require :: any)(fresh_module)
	end)
end)

-- functions
local function tracking_dependencies<P..., R...>(func: (P...) -> R..., ...: P...): R...
	local scope = graph.get_scope() or error(`attempt to track requires in a untracked module`)
	local last_effect = scope.effect :: any

	scope.effect = last_effect or table.pack
	local result = { func(...) }

	scope.effect = last_effect :: any
	return unpack(result)
end
local function track_require(...: ModuleScript)
	-- modules are loaded in a stable scope to be able to create reactive stuffs
	-- but we need this scope as reactive again to track module dependencies
	local modules = { ... }
	return tracking_dependencies(function()
		local result = {}
		for i, module in modules do
			result[i] = required_modules(module:GetFullName()) or (require :: any)(module)
		end
		return unpack(result)
	end)
end
local function track_requires(level: number?)
	if _G.RELEASE then getfenv(1 + (level or 1)).require = track_require end
end

-- module
return table.freeze {
	load_descendants = load_descendants,
	track_requires = track_requires,
	require = track_require,
}
