--!strict
--[[
	Replication - Custom physics replication system for Rewind v1.1.0

	Replaces Roblox's default character replication with a custom system
	that provides:
	- Unified state buffer for interpolation AND hit validation
	- Configurable tick rate independent of Roblox's replication
	- Delta compression for bandwidth optimization
	- Proximity-based update frequency
	- Client-authoritative movement with server reconciliation
	- Full NPC support

	Usage (Server):
		local Replication = Rewind.Replication

		Replication.Start({
			tickRate = 20,
			deltaCompression = true,
			proximityBased = true,
		})

		-- Register entities
		Replication.RegisterPlayer(player)
		Replication.RegisterNPC(npcModel)

	Usage (Client):
		local Replication = Rewind.Replication

		Replication.StartClient({
			interpolationDelay = 100,
		})
]]

local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local Types = require(script.Parent.Types)
local Remotes = require(script.Parent.Net.Remotes)

local EntityRegistry = require(script.EntityRegistry)
local StateBuffer = require(script.StateBuffer)
local ServerReplicator = require(script.ServerReplicator)
local ClientInterpolator = require(script.ClientInterpolator)

local Replication = {}

local _registry: any = nil
local _serverReplicator: any = nil
local _clientInterpolator: any = nil

--[[
	Expose submodules for advanced usage
]]
Replication.EntityRegistry = EntityRegistry
Replication.StateBuffer = StateBuffer
Replication.ServerReplicator = ServerReplicator
Replication.ClientInterpolator = ClientInterpolator

--[[
	Get the entity registry
]]
function Replication.GetRegistry(): any
	if not _registry then
		_registry = EntityRegistry.new()
	end
	return _registry
end

--[[
	Start the server-side replication system

	@param config ReplicationConfig options
]]
function Replication.Start(config: Types.ReplicationConfig?)
	if not RunService:IsServer() then
		warn("[Rewind.Replication] Start() should only be called on the server")
		return
	end

	Remotes.EnsureAll()

	if not _registry then
		_registry = EntityRegistry.new()
	end

	if not _serverReplicator then
		_serverReplicator = ServerReplicator.new(_registry, Remotes, config)
	else
		_serverReplicator:Configure(config or {})
	end

	_serverReplicator:Start()

	Remotes.ClientState().OnServerEvent:Connect(function(player, state)
		if _serverReplicator then
			_serverReplicator:HandleClientState(player, state)
		end
	end)
end

--[[
	Stop the server-side replication system
]]
function Replication.Stop()
	if _serverReplicator then
		_serverReplicator:Stop()
	end
end

--[[
	Register a player for custom replication (server)

	@param player The player to register
	@param priority Optional priority level (default 5)
]]
function Replication.RegisterPlayer(player: Player, priority: number?): Types.EntityInfo?
	if not RunService:IsServer() then return nil end

	local registry = Replication.GetRegistry()
	local info = registry:RegisterPlayer(player, priority)

	if info then
		-- Notify all clients
		Remotes.EntityAdded():FireAllClients({
			id = info.id,
			entityType = info.entityType,
			model = info.model,
		})
	end

	return info
end

--[[
	Register an NPC for custom replication (server)

	@param model The NPC model
	@param priority Optional priority level (default 3)
]]
function Replication.RegisterNPC(model: Model, priority: number?): Types.EntityInfo?
	if not RunService:IsServer() then return nil end

	local registry = Replication.GetRegistry()
	local info = registry:RegisterNPC(model, priority)

	if info then
		Remotes.EntityAdded():FireAllClients({
			id = info.id,
			entityType = info.entityType,
			model = info.model,
		})
	end

	return info
end

--[[
	Unregister an entity (server)
]]
function Replication.Unregister(modelOrPlayer: Model | Player)
	if not RunService:IsServer() then return end

	local registry = Replication.GetRegistry()
	local info: Types.EntityInfo? = nil

	if typeof(modelOrPlayer) == "Instance" then
		if modelOrPlayer:IsA("Player") then
			info = registry:GetByPlayer(modelOrPlayer :: Player)
			registry:UnregisterPlayer(modelOrPlayer :: Player)
		else
			info = registry:GetByModel(modelOrPlayer :: Model)
			registry:UnregisterByModel(modelOrPlayer :: Model)
		end
	end

	if info then
		Remotes.EntityRemoved():FireAllClients(info.id)
	end
end

--[[
	Get the server replicator (for advanced usage)
]]
function Replication.GetServerReplicator(): any
	return _serverReplicator
end

--[[
	Sample entity state for rewind (hit validation)

	@param entityId The entity ID
	@param rewindTime The timestamp to sample
	@return EntityState or nil
]]
function Replication.SampleForRewind(entityId: string, rewindTime: number): Types.EntityState?
	if _serverReplicator then
		return _serverReplicator:SampleForRewind(entityId, rewindTime)
	end
	return nil
end

--[[
	Start the client-side interpolation system

	@param config ReplicationConfig options
]]
function Replication.StartClient(config: Types.ReplicationConfig?)
	if not RunService:IsClient() then
		warn("[Rewind.Replication] StartClient() should only be called on the client")
		return
	end

	if not _clientInterpolator then
		_clientInterpolator = ClientInterpolator.new(Remotes, config)
	else
		_clientInterpolator:Configure(config or {})
	end

	_clientInterpolator:Start()

	Remotes.EntityAdded().OnClientEvent:Connect(function(data)
		if data.model and _clientInterpolator then
			_clientInterpolator:RegisterEntity(data.id, data.model)
		end
	end)

	Remotes.EntityRemoved().OnClientEvent:Connect(function(entityId)
		if _clientInterpolator then
			_clientInterpolator:UnregisterEntity(entityId)
		end
	end)
end

--[[
	Stop the client-side interpolation system
]]
function Replication.StopClient()
	if _clientInterpolator then
		_clientInterpolator:Stop()
	end
end

--[[
	Get the client interpolator (for advanced usage)
]]
function Replication.GetClientInterpolator(): any
	return _clientInterpolator
end

--[[
	Get interpolated CFrame for an entity (client)
]]
function Replication.GetInterpolatedCFrame(entityId: string): CFrame?
	if _clientInterpolator then
		return _clientInterpolator:GetInterpolatedCFrame(entityId)
	end
	return nil
end

--[[
	Check if replication is running
]]
function Replication.IsRunning(): boolean
	if RunService:IsServer() then
		return _serverReplicator ~= nil and _serverReplicator._running
	else
		return _clientInterpolator ~= nil and _clientInterpolator._running
	end
end

--[[
	Get entity count
]]
function Replication.GetEntityCount(): number
	local registry = Replication.GetRegistry()
	return registry:Count()
end

--[[
	Get all registered entities
]]
function Replication.GetAllEntities(): { Types.EntityInfo }
	local registry = Replication.GetRegistry()
	return registry:GetAll()
end

--[[
	Get entity by model
]]
function Replication.GetEntity(model: Model): Types.EntityInfo?
	local registry = Replication.GetRegistry()
	return registry:GetByModel(model)
end

return Replication
