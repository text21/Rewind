--!strict
local RigAdapter = {}

--[[
	Detects if a character is using an R15 rig.
	Checks multiple indicators for robustness:
	1. Humanoid.RigType (most reliable if Humanoid exists)
	2. Presence of R15-specific parts (UpperTorso, LowerTorso)
	3. Absence of R6-specific part (Torso)
]]
function RigAdapter.IsR15(character: Model): boolean
	if not character then return false end

	-- Try Humanoid.RigType first (most reliable)
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		local ok, rigType = pcall(function()
			return humanoid.RigType
		end)
		if ok and rigType then
			return rigType == Enum.HumanoidRigType.R15
		end
	end

	-- Fallback: check for R15-specific parts
	local hasUpperTorso = character:FindFirstChild("UpperTorso") ~= nil
	local hasLowerTorso = character:FindFirstChild("LowerTorso") ~= nil
	if hasUpperTorso or hasLowerTorso then
		return true
	end

	-- Check for R6 Torso (if present, it's R6)
	local hasTorso = character:FindFirstChild("Torso") ~= nil
	if hasTorso then
		return false
	end

	-- Default to R15 if we can't determine
	return true
end

--[[
	Resolves the appropriate hitbox profile ID for a character.
	Returns "R15_Default" or "R6_Default" based on rig detection.
]]
function RigAdapter.ResolveProfileId(character: Model): string
	if not character then return "R15_Default" end
	return RigAdapter.IsR15(character) and "R15_Default" or "R6_Default"
end

--[[
	Collects BasePart references from a character model.
	Gracefully skips missing parts (no error) and logs if debug mode.
	@param character The character model
	@param partNames Array of part names to collect
	@return Dictionary mapping found part names to BasePart references
]]
function RigAdapter.CollectParts(character: Model, partNames: { string }): { [string]: BasePart }
	local out = {}
	if not character or not partNames then return out end

	for _, name in ipairs(partNames) do
		local inst = character:FindFirstChild(name)
		if inst and inst:IsA("BasePart") then
			out[name] = inst
		-- else: gracefully skip missing parts
		end
	end
	return out
end

--[[
	Applies scale multiplier to part sizes (for scaled avatar support).
	@param parts Dictionary of part snapshots
	@param scale The scale multiplier (1.0 = no change)
	@return Scaled parts dictionary
]]
function RigAdapter.ApplyScale(parts: { [string]: { cf: CFrame, size: Vector3 } }, scale: number): { [string]: { cf: CFrame, size: Vector3 } }
	if not scale or scale == 1 then return parts end

	local scaled = {}
	for name, snap in pairs(parts) do
		scaled[name] = {
			cf = snap.cf,
			size = snap.size * scale,
		}
	end
	return scaled
end

return RigAdapter
