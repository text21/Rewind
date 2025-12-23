--!strict
--[[
	HitboxProfile - Defines which parts to track for hit detection.

	Built-in profiles:
	- R15_Default: All 16 standard R15 body parts
	- R6_Default: All 7 standard R6 body parts

	Custom profiles can be defined via HitboxProfile.Define() or Rewind.DefineHitboxProfile()

	v1.1.0: Added hit priority support for configurable per-part hit preference
]]

local HitboxProfile = {}

export type HitPriority = {
	priority: number,
	damageMultiplier: number?,
}

export type Profile = {
	id: string,
	parts: { string },
	forgiveness: { [string]: number }?,
	hitPriority: { [string]: HitPriority }?,
	description: string?,
}

local DEFAULT_HIT_PRIORITY: { [string]: HitPriority } = {
	Head = { priority = 10, damageMultiplier = 2.0 },

	UpperTorso = { priority = 5, damageMultiplier = 1.0 },
	LowerTorso = { priority = 5, damageMultiplier = 1.0 },
	Torso = { priority = 5, damageMultiplier = 1.0 }, -- R6

	LeftUpperArm = { priority = 2, damageMultiplier = 0.8 },
	LeftLowerArm = { priority = 2, damageMultiplier = 0.8 },
	LeftHand = { priority = 1, damageMultiplier = 0.7 },
	RightUpperArm = { priority = 2, damageMultiplier = 0.8 },
	RightLowerArm = { priority = 2, damageMultiplier = 0.8 },
	RightHand = { priority = 1, damageMultiplier = 0.7 },
	["Left Arm"] = { priority = 2, damageMultiplier = 0.8 }, -- R6
	["Right Arm"] = { priority = 2, damageMultiplier = 0.8 }, -- R6

	LeftUpperLeg = { priority = 2, damageMultiplier = 0.8 },
	LeftLowerLeg = { priority = 2, damageMultiplier = 0.8 },
	LeftFoot = { priority = 1, damageMultiplier = 0.7 },
	RightUpperLeg = { priority = 2, damageMultiplier = 0.8 },
	RightLowerLeg = { priority = 2, damageMultiplier = 0.8 },
	RightFoot = { priority = 1, damageMultiplier = 0.7 },
	["Left Leg"] = { priority = 2, damageMultiplier = 0.8 }, -- R6
	["Right Leg"] = { priority = 2, damageMultiplier = 0.8 }, -- R6

	HumanoidRootPart = { priority = 0, damageMultiplier = 1.0 },
}

local profiles: { [string]: Profile } = {}

local function def(p: Profile)
	profiles[p.id] = p
end

-- Built-in R15 profile with all standard parts
def({
	id = "R15_Default",
	description = "Standard R15 rig with all 16 body parts",
	parts = {
		"Head",
		"UpperTorso",
		"LowerTorso",
		"HumanoidRootPart",
		"LeftUpperArm",
		"LeftLowerArm",
		"LeftHand",
		"RightUpperArm",
		"RightLowerArm",
		"RightHand",
		"LeftUpperLeg",
		"LeftLowerLeg",
		"LeftFoot",
		"RightUpperLeg",
		"RightLowerLeg",
		"RightFoot",
	},
})

-- Built-in R6 profile with all standard parts
def({
	id = "R6_Default",
	description = "Standard R6 rig with all 7 body parts",
	parts = {
		"Head",
		"Torso",
		"HumanoidRootPart",
		"Left Arm",
		"Right Arm",
		"Left Leg",
		"Right Leg",
	},
})

--[[
	Define a custom hitbox profile.
	@param id Unique identifier for this profile
	@param profile Profile definition with parts list
]]
function HitboxProfile.Define(id: string, profile: Profile)
	profile.id = id
	profiles[id] = profile
end

--[[
	Get a hitbox profile by ID.
	@param id Profile identifier
	@return Profile or nil if not found
]]
function HitboxProfile.Get(id: string): Profile?
	return profiles[id]
end

--[[
	Get all registered profile IDs.
	@return Array of profile IDs
]]
function HitboxProfile.GetAllIds(): { string }
	local ids = {}
	for id in pairs(profiles) do
		table.insert(ids, id)
	end
	return ids
end

--[[
	Check if a profile exists.
	@param id Profile identifier
	@return true if profile exists
]]
function HitboxProfile.Exists(id: string): boolean
	return profiles[id] ~= nil
end

--[[
	v1.1.0: Get hit priority for a body part.
	Returns the priority and damage multiplier for hit selection.

	@param profileId Profile identifier (optional, uses defaults if nil)
	@param partName The body part name
	@return HitPriority or default values
]]
function HitboxProfile.GetHitPriority(profileId: string?, partName: string): HitPriority
	if profileId then
		local profile = profiles[profileId]
		if profile and profile.hitPriority and profile.hitPriority[partName] then
			return profile.hitPriority[partName]
		end
	end

	local default = DEFAULT_HIT_PRIORITY[partName]
	if default then
		return default
	end

	return { priority = 1, damageMultiplier = 1.0 }
end

--[[
	v1.1.0: Get all default hit priorities.
	Useful for customization.

	@return Table of default priorities
]]
function HitboxProfile.GetDefaultPriorities(): { [string]: HitPriority }
	return DEFAULT_HIT_PRIORITY
end

--[[
	v1.1.0: Compare two parts by hit priority.
	Returns the part with higher priority.

	@param profileId Profile identifier
	@param partA First part name
	@param partB Second part name
	@return The part name with higher priority
]]
function HitboxProfile.CompareByPriority(profileId: string?, partA: string, partB: string): string
	local prioA = HitboxProfile.GetHitPriority(profileId, partA)
	local prioB = HitboxProfile.GetHitPriority(profileId, partB)

	if prioA.priority >= prioB.priority then
		return partA
	end
	return partB
end

return HitboxProfile
