--!strict
local Client = {}

function Client.GetClientTime(): number
	local ok, t = pcall(function()
		return workspace:GetServerTimeNow()
	end)
	if ok then return t end
	return os.clock()
end

function Client.MakeShotPayload(origin: Vector3, direction: Vector3, weaponId: string?)
	local now = Client.GetClientTime()
	return {
		weaponId = weaponId,
		origin = origin,
		direction = direction,
		clientTime = now,
		clientShotId = tostring(now) .. ":" .. tostring(math.random(1, 1e9)),
	}
end

function Client.EnableDebugUI(Rewind)
	local ok = pcall(function()
		require(script.Parent.Parent.Debug.IrisPanel).Start(Rewind)
	end)
	return ok
end


return Client
