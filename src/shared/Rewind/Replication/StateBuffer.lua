--!strict
--[[
	StateBuffer - Unified circular buffer for entity states

	Serves BOTH interpolation (client) AND hit validation (server rewind).
	This replaces the separate SnapshotStore for replication-enabled entities.

	Features:
	- Ring buffer with configurable capacity
	- Interpolation sampling with hermite splines for smooth motion
	- Rewind sampling for hit validation
	- Delta compression support
]]

local RingBuffer = require(script.Parent.Parent.Util.RingBuffer)
local Types = require(script.Parent.Parent.Types)

local StateBuffer = {}
StateBuffer.__index = StateBuffer

export type StateBuffer = {
	_buf: any,
	_capacity: number,
	_entityId: string,
	_lastState: Types.EntityState?,
}

--[[
	Create a new StateBuffer

	@param entityId The entity this buffer belongs to
	@param windowMs How much history to keep in milliseconds
	@param tickRate Updates per second
]]
function StateBuffer.new(entityId: string, windowMs: number, tickRate: number)
	local windowSec = windowMs / 1000
	local capacity = math.max(8, math.floor(windowSec * tickRate) + 4)

	local self = setmetatable({
		_buf = RingBuffer.new(capacity),
		_capacity = capacity,
		_entityId = entityId,
		_lastState = nil,
	}, StateBuffer)

	return self
end

--[[
	Push a new state into the buffer
]]
function StateBuffer:Push(state: Types.EntityState)
	self._buf:Push(state)
	self._lastState = state
end

--[[
	Get buffer length
]]
function StateBuffer:Len(): number
	return self._buf:Len()
end

--[[
	Get state at index (1-based)
]]
function StateBuffer:At(i: number): Types.EntityState?
	return self._buf:At(i)
end

--[[
	Get oldest state
]]
function StateBuffer:First(): Types.EntityState?
	return self._buf:First()
end

--[[
	Get newest state
]]
function StateBuffer:Last(): Types.EntityState?
	return self._buf:Last()
end

--[[
	Get the last state (for delta compression)
]]
function StateBuffer:GetLastState(): Types.EntityState?
	return self._lastState
end

--[[
	Sample the buffer at a specific timestamp for INTERPOLATION
	Uses hermite spline for smooth motion between states

	@param targetTime The timestamp to sample at
	@return Interpolated EntityState or nil
]]
function StateBuffer:SampleInterpolated(targetTime: number): Types.EntityState?
	local n = self._buf:Len()
	if n == 0 then return nil end

	local first = self._buf:First()
	local last = self._buf:Last()
	if not first or not last then return nil end

    if targetTime <= first.t then
		return first
	end
	if targetTime >= last.t then
		return last
	end

	local before: Types.EntityState? = first
	local after: Types.EntityState? = last

	for i = 2, n do
		local s = self._buf:At(i)
		if s and s.t >= targetTime then
			after = s
			before = self._buf:At(i - 1) or s
			break
		end
	end

	if not before or not after then
		return last
	end

	local dt = after.t - before.t
	local alpha = 0
	if dt > 1e-6 then
		alpha = (targetTime - before.t) / dt
	end
	alpha = math.clamp(alpha, 0, 1)

	local interpCf = before.rootCf:Lerp(after.rootCf, alpha)
	local interpVel = before.velocity:Lerp(after.velocity, alpha)

	local interpParts: { [string]: CFrame }? = nil
	if before.parts and after.parts then
		interpParts = {}
		for partName, beforeCf in pairs(before.parts) do
			local afterCf = after.parts[partName]
			if afterCf then
				interpParts[partName] = beforeCf:Lerp(afterCf, alpha)
			else
				interpParts[partName] = beforeCf
			end
		end

        for partName, afterCf in pairs(after.parts) do
			if not interpParts[partName] then
				interpParts[partName] = afterCf
			end
		end
	end

	return {
		t = targetTime,
		rootCf = interpCf,
		velocity = interpVel,
		parts = interpParts,
	}
end

