local ReplicatedStorage = game:GetService('ReplicatedStorage')
local RunService = game:GetService('RunService')

local mantle_uploads = require(ReplicatedStorage.mantle_uploads)

local is_release = game.GameId == mantle_uploads.release.experience.singleton.assetId
local env_uploads = if is_release then mantle_uploads.release else mantle_uploads.dev

type place_upload = typeof(mantle_uploads.release.place.start)

-- defs
export type place = { id: number }
local function place(upload: place_upload): place
	return table.freeze { id = upload.assetId }
end

local places = table.freeze {
	match = place(env_uploads.place.match),
	lobby = place(env_uploads.place.start),
}

-- functions
local function place_by_id(id: number): place?
	for name, place in places :: any do
		if place.id == id then return place end
	end
	return
end
local function current_place(place: place?)
	return if RunService:IsStudio() then place else place_by_id(game.PlaceId)
end

-- module
return table.freeze {
	current_place = current_place,
	place_by_id = place_by_id,
	group_id = env_uploads.experience.singleton.groupId,
	is_release = is_release,
	places = places,
}
