--!strict
local RingBuffer = {}
RingBuffer.__index = RingBuffer

export type RingBuffer<T> = {
	_cap: number,
	_len: number,
	_head: number,
	_data: { T? },

	Push: (self: RingBuffer<T>, v: T) -> (),
	Len: (self: RingBuffer<T>) -> number,
	At: (self: RingBuffer<T>, i: number) -> T?,
	First: (self: RingBuffer<T>) -> T?,
	Last: (self: RingBuffer<T>) -> T?,
	Clear: (self: RingBuffer<T>) -> (),
}

function RingBuffer.new<T>(cap: number): RingBuffer<T>
	assert(cap > 0, "cap must be > 0")
	return setmetatable({
		_cap = cap,
		_len = 0,
		_head = 1,
		_data = table.create(cap),
	}, RingBuffer) :: any
end

function RingBuffer:Push(v)
	local cap = self._cap
	local idx = ((self._head + self._len - 1) % cap) + 1
	self._data[idx] = v

	if self._len < cap then
		self._len += 1
	else
		self._head = (self._head % cap) + 1
	end
end

function RingBuffer:Len()
	return self._len
end

function RingBuffer:At(i: number)
	if i < 1 or i > self._len then return nil end
	local cap = self._cap
	local idx = ((self._head + i - 2) % cap) + 1
	return self._data[idx]
end

function RingBuffer:First()
	return self:At(1)
end

function RingBuffer:Last()
	return self:At(self._len)
end

function RingBuffer:Clear()
	self._len = 0
	self._head = 1
	table.clear(self._data)
end

return RingBuffer
