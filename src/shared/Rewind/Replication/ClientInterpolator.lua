--!strict
--[[
	ClientInterpolator - Client-side entity interpolation

	Receives state updates from server and smoothly interpolates entity positions.
	Features:
	- Configurable interpolation delay (render time behind server)
	- Smooth interpolation between network updates
	- Extrapolation for late updates
	- Visual smoothing for jitter reduction
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local Types = require(script.Parent.Parent.Types)
local StateBuffer = require(script.Parent.StateBuffer)

local ClientInterpolator = {}
ClientInterpolator.__index = ClientInterpolator

local DEFAULT_CONFIG = {
	interpolationDelay = 100,
	maxExtrapolation = 200,
	smoothingFactor = 0.15,
	teleportThreshold = 10,
}

export type ClientInterpolator = {
	_config: any,
	_buffers: { [string]: any },
	_models: { [string]: Model },
	_interpolatedCf: { [string]: CFrame },
	_running: boolean,
	_renderStepped: RBXScriptConnection?,
	_remotes: any,
	_localPlayer: Player,
}

function ClientInterpolator.new(remotes: any, config: Types.ReplicationConfig?)
	local mergedConfig = {}
	for k, v in pairs(DEFAULT_CONFIG) do
		mergedConfig[k] = v
	end
	if config then
		if config.interpolationDelay then
			mergedConfig.interpolationDelay = config.interpolationDelay
		end
		if config.maxExtrapolation then
			mergedConfig.maxExtrapolation = config.maxExtrapolation
		end
	end

	local self = setmetatable({
		_config = mergedConfig,
		_buffers = {},
		_models = {},
		_interpolatedCf = {},
		_running = false,
		_renderStepped = nil,
		_remotes = remotes,
		_localPlayer = Players.LocalPlayer,
	}, ClientInterpolator)

	return self
end

--[[
	Start the interpolator
]]
function ClientInterpolator:Start()
	if self._running then return end
	self._running = true

	if self._remotes then
		self._remotes.StateUpdate().OnClientEvent:Connect(function(payload)
			self:_handleStateUpdate(payload)
		end)

		self._remotes.StateCorrection().OnClientEvent:Connect(function(correction)
			self:_handleStateCorrection(correction)
		end)
	end

	self._renderStepped = RunService.RenderStepped:Connect(function(dt)
		self:_render(dt)
	end)
end

--[[
	Stop the interpolator
]]
function ClientInterpolator:Stop()
	if not self._running then return end
	self._running = false

	if self._renderStepped then
		self._renderStepped:Disconnect()
		self._renderStepped = nil
	end
end

--[[
	Register an entity for interpolation

	@param entityId The entity's unique ID
	@param model The entity's Model
]]
function ClientInterpolator:RegisterEntity(entityId: string, model: Model)
	local windowMs = 500
	local tickRate = 20

	self._buffers[entityId] = StateBuffer.new(entityId, windowMs, tickRate)
	self._models[entityId] = model
end

--[[
	Unregister an entity
]]
function ClientInterpolator:UnregisterEntity(entityId: string)
	self._buffers[entityId] = nil
	self._models[entityId] = nil
	self._interpolatedCf[entityId] = nil
end

--[[
	Get current server time estimate
]]
function ClientInterpolator:_now(): number
	local ok, t = pcall(function()
		return workspace:GetServerTimeNow()
	end)
	if ok then return t end
	return os.clock()
end

--[[
	Handle incoming state update from server
]]
function ClientInterpolator:_handleStateUpdate(payload: { [string]: Types.CompressedState })
	for entityId, compressed in pairs(payload) do
		local buffer = self._buffers[entityId]

		if not buffer then
			-- Auto-register if we have the model
			-- This handles cases where server sends before client registers
			continue
		end

		local state = StateBuffer.Decompress(compressed)
		buffer:Push(state)
	end
end

--[[
	Handle state correction from server
]]
function ClientInterpolator:_handleStateCorrection(correction: Types.CompressedState)
	local character = self._localPlayer.Character
	if not character then return end

	local hrp = character:FindFirstChild("HumanoidRootPart")
	if not hrp or not hrp:IsA("BasePart") then return end

	local rot = correction.rot
	local cf = CFrame.new(correction.pos) * CFrame.Angles(rot[1], rot[2], rot[3])

	hrp.CFrame = cf
end

--[[
	Main render loop - interpolate all entities
]]
function ClientInterpolator:_render(dt: number)
	local now = self:_now()
	local delayMs = self._config.interpolationDelay
	local renderTime = now - (delayMs / 1000)

	for entityId, buffer in pairs(self._buffers) do
		local model = self._models[entityId]
		if not model or not model.Parent then
			continue
		end

		local hrp = model:FindFirstChild("HumanoidRootPart")
		if not hrp or not hrp:IsA("BasePart") then
			continue
		end

		local humanoid = model:FindFirstChildOfClass("Humanoid")
		if humanoid then
			local player = Players:GetPlayerFromCharacter(model)
			if player == self._localPlayer then
				continue
			end
		end

		local state: Types.EntityState? = nil

		if buffer:ContainsTime(renderTime) then
			state = buffer:SampleInterpolated(renderTime)
		else
			local oldest, newest = buffer:GetTimeRange()
			if newest > 0 and renderTime > newest then
				state = buffer:Extrapolate(renderTime, self._config.maxExtrapolation)
			end
		end

		if state then
			local targetCf = state.rootCf
			local currentCf = self._interpolatedCf[entityId]

			if not currentCf then
				self._interpolatedCf[entityId] = targetCf
				hrp.CFrame = targetCf
			else
				local distance = (targetCf.Position - currentCf.Position).Magnitude
				if distance > self._config.teleportThreshold then
					self._interpolatedCf[entityId] = targetCf
					hrp.CFrame = targetCf
				else
					local smoothing = self._config.smoothingFactor
					local smoothedCf = currentCf:Lerp(targetCf, smoothing)
					self._interpolatedCf[entityId] = smoothedCf
					hrp.CFrame = smoothedCf
				end
			end
		end
	end
end

--[[
	Get the current interpolated CFrame for an entity
]]
function ClientInterpolator:GetInterpolatedCFrame(entityId: string): CFrame?
	return self._interpolatedCf[entityId]
end

--[[
	Get the state buffer for an entity (for debugging)
]]
function ClientInterpolator:GetBuffer(entityId: string): any?
	return self._buffers[entityId]
end

--[[
	Send local player state to server (for client-authoritative mode)
]]
function ClientInterpolator:SendLocalState()
	local character = self._localPlayer.Character
	if not character then return end

	local hrp = character:FindFirstChild("HumanoidRootPart")
	if not hrp or not hrp:IsA("BasePart") then return end

	local rx, ry, rz = hrp.CFrame:ToEulerAnglesXYZ()

	local state: Types.CompressedState = {
		t = self:_now(),
		pos = hrp.Position,
		rot = { rx, ry, rz },
		vel = hrp.AssemblyLinearVelocity,
	}

	if self._remotes then
		self._remotes.ClientState():FireServer(state)
	end
end

--[[
	Configure interpolation settings
]]
function ClientInterpolator:Configure(config: any)
	for k, v in pairs(config) do
		self._config[k] = v
	end
end

return ClientInterpolator
