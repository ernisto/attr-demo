local ReplicatedStorage = game:GetService('ReplicatedStorage')

local map_values = require(ReplicatedStorage.shared.vide.map_values)

local function keep_pair<V, K>(v: V, k: K): V
	return v
end

return function<K, V>(source: () -> { [K]: V })
	return map_values(source, keep_pair)
end
