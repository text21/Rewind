--!strict
--[[
	Rewind - Lag Compensation Framework for Roblox

	Server-side hit validation with rewound snapshots for fair hit detection.

	Quick Start:
		-- Server
		Rewind.Start({ snapshotHz = 30, windowMs = 750 })
		Rewind.ClockSync.StartServer()

		-- Client
		Rewind.ClockSync.StartClient()

		-- Validate a hit
		local result = Rewind.ValidateRay(player, { origin = pos, direction = dir })
		if result.hit then
			-- Handle hit
		end

	High-level API:
		Rewind.Validate(player, "Ray", params) -- Unified dispatcher
		Rewind.ValidateRay / ValidateSphere / ValidateCapsule / ValidateCone / ValidateFan
]]

local RunService = game:GetService("RunService")

local Types = require(script.Types)
local Config = require(script.Config)
local HitboxProfile = require(script.Rig.HitboxProfile)
local RigAdapter = require(script.Rig.RigAdapter)

local Rewind = {}
Rewind.__index = Rewind

local _server = nil

Rewind.Version = Config.Version
Rewind.VersionName = Config.VersionName

Rewind.Client = require(script.Client.Client)
Rewind.ClockSync = require(script.ClockSync)
Rewind.HitboxProfile = HitboxProfile
Rewind.RigAdapter = RigAdapter
Rewind.Types = Types
Rewind.Config = Config

Rewind.Replication = require(script.Replication)

local Validator = nil
if RunService:IsServer() then
	Validator = require(script.Server.Validator)
end
Rewind.Validator = Validator

function Rewind.Start(opts: Types.Options?)
	if RunService:IsServer() then
		if not _server then
			_server = require(script.Server.Server).new()
		end
		_server:Start(opts)
		return
	end
end

function Rewind.Stop()
	if _server then _server:Stop() end
end

function Rewind.GetOptions()
	if _server then return _server:GetOptions() end
	return Config.Defaults
end

function Rewind.Configure(opts: Types.Options)
	if _server then _server:Configure(opts) end
end

function Rewind.DefineHitboxProfile(id: string, def)
	HitboxProfile.Define(id, def)
end

function Rewind.RegisterCharacter(character: Model, profileId: string?)
	if _server then _server:RegisterCharacter(character, profileId) end
end

function Rewind.UnregisterCharacter(character: Model)
	if _server then _server:UnregisterCharacter(character) end
end

function Rewind.RegisterNPC(model: Model, profileId: string?)
	if _server then _server:RegisterCharacter(model, profileId) end
end

function Rewind.DefineWeapon(profile: Types.WeaponProfile)
	if _server then _server:DefineWeapon(profile) end
end

function Rewind.GetWeapon(id: string)
	if _server then return _server:GetWeapon(id) end
	return nil
end

function Rewind.ValidateRay(player: Player, params: Types.ValidateRayParams): Types.HitResult
	if not _server then
		return {
			hit = false,
			serverNow = 0,
			rewindTo = 0,
			usedRewindMs = 0,
			reason = "not_server",
		} :: any
	end
	return _server:ValidateRay(player, params)
end

function Rewind.ServerNow(): number
	if _server then return _server:ServerNow() end
	return 0
end

function Rewind.EstimateRewindTime(player: Player, clientTime: number?): number
	if _server then return _server:EstimateRewindTime(player, clientTime) end
	return 0
end

function Rewind.GetStats()
	if _server then return _server:GetStats() end
	return {}
end

function Rewind.StartClockSyncServer()
	Rewind.ClockSync.StartServer()
end

function Rewind.StartClockSyncClient(opts)
	Rewind.ClockSync.StartClient(opts)
end

function Rewind.ValidateCapsule(player: Player, params: Types.ValidateCapsuleParams): Types.HitResult
	if not _server then
		return {
			hit = false,
			serverNow = 0,
			rewindTo = 0,
			usedRewindMs = 0,
			reason = "not_server",
		} :: any
	end
	return _server:ValidateCapsule(player, params)
end

function Rewind.ValidateSphere(player: Player, params: Types.ValidateSphereParams): Types.HitResult
	if not _server then
		return {
			hit = false,
			serverNow = 0,
			rewindTo = 0,
			usedRewindMs = 0,
			reason = "not_server",
		} :: any
	end
	return _server:ValidateSphere(player, params)
end

