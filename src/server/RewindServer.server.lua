local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Rewind = require(ReplicatedStorage:WaitForChild("Rewind"))

local rig = Workspace:WaitForChild("Rig")

Rewind.ClockSync.StartServer()

Rewind.DefineHitboxProfile("R6", {
	parts = {
		"HumanoidRootPart",
		"Torso",
		"Head",
		"Left Arm",
		"Right Arm",
		"Left Leg",
		"Right Leg",
	},
})

Rewind.Start({
	snapshotHz = 30,
	windowMs = 750,
	maxRewindMs = 500,
	debug = { enabled = true },
	mode = "GhostParts",
})

Rewind.RegisterNPC(rig, "R6")

Rewind.DefineWeapon({
	id = "Fist",
	maxDistance = 10,
	maxRewindMs = 250,
	extraForgivenessStuds = 0.5,
})

print("Registered NPC rig for Rewind:", rig)
