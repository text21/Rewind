# Armor System

The Armor System module provides multiple hitbox layers with damage reduction, regeneration, and armor breaking mechanics.

## Overview

```lua
local Rewind = require(ReplicatedStorage.Packages.Rewind)

-- Define armor for a player
Rewind.DefineArmor(player.Character, {
    layers = {
        {
            partName = "UpperTorso",
            reduction = 0.5, -- 50% damage reduction
            maxHealth = 100,
            regeneration = 2, -- 2 HP per second
        },
        {
            partName = "Head",
            reduction = 0.3,
            maxHealth = 50,
            breakThreshold = 0.2, -- Breaks at 20% health
        },
    },
})

-- Apply damage through armor
local result = Rewind.ApplyDamageWithArmor(player.Character, "UpperTorso", 50)
print("Final damage:", result.finalDamage) -- 25 (50% reduced)
print("Armor absorbed:", result.absorbed)  -- 25
```

## Types

### ArmorLayer

```lua
type ArmorLayer = {
    partName: string,           -- Name of the body part
    reduction: number,          -- Damage reduction (0-1, where 1 = 100% reduction)
    maxHealth: number?,         -- Max armor health (default 100)
    currentHealth: number?,     -- Current health (set automatically)
    regeneration: number?,      -- HP regenerated per second
    breakThreshold: number?,    -- Health % at which armor breaks (0-1)
    brokenReduction: number?,   -- Reduction when broken (default 0)
}
```

### ArmorConfig

```lua
type ArmorConfig = {
    layers: {ArmorLayer},       -- Armor layers for different parts
    globalReduction: number?,   -- Global damage reduction applied to all parts
    regenerationDelay: number?, -- Seconds before regeneration starts (default 3)
    onLayerBroken: ((entity: Model, partName: string) -> ())?,
    onLayerRepaired: ((entity: Model, partName: string) -> ())?,
    onDamageAbsorbed: ((entity: Model, partName: string, absorbed: number) -> ())?,
}
```

### ArmorState

```lua
type ArmorState = {
    entity: Model,
    config: ArmorConfig,
    layers: {[string]: ArmorLayer}, -- Map of partName -> ArmorLayer
    lastDamageTime: number,
}
```

### DamageResult

```lua
type DamageResult = {
    originalDamage: number,     -- Damage before reduction
    finalDamage: number,        -- Damage after armor reduction
    absorbed: number,           -- Total damage absorbed by armor
    armorDamage: number,        -- Damage dealt to armor health
    layerBroken: boolean,       -- Whether the armor layer broke
    layerHealth: number,        -- Remaining armor health
    penetrated: boolean,        -- Whether armor was fully penetrated
}
```

## API Reference

### DefineArmor

Defines armor layers for an entity (player character, NPC, or vehicle).

```lua
Rewind.DefineArmor(entity: Model, config: ArmorConfig): ArmorState
```

**Parameters:**

- `entity` - The model to add armor to
- `config` - The armor configuration

**Returns:** `ArmorState` - The created armor state

**Example:**

```lua
-- Heavy armor build
Rewind.DefineArmor(player.Character, {
    layers = {
        {
            partName = "UpperTorso",
            reduction = 0.7,
            maxHealth = 150,
            regeneration = 3,
            breakThreshold = 0.1,
        },
        {
            partName = "LowerTorso",
            reduction = 0.5,
            maxHealth = 100,
            regeneration = 2,
        },
        {
            partName = "Head",
            reduction = 0.4,
            maxHealth = 75,
            breakThreshold = 0.25,
            brokenReduction = 0.1,
        },
    },
    globalReduction = 0.1, -- Additional 10% reduction on all parts
    regenerationDelay = 5, -- Wait 5 seconds after damage before regen
    onLayerBroken = function(entity, partName)
        -- Play armor break effect
        playArmorBreakSound(entity, partName)
    end,
    onDamageAbsorbed = function(entity, partName, absorbed)
        -- Show damage numbers
        showDamageNumber(entity, partName, absorbed, "BLOCKED")
    end,
})
```

---

### RemoveArmor

Removes all armor from an entity.

```lua
Rewind.RemoveArmor(entity: Model): boolean
```

**Parameters:**

- `entity` - The entity to remove armor from

**Returns:** `boolean` - Whether armor was found and removed

---

### GetArmor

Gets the current armor state for an entity.

```lua
Rewind.GetArmor(entity: Model): ArmorState?
```

**Parameters:**

- `entity` - The entity to get armor for

**Returns:** `ArmorState?` - The armor state, or nil if no armor

**Example:**

```lua
local armorState = Rewind.GetArmor(player.Character)
if armorState then
    for partName, layer in pairs(armorState.layers) do
        local percent = (layer.currentHealth / layer.maxHealth) * 100
        print(partName .. " armor: " .. percent .. "%")
    end
end
```

---

### ApplyDamageWithArmor

Applies damage to an entity, calculating armor reduction.

```lua
Rewind.ApplyDamageWithArmor(
    entity: Model,
    partName: string,
    damage: number,
    armorPenetration: number?
): DamageResult
```

**Parameters:**

- `entity` - The entity taking damage
- `partName` - The body part hit
- `damage` - The raw damage amount
- `armorPenetration` - Optional armor penetration (0-1, bypasses that % of armor)

**Returns:** `DamageResult` - The damage calculation result

**Example:**

```lua
-- Standard weapon hit
local result = Rewind.ApplyDamageWithArmor(target, "UpperTorso", 100)
print("Final damage:", result.finalDamage)

-- Armor-piercing weapon
local result = Rewind.ApplyDamageWithArmor(target, "UpperTorso", 100, 0.5)
-- Bypasses 50% of armor reduction
```

---

### RepairArmor

