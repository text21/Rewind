--!strict
local Geom = {}

function Geom.ClosestPointOBB(pointWorld: Vector3, boxCf: CFrame, boxSize: Vector3): Vector3
	local p = boxCf:PointToObjectSpace(pointWorld)
	local hx, hy, hz = boxSize.X * 0.5, boxSize.Y * 0.5, boxSize.Z * 0.5

	local cx = math.clamp(p.X, -hx, hx)
	local cy = math.clamp(p.Y, -hy, hy)
	local cz = math.clamp(p.Z, -hz, hz)

	return boxCf:PointToWorldSpace(Vector3.new(cx, cy, cz))
end

function Geom.SphereOBB(center: Vector3, radius: number, boxCf: CFrame, boxSize: Vector3): (boolean, Vector3)
	local closest = Geom.ClosestPointOBB(center, boxCf, boxSize)
	local d = center - closest
	if d:Dot(d) <= radius * radius then
		return true, closest
	end
	return false, closest
end

function Geom.AngleBetween(a: Vector3, b: Vector3): number
	local da = a.Magnitude
	local db = b.Magnitude
	if da < 1e-8 or db < 1e-8 then return 0 end
	local c = math.clamp(a:Dot(b) / (da * db), -1, 1)
	return math.acos(c)
end

return Geom
