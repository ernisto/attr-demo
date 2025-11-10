local ReplicatedStorage = game:GetService('ReplicatedStorage')

local attr = require(ReplicatedStorage.packages.luau.attr)
local vide = require(ReplicatedStorage.packages.vide)

local function archetype_all(archetype: any): () -> { attr.id }
	local raw = archetype:all()
	local s = vide.source(raw)
	attr.on_add(archetype, function(item): ()
		table.insert(raw, item)
		s(raw)
	end)
	attr.on_remove(archetype, function(item): ()
		local index = table.find(raw, item)
		if index then table.remove(raw, item) end
		s(raw)
	end)
	return s
end

local function to_sources<T>(attribute: attr.attr<T>): attr.attr<vide.source<T>>
	local sources = attr.any(nil :: any)
	attr.on_add(attribute, function(id, value): ()
		sources:set(id, vide.source(value))
	end)
	attr.on_change(attribute, function(id, value): ()
		sources:assert(id)(value)
	end)
	return sources
end

-- module
return table.freeze {
	archetype_all = archetype_all,
	to_sources = to_sources,
}
