local ReplicatedStorage = game:GetService('ReplicatedStorage')

local vide = require(ReplicatedStorage.packages.vide)
require(ReplicatedStorage.shared.world)

vide.root(function()
	local loader = require(ReplicatedStorage.shared.vide.loader)
	loader.load_descendants(ReplicatedStorage.shared)
	loader.load_descendants(script)
end)
