type param = BasePart | { Size: Vector3, CFrame: CFrame }

local function aabb(part1: param, part2: param)
	local abs_offset = part1.CFrame:PointToObjectSpace(part2.CFrame.Position):Abs()
	local distances = part1.Size / 2 + part2.Size / 2

	return abs_offset.X <= distances.X and abs_offset.Y <= distances.Y and abs_offset.Z <= distances.Z
end

return aabb
