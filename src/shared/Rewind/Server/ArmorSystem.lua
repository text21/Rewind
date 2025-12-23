--!strict
--[[
	ArmorSystem - Multiple hitbox layers with damage reduction

	Allows entities to have armor layers that must be penetrated before
	dealing full damage. Each layer has its own health and damage reduction.

	v1.2.0: Initial implementation

	Usage:
		-- Define armor for a character
		Rewind.DefineArmor(character, {
			layers = {
				{
					name = "Shield",
					health = 100,
					damageReduction = 0.8,  -- Absorbs 80% of damage
					coversParts = { "Torso", "Head" },
				},
				{
					name = "Vest",
					health = 50,
					damageReduction = 0.5,
					coversParts = { "Torso" },
				},
			},
		})

		-- Apply damage (checks armor first)
		local result = Rewind.ApplyDamageWithArmor(character, "Torso", 100)
		-- result.finalDamage = damage after armor reduction
		-- result.armorDamage = damage absorbed by armor
		-- result.brokenLayers = { "Shield" } if any layers broke
]]

local ArmorSystem = {}

export type ArmorLayer = {
	name: string,
	health: number,
	maxHealth: number,
	damageReduction: number,
	coversParts: { string },
	broken: boolean,
	regenerates: boolean?,
	regenRate: number?,
	regenDelay: number?,
	lastDamageTime: number?,
}

export type ArmorConfig = {
	layers: { {
		name: string,
		health: number,
		damageReduction: number,
		coversParts: { string },
		regenerates: boolean?,
		regenRate: number?,
		regenDelay: number?,
	} },
}

export type ArmorState = {
	entityId: string,
	model: Model,
	layers: { ArmorLayer },
}

export type DamageResult = {
	finalDamage: number,
	armorDamage: number,
	brokenLayers: { string },
	penetrated: boolean,
}

local _armorStates: { [Model]: ArmorState } = {}
local _entityToArmor: { [string]: ArmorState } = {}

--[[
	Define armor for an entity

	@param model The character/entity model
	@param config Armor configuration
	@param entityId Optional entity ID for cross-referencing
	@return ArmorState
]]
function ArmorSystem.DefineArmor(model: Model, config: ArmorConfig, entityId: string?): ArmorState
	if _armorStates[model] then
		ArmorSystem.RemoveArmor(model)
	end

	local layers: { ArmorLayer } = {}

	for i, layerConfig in ipairs(config.layers) do
		local layer: ArmorLayer = {
			name = layerConfig.name,
			health = layerConfig.health,
			maxHealth = layerConfig.health,
			damageReduction = math.clamp(layerConfig.damageReduction, 0, 1),
			coversParts = layerConfig.coversParts,
			broken = false,
			regenerates = layerConfig.regenerates or false,
			regenRate = layerConfig.regenRate or 10,
			regenDelay = layerConfig.regenDelay or 5,
			lastDamageTime = nil,
		}
		table.insert(layers, layer)
	end

	local id = entityId or tostring(model:GetFullName())

	local state: ArmorState = {
		entityId = id,
		model = model,
		layers = layers,
	}

	_armorStates[model] = state
	_entityToArmor[id] = state

	model.Destroying:Connect(function()
		ArmorSystem.RemoveArmor(model)
	end)

	return state
end

--[[
	Remove armor from an entity

	@param model The entity model
]]
function ArmorSystem.RemoveArmor(model: Model)
	local state = _armorStates[model]
	if not state then return end

	_entityToArmor[state.entityId] = nil
	_armorStates[model] = nil
end

--[[
	Get armor state for an entity

	@param model The entity model
	@return ArmorState or nil
]]
function ArmorSystem.GetArmor(model: Model): ArmorState?
	return _armorStates[model]
end

--[[
	Get armor state by entity ID

	@param entityId The entity ID
	@return ArmorState or nil
]]
function ArmorSystem.GetArmorById(entityId: string): ArmorState?
	return _entityToArmor[entityId]
end

--[[
	Get layers that cover a specific body part

	@param state The armor state
	@param partName The body part name
	@return Array of ArmorLayers (outer to inner order)
]]
function ArmorSystem.GetLayersForPart(state: ArmorState, partName: string): { ArmorLayer }
	local result = {}

	for _, layer in ipairs(state.layers) do
		if not layer.broken then
			for _, coveredPart in ipairs(layer.coversParts) do
				if coveredPart == partName or coveredPart == "*" then
					table.insert(result, layer)
					break
				end
			end
		end
	end

	return result
end

