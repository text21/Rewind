--!strict
local RateLimiter = {}
RateLimiter.__index = RateLimiter

export type RateLimiter = {
	rate: number,
	burst: number,
	tokens: number,
	last: number,
	Allow: (self: RateLimiter, now: number, cost: number?) -> boolean,
}

function RateLimiter.new(rate: number, burst: number): RateLimiter
	return setmetatable({
		rate = rate,
		burst = burst,
		tokens = burst,
		last = 0,
	}, RateLimiter)
end

function RateLimiter:Allow(now: number, cost: number?)
	cost = cost or 1

	local dt = now - self.last
	if dt > 0 then
		self.tokens = math.min(self.burst, self.tokens + dt * self.rate)
		self.last = now
	end

	if self.tokens >= cost then
		self.tokens -= cost
		return true
	end

	return false
end

return RateLimiter
