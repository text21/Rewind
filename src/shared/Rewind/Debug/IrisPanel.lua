--!strict
--[[
	IrisPanel - Debug UI for Rewind framework.

	Crash-proof: handles missing remotes, uninitialized ClockSync, etc.
]]
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local IrisPanel = {}
IrisPanel.__index = IrisPanel

-- Safe require that doesn't error
local function safeRequire(path)
	local ok, result = pcall(function()
		return require(path)
	end)
	if ok then
		return result
	end
	return nil
end

-- Safe remote getter that returns nil instead of erroring
local function safeGetRemote(remotesModule, name)
	if not remotesModule then return nil end
	local getter = remotesModule[name]
	if not getter then return nil end

	local ok, remote = pcall(function()
		return getter()
	end)
	if ok then
		return remote
	end
	return nil
end

function IrisPanel.new(Iris)
	return setmetatable({
		Iris = Iris,
		started = false,
		lastEnabled = false,
		lastData = nil,
		_remotesAvailable = false,
	}, IrisPanel)
end

function IrisPanel:Start()
	if self.started then return end
	self.started = true

	-- Safe require Rewind
	local Rewind = safeRequire(ReplicatedStorage:FindFirstChild("Rewind"))
	if not Rewind then
		warn("[IrisPanel] Rewind module not found, panel will have limited functionality")
	end

	-- Get ClockSync safely
	local ClockSync = Rewind and Rewind.ClockSync or nil

	-- Try to get remotes (may not exist if server hasn't started yet)
	local Remotes = safeRequire(ReplicatedStorage:FindFirstChild("Rewind") and ReplicatedStorage.Rewind:FindFirstChild("Net") and ReplicatedStorage.Rewind.Net:FindFirstChild("Remotes"))

	local debugData = Remotes and safeGetRemote(Remotes, "DebugData")
	local debugCmd = Remotes and safeGetRemote(Remotes, "DebugCmd")

	self._remotesAvailable = (debugData ~= nil and debugCmd ~= nil)

	local Iris = self.Iris

	local enabled = Iris.State(false)
	local showPose = Iris.State(true)
	local showRays = Iris.State(true)
	local showCapsules = Iris.State(true)

	self.lastEnabled = enabled:get()

	-- Connect to debug data if available
	if debugData then
		local ok, _ = pcall(function()
			debugData.OnClientEvent:Connect(function(payload)
				self.lastData = payload
			end)
		end)
		if not ok then
			self._remotesAvailable = false
		end
	end

	Iris:Connect(function()
		Iris.Window({ "Rewind Debug" })

		-- ClockSync section (safe even if not initialized)
		Iris.Text({ "ClockSync" })
		do
			local lock = false
			local offsetMs = 0
			local rttMs = 0

			if ClockSync then
				-- These methods are now safe to call anytime
				lock = ClockSync.HasLock()
				offsetMs = ClockSync.GetOffset() * 1000
				rttMs = ClockSync.GetRTT() * 1000
			end

			Iris.Text({ ("Lock: %s"):format(lock and "✅" or "❌") })
			Iris.Text({ ("Offset: %.2f ms"):format(offsetMs) })
			Iris.Text({ ("RTT: %.2f ms"):format(rttMs) })
		end

		Iris.Separator()

		-- Debug toggles section
		do
			if not self._remotesAvailable then
				Iris.Text({ "⚠️ Debug remotes not available" })
				Iris.Text({ "(Server may not have started debug mode)" })
			else
				Iris.Checkbox({ "Enable Server Debug" }, { isChecked = enabled })
				Iris.Checkbox({ "Draw Rewound Pose" }, { isChecked = showPose })
				Iris.Checkbox({ "Draw Rays" }, { isChecked = showRays })
				Iris.Checkbox({ "Draw Capsules" }, { isChecked = showCapsules })

				local nowEnabled = enabled:get()
				if nowEnabled ~= self.lastEnabled then
					self.lastEnabled = nowEnabled
					if debugCmd then
						pcall(function()
							debugCmd:FireServer("set_enabled", nowEnabled)
						end)
					end
				end
			end
		end

		Iris.Separator()

		-- Last validation data
		local d = self.lastData
		if d then
			Iris.Text({ "Last Validation" })
			Iris.Text({ "Reason: " .. tostring(d.reason or "hit") })
			Iris.Text({ "UsedRewindMs: " .. tostring(d.usedRewindMs or 0) })
			if d.targetName then Iris.Text({ "Target: " .. tostring(d.targetName) }) end
			if d.partName then Iris.Text({ "Part: " .. tostring(d.partName) }) end
		else
			Iris.Text({ "No debug packets yet." })
		end

		Iris.End()
	end)
end

return IrisPanel
