--!strict
--[[
	EntityRegistry - Central registry for all entities participating in custom replication

	Manages player characters and NPCs that bypass Roblox's default physics replication.
	Entities are tracked with unique IDs, priority levels, and type information.
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local Types = require(script.Parent.Parent.Types)

local EntityRegistry = {}
EntityRegistry.__index = EntityRegistry

export type EntityRegistry = {
	_entities: { [string]: Types.EntityInfo },
	_modelToId: { [Model]: string },
	_playerToId: { [Player]: string },
	_nextNpcId: number,
	_onEntityAdded: BindableEvent,
	_onEntityRemoved: BindableEvent,
}

function EntityRegistry.new()
	local self = setmetatable({
		_entities = {},
		_modelToId = {},
		_playerToId = {},
		_nextNpcId = 1,
		_onEntityAdded = Instance.new("BindableEvent"),
		_onEntityRemoved = Instance.new("BindableEvent"),
	}, EntityRegistry)

	return self
end

--[[
	Generate a unique ID for an entity
]]
function EntityRegistry:_generateId(entityType: Types.EntityType, player: Player?): string
	if entityType == "Player" and player then
		return "player_" .. tostring(player.UserId)
	else
		local id = "npc_" .. tostring(self._nextNpcId)
		self._nextNpcId += 1
		return id
	end
end

--[[
	Register a player character for custom replication

	@param player The player whose character to register
	@param priority Optional priority level (default 5)
	@return EntityInfo or nil if no character
]]
function EntityRegistry:RegisterPlayer(player: Player, priority: number?): Types.EntityInfo?
	local character = player.Character
	if not character then
		return nil
	end

	if self._playerToId[player] then
		return self._entities[self._playerToId[player]]
	end

	local id = self:_generateId("Player", player)

	local info: Types.EntityInfo = {
		id = id,
		entityType = "Player",
		model = character,
		player = player,
		priority = priority or 5,
		lastUpdate = 0,
	}

	self._entities[id] = info
	self._modelToId[character] = id
	self._playerToId[player] = id

	self._onEntityAdded:Fire(info)

	return info
end

--[[
	Register an NPC for custom replication

	@param model The NPC model
	@param priority Optional priority level (default 3)
	@return EntityInfo
]]
function EntityRegistry:RegisterNPC(model: Model, priority: number?): Types.EntityInfo
	if self._modelToId[model] then
		return self._entities[self._modelToId[model]]
	end

	local id = self:_generateId("NPC", nil)

	local info: Types.EntityInfo = {
		id = id,
		entityType = "NPC",
		model = model,
		player = nil,
		priority = priority or 3,
		lastUpdate = 0,
	}

	self._entities[id] = info
	self._modelToId[model] = id

	self._onEntityAdded:Fire(info)

	return info
end

--[[
	Unregister an entity by ID
]]
function EntityRegistry:UnregisterById(id: string)
	local info = self._entities[id]
	if not info then return end

	self._modelToId[info.model] = nil
	if info.player then
		self._playerToId[info.player] = nil
	end
	self._entities[id] = nil

	self._onEntityRemoved:Fire(info)
end

--[[
	Unregister an entity by model
]]
function EntityRegistry:UnregisterByModel(model: Model)
	local id = self._modelToId[model]
	if id then
		self:UnregisterById(id)
	end
end

--[[
	Unregister a player's entity
]]
function EntityRegistry:UnregisterPlayer(player: Player)
	local id = self._playerToId[player]
	if id then
		self:UnregisterById(id)
	end
end

--[[
	Get entity by ID
]]
function EntityRegistry:GetById(id: string): Types.EntityInfo?
	return self._entities[id]
end

--[[
	Get entity by model
]]
function EntityRegistry:GetByModel(model: Model): Types.EntityInfo?
	local id = self._modelToId[model]
	if id then
		return self._entities[id]
	end
	return nil
end

--[[
	Get entity by player
]]
function EntityRegistry:GetByPlayer(player: Player): Types.EntityInfo?
	local id = self._playerToId[player]
	if id then
		return self._entities[id]
	end
	return nil
end

--[[
	Get all registered entities
]]
function EntityRegistry:GetAll(): { Types.EntityInfo }
	local list = {}
	for _, info in pairs(self._entities) do
		table.insert(list, info)
	end
	return list
end

--[[
	Get all entities of a specific type
]]
function EntityRegistry:GetByType(entityType: Types.EntityType): { Types.EntityInfo }
	local list = {}
	for _, info in pairs(self._entities) do
		if info.entityType == entityType then
			table.insert(list, info)
		end
	end
	return list
end

--[[
	Get entity count
]]
function EntityRegistry:Count(): number
	local count = 0
	for _ in pairs(self._entities) do
		count += 1
	end
	return count
end

--[[
	Check if entity is registered
]]
function EntityRegistry:IsRegistered(model: Model): boolean
	return self._modelToId[model] ~= nil
end

--[[
	Update entity's last update timestamp
]]
function EntityRegistry:MarkUpdated(id: string, timestamp: number)
	local info = self._entities[id]
	if info then
		info.lastUpdate = timestamp
	end
end

--[[
	Set entity priority
]]
function EntityRegistry:SetPriority(id: string, priority: number)
	local info = self._entities[id]
	if info then
		info.priority = priority
	end
end

--[[
	Connect to entity added event
]]
function EntityRegistry:OnEntityAdded(callback: (Types.EntityInfo) -> ())
	return self._onEntityAdded.Event:Connect(callback)
end

--[[
	Connect to entity removed event
]]
function EntityRegistry:OnEntityRemoved(callback: (Types.EntityInfo) -> ())
	return self._onEntityRemoved.Event:Connect(callback)
end

--[[
	Clean up registry
]]
function EntityRegistry:Destroy()
	self._onEntityAdded:Destroy()
	self._onEntityRemoved:Destroy()
	table.clear(self._entities)
	table.clear(self._modelToId)
	table.clear(self._playerToId)
end

return EntityRegistry