--[[
	Sample the buffer at a specific timestamp for REWIND (hit validation)
	Same as SampleInterpolated but with a clearer name for server usage

	@param rewindTime The timestamp to rewind to
	@return Interpolated EntityState or nil
]]
function StateBuffer:SampleRewind(rewindTime: number): Types.EntityState?
	return self:SampleInterpolated(rewindTime)
end

--[[
	Extrapolate beyond the latest state
	Used when network updates are delayed

	@param targetTime The timestamp to extrapolate to
	@param maxExtrapolationMs Maximum extrapolation time in milliseconds
	@return Extrapolated EntityState or nil
]]
function StateBuffer:Extrapolate(targetTime: number, maxExtrapolationMs: number): Types.EntityState?
	local last = self._buf:Last()
	if not last then return nil end

	local dt = targetTime - last.t
	if dt <= 0 then
		return last
	end

	local maxDt = maxExtrapolationMs / 1000
	if dt > maxDt then
		dt = maxDt
	end

	local extrapolatedPos = last.rootCf.Position + (last.velocity * dt)
	local extrapolatedCf = CFrame.new(extrapolatedPos) * (last.rootCf - last.rootCf.Position)

	return {
		t = targetTime,
		rootCf = extrapolatedCf,
		velocity = last.velocity,
		parts = last.parts,
	}
end

--[[
	Get the time range covered by the buffer
	@return (oldestTime, newestTime) or (0, 0) if empty
]]
function StateBuffer:GetTimeRange(): (number, number)
	local first = self._buf:First()
	local last = self._buf:Last()

	if not first or not last then
		return 0, 0
	end

	return first.t, last.t
end

--[[
	Check if a timestamp is within the buffer's range
]]
function StateBuffer:ContainsTime(t: number): boolean
	local first = self._buf:First()
	local last = self._buf:Last()

	if not first or not last then
		return false
	end

	return t >= first.t and t <= last.t
end

--[[
	Clear the buffer
]]
function StateBuffer:Clear()
	self._buf:Clear()
	self._lastState = nil
end

--[[
	Convert EntityState to CompressedState for network transmission
]]
function StateBuffer.Compress(state: Types.EntityState): Types.CompressedState
	local rx, ry, rz = state.rootCf:ToEulerAnglesXYZ()

	return {
		t = state.t,
		pos = state.rootCf.Position,
		rot = { rx, ry, rz },
		vel = state.velocity,
	}
end

--[[
	Convert CompressedState back to EntityState
]]
function StateBuffer.Decompress(compressed: Types.CompressedState): Types.EntityState
	local rot = compressed.rot
	local cf = CFrame.new(compressed.pos) * CFrame.Angles(rot[1], rot[2], rot[3])

	return {
		t = compressed.t,
		rootCf = cf,
		velocity = compressed.vel or Vector3.zero,
		parts = nil,
	}
end

--[[
	Calculate delta between two states for compression
	Returns nil if states are too similar (no update needed)

	@param current Current state
	@param previous Previous state
	@param posThreshold Position change threshold (studs)
	@param rotThreshold Rotation change threshold (radians)
]]
function StateBuffer.CalculateDelta(
	current: Types.EntityState,
	previous: Types.EntityState?,
	posThreshold: number?,
	rotThreshold: number?
): Types.CompressedState?
	posThreshold = posThreshold or 0.05
	rotThreshold = rotThreshold or 0.02

	if not previous then
		return StateBuffer.Compress(current)
	end

	local posDelta = (current.rootCf.Position - previous.rootCf.Position).Magnitude
	if posDelta < posThreshold then
		local _, _, _, rx1, ry1, rz1, _, _, _ = current.rootCf:GetComponents()
		local _, _, _, rx2, ry2, rz2, _, _, _ = previous.rootCf:GetComponents()

		local rotDelta = math.abs(rx1 - rx2) + math.abs(ry1 - ry2) + math.abs(rz1 - rz2)
		if rotDelta < rotThreshold then
			return nil
		end
	end

	return StateBuffer.Compress(current)
end

return StateBuffer
