--!strict
--[[
	VehicleAdapter - Handles vehicle and mount registration for hit validation

	Vehicles can have their own hitboxes (e.g., tanks, cars) and passengers
	inside can be protected or exposed based on configuration.

	v1.2.0: Initial implementation

	Usage:
		-- Register a vehicle
		Rewind.RegisterVehicle(vehicleModel, {
			hitboxes = {
				Body = { size = Vector3.new(10, 4, 20), offset = Vector3.zero },
				Turret = { size = Vector3.new(3, 2, 3), offset = Vector3.new(0, 3, 2) },
			},
			protectsPassengers = true,
			damageMultiplier = 0.5,
		})

		-- Register a mount (creature the player rides)
		Rewind.RegisterMount(mountModel, {
			hitboxProfile = "Horse", -- Uses standard hitbox profile
			exposeRider = true,      -- Rider can be hit separately
		})
]]

local RunService = game:GetService("RunService")

local Types = require(script.Parent.Parent.Types)
local HitboxProfile = require(script.Parent.HitboxProfile)

local VehicleAdapter = {}

export type VehicleHitbox = {
	size: Vector3,
	offset: Vector3?,
	damageMultiplier: number?,
	isWeakSpot: boolean?,
}

export type VehicleConfig = {
	hitboxes: { [string]: VehicleHitbox }?,
	hitboxProfile: string?,
	protectsPassengers: boolean?,
	damageMultiplier: number?,
	health: number?,
}

export type MountConfig = {
	hitboxProfile: string?,
	exposeRider: boolean?,
	riderOffset: Vector3?,
}

export type VehicleInfo = {
	id: string,
	model: Model,
	config: VehicleConfig,
	passengers: { Player },
	health: number,
	maxHealth: number,
	destroyed: boolean,
}

export type MountInfo = {
	id: string,
	model: Model,
	config: MountConfig,
	rider: Player?,
}

local _vehicles: { [Model]: VehicleInfo } = {}
local _mounts: { [Model]: MountInfo } = {}
local _playerToVehicle: { [Player]: VehicleInfo } = {}
local _playerToMount: { [Player]: MountInfo } = {}
local _nextVehicleId = 1
local _nextMountId = 1

--[[
	Register a vehicle for hit validation

	@param model The vehicle model
	@param config Vehicle configuration
	@return VehicleInfo
]]
function VehicleAdapter.RegisterVehicle(model: Model, config: VehicleConfig?): VehicleInfo
	if _vehicles[model] then
		return _vehicles[model]
	end

	config = config or {}

	local maxHealth = config.health or 1000
	local id = "vehicle_" .. _nextVehicleId
	_nextVehicleId += 1

	local info: VehicleInfo = {
		id = id,
		model = model,
		config = config,
		passengers = {},
		health = maxHealth,
		maxHealth = maxHealth,
		destroyed = false,
	}

	_vehicles[model] = info

	model.Destroying:Connect(function()
		VehicleAdapter.UnregisterVehicle(model)
	end)

	return info
end

--[[
	Unregister a vehicle

	@param model The vehicle model
]]
function VehicleAdapter.UnregisterVehicle(model: Model)
	local info = _vehicles[model]
	if not info then return end

	for _, passenger in ipairs(info.passengers) do
		_playerToVehicle[passenger] = nil
	end

	_vehicles[model] = nil
end

--[[
	Register a mount for hit validation

	@param model The mount model (creature/animal)
	@param config Mount configuration
	@return MountInfo
]]
function VehicleAdapter.RegisterMount(model: Model, config: MountConfig?): MountInfo
	if _mounts[model] then
		return _mounts[model]
	end

	config = config or {}

	local id = "mount_" .. _nextMountId
	_nextMountId += 1

	local info: MountInfo = {
		id = id,
		model = model,
		config = config,
		rider = nil,
	}

	_mounts[model] = info

	model.Destroying:Connect(function()
		VehicleAdapter.UnregisterMount(model)
	end)

	return info
end

--[[
	Unregister a mount

	@param model The mount model
]]
function VehicleAdapter.UnregisterMount(model: Model)
	local info = _mounts[model]
	if not info then return end

	if info.rider then
		_playerToMount[info.rider] = nil
	end

	_mounts[model] = nil
end

--[[
	Add a passenger to a vehicle

	@param player The player entering the vehicle
	@param vehicle The vehicle model
]]
function VehicleAdapter.AddPassenger(player: Player, vehicle: Model)
	local info = _vehicles[vehicle]
	if not info then return end

	VehicleAdapter.RemovePassenger(player)

	table.insert(info.passengers, player)
	_playerToVehicle[player] = info
end

--[[
	Remove a passenger from their vehicle

	@param player The player exiting
]]
function VehicleAdapter.RemovePassenger(player: Player)
	local info = _playerToVehicle[player]
	if not info then return end

	local idx = table.find(info.passengers, player)
	if idx then
		table.remove(info.passengers, idx)
	end

	_playerToVehicle[player] = nil
end

--[[
	Set the rider of a mount

	@param player The player mounting
	@param mount The mount model
]]
function VehicleAdapter.SetRider(player: Player, mount: Model)
	local info = _mounts[mount]
	if not info then return end

	VehicleAdapter.RemoveRider(player)

	info.rider = player
	_playerToMount[player] = info
