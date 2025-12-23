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

local VehicleAdapter = require(script.Rig.VehicleAdapter)
local ArmorSystem = nil
local AbuseTracker = nil
local MovementValidator = nil

if RunService:IsServer() then
	ArmorSystem = require(script.Server.ArmorSystem)
	AbuseTracker = require(script.Server.AbuseTracker)
	MovementValidator = require(script.Server.MovementValidator)
end

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

Rewind.VehicleAdapter = VehicleAdapter
Rewind.ArmorSystem = ArmorSystem
Rewind.AbuseTracker = AbuseTracker
Rewind.MovementValidator = MovementValidator

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

--[[
	Register a vehicle for hit validation.
	Vehicles can have their own hitboxes and optionally protect passengers.

	@param model The vehicle model
	@param config VehicleConfig options
	@return VehicleInfo
]]
function Rewind.RegisterVehicle(model: Model, config: Types.VehicleConfig?)
	return VehicleAdapter.RegisterVehicle(model, config)
end

--[[
	Unregister a vehicle.

	@param model The vehicle model
]]
function Rewind.UnregisterVehicle(model: Model)
	VehicleAdapter.UnregisterVehicle(model)
end

--[[
	Register a mount (creature player rides).

	@param model The mount model
	@param config MountConfig options
	@return MountInfo
]]
function Rewind.RegisterMount(model: Model, config: Types.MountConfig?)
	return VehicleAdapter.RegisterMount(model, config)
end

--[[
	Add a passenger to a vehicle.

	@param player The player
	@param vehicle The vehicle model
]]
function Rewind.AddPassengerToVehicle(player: Player, vehicle: Model)
	VehicleAdapter.AddPassenger(player, vehicle)
end

--[[
	Remove a passenger from their vehicle.

	@param player The player
]]
function Rewind.RemovePassengerFromVehicle(player: Player)
	VehicleAdapter.RemovePassenger(player)
end

--[[
	Set a rider on a mount.

	@param player The player
	@param mount The mount model
]]
function Rewind.SetMountRider(player: Player, mount: Model)
	VehicleAdapter.SetRider(player, mount)
end

--[[
	Get the vehicle a player is in.

	@param player The player
	@return VehicleInfo or nil
]]
function Rewind.GetPlayerVehicle(player: Player)
	return VehicleAdapter.GetPlayerVehicle(player)
end

--[[
	Define armor layers for an entity.

	@param model The entity model
	@param config ArmorConfig
	@param entityId Optional entity ID
	@return ArmorState
]]
function Rewind.DefineArmor(model: Model, config: Types.ArmorConfig, entityId: string?)
	if not ArmorSystem then return nil end
	return ArmorSystem.DefineArmor(model, config, entityId)
end

--[[
	Remove armor from an entity.

	@param model The entity model
]]
function Rewind.RemoveArmor(model: Model)
	if not ArmorSystem then return end
	ArmorSystem.RemoveArmor(model)
end

--[[
	Get armor state for an entity.

	@param model The entity model
	@return ArmorState or nil
]]
function Rewind.GetArmor(model: Model)
	if not ArmorSystem then return nil end
	return ArmorSystem.GetArmor(model)
end

--[[
	Apply damage to an entity with armor calculation.

	@param model The entity model
	@param partName The body part hit
	@param rawDamage The incoming damage
	@return DamageResult or nil
]]
function Rewind.ApplyDamageWithArmor(model: Model, partName: string, rawDamage: number)
	if not ArmorSystem then return nil end
	return ArmorSystem.ApplyDamage(model, partName, rawDamage)
end

--[[
	Repair armor for an entity.

	@param model The entity model
	@param layerName Optional specific layer to repair
	@param amount Amount to repair (nil = full repair)
]]
function Rewind.RepairArmor(model: Model, layerName: string?, amount: number?)
	if not ArmorSystem then return end
	ArmorSystem.RepairArmor(model, layerName, amount)
