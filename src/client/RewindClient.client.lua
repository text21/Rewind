--!strict
--[[
	Rewind Client - v1.1.0
	Handles clock sync and debug UI for lag compensation.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Rewind = require(ReplicatedStorage:WaitForChild("Rewind"))

print("🎮 Rewind Client v" .. Rewind.Version .. " - " .. Rewind.VersionName)

Rewind.ClockSync.StartClient({
	syncInterval = 2.0,
	burstSamples = 5,
	alpha = 0.12,
	useBestRtt = true,
})

Rewind.StartReplicationClient({
	enabled = true,
	interpolationDelay = 100,
	maxExtrapolation = 200,
})

local success, Iris = pcall(function()
	return require(ReplicatedStorage.DevPackages.iris).Init()
end)

if success and Iris then
	local IrisPanel = require(ReplicatedStorage.Rewind.Debug.IrisPanel)
	local panel = IrisPanel.new(Iris)
	panel:Start()
end

Rewind.Client.EnableDebugUI(Rewind)

print("✅ Rewind Client ready")