end

--[[
	Remove a rider from their mount

	@param player The player dismounting
]]
function VehicleAdapter.RemoveRider(player: Player)
	local info = _playerToMount[player]
	if not info then return end

	info.rider = nil
	_playerToMount[player] = nil
end

--[[
	Get the vehicle a player is in

	@param player The player
	@return VehicleInfo or nil
]]
function VehicleAdapter.GetPlayerVehicle(player: Player): VehicleInfo?
	return _playerToVehicle[player]
end

--[[
	Get the mount a player is riding

	@param player The player
	@return MountInfo or nil
]]
function VehicleAdapter.GetPlayerMount(player: Player): MountInfo?
	return _playerToMount[player]
end

--[[
	Check if a player is protected by a vehicle

	@param player The player
	@return Whether the player is protected
]]
function VehicleAdapter.IsPlayerProtected(player: Player): boolean
	local vehicleInfo = _playerToVehicle[player]
	if vehicleInfo and vehicleInfo.config.protectsPassengers then
		return not vehicleInfo.destroyed
	end
	return false
end

--[[
	Get vehicle info by model

	@param model The vehicle model
	@return VehicleInfo or nil
]]
function VehicleAdapter.GetVehicle(model: Model): VehicleInfo?
	return _vehicles[model]
end

--[[
	Get mount info by model

	@param model The mount model
	@return MountInfo or nil
]]
function VehicleAdapter.GetMount(model: Model): MountInfo?
	return _mounts[model]
end

--[[
	Get all registered vehicles

	@return Array of VehicleInfo
]]
function VehicleAdapter.GetAllVehicles(): { VehicleInfo }
	local result = {}
	for _, info in pairs(_vehicles) do
		table.insert(result, info)
	end
	return result
end

--[[
	Get all registered mounts

	@return Array of MountInfo
]]
function VehicleAdapter.GetAllMounts(): { MountInfo }
	local result = {}
	for _, info in pairs(_mounts) do
		table.insert(result, info)
	end
	return result
end

--[[
	Get vehicle hitbox parts for snapshot/validation
	Returns a table similar to character hitbox parts

	@param vehicleInfo The vehicle info
	@return Table of part data { [partName]: { cf, size } }
]]
function VehicleAdapter.GetVehicleHitboxParts(vehicleInfo: VehicleInfo): { [string]: { cf: CFrame, size: Vector3 } }
	local result = {}
	local model = vehicleInfo.model
	local primaryPart = model.PrimaryPart or model:FindFirstChild("HumanoidRootPart") or model:FindFirstChildWhichIsA("BasePart")

	if not primaryPart then
		return result
	end

	local baseCf = primaryPart.CFrame

	if vehicleInfo.config.hitboxes then
		for name, hitbox in pairs(vehicleInfo.config.hitboxes) do
			local offset = hitbox.offset or Vector3.zero
			result[name] = {
				cf = baseCf * CFrame.new(offset),
				size = hitbox.size,
			}
		end
	else
		for _, part in ipairs(model:GetDescendants()) do
			if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
				result[part.Name] = {
					cf = part.CFrame,
					size = part.Size,
				}
			end
		end
	end

	return result
end

--[[
	Apply damage to a vehicle

	@param vehicleInfo The vehicle to damage
	@param damage The damage amount
	@param hitPart Optional part name that was hit
	@return Remaining health
]]
function VehicleAdapter.DamageVehicle(vehicleInfo: VehicleInfo, damage: number, hitPart: string?): number
	if vehicleInfo.destroyed then
		return 0
	end

	local multiplier = vehicleInfo.config.damageMultiplier or 1.0

	if hitPart and vehicleInfo.config.hitboxes then
		local hitbox = vehicleInfo.config.hitboxes[hitPart]
		if hitbox and hitbox.isWeakSpot then
			multiplier = (hitbox.damageMultiplier or 2.0)
		elseif hitbox and hitbox.damageMultiplier then
			multiplier = hitbox.damageMultiplier
		end
	end

	local actualDamage = damage * multiplier
	vehicleInfo.health = math.max(0, vehicleInfo.health - actualDamage)

	if vehicleInfo.health <= 0 then
		vehicleInfo.destroyed = true
	end

	return vehicleInfo.health
end

--[[
	Repair a vehicle

	@param vehicleInfo The vehicle to repair
	@param amount The repair amount
	@return New health
]]
function VehicleAdapter.RepairVehicle(vehicleInfo: VehicleInfo, amount: number): number
	vehicleInfo.health = math.min(vehicleInfo.maxHealth, vehicleInfo.health + amount)

	if vehicleInfo.health > 0 then
		vehicleInfo.destroyed = false
	end

	return vehicleInfo.health
end

--[[
	Check if a model is a registered vehicle

	@param model The model to check
	@return boolean
]]
function VehicleAdapter.IsVehicle(model: Model): boolean
	return _vehicles[model] ~= nil
end

--[[
	Check if a model is a registered mount

	@param model The model to check
	@return boolean
]]
function VehicleAdapter.IsMount(model: Model): boolean
	return _mounts[model] ~= nil
end

return VehicleAdapter
