--!strict
--[[
	MovementValidator - Detects movement anomalies using snapshot data

	Analyzes player movement patterns to detect speed hacks, teleportation,
	and fly hacks by examining position changes between snapshots.

	v1.2.0: Initial implementation

	Usage:
		-- Configure movement validation
		Rewind.ConfigureMovementValidation({
			maxSpeed = 50,           -- Max studs/second
			maxVerticalSpeed = 100,  -- Max vertical studs/second (jumping)
			teleportThreshold = 100, -- Distance to consider a teleport
			flyCheckInterval = 0.5,  -- How often to check for flying
			maxAirTime = 3,          -- Max seconds in air without touching ground
		})

		-- Validate movement
		local result = Rewind.ValidateMovement(player, fromPos, toPos, deltaTime)
		if not result.valid then
			print("Anomaly detected:", result.anomaly)
		end

		-- Enable automatic monitoring
		Rewind.StartMovementMonitoring()
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local MovementValidator = {}

export type AnomalyType =
	| "speed_hack"
	| "teleport"
	| "fly_hack"
	| "noclip"
	| "vertical_speed"

export type ValidationResult = {
	valid: boolean,
	anomaly: AnomalyType?,
	details: {
		speed: number?,
		distance: number?,
		airTime: number?,
		expectedMax: number?,
	}?,
}

export type MovementConfig = {
	maxSpeed: number?,
	maxVerticalSpeed: number?,
	teleportThreshold: number?,
	flyCheckInterval: number?,
	maxAirTime: number?,
	noclipCheckEnabled: boolean?,
	speedTolerance: number?,
	enableMonitoring: boolean?,
}

export type PlayerMovementState = {
	lastPosition: Vector3,
	lastTimestamp: number,
	airStartTime: number?,
	isInAir: boolean,
	violations: {
		speed: number,
		teleport: number,
		fly: number,
		noclip: number,
	},
	lastGroundPosition: Vector3?,
}

local DEFAULT_CONFIG: MovementConfig = {
	maxSpeed = 50,
	maxVerticalSpeed = 100,
	teleportThreshold = 100,
	flyCheckInterval = 0.5,
	maxAirTime = 5,
	noclipCheckEnabled = false,
	speedTolerance = 1.5,
	enableMonitoring = false,
}

local _config: MovementConfig = DEFAULT_CONFIG
local _playerStates: { [Player]: PlayerMovementState } = {}
local _onAnomalyDetected = Instance.new("BindableEvent")
local _monitorConnection: RBXScriptConnection? = nil
local _started = false

local _playerSpeedMultipliers: { [Player]: number } = {}

MovementValidator.OnAnomalyDetected = _onAnomalyDetected.Event

--[[
	Configure movement validation settings

	@param config MovementConfig options
]]
function MovementValidator.Configure(config: MovementConfig?)
	_config = {
		maxSpeed = config and config.maxSpeed or DEFAULT_CONFIG.maxSpeed,
		maxVerticalSpeed = config and config.maxVerticalSpeed or DEFAULT_CONFIG.maxVerticalSpeed,
		teleportThreshold = config and config.teleportThreshold or DEFAULT_CONFIG.teleportThreshold,
		flyCheckInterval = config and config.flyCheckInterval or DEFAULT_CONFIG.flyCheckInterval,
		maxAirTime = config and config.maxAirTime or DEFAULT_CONFIG.maxAirTime,
		noclipCheckEnabled = if config and config.noclipCheckEnabled ~= nil then config.noclipCheckEnabled else DEFAULT_CONFIG.noclipCheckEnabled,
		speedTolerance = config and config.speedTolerance or DEFAULT_CONFIG.speedTolerance,
		enableMonitoring = if config and config.enableMonitoring ~= nil then config.enableMonitoring else DEFAULT_CONFIG.enableMonitoring,
	}

	if _config.enableMonitoring and not _started then
		MovementValidator.StartMonitoring()
	end
end

--[[
	Start automatic movement monitoring

	Monitors all players every frame using their character positions.
]]
function MovementValidator.StartMonitoring()
	if _started then return end
	_started = true

	Players.PlayerAdded:Connect(function(player)
		MovementValidator._initPlayerState(player)
	end)

	Players.PlayerRemoving:Connect(function(player)
		_playerStates[player] = nil
		_playerSpeedMultipliers[player] = nil
	end)

	for _, player in ipairs(Players:GetPlayers()) do
		MovementValidator._initPlayerState(player)
	end

	_monitorConnection = RunService.Heartbeat:Connect(function()
		local now = Workspace:GetServerTimeNow()

		for player, state in pairs(_playerStates) do
			local character = player.Character
			if not character then continue end

			local rootPart = character:FindFirstChild("HumanoidRootPart") :: BasePart?
			if not rootPart then continue end

			local position = rootPart.Position
			local deltaTime = now - state.lastTimestamp

			if deltaTime > 0.01 then
				local result = MovementValidator._validateMovement(
					player,
					state.lastPosition,
					position,
					deltaTime,
					state
				)

				if not result.valid and result.anomaly then
					_onAnomalyDetected:Fire(player, result.anomaly, result.details)
				end

				state.lastPosition = position
				state.lastTimestamp = now
			end
		end
	end)
end

--[[
	Stop automatic movement monitoring
]]
function MovementValidator.StopMonitoring()
	_started = false

	if _monitorConnection then
		_monitorConnection:Disconnect()
		_monitorConnection = nil
	end
end

--[[
	Validate a single movement

	@param player The player
	@param fromPos Starting position
	@param toPos Ending position
	@param deltaTime Time between positions
	@return ValidationResult
]]
function MovementValidator.ValidateMovement(
	player: Player,
	fromPos: Vector3,
	toPos: Vector3,
	deltaTime: number
): ValidationResult
	local state = _playerStates[player]
	if not state then
		state = MovementValidator._initPlayerState(player)
	end

	return MovementValidator._validateMovement(player, fromPos, toPos, deltaTime, state)
end

--[[
	Validate movement using snapshot data

	@param player The player
	@param timestamp The timestamp to validate
	@param position The claimed position
	@param snapshotStore Reference to SnapshotStore
	@return ValidationResult
]]
function MovementValidator.ValidateFromSnapshots(
	player: Player,
	timestamp: number,
	position: Vector3,
	snapshotStore: any -- SnapshotStore module
): ValidationResult
	local snapshot = snapshotStore.GetNearestSnapshot(player.Character, timestamp)
	if not snapshot then
		return { valid = true, anomaly = nil, details = nil }
	end

	local snapshotPos = snapshot.position
	local deltaTime = math.abs(timestamp - snapshot.timestamp)

	return MovementValidator.ValidateMovement(player, snapshotPos, position, deltaTime)
end

--[[
	Set speed multiplier for a player (for vehicles, speed boosts, etc.)

	@param player The player
	@param multiplier Speed multiplier (1 = normal)
]]
function MovementValidator.SetSpeedMultiplier(player: Player, multiplier: number)
	_playerSpeedMultipliers[player] = multiplier
end

--[[
	Clear speed multiplier for a player

	@param player The player
]]
function MovementValidator.ClearSpeedMultiplier(player: Player)
	_playerSpeedMultipliers[player] = nil
end

--[[
	Get current violation counts for a player

	@param player The player
	@return Violation counts
]]
function MovementValidator.GetViolations(player: Player): { speed: number, teleport: number, fly: number, noclip: number }?
	local state = _playerStates[player]
	return state and state.violations
end

--[[
	Clear violations for a player

	@param player The player
]]
function MovementValidator.ClearViolations(player: Player)
	local state = _playerStates[player]
	if state then
		state.violations = {
			speed = 0,
			teleport = 0,
			fly = 0,
			noclip = 0,
		}
	end
end

--[[
	Check if a position is grounded (touching ground)

	@param position The position to check
	@param character The character to ignore
	@return boolean
]]
function MovementValidator.IsGrounded(position: Vector3, character: Model?): boolean
	local raycastParams = RaycastParams.new()
	raycastParams.FilterType = Enum.RaycastFilterType.Exclude
	if character then
		raycastParams.FilterDescendantsInstances = { character }
	end

	local result = Workspace:Raycast(position, Vector3.new(0, -4, 0), raycastParams)
	return result ~= nil
end

function MovementValidator._initPlayerState(player: Player): PlayerMovementState
	local character = player.Character
	local position = Vector3.zero

	if character then
		local rootPart = character:FindFirstChild("HumanoidRootPart") :: BasePart?
		if rootPart then
			position = rootPart.Position
		end
	end

	local state: PlayerMovementState = {
		lastPosition = position,
		lastTimestamp = Workspace:GetServerTimeNow(),
		airStartTime = nil,
		isInAir = false,
		violations = {
			speed = 0,
			teleport = 0,
			fly = 0,
			noclip = 0,
		},
		lastGroundPosition = position,
	}

	_playerStates[player] = state
	return state
end

function MovementValidator._validateMovement(
	player: Player,
	fromPos: Vector3,
	toPos: Vector3,
	deltaTime: number,
	state: PlayerMovementState
): ValidationResult
	if deltaTime < 0.001 then
		return { valid = true, anomaly = nil, details = nil }
	end

	local displacement = toPos - fromPos
	local distance = displacement.Magnitude
	local horizontalDisplacement = Vector3.new(displacement.X, 0, displacement.Z)
	local horizontalDistance = horizontalDisplacement.Magnitude
	local verticalDistance = math.abs(displacement.Y)

	local speedMultiplier = _playerSpeedMultipliers[player] or 1

	local horizontalSpeed = horizontalDistance / deltaTime
	local verticalSpeed = verticalDistance / deltaTime

	local tolerance = _config.speedTolerance or 1.5

	local teleportThreshold = _config.teleportThreshold or 100
	if distance > teleportThreshold then
		state.violations.teleport += 1
		return {
			valid = false,
			anomaly = "teleport",
			details = {
				distance = distance,
				expectedMax = teleportThreshold,
			},
		}
	end

	local maxSpeed = (_config.maxSpeed or 50) * speedMultiplier * tolerance
	if horizontalSpeed > maxSpeed then
		state.violations.speed += 1
		return {
			valid = false,
			anomaly = "speed_hack",
			details = {
				speed = horizontalSpeed,
				expectedMax = maxSpeed,
			},
		}
	end

	local maxVertical = (_config.maxVerticalSpeed or 100) * tolerance
	if verticalSpeed > maxVertical then
		state.violations.speed += 1
		return {
			valid = false,
			anomaly = "vertical_speed",
			details = {
				speed = verticalSpeed,
				expectedMax = maxVertical,
			},
		}
	end

	local character = player.Character
	local isGrounded = MovementValidator.IsGrounded(toPos, character)

	if isGrounded then
		state.isInAir = false
		state.airStartTime = nil
		state.lastGroundPosition = toPos
	else
		if not state.isInAir then
			state.isInAir = true
			state.airStartTime = Workspace:GetServerTimeNow()
		else
			local airTime = Workspace:GetServerTimeNow() - (state.airStartTime or 0)
			local maxAirTime = _config.maxAirTime or 5

			if airTime > maxAirTime then
				state.violations.fly += 1
				return {
					valid = false,
					anomaly = "fly_hack",
					details = {
						airTime = airTime,
						expectedMax = maxAirTime,
					},
				}
			end
		end
	end

	if _config.noclipCheckEnabled then
		local noclipResult = MovementValidator._checkNoclip(fromPos, toPos, character)
		if noclipResult then
			state.violations.noclip += 1
			return {
				valid = false,
				anomaly = "noclip",
				details = {
					distance = distance,
				},
			}
		end
	end

	return { valid = true, anomaly = nil, details = nil }
end

function MovementValidator._checkNoclip(fromPos: Vector3, toPos: Vector3, character: Model?): boolean
	local raycastParams = RaycastParams.new()
	raycastParams.FilterType = Enum.RaycastFilterType.Exclude
	if character then
		raycastParams.FilterDescendantsInstances = { character }
	end

	local direction = toPos - fromPos
	local distance = direction.Magnitude

	if distance < 1 then
		return false
	end

	local result = Workspace:Raycast(fromPos, direction, raycastParams)

	if result and (result.Position - fromPos).Magnitude < distance - 1 then
		return true
	end

	return false
end

return MovementValidator
