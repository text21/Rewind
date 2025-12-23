--!strict
local Config = {}

-- Version info
Config.Version = "1.2.0"
Config.VersionName = "Anti-Cheat & Vehicles"

Config.Defaults = {
	enabled = true,

	snapshotHz = 30,
	windowMs = 750,
	maxRewindMs = 500,

	maxRayDistance = 1000,
	allowHeadshots = true,

	teamCheck = true,
	friendlyFire = false,

	antiSpam = {
		perSecond = 30,
		burst = 60,
	},

	mode = "Analytic", -- "Analytic" | "GhostParts"

	debug = {
		enabled = false,
	},
}

return Config
