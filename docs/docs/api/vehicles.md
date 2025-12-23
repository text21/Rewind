# Vehicle Adapter

The Vehicle Adapter module provides vehicle and mount registration for hit validation. Register vehicles with custom hitboxes, damage multipliers, weak spots, and passenger protection.

## Overview

```lua
local Rewind = require(ReplicatedStorage.Packages.Rewind)

-- Register a vehicle
Rewind.RegisterVehicle(carModel, {
    maxPassengers = 4,
    hitboxes = {
        { part = carModel.Body, damageMultiplier = 1.0 },
        { part = carModel.Engine, damageMultiplier = 2.0, isWeakSpot = true },
        { part = carModel.Wheels, damageMultiplier = 0.5 },
    },
    passengerProtection = 0.5, -- 50% damage reduction for passengers
})

-- Register a mount
Rewind.RegisterMount(horseModel, {
    hitboxes = {
        { part = horseModel.Body, damageMultiplier = 1.0 },
        { part = horseModel.Head, damageMultiplier = 1.5 },
    },
    riderProtection = 0.25, -- 25% damage reduction for rider
})
```

## Types

### VehicleHitbox

```lua
type VehicleHitbox = {
    part: BasePart,              -- The hitbox part
    damageMultiplier: number?,   -- Damage multiplier (default 1.0)
    isWeakSpot: boolean?,        -- Is this a weak spot?
    priority: number?,           -- Hit priority (higher = preferred)
}
```

### VehicleConfig

```lua
type VehicleConfig = {
    maxPassengers: number?,      -- Max passengers (default 4)
    hitboxes: {VehicleHitbox}?,  -- Custom hitboxes
    passengerProtection: number?, -- Damage reduction for passengers (0-1)
    allowPassengerTargeting: boolean?, -- Can passengers be targeted?
    onDestroyed: ((vehicle: Model) -> ())?, -- Destruction callback
    onDamaged: ((vehicle: Model, damage: number, part: BasePart) -> ())?,
}
```

### MountConfig

```lua
type MountConfig = {
    hitboxes: {VehicleHitbox}?,  -- Custom hitboxes
    riderProtection: number?,    -- Damage reduction for rider (0-1)
    allowRiderTargeting: boolean?, -- Can rider be targeted?
    onDamaged: ((mount: Model, damage: number, part: BasePart) -> ())?,
}
```

### VehicleInfo

```lua
type VehicleInfo = {
    model: Model,
    config: VehicleConfig,
    passengers: {Player},
    health: number?,
    maxHealth: number?,
}
```

### MountInfo

```lua
type MountInfo = {
    model: Model,
    config: MountConfig,
    rider: Player?,
    health: number?,
}
```

## API Reference

### RegisterVehicle

Registers a vehicle model for hit validation.

```lua
Rewind.RegisterVehicle(model: Model, config: VehicleConfig?): VehicleInfo
```

**Parameters:**

- `model` - The vehicle model to register
- `config` - Optional vehicle configuration

**Returns:** `VehicleInfo` - The registered vehicle info

**Example:**

```lua
local tankInfo = Rewind.RegisterVehicle(tank, {
    maxPassengers = 3,
    hitboxes = {
        { part = tank.Hull, damageMultiplier = 0.5 },
        { part = tank.Turret, damageMultiplier = 1.0 },
        { part = tank.Engine, damageMultiplier = 3.0, isWeakSpot = true },
        { part = tank.Tracks, damageMultiplier = 1.5 },
    },
    passengerProtection = 0.8, -- 80% protection inside tank
    allowPassengerTargeting = false, -- Can't target crew directly
    onDestroyed = function(vehicle)
        -- Explode the tank
        createExplosion(vehicle.PrimaryPart.Position)
    end,
    onDamaged = function(vehicle, damage, part)
        -- Play damage effects
        playDamageEffect(part)
    end,
})
```

---

### UnregisterVehicle

Removes a vehicle from the registry.

```lua
Rewind.UnregisterVehicle(model: Model): boolean
```

**Parameters:**

- `model` - The vehicle model to unregister

**Returns:** `boolean` - Whether the vehicle was found and removed

---

### RegisterMount

Registers a mount (single rider) for hit validation.

```lua
Rewind.RegisterMount(model: Model, config: MountConfig?): MountInfo
```

**Parameters:**

- `model` - The mount model to register
- `config` - Optional mount configuration

**Returns:** `MountInfo` - The registered mount info

**Example:**

