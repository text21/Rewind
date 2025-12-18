--!strict
local RingBuffer = require(script.Parent.Parent.Util.RingBuffer)

export type PartSnap = {
	cf: CFrame,
	size: Vector3,
}

export type Snapshot = {
	t: number,
	parts: { [string]: PartSnap },
}

export type TargetStore = {
	buf: any,
	windowSec: number,
}

local SnapshotStore = {}
SnapshotStore.__index = SnapshotStore

function SnapshotStore.new(windowMs: number, snapshotHz: number)
	local windowSec = windowMs / 1000
	local cap = math.max(4, math.floor(windowSec * snapshotHz) + 4)
	return setmetatable({
		buf = RingBuffer.new(cap),
		windowSec = windowSec,
	}, SnapshotStore)
end

function SnapshotStore:Push(s: Snapshot)
	self.buf:Push(s)
	-- ring buffer cap handles memory, but we also keep time window “soft”
	-- (interpolator will clamp)
end

function SnapshotStore:Len()
	return self.buf:Len()
end

function SnapshotStore:At(i: number)
	return self.buf:At(i)
end

function SnapshotStore:First()
	return self.buf:First()
end

function SnapshotStore:Last()
	return self.buf:Last()
end

return SnapshotStore
