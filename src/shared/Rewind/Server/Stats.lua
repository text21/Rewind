--!strict
local Stats = {}
Stats.__index = Stats

function Stats.new()
	return setmetatable({
		startedAt = os.clock(),
		validations = 0,
		hits = 0,
		rejects = 0,
		reasons = {},
	}, Stats)
end

function Stats:Inc(name: string, reason: string?)
	self[name] = (self[name] or 0) + 1
	if reason then
		self.reasons[reason] = (self.reasons[reason] or 0) + 1
	end
end

function Stats:Snapshot()
	return {
		uptime = os.clock() - self.startedAt,
		validations = self.validations,
		hits = self.hits,
		rejects = self.rejects,
		reasons = self.reasons,
	}
end

return Stats
