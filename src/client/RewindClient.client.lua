local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Rewind = require(ReplicatedStorage:WaitForChild("Rewind"))

local Iris = require(ReplicatedStorage.DevPackages.iris).Init()
local IrisPanel = require(ReplicatedStorage.Rewind.Debug.IrisPanel)

Rewind.ClockSync.StartClient({
	syncInterval = 2.0,
	burstSamples = 5,
	alpha = 0.12,
	useBestRtt = true,
})

local panel = IrisPanel.new(Iris)
panel:Start()

Rewind.Client.EnableDebugUI(Rewind)