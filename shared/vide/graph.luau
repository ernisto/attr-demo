local ReplicatedStorage = game:GetService('ReplicatedStorage')
local module = require(ReplicatedStorage.packages['.pesde']['centau_vide@0.3.1'].vide.graph)
export type Node<T = any> = module.Node<T>
return module