function Rewind.ValidateMeleeArc(player: Player, params: Types.ValidateMeleeArcParams): Types.HitResult
	if not _server then
		return {
			hit = false,
			serverNow = 0,
			rewindTo = 0,
			usedRewindMs = 0,
			reason = "not_server",
		} :: any
	end
	return _server:ValidateMeleeArc(player, params)
end

function Rewind.ValidateMeleeFan(player: Player, params: Types.ValidateMeleeFanParams): Types.HitResult
	if not _server then
		return {
			hit = false,
			serverNow = 0,
			rewindTo = 0,
			usedRewindMs = 0,
			reason = "not_server",
		} :: any
	end
	return _server:ValidateMeleeFan(player, params)
end

-- Aliases for consistency
Rewind.ValidateCone = Rewind.ValidateMeleeArc
Rewind.ValidateFan = Rewind.ValidateMeleeFan

--[[
	High-level unified validation dispatcher.

	@param player The player making the validation request
	@param mode "Ray" | "Sphere" | "Capsule" | "Cone" | "Fan"
	@param params Validation parameters (varies by mode)
	@return HitResult

	Example:
		Rewind.Validate(player, "Ray", { origin = pos, direction = dir })
		Rewind.Validate(player, "Capsule", { a = pos1, b = pos2, radius = 1 })
]]
function Rewind.Validate(player: Player, mode: Types.ValidationMode, params: any): Types.HitResult
	if mode == "Ray" then
		return Rewind.ValidateRay(player, params)
	elseif mode == "Sphere" then
		return Rewind.ValidateSphere(player, params)
	elseif mode == "Capsule" then
		return Rewind.ValidateCapsule(player, params)
	elseif mode == "Cone" then
		return Rewind.ValidateMeleeArc(player, params)
	elseif mode == "Fan" then
		return Rewind.ValidateMeleeFan(player, params)
	else
		return {
			hit = false,
			serverNow = 0,
			rewindTo = 0,
			usedRewindMs = 0,
			reason = "invalid_params",
		} :: any
	end
end

--[[
	Create params from a weapon profile.
	Useful for tools that don't want to hardcode numbers.

	@param weaponId The weapon ID
	@param baseParams Base parameters to merge with weapon tuning
	@return Merged params suitable for validation
]]
function Rewind.CreateParamsFromWeapon(weaponId: string, baseParams: any): any
	local weapon = Rewind.GetWeapon(weaponId)
	if not weapon then
		return baseParams
	end

	local merged = table.clone(baseParams)
	merged.weaponId = weaponId

	-- Apply weapon tuning if not specified in baseParams
	if weapon.meleeRange and not merged.range then
		merged.range = weapon.meleeRange
	end
	if weapon.meleeAngleDeg and not merged.angleDeg then
		merged.angleDeg = weapon.meleeAngleDeg
	end
	if weapon.meleeRays and not merged.rays then
		merged.rays = weapon.meleeRays
	end
	if weapon.capsuleRadius and not merged.radius then
		merged.radius = weapon.capsuleRadius
	end
	if weapon.capsuleSteps and not merged.steps then
		merged.steps = weapon.capsuleSteps
	end

	return merged
end

--[[
	Start the replication system (server-side).
	This enables custom character replication with interpolation and hit validation.

	@param config ReplicationConfig options
]]
function Rewind.StartReplication(config: Types.ReplicationConfig?)
	Rewind.Replication.Start(config)
end

--[[
	Start the client-side interpolation system.

	@param config ReplicationConfig options
]]
function Rewind.StartReplicationClient(config: Types.ReplicationConfig?)
	Rewind.Replication.StartClient(config)
end

--[[
	Register a player for custom replication (server).
	The player's character will be replicated using Rewind's system instead of Roblox's default.

	@param player The player to register
	@param priority Optional priority level (higher = more bandwidth, default 5)
]]
function Rewind.RegisterPlayerForReplication(player: Player, priority: number?)
	Rewind.Replication.RegisterPlayer(player, priority)
end

--[[
	Register an NPC for custom replication (server).

	@param model The NPC model
	@param priority Optional priority level (default 3)
]]
function Rewind.RegisterNPCForReplication(model: Model, priority: number?)
	Rewind.Replication.RegisterNPC(model, priority)
end

--[[
	Unregister an entity from custom replication.

	@param modelOrPlayer The model or player to unregister
]]
function Rewind.UnregisterFromReplication(modelOrPlayer: Model | Player)
	Rewind.Replication.Unregister(modelOrPlayer)
end

return Rewind
