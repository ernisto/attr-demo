local MemoryStoreService = game:GetService('MemoryStoreService')
local RunService = game:GetService('RunService')

type live_store = { kind: 'live', name: string, store: MemoryStoreHashMap }
type debug_store = { kind: 'debug', name: string, data: { [string]: any }, lifetime: { [string]: thread } }
export type store = live_store | debug_store

-- functions
local function get_hashmap(name: string): store
	return if RunService:IsStudio()
		then { kind = 'debug', name = name, data = {}, lifetime = {} }
		else { kind = 'live', name = name, store = MemoryStoreService:GetHashMap(name) }
end

-- methods
local function await_live_get(store: live_store, key: string): any
	return store.store:GetAsync(key)
end
local function debug_get(store: debug_store, key: string): any
	return store.data[key]
end
local function await_get(store: store, key: string): any
	return if store.kind == 'live' then await_live_get(store, key) else debug_get(store, key)
end

local function await_live_remove(store: live_store, key: string)
	store.store:RemoveAsync(key)
end
local function debug_remove(store: debug_store, key: string)
	store.data[key] = nil
end
local function await_remove(store: store, key: string): any
	return if store.kind == 'live' then await_live_remove(store, key) else debug_remove(store, key)
end

local function await_live_set(store: live_store, key: string, value: any, duration: number)
	store.store:SetAsync(key, value, duration)
end
local function debug_set(store: debug_store, key: string, value: any, duration: number)
	local lifetime = store.lifetime[key]
	if lifetime then return task.cancel(lifetime) end

	store.data[key] = value
	store.lifetime[key] = task.delay(duration, debug_remove, store, key)
end
local function await_set(store: store, key: string, value: any, duration: number): any
	return if store.kind == 'live'
		then await_live_set(store, key, value, duration)
		else debug_set(store, key, value, duration)
end

-- module
return table.freeze {
	get_hashmap = get_hashmap,
	await_remove = await_remove,
	await_set = await_set,
	await_get = await_get,
}