end

--[[
	Start the abuse tracking system with optional DataStore persistence.

	@param config AbuseConfig options
]]
function Rewind.StartAbuseTracking(config: Types.AbuseConfig?)
	if not AbuseTracker then return end
	AbuseTracker.Start(config)
end

--[[
	Record an abuse event for a player.

	@param player The player
	@param reason The abuse reason
	@param metadata Optional additional data
]]
function Rewind.RecordAbuse(player: Player, reason: Types.AbuseReason, metadata: { [string]: any }?)
	if not AbuseTracker then return end
	AbuseTracker.RecordAbuse(player, reason, metadata)
end

--[[
	Get abuse history for a player.

	@param player The player
	@return PlayerAbuseHistory or nil
]]
function Rewind.GetAbuseHistory(player: Player)
	if not AbuseTracker then return nil end
	return AbuseTracker.GetHistory(player)
end

--[[
	Check if a player is banned.

	@param userId The player's UserId
	@return boolean
]]
function Rewind.IsPlayerBanned(userId: number): boolean
	if not AbuseTracker then return false end
	return AbuseTracker.IsBanned(userId)
end

--[[
	Ban a player (persists to DataStore if enabled).

	@param userId The player's UserId
	@param reason Ban reason
]]
function Rewind.BanPlayer(userId: number, reason: string?)
	if not AbuseTracker then return end
	AbuseTracker.Ban(userId, reason)
end

--[[
	Unban a player.

	@param userId The player's UserId
]]
function Rewind.UnbanPlayer(userId: number)
	if not AbuseTracker then return end
	AbuseTracker.Unban(userId)
end

-- Expose abuse events
if AbuseTracker then
	Rewind.OnAbuseDetected = AbuseTracker.OnAbuseDetected
	Rewind.OnAbuseThresholdReached = AbuseTracker.OnThresholdReached
end

--[[
	Configure movement validation settings.

	@param config MovementConfig options
]]
function Rewind.ConfigureMovementValidation(config: Types.MovementConfig?)
	if not MovementValidator then return end
	MovementValidator.Configure(config)
end

--[[
	Start automatic movement monitoring for all players.
]]
function Rewind.StartMovementMonitoring()
	if not MovementValidator then return end
	MovementValidator.StartMonitoring()
end

--[[
	Stop movement monitoring.
]]
function Rewind.StopMovementMonitoring()
	if not MovementValidator then return end
	MovementValidator.StopMonitoring()
end

--[[
	Validate a single movement.

	@param player The player
	@param fromPos Starting position
	@param toPos Ending position
	@param deltaTime Time between positions
	@return MovementValidationResult
]]
function Rewind.ValidateMovement(player: Player, fromPos: Vector3, toPos: Vector3, deltaTime: number)
	if not MovementValidator then
		return { valid = true, anomaly = nil, details = nil }
	end
	return MovementValidator.ValidateMovement(player, fromPos, toPos, deltaTime)
end

--[[
	Set speed multiplier for a player (for vehicles, speed boosts).

	@param player The player
	@param multiplier Speed multiplier (1 = normal)
]]
function Rewind.SetPlayerSpeedMultiplier(player: Player, multiplier: number)
	if not MovementValidator then return end
	MovementValidator.SetSpeedMultiplier(player, multiplier)
end

--[[
	Get movement violations for a player.

	@param player The player
	@return Violation counts or nil
]]
function Rewind.GetMovementViolations(player: Player)
	if not MovementValidator then return nil end
	return MovementValidator.GetViolations(player)
end

--[[
	Clear movement violations for a player.

	@param player The player
]]
function Rewind.ClearMovementViolations(player: Player)
	if not MovementValidator then return end
	MovementValidator.ClearViolations(player)
end

if MovementValidator then
	Rewind.OnMovementAnomaly = MovementValidator.OnAnomalyDetected
end

return Rewind
