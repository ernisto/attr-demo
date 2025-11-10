local ReplicatedStorage = game:GetService('ReplicatedStorage')
local ServerScriptService = game:GetService('ServerScriptService')

local attr = require(ReplicatedStorage.packages.luau.attr)
local attr_save = require(ReplicatedStorage.packages.luau.attr_save)
local profile_store = require(ServerScriptService.packages.profile_store)

-- types
export type profile<T = json> = profile_store.Profile<{}>
export type handler<T = json, M = json> = attr.id -- profile_store.ProfileStore<T>
export type message = json
type json = profile_store.JSONAcceptable

local z = nil :: any
local stores = attr.any(z :: profile_store.ProfileStore<any>)
local profiles = attr.refs()

-- function
local function await_load<T>(handler: handler<T>, store_key: string, key: attr.key, steal: 'steal'?): profile?
	local _, id = attr.id(key)
	local function should_cancel()
		return not attr.is_alive(id)
	end

	local profile = stores:assert(handler):StartSessionAsync(store_key, { Cancel = should_cancel })
	if profile == nil then return end

	attr_save.load(handler, profile.Data, key)
	profile.OnSave:Connect(function()
		profile.Data = attr_save.save(handler, key)
	end)

	attr.on_destroy(key, function()
		profile:EndSession()
	end)
	return profile
end
local function await_global_update<T, M>(handler: handler<T>, key: string, message: M)
	return stores:assert(handler):MessageAsync(key, message :: any)
end
local function handle<T, M>(store_name: string): handler<T, M>
	local handler = attr.id()
	stores:set(handler, profile_store.New(store_name, {}))
	return handler
end

-- module
return table.freeze {
	await_load = await_load,
	await_global_update = await_global_update,
	handle = handle,

	profiles = profiles,
	stores = stores,
}
