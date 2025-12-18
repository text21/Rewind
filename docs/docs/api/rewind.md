---
sidebar_position: 1
---

# Rewind

The main entry point for the Rewind framework.

```lua
local Rewind = require(ReplicatedStorage.Rewind)
```

## Properties

### Version

```lua
Rewind.Version: string
```

The current version of Rewind.

---

### Server

```lua
Rewind.Server: ServerModule
```

Server-side module. See [Server API](./server).

---

### Client

```lua
Rewind.Client: ClientModule
```

Client-side module. See [Client API](./client).

---

### ClockSync

```lua
Rewind.ClockSync: ClockSyncModule
```

Clock synchronization module. See [ClockSync API](./clock-sync).

---

### Types

```lua
Rewind.Types: TypeDefinitions
```

Type definitions and enums. See [Types](./types).

---

### Config

```lua
Rewind.Config: ConfigTable
```

Configuration values. See [Config](./config).

---

### RigAdapter

```lua
Rewind.RigAdapter: RigAdapterModule
```

Character rig utilities. See [RigAdapter API](./rig-adapter).

---

### HitboxProfile

```lua
Rewind.HitboxProfile: HitboxProfiles
```

Built-in hitbox profiles. See [HitboxProfile](./hitbox-profile).

---

## Functions

### Validate

```lua
Rewind.Validate(
    player: Player,
    mode: ValidationMode,
    params: ValidationParams
): ValidationResult
```

High-level validation function that dispatches to the appropriate validator.

**Parameters:**

- `player` - The attacking player
- `mode` - Validation mode: `"Raycast"`, `"Projectile"`, `"Capsule"`, or `"Melee"`
- `params` - Validation parameters (varies by mode)

**Returns:** `ValidationResult` with accepted status, victims, and reason if rejected.

**Example:**

```lua
local result = Rewind.Validate(player, "Raycast", {
    origin = Vector3.new(0, 5, 0),
    direction = Vector3.new(0, 0, 100),
    targetIds = { 12345 },
    weaponId = "Rifle",
    timestamp = Rewind.ClockSync.ClientNow(),
})

if result.accepted then
    for _, victim in result.victims do
        print("Hit:", victim.player.Name)
    end
end
```

---

### CreateParamsFromWeapon

```lua
Rewind.CreateParamsFromWeapon(
    profile: WeaponProfile,
    baseParams: table
): ValidationParams
```

Creates validation parameters from a weapon profile.

**Parameters:**

- `profile` - The weapon profile to use
- `baseParams` - Base parameters (origin, direction, targetIds, timestamp)

**Returns:** Complete `ValidationParams` with weapon settings applied.

**Example:**

```lua
local rifleProfile = {
    maxDistance = 500,
    tolerance = 0.1,
    capsuleRadius = 0.3,
}

local params = Rewind.CreateParamsFromWeapon(rifleProfile, {
    origin = origin,
    direction = direction,
    targetIds = targets,
    timestamp = timestamp,
})
```

---

## Type Definitions

### ValidationMode

```lua
type ValidationMode = "Raycast" | "Projectile" | "Capsule" | "Melee"
```

### ValidationParams

```lua
type ValidationParams = {
    origin: Vector3,
    direction: Vector3,
    targetIds: { number },
    timestamp: number,
    weaponId: string?,
    maxDistance: number?,
    tolerance: number?,
    -- Mode-specific fields...
}
```

### ValidationResult

```lua
type ValidationResult = {
    accepted: boolean,
    victims: { Victim }?,
    reason: RejectReason?,
    debugInfo: table?,
}
```

### Victim

```lua
type Victim = {
    player: Player,
    character: Model,
    hitPart: string,
    hitPosition: Vector3,
}
```