Repairs armor for an entity.

```lua
Rewind.RepairArmor(entity: Model, partName: string?, amount: number?): boolean
```

**Parameters:**

- `entity` - The entity to repair armor for
- `partName` - Optional specific part to repair (nil = all parts)
- `amount` - Optional repair amount (nil = full repair)

**Returns:** `boolean` - Whether any armor was repaired

**Example:**

```lua
-- Full repair all armor
Rewind.RepairArmor(player.Character)

-- Repair specific part
Rewind.RepairArmor(player.Character, "Head")

-- Partial repair
Rewind.RepairArmor(player.Character, "UpperTorso", 50)
```

---

## Integration with Hit Validation

Armor is automatically applied during hit validation:

```lua
local result = Rewind.Validate({
    shooter = player,
    target = targetPlayer,
    timestamp = os.clock(),
    origin = firePosition,
    direction = fireDirection,
    weapon = "rifle",
})

if result.valid then
    local armorResult = result.armorResult
    if armorResult then
        print("Original damage:", armorResult.originalDamage)
        print("After armor:", armorResult.finalDamage)
        print("Absorbed:", armorResult.absorbed)

        if armorResult.layerBroken then
            print("Armor layer broke!")
        end

        -- Apply the final damage
        target.Humanoid:TakeDamage(armorResult.finalDamage)
    else
        -- No armor on target
        target.Humanoid:TakeDamage(baseDamage)
    end
end
```

## Weapon Armor Penetration

Configure armor penetration in weapon profiles:

```lua
Rewind.RegisterProfile("armor_piercing_rifle", {
    maxDistance = 150,
    hitboxExpansion = 0.3,
    hitPriority = { head = 10, upperTorso = 5 },
    armorPenetration = 0.6, -- Bypasses 60% of armor
})

Rewind.RegisterProfile("standard_rifle", {
    maxDistance = 100,
    hitboxExpansion = 0.3,
    hitPriority = { head = 10, upperTorso = 5 },
    armorPenetration = 0.2, -- Bypasses 20% of armor
})

Rewind.RegisterProfile("knife", {
    maxDistance = 3,
    hitboxExpansion = 0.5,
    armorPenetration = 0, -- No armor penetration
})
```

## Armor Presets

### Light Armor

```lua
local function applyLightArmor(character)
    return Rewind.DefineArmor(character, {
        layers = {
            { partName = "UpperTorso", reduction = 0.2, maxHealth = 50, regeneration = 5 },
            { partName = "LowerTorso", reduction = 0.15, maxHealth = 40, regeneration = 4 },
        },
        regenerationDelay = 2,
    })
end
```

### Medium Armor

```lua
local function applyMediumArmor(character)
    return Rewind.DefineArmor(character, {
        layers = {
            { partName = "UpperTorso", reduction = 0.4, maxHealth = 100, regeneration = 3 },
            { partName = "LowerTorso", reduction = 0.3, maxHealth = 75, regeneration = 2 },
            { partName = "Head", reduction = 0.25, maxHealth = 50, breakThreshold = 0.3 },
        },
        regenerationDelay = 3,
    })
end
```

### Heavy Armor

```lua
local function applyHeavyArmor(character)
    return Rewind.DefineArmor(character, {
        layers = {
            { partName = "UpperTorso", reduction = 0.7, maxHealth = 200, regeneration = 2 },
            { partName = "LowerTorso", reduction = 0.6, maxHealth = 150, regeneration = 1.5 },
            { partName = "Head", reduction = 0.5, maxHealth = 100, breakThreshold = 0.2, brokenReduction = 0.1 },
            { partName = "LeftUpperArm", reduction = 0.4, maxHealth = 50 },
            { partName = "RightUpperArm", reduction = 0.4, maxHealth = 50 },
        },
        globalReduction = 0.1,
        regenerationDelay = 5,
    })
end
```

## Best Practices

### 1. Balance Armor with Weapon Penetration

```lua
-- Create a rock-paper-scissors dynamic
-- Heavy armor vs. standard weapons = armor wins
-- Heavy armor vs. armor-piercing = fair fight
-- Light armor vs. standard weapons = fair fight
-- Light armor vs. armor-piercing = weapons win
```

### 2. Use Break Thresholds for Feedback

```lua
Rewind.DefineArmor(character, {
    layers = {
        {
            partName = "UpperTorso",
            reduction = 0.5,
            maxHealth = 100,
            breakThreshold = 0.2, -- Breaks at 20%
            brokenReduction = 0.1, -- Still provides 10% when broken
        },
    },
    onLayerBroken = function(entity, partName)
        -- Visual feedback
        spawnArmorBreakParticles(entity, partName)
        playSound("ArmorBreak")

        -- Notify the player
        local player = Players:GetPlayerFromCharacter(entity)
        if player then
            notifyPlayer(player, "Your " .. partName .. " armor has broken!")
        end
    end,
})
```

### 3. Regeneration Balance

```lua
-- Fast regen for aggressive play
local aggressiveArmor = {
    regeneration = 10,
    regenerationDelay = 2,
}

-- Slow regen for tactical play
local tacticalArmor = {
    regeneration = 2,
    regenerationDelay = 5,
}
```

### 4. Combine with Vehicles

```lua
-- Vehicle has its own armor
Rewind.DefineArmor(tank, {
    layers = {
        { partName = "Hull", reduction = 0.9, maxHealth = 1000 },
        { partName = "Turret", reduction = 0.7, maxHealth = 500 },
        { partName = "Tracks", reduction = 0.3, maxHealth = 200, breakThreshold = 0.5 },
    },
    onLayerBroken = function(entity, partName)
        if partName == "Tracks" then
            -- Immobilize the tank
            disableVehicleMovement(entity)
        end
    end,
})
```
