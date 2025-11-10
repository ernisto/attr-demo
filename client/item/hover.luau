local CollectionService = game:GetService('CollectionService')
local Players = game:GetService('Players')
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local RunService = game:GetService('RunService')
local UserInputService = game:GetService('UserInputService')

local vide = require(ReplicatedStorage.packages.vide)

-- vars
local highlight = vide.create 'Highlight' {
	FillColor = Color3.new(1, 1, 1),
	DepthMode = Enum.HighlightDepthMode.Occluded,
	Parent = Players.LocalPlayer.PlayerGui,
} :: Highlight

-- functions
local function get_hover_ore_model(): PVInstance?
	local pos = UserInputService:GetMouseLocation()
	local ray = workspace.CurrentCamera:ViewportPointToRay(pos.X, pos.Y, 500)

	local param = RaycastParams.new()
	param.FilterDescendantsInstances = CollectionService:GetTagged('placed')
	param.FilterType = Enum.RaycastFilterType.Include

	local hit = workspace:Raycast(workspace.CurrentCamera.CFrame.Position, ray.Direction * 500, param)
	return hit and hit.Instance:FindFirstAncestorWhichIsA('PVInstance')
end
local function get_hover_ore()
	local model = get_hover_ore_model()
	return model and model:GetAttribute('id')
end

-- connections
RunService.Heartbeat:Connect(function(dt)
	local model = get_hover_ore_model()
	highlight.Adornee = model
	highlight.FillTransparency = math.map(math.sin(os.clock() * 2), -1, 1, 0.5, 1)
end)

-- module
return table.freeze {
	get_hover_ore = get_hover_ore,
}
