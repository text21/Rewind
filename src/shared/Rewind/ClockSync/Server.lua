--!strict
local Remotes = require(script.Parent.Remotes)

local Server = {}
Server.__index = Server

local function serverNow(): number
	local ok, t = pcall(function()
		return workspace:GetServerTimeNow()
	end)
	if ok then return t end
	return os.clock()
end

function Server.new()
	return setmetatable({
		started = false,
	}, Server)
end

function Server:Start()
	if self.started then return end
	self.started = true

	Remotes.Ensure()
	local rf = Remotes.ClockSync()

	rf.OnServerInvoke = function(_player, clientSendTime: number)
		local t1 = serverNow()
		local t2 = serverNow()
		return t1, t2, clientSendTime
	end
end

return Server
