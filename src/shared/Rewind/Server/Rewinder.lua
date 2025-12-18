--!strict
local Rewinder = {}

local function lerpCf(a: CFrame, b: CFrame, alpha: number): CFrame
	return a:Lerp(b, alpha)
end

function Rewinder.Sample(store, rewindTo: number)
	local n = store:Len()
	if n == 0 then return nil end

	local first = store:First()
	local last = store:Last()
	if not first or not last then return nil end

	if rewindTo <= first.t then
		return first
	end
	if rewindTo >= last.t then
		return last
	end

	local a = first
	local b = last

	for i = 2, n do
		local s = store:At(i)
		if s and s.t >= rewindTo then
			b = s
			a = store:At(i - 1) or s
			break
		end
	end

	local dt = (b.t - a.t)
	local alpha = 0
	if dt > 1e-6 then
		alpha = (rewindTo - a.t) / dt
	end

	local parts = {}
	for name, pa in pairs(a.parts) do
		local pb = b.parts[name]
		if pb then
			parts[name] = {
				cf = lerpCf(pa.cf, pb.cf, alpha),
				size = pa.size,
			}
		else
			parts[name] = pa
		end
	end

	return {
		t = rewindTo,
		parts = parts,
	}
end

return Rewinder
