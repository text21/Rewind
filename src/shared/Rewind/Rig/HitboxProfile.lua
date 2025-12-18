--!strict
--[[
	HitboxProfile - Defines which parts to track for hit detection.

	Built-in profiles:
	- R15_Default: All 16 standard R15 body parts
	- R6_Default: All 7 standard R6 body parts

	Custom profiles can be defined via HitboxProfile.Define() or Rewind.DefineHitboxProfile()
]]

local HitboxProfile = {}

export type Profile = {
	id: string,
	parts: { string },
	-- Optional per-part forgiveness (extra hitbox expansion per part)
	forgiveness: { [string]: number }?,
	-- Optional description for documentation
	description: string?,
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

return HitboxProfile