--[[
	Calculate damage after armor reduction

	@param state The armor state
	@param partName The body part hit
	@param rawDamage The incoming damage
	@param currentTime Optional current time for regen tracking
	@return DamageResult
]]
function ArmorSystem.CalculateDamage(
	state: ArmorState,
	partName: string,
	rawDamage: number,
	currentTime: number?
): DamageResult
	local layers = ArmorSystem.GetLayersForPart(state, partName)
	local now = currentTime or os.clock()

	local remainingDamage = rawDamage
	local totalArmorDamage = 0
	local brokenLayers = {}

	for _, layer in ipairs(layers) do
		if remainingDamage <= 0 then break end
		if layer.broken then continue end

		local absorbed = remainingDamage * layer.damageReduction
		local passthrough = remainingDamage * (1 - layer.damageReduction)

		layer.lastDamageTime = now

		if absorbed >= layer.health then
			totalArmorDamage += layer.health
			layer.health = 0
			layer.broken = true
			table.insert(brokenLayers, layer.name)

			local excess = absorbed - layer.health
			remainingDamage = passthrough + excess
		else
			layer.health -= absorbed
			totalArmorDamage += absorbed
			remainingDamage = passthrough
		end
	end

	return {
		finalDamage = remainingDamage,
		armorDamage = totalArmorDamage,
		brokenLayers = brokenLayers,
		penetrated = remainingDamage > 0,
	}
end

--[[
	Apply damage to an entity with armor

	@param model The entity model
	@param partName The body part hit
	@param rawDamage The incoming damage
	@param currentTime Optional current time
	@return DamageResult or nil if no armor
]]
function ArmorSystem.ApplyDamage(model: Model, partName: string, rawDamage: number, currentTime: number?): DamageResult?
	local state = _armorStates[model]
	if not state then
		return {
			finalDamage = rawDamage,
			armorDamage = 0,
			brokenLayers = {},
			penetrated = true,
		}
	end

	return ArmorSystem.CalculateDamage(state, partName, rawDamage, currentTime)
end

--[[
	Repair a specific armor layer

	@param state The armor state
	@param layerName The layer to repair
	@param amount The repair amount (nil = full repair)
	@return New layer health
]]
function ArmorSystem.RepairLayer(state: ArmorState, layerName: string, amount: number?): number
	for _, layer in ipairs(state.layers) do
		if layer.name == layerName then
			if amount then
				layer.health = math.min(layer.maxHealth, layer.health + amount)
			else
				layer.health = layer.maxHealth
			end
			layer.broken = layer.health <= 0
			return layer.health
		end
	end
	return 0
end

--[[
	Repair all armor layers

	@param state The armor state
	@param amount The repair amount per layer (nil = full repair)
]]
function ArmorSystem.RepairAll(state: ArmorState, amount: number?)
	for _, layer in ipairs(state.layers) do
		if amount then
			layer.health = math.min(layer.maxHealth, layer.health + amount)
		else
			layer.health = layer.maxHealth
		end
		layer.broken = layer.health <= 0
	end
end

--[[
	Update armor regeneration

	@param state The armor state
	@param deltaTime Time since last update
	@param currentTime Current time
]]
function ArmorSystem.UpdateRegeneration(state: ArmorState, deltaTime: number, currentTime: number)
	for _, layer in ipairs(state.layers) do
		if not layer.regenerates then continue end
		if layer.health >= layer.maxHealth then continue end

		if layer.lastDamageTime then
			local timeSinceDamage = currentTime - layer.lastDamageTime
			if timeSinceDamage < (layer.regenDelay or 5) then
				continue
			end
		end

		local regenAmount = (layer.regenRate or 10) * deltaTime
		layer.health = math.min(layer.maxHealth, layer.health + regenAmount)
		layer.broken = layer.health <= 0
	end
end

--[[
	Get total armor health remaining

	@param state The armor state
	@return Current health, Max health
]]
function ArmorSystem.GetTotalHealth(state: ArmorState): (number, number)
	local current = 0
	local max = 0

	for _, layer in ipairs(state.layers) do
		current += layer.health
		max += layer.maxHealth
	end

	return current, max
end

--[[
	Get armor health as percentage

	@param state The armor state
	@return Percentage (0-1)
]]
function ArmorSystem.GetHealthPercent(state: ArmorState): number
	local current, max = ArmorSystem.GetTotalHealth(state)
	if max == 0 then return 0 end
	return current / max
end

--[[
	Check if entity has any active armor for a part

	@param model The entity model
	@param partName The body part
	@return boolean
]]
function ArmorSystem.HasArmorForPart(model: Model, partName: string): boolean
	local state = _armorStates[model]
	if not state then return false end

	local layers = ArmorSystem.GetLayersForPart(state, partName)
	return #layers > 0
end

--[[
	Get all entities with armor

	@return Array of ArmorState
]]
function ArmorSystem.GetAllArmorStates(): { ArmorState }
	local result = {}
	for _, state in pairs(_armorStates) do
		table.insert(result, state)
	end
	return result
end

return ArmorSystem
