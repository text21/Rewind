--!strict
local RunService = game:GetService("RunService")
local Remotes = require(script.Parent.Remotes)

local Client = {}
Client.__index = Client

type Options = {
	syncInterval: number?,
	burstSamples: number?,
	alpha: number?,
	useBestRtt: boolean?,
	minGoodSamples: number?,
}

local function localNow(): number
	local ok, t = pcall(function()
		return os.clock()
	end)
	if ok then return t end
	return tick()
end

function Client.new(opts: Options?)
	opts = opts or {}

	return setmetatable({
		started = false,

		syncInterval = opts.syncInterval or 2.0,
		burstSamples = opts.burstSamples or 5,
		alpha = opts.alpha or 0.12,
		useBestRtt = if opts.useBestRtt == nil then true else opts.useBestRtt,
		minGoodSamples = opts.minGoodSamples or 2,

		offset = 0.0,
		rtt = 0.0,
		hasLock = false,

		_seq = 0,
	}, Client)
end

function Client:GetOffset(): number
	return self.offset
end

function Client:GetRTT(): number
	return self.rtt
end

function Client:HasLock(): boolean
	return self.hasLock
end

function Client:Now(): number
	-- estimated server time
	return localNow() + self.offset
end

function Client:_applySample(sampleOffset: number, sampleRtt: number)
	if not self.hasLock then
		self.offset = sampleOffset
		self.rtt = sampleRtt
		self.hasLock = true
		return
	end

	local a = self.alpha
	self.offset = self.offset + (sampleOffset - self.offset) * a
	self.rtt = self.rtt + (sampleRtt - self.rtt) * a
end

function Client:SyncOnce(): (boolean, number?, number?)
	Remotes.Ensure()
	local rf = Remotes.ClockSync()

	local t0 = localNow()
	local t1, t2, echoT0 = rf:InvokeServer(t0)
	local t3 = localNow()

	if type(t1) ~= "number" or type(t2) ~= "number" or type(echoT0) ~= "number" then
		return false
	end

	-- round trip
	local rtt = (t3 - t0) - (t2 - t1)
	if rtt < 0 then rtt = (t3 - t0) end

	-- NTP offset estimate: server receive - midpoint of client times
	local midpoint = (t0 + t3) * 0.5
	local offset = t1 - midpoint

	return true, offset, rtt
end

function Client:SyncBurst()
	local bestOffset = nil :: number?
	local bestRtt = math.huge
	local good = 0

	for _ = 1, self.burstSamples do
		local ok, o, r = self:SyncOnce()
		if ok and o and r then
			good += 1
			if self.useBestRtt then
				if r < bestRtt then
					bestRtt = r
					bestOffset = o
				end
			else
				-- average-ish: just push through EMA
				self:_applySample(o, r)
			end
		end
		task.wait()
	end

	if self.useBestRtt then
		if bestOffset and good >= self.minGoodSamples then
			self:_applySample(bestOffset, bestRtt)
		end
	end
end

function Client:Start()
	if self.started then return end
	self.started = true

	if RunService:IsServer() then return end

	task.spawn(function()
		while self.started do
			self:SyncBurst()
			task.wait(self.syncInterval)
		end
	end)
end

function Client:Stop()
	self.started = false
end

return Client
