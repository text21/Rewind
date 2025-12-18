--!strict
local Math = require(script.Parent.Parent.Util.Math)
local Geom = require(script.Parent.Parent.Util.Geom)

local Validator = {}

export type ValidateContext = {
	maxRayDistance: number,
	allowHeadshots: boolean,
	extraForgiveness: number,
}

local function partSizeWithForgiveness(size: Vector3, extra: number): Vector3
	if extra <= 0 then return size end
	local e = Vector3.new(extra, extra, extra)
	return size + e
end

function Validator.RaycastPose(origin: Vector3, dir: Vector3, pose, ctx: ValidateContext)
	local dist = dir.Magnitude
	if dist <= 1e-6 then
		return nil
	end

	local maxDist = math.min(dist, ctx.maxRayDistance)
	local dirUnit = dir / dist

	local bestT = math.huge
	local best = nil

	for partName, snap in pairs(pose.parts) do
		local size = partSizeWithForgiveness(snap.size, ctx.extraForgiveness)

		local hit, tHit, normal = Math.RayOBB(origin, dirUnit, maxDist, snap.cf, size)
		if hit and tHit < bestT then
			local isHead = (partName == "Head")
			if isHead and not ctx.allowHeadshots then
				-- ignore
			else
				bestT = tHit
				best = {
					partName = partName,
					t = tHit,
					normal = normal,
					isHeadshot = isHead,
				}
			end
		end
	end

	return best
end

-- Sphere overlap against rewound OBBs
function Validator.SpherePose(center: Vector3, radius: number, pose, ctx: ValidateContext)
	local best = nil
	local bestDist2 = math.huge

	for partName, snap in pairs(pose.parts) do
		local size = partSizeWithForgiveness(snap.size, ctx.extraForgiveness)
		local ok, closest = Geom.SphereOBB(center, radius, snap.cf, size)
		if ok then
			local isHead = (partName == "Head")
			if isHead and not ctx.allowHeadshots then
				-- ignore
			else
				local d = center - closest
				local dist2 = d:Dot(d)
				if dist2 < bestDist2 then
					bestDist2 = dist2
					best = {
						partName = partName,
						closest = closest,
						isHeadshot = isHead,
					}
				end
			end
		end
	end

	return best
end

-- Capsule sweep (segment A->B with radius).
-- This uses sampling along the segment (robust + fast enough) and sphere-OBB checks.
function Validator.CapsuleSweepPose(a: Vector3, b: Vector3, radius: number, pose, ctx: ValidateContext, steps: number?)
	steps = steps or 10
	if steps < 1 then steps = 1 end

	local best = nil
	local bestT = math.huge

	local ab = (b - a)
	local len = ab.Magnitude
	if len < 1e-6 then
		local s = Validator.SpherePose(a, radius, pose, ctx)
		if s then
			return {
				partName = s.partName,
				t = 0,
				point = s.closest,
				isHeadshot = s.isHeadshot,
			}
		end
		return nil
	end

	for i = 0, steps do
		local t = i / steps
		local p = a + ab * t

		local s = Validator.SpherePose(p, radius, pose, ctx)
		if s then
			-- pick earliest along sweep
			if t < bestT then
				bestT = t
				best = {
					partName = s.partName,
					t = t,
					point = s.closest,
					isHeadshot = s.isHeadshot,
				}
			end
		end
	end

	return best
end

-- Cone/Arc test (fast): checks if closest point on OBB is within cone and range.
function Validator.ConePose(originCf: CFrame, range: number, angleDeg: number, pose, ctx: ValidateContext)
	local forward = originCf.LookVector
	local origin = originCf.Position
	local halfAngle = math.rad(angleDeg) * 0.5

	local best = nil
	local bestDist2 = math.huge

	for partName, snap in pairs(pose.parts) do
		local size = partSizeWithForgiveness(snap.size, ctx.extraForgiveness)

		-- approximate target point as closest point to origin on OBB
		local closest = Geom.ClosestPointOBB(origin, snap.cf, size)
		local v = closest - origin
		local dist2 = v:Dot(v)
		if dist2 <= range * range then
			local ang = Geom.AngleBetween(forward, v)
			if ang <= halfAngle then
				local isHead = (partName == "Head")
				if isHead and not ctx.allowHeadshots then
					-- ignore
				else
					if dist2 < bestDist2 then
						bestDist2 = dist2
						best = {
							partName = partName,
							point = closest,
							isHeadshot = isHead,
						}
					end
				end
			end
		end
	end

	return best
end

-- Multi-ray fan inside a yaw arc around LookVector.
function Validator.FanRaysPose(originCf: CFrame, range: number, angleDeg: number, rays: number, pose, ctx: ValidateContext)
	if rays < 1 then rays = 1 end
	local origin = originCf.Position
	local best = nil
	local bestT = math.huge

	if rays == 1 then
		return Validator.RaycastPose(origin, originCf.LookVector * range, pose, ctx)
	end

	local half = math.rad(angleDeg) * 0.5
	for i = 0, rays - 1 do
		local u = if rays == 1 then 0.5 else (i / (rays - 1))
		local yaw = -half + (2 * half) * u

		local dir = (originCf * CFrame.Angles(0, yaw, 0)).LookVector * range
		local r = Validator.RaycastPose(origin, dir, pose, ctx)
		if r and r.t < bestT then
			bestT = r.t
			best = r
		end
	end

	return best
end

return Validator