```lua
local horseInfo = Rewind.RegisterMount(horse, {
    hitboxes = {
        { part = horse.Body, damageMultiplier = 1.0 },
        { part = horse.Head, damageMultiplier = 1.5 },
        { part = horse.Legs, damageMultiplier = 0.75 },
    },
    riderProtection = 0.25,
    allowRiderTargeting = true, -- Rider can still be hit
})
```

---

### AddPassengerToVehicle

Adds a player as a passenger to a vehicle.

```lua
Rewind.AddPassengerToVehicle(vehicle: Model, player: Player, seatName: string?): boolean
```

**Parameters:**

- `vehicle` - The vehicle model
- `player` - The player to add as passenger
- `seatName` - Optional seat name to assign

**Returns:** `boolean` - Whether the passenger was added successfully

---

### RemovePassengerFromVehicle

Removes a player from a vehicle.

```lua
Rewind.RemovePassengerFromVehicle(vehicle: Model, player: Player): boolean
```

**Parameters:**

- `vehicle` - The vehicle model
- `player` - The player to remove

**Returns:** `boolean` - Whether the passenger was found and removed

---

### SetMountRider

Sets or clears the rider of a mount.

```lua
Rewind.SetMountRider(mount: Model, player: Player?): boolean
```

**Parameters:**

- `mount` - The mount model
- `player` - The player to set as rider, or nil to clear

**Returns:** `boolean` - Whether the operation succeeded

---

### GetPlayerVehicle

Gets the vehicle or mount a player is currently in.

```lua
Rewind.GetPlayerVehicle(player: Player): (Model?, "Vehicle" | "Mount" | nil)
```

**Parameters:**

- `player` - The player to check

**Returns:**

- `Model?` - The vehicle/mount model, or nil
- `string?` - The type ("Vehicle" or "Mount"), or nil

**Example:**

```lua
local vehicle, vehicleType = Rewind.GetPlayerVehicle(player)
if vehicle then
    if vehicleType == "Vehicle" then
        print(player.Name .. " is in a vehicle")
    else
        print(player.Name .. " is on a mount")
    end
end
```

---

## Integration with Hit Validation

When validating hits, Rewind automatically checks for vehicle hitboxes and applies the appropriate damage multipliers:

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
    if result.vehicle then
        -- Hit a vehicle
        print("Hit vehicle:", result.vehicle.Name)
        print("Part hit:", result.partHit.Name)
        print("Damage multiplier:", result.vehicleInfo.damageMultiplier)
    elseif result.armorResult then
        -- Hit through armor
        print("Final damage:", result.armorResult.finalDamage)
    end
end
```

## Best Practices

### 1. Use Weak Spots Strategically

```lua
Rewind.RegisterVehicle(helicopter, {
    hitboxes = {
        { part = helicopter.Body, damageMultiplier = 0.5 },
        { part = helicopter.Cockpit, damageMultiplier = 1.5 },
        { part = helicopter.TailRotor, damageMultiplier = 5.0, isWeakSpot = true },
        { part = helicopter.MainRotor, damageMultiplier = 3.0, isWeakSpot = true },
    },
})
```

### 2. Balance Passenger Protection

```lua
-- Light vehicle - less protection
Rewind.RegisterVehicle(jeep, {
    passengerProtection = 0.2,
    allowPassengerTargeting = true,
})

-- Heavy vehicle - more protection
Rewind.RegisterVehicle(apc, {
    passengerProtection = 0.7,
    allowPassengerTargeting = false,
})
```

### 3. Handle Vehicle Destruction

```lua
Rewind.RegisterVehicle(car, {
    onDestroyed = function(vehicle)
        -- Eject passengers
        for _, passenger in vehicle:GetPassengers() do
            Rewind.RemovePassengerFromVehicle(vehicle, passenger)
        end

        -- Destroy after delay
        task.delay(5, function()
            vehicle:Destroy()
        end)
    end,
})
```

### 4. Combine with Armor System

```lua
-- Register vehicle
Rewind.RegisterVehicle(tank, {
    hitboxes = {
        { part = tank.Hull, damageMultiplier = 1.0 },
        { part = tank.Turret, damageMultiplier = 1.5 },
    },
})

-- Add armor to vehicle parts
Rewind.DefineArmor(tank, {
    layers = {
        {
            partName = "Hull",
            reduction = 0.8, -- 80% damage reduction
            maxHealth = 500,
            regeneration = 5,
        },
        {
            partName = "Turret",
            reduction = 0.5,
            maxHealth = 200,
        },
    },
})
```
