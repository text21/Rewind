--!strict
local Math = {}

-- Ray vs OBB (box). Returns (hit:boolean, t:number, normalWorld:Vector3)
-- rayDirUnit must be unit; maxDist is scalar.
function Math.RayOBB(origin: Vector3, dirUnit: Vector3, maxDist: number, boxCf: CFrame, boxSize: Vector3)
	local o = boxCf:PointToObjectSpace(origin)
	local d = boxCf:VectorToObjectSpace(dirUnit)

	local hx, hy, hz = boxSize.X * 0.5, boxSize.Y * 0.5, boxSize.Z * 0.5

	local tMin = -math.huge
	local tMax = math.huge
	local hitNormalLocal = Vector3.new()

	local function slab(oAxis: number, dAxis: number, minA: number, maxA: number, axisNormal: Vector3)
		if math.abs(dAxis) < 1e-8 then
			if oAxis < minA or oAxis > maxA then
				return false
			end
			return true
		end

		local inv = 1 / dAxis
		local t1 = (minA - oAxis) * inv
		local t2 = (maxA - oAxis) * inv
		local n = axisNormal

		if t1 > t2 then
			t1, t2 = t2, t1
			n = -n
		end

		if t1 > tMin then
			tMin = t1
			hitNormalLocal = n
		end
		if t2 < tMax then
			tMax = t2
		end

		if tMin > tMax then
			return false
		end

		return true
	end

	if not slab(o.X, d.X, -hx, hx, Vector3.new(1, 0, 0)) then return false end
	if not slab(o.Y, d.Y, -hy, hy, Vector3.new(0, 1, 0)) then return false end
	if not slab(o.Z, d.Z, -hz, hz, Vector3.new(0, 0, 1)) then return false end

	local tHit = tMin
	if tHit < 0 then
		tHit = tMax
		if tHit < 0 then
			return false
		end
	end

	if tHit > maxDist then
		return false
	end

	local normalWorld = boxCf:VectorToWorldSpace(hitNormalLocal)
	return true, tHit, normalWorld
end

function Math.Clamp(x: number, a: number, b: number): number
	if x < a then return a end
	if x > b then return b end
	return x
end

return Math
