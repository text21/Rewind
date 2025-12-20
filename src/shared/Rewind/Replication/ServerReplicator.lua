--!strict
--[[
	ServerReplicator - Server-side entity state broadcasting

	Captures entity states at configurable tick rate and broadcasts to clients.
	Features:
	- Configurable tick rate (independent of snapshot rate)
	- Delta compression (only send changed data)
	- Proximity-based update frequency (distant entities update less often)
	- Bandwidth optimization with priority-based scheduling
	- Network ownership support (client-authoritative with server reconciliation)
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local Types = require(script.Parent.Parent.Types)
local EntityRegistry = require(script.Parent.EntityRegistry)
local StateBuffer = require(script.Parent.StateBuffer)

local ServerReplicator = {}
ServerReplicator.__index = ServerReplicator

local DEFAULT_CONFIG: Types.ReplicationConfig = {
	enabled = true,
	tickRate = 20,
	interpolationDelay = 100,
	maxExtrapolation = 200,
	deltaCompression = true,
	proximityBased = true,
	nearDistance = 100,
	farDistance = 500,
	farTickDivisor = 4,
	clientAuthoritative = true,
	reconciliationThreshold = 5,
}

export type ServerReplicator = {
	_config: Types.ReplicationConfig,
	_registry: any,
	_buffers: { [string]: any },
	_lastSent: { [string]: { [Player]: Types.CompressedState? } },
	_tickAccum: number,
	_farTickAccum: { [string]: number },
	_running: boolean,
	_heartbeat: RBXScriptConnection?,
	_remotes: any,
}

function ServerReplicator.new(registry: any, remotes: any, config: Types.ReplicationConfig?)
	local mergedConfig = {}
	for k, v in pairs(DEFAULT_CONFIG) do
		mergedConfig[k] = v
	end
	if config then
		for k, v in pairs(config) do
			mergedConfig[k] = v
		end
	end

	local self = setmetatable({
		_config = mergedConfig,
		_registry = registry,
		_buffers = {},
		_lastSent = {},
		_tickAccum = 0,
		_farTickAccum = {},
		_running = false,
		_heartbeat = nil,
		_remotes = remotes,
	}, ServerReplicator)

	return self
end

--[[
	Start the replicator
]]
function ServerReplicator:Start()
	if self._running then return end
	self._running = true

	self._registry:OnEntityAdded(function(info: Types.EntityInfo)
		self:_onEntityAdded(info)
	end)

	self._registry:OnEntityRemoved(function(info: Types.EntityInfo)
		self:_onEntityRemoved(info)
	end)

	for _, info in ipairs(self._registry:GetAll()) do
		self:_onEntityAdded(info)
	end

	self._heartbeat = RunService.Heartbeat:Connect(function(dt)
		self:_tick(dt)
	end)
end

--[[
	Stop the replicator
]]
function ServerReplicator:Stop()
	if not self._running then return end
	self._running = false

	if self._heartbeat then
		self._heartbeat:Disconnect()
		self._heartbeat = nil
	end
end

--[[
	Update configuration
]]
function ServerReplicator:Configure(config: Types.ReplicationConfig)
	for k, v in pairs(config) do
		self._config[k] = v
	end
end

--[[
	Get StateBuffer for an entity (for hit validation)
]]
function ServerReplicator:GetBuffer(entityId: string): any?
	return self._buffers[entityId]
end

--[[
	Handle entity registration
]]
function ServerReplicator:_onEntityAdded(info: Types.EntityInfo)
	local windowMs = 1000
	local buffer = StateBuffer.new(info.id, windowMs, self._config.tickRate or 20)
	self._buffers[info.id] = buffer
	self._lastSent[info.id] = {}
	self._farTickAccum[info.id] = 0
end

--[[
	Handle entity removal
]]
function ServerReplicator:_onEntityRemoved(info: Types.EntityInfo)
	self._buffers[info.id] = nil
	self._lastSent[info.id] = nil
	self._farTickAccum[info.id] = nil
end

--[[
	Get current server time
]]
function ServerReplicator:_now(): number
	local ok, t = pcall(function()
		return workspace:GetServerTimeNow()
	end)
	if ok then return t end
	return os.clock()
end

--[[
	Capture current state of an entity
]]
function ServerReplicator:_captureState(info: Types.EntityInfo): Types.EntityState?
	local model = info.model
	if not model or not model.Parent then
		return nil
	end

	local hrp = model:FindFirstChild("HumanoidRootPart")
	if not hrp or not hrp:IsA("BasePart") then
		return nil
	end

	-- Get velocity
	local velocity = Vector3.zero
	local humanoid = model:FindFirstChildOfClass("Humanoid")
	if humanoid then
		velocity = hrp.AssemblyLinearVelocity
	end

	return {
		t = self:_now(),
		rootCf = hrp.CFrame,
		velocity = velocity,
		parts = nil,
	}
end

--[[
	Calculate distance from player to entity
]]
function ServerReplicator:_distanceToPlayer(player: Player, entityInfo: Types.EntityInfo): number
	local playerChar = player.Character
	if not playerChar then return math.huge end

	local playerHrp = playerChar:FindFirstChild("HumanoidRootPart")
	if not playerHrp or not playerHrp:IsA("BasePart") then return math.huge end

	local entityHrp = entityInfo.model:FindFirstChild("HumanoidRootPart")
	if not entityHrp or not entityHrp:IsA("BasePart") then return math.huge end

	return (playerHrp.Position - entityHrp.Position).Magnitude
end

--[[
	Determine if entity should update for this player based on proximity
]]
function ServerReplicator:_shouldUpdateForPlayer(
	entityId: string,
	player: Player,
	entityInfo: Types.EntityInfo
): boolean
	if not self._config.proximityBased then
		return true
	end

	local distance = self:_distanceToPlayer(player, entityInfo)
	local nearDist = self._config.nearDistance or 100
	local farDist = self._config.farDistance or 500
	local farDivisor = self._config.farTickDivisor or 4

	if distance <= nearDist then
		return true
	end

	if distance >= farDist then
		local accum = self._farTickAccum[entityId] or 0
		if accum >= farDivisor then
			self._farTickAccum[entityId] = 0
			return true
		end
		return false
	end

	local t = (distance - nearDist) / (farDist - nearDist)
	local requiredTicks = math.floor(1 + t * (farDivisor - 1))

	local accum = self._farTickAccum[entityId] or 0
	if accum >= requiredTicks then
		self._farTickAccum[entityId] = 0
		return true
	end
	return false
end

--[[
	Main tick function
]]
function ServerReplicator:_tick(dt: number)
	if not self._config.enabled then return end

	self._tickAccum += dt
	local interval = 1 / (self._config.tickRate or 20)

	if self._tickAccum < interval then
		return
	end
	self._tickAccum = self._tickAccum % interval

	for entityId in pairs(self._buffers) do
		self._farTickAccum[entityId] = (self._farTickAccum[entityId] or 0) + 1
	end

	local now = self:_now()
	local entities = self._registry:GetAll()

	local states: { [string]: Types.EntityState } = {}
	for _, info in ipairs(entities) do
		local state = self:_captureState(info)
		if state then
			states[info.id] = state

			local buffer = self._buffers[info.id]
			if buffer then
				buffer:Push(state)
			end

			self._registry:MarkUpdated(info.id, now)
		end
	end

	for _, player in ipairs(Players:GetPlayers()) do
		local payload: { [string]: Types.CompressedState } = {}
		local hasData = false

		for _, info in ipairs(entities) do
			if self._config.clientAuthoritative and info.player == player then
				continue
			end

			if not self:_shouldUpdateForPlayer(info.id, player, info) then
				continue
			end

			local state = states[info.id]
			if not state then continue end

			local compressed: Types.CompressedState?
			if self._config.deltaCompression then
				local lastSentToPlayer = self._lastSent[info.id]
				local lastState = lastSentToPlayer and lastSentToPlayer[player]

				if lastState then
					compressed = StateBuffer.CalculateDelta(state, StateBuffer.Decompress(lastState))
				else
					compressed = StateBuffer.Compress(state)
				end
			else
				compressed = StateBuffer.Compress(state)
			end

			if compressed then
				payload[info.id] = compressed
				hasData = true

				if not self._lastSent[info.id] then
					self._lastSent[info.id] = {}
				end
				self._lastSent[info.id][player] = compressed
			end
		end

		if hasData and self._remotes then
			self._remotes.StateUpdate():FireClient(player, payload)
		end
	end
end

--[[
	Handle client state update (for client-authoritative mode)
	Validates and reconciles client-reported position

	@param player The player sending the update
	@param state The client-reported state
	@return boolean Whether the update was accepted
]]
function ServerReplicator:HandleClientState(player: Player, state: Types.CompressedState): boolean
	if not self._config.clientAuthoritative then
		return false
	end

	local entityInfo = self._registry:GetByPlayer(player)
	if not entityInfo then
		return false
	end

	local buffer = self._buffers[entityInfo.id]
	if not buffer then
		return false
	end

	local fullState = StateBuffer.Decompress(state)
	local lastState = buffer:Last()

	if lastState then
		local posDelta = (fullState.rootCf.Position - lastState.rootCf.Position).Magnitude
		local timeDelta = fullState.t - lastState.t

		if timeDelta > 0 then
			local speed = posDelta / timeDelta
			local maxSpeed = 100

			if speed > maxSpeed then
				return false
			end
		end

		local threshold = self._config.reconciliationThreshold or 5
		local character = player.Character
		if character then
			local hrp = character:FindFirstChild("HumanoidRootPart")
			if hrp and hrp:IsA("BasePart") then
				local serverPos = hrp.Position
				local clientPos = fullState.rootCf.Position
				local drift = (serverPos - clientPos).Magnitude

				if drift > threshold then
					self._remotes.StateCorrection():FireClient(player, {
						t = self:_now(),
						pos = serverPos,
						rot = { hrp.CFrame:ToEulerAnglesXYZ() },
					})
					return false
				end
			end
		end
	end

	buffer:Push(fullState)
	return true
end

--[[
	Get buffer for rewind queries (used by hit validation)
]]
function ServerReplicator:SampleForRewind(entityId: string, rewindTime: number): Types.EntityState?
	local buffer = self._buffers[entityId]
	if not buffer then
		return nil
	end
	return buffer:SampleRewind(rewindTime)
end

return ServerReplicator
