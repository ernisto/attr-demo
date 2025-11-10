return function(time: number): string
	local sec = time % 60
	local min = (time // 60) % 60
	local hour = (time // (60 * 60)) % 24
	local day = (time // (24 * 60 * 60))

	if time <= 0 then return '--' end

	if day > 0 then
		return string.format('%dd %dh %dm', day, hour, min)
	elseif hour > 0 then
		return string.format('%dh %dm %ds', hour, min, sec)
	elseif min > 0 then
		return string.format('%dm %ds', min, sec)
	elseif sec > 0 then
		return string.format('%ds', sec)
	end

	return '--'
end
