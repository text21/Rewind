--!strict
--[[
	ClockSync - Client-server time synchronization for lag compensation.

	All methods are safe to call before lock is acquired - they return sensible defaults.
]]
local RunService = game:GetService("RunService")

local ClockSync = {}

local ServerMod = require(script.Server)
local ClientMod = require(script.Client)

local _server = nil
local _client = nil

--[[
	Start the clock sync server (call from server only).
]]
function ClockSync.StartServer()
	if not RunService:IsServer() then return end
	if _server then return end
	local ok, err = pcall(function()
		_server = ServerMod.new()
		_server:Start()
	end)
	if not ok then
		warn("[ClockSync] Failed to start server:", err)
	end
end

--[[
	Start the clock sync client (call from client only).
	@param opts Optional configuration { syncInterval, burstSamples, alpha, useBestRtt, minGoodSamples }
]]
function ClockSync.StartClient(opts)
	if RunService:IsServer() then return end
	if _client then return end
	local ok, err = pcall(function()
		_client = ClientMod.new(opts)
		_client:Start()
	end)
	if not ok then
		warn("[ClockSync] Failed to start client:", err)
	end
end

--[[
	Get the estimated server time from the client.
	Safe to call before lock - returns os.clock() as fallback.
	@return Estimated server time
]]
function ClockSync.ClientNow(): number
	if _client then
		local ok, result = pcall(function()
			return _client:Now()
		end)
		if ok and result then
			return result
		end
	end
	-- Fallback: return local time
	return os.clock()
end

--[[
	Check if the client has acquired a clock lock.
	Safe to call anytime - returns false if not initialized.
	@return true if locked
]]
function ClockSync.HasLock(): boolean
	if not _client then return false end
	local ok, result = pcall(function()
		return _client:HasLock()
	end)
	if ok then
		return result == true
	end
	return false
end

--[[
	Get the current clock offset (client to server).
	Safe to call anytime - returns 0 if not initialized.
	@return Offset in seconds
]]
function ClockSync.GetOffset(): number
	if not _client then return 0 end
	local ok, result = pcall(function()
		return _client:GetOffset()
	end)
	if ok and type(result) == "number" then
		return result
	end
	return 0
end

--[[
	Get the current round-trip time estimate.
	Safe to call anytime - returns 0 if not initialized.
	@return RTT in seconds
]]
function ClockSync.GetRTT(): number
	if not _client then return 0 end
	local ok, result = pcall(function()
		return _client:GetRTT()
	end)
	if ok and type(result) == "number" then
		return result
	end
	return 0
end

--[[
	Stop the clock sync (client or server).
]]
function ClockSync.Stop()
	if _client then
		pcall(function()
			_client:Stop()
		end)
		_client = nil
	end
	if _server then
		_server = nil
	end
end

return ClockSync
