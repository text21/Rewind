---
sidebar_position: 4
---

# Server

Server-side module for snapshot management and hit validation.

```lua
local Server = require(ReplicatedStorage.Rewind.Server)
-- or
local Server = Rewind.Server
```

## Functions

### Init

```lua
Server.Init(config: ServerConfig?): ()
```

Initialize the server module. Call this once at server startup.

**Parameters:**

- `config` - Optional configuration overrides

**Example:**

```lua
Server.Init({
    maxRewindTime = 1.0,
    snapshotRate = 20,
    debugMode = false,
    weaponProfiles = {
        Rifle = { maxDistance = 500 },
    },
})
```

---

### ValidateRaycast

```lua
Server.ValidateRaycast(
    player: Player,
    params: RaycastParams
): ValidationResult
```

Validate a raycast (hitscan) attack.

**Parameters:**

- `player` - The attacking player
- `params` - Raycast parameters

**Returns:** `ValidationResult`

**Example:**

```lua
local result = Server.ValidateRaycast(player, {
    origin = origin,
    direction = direction,
    targetIds = { targetPlayer.UserId },
    timestamp = timestamp,
    weaponId = "Rifle",
})
```

---

### ValidateProjectile

```lua
Server.ValidateProjectile(
    player: Player,
    params: ProjectileParams
): ValidationResult
```

Validate a projectile attack with travel time.

**Parameters:**

- `player` - The attacking player
- `params` - Projectile parameters

**Returns:** `ValidationResult`

**Example:**

```lua
local result = Server.ValidateProjectile(player, {
    origin = origin,
    direction = direction,
    velocity = 100, -- studs per second
    targetIds = { targetPlayer.UserId },
    timestamp = timestamp,
    weaponId = "RocketLauncher",
})
```

---

### ValidateCapsule

```lua
Server.ValidateCapsule(
    player: Player,
    params: CapsuleParams
): ValidationResult
```

Validate a capsule sweep (thick bullet).

**Parameters:**

- `player` - The attacking player
- `params` - Capsule parameters

**Returns:** `ValidationResult`

**Example:**

```lua
local result = Server.ValidateCapsule(player, {
    origin = origin,
    direction = direction,
    capsuleRadius = 0.5,
    capsuleSteps = 10,
    targetIds = { targetPlayer.UserId },
    timestamp = timestamp,
})
```

---

### ValidateMelee

```lua
Server.ValidateMelee(
    player: Player,
    params: MeleeParams
): ValidationResult
```

Validate a melee attack.

**Parameters:**

- `player` - The attacking player
- `params` - Melee parameters

**Returns:** `ValidationResult`

**Example:**

```lua
local result = Server.ValidateMelee(player, {
    origin = origin,
    lookVector = lookVector,
    meleeRange = 6,
    meleeAngleDeg = 90,
    meleeRays = 5,
    targetIds = { targetPlayer.UserId },
    timestamp = timestamp,
    weaponId = "Sword",
})
```

---

### UpdateWeaponProfile

```lua
Server.UpdateWeaponProfile(
    weaponId: string,
    profile: WeaponProfile
): ()
```

Update or add a weapon profile at runtime.

**Example:**

```lua
Server.UpdateWeaponProfile("Rifle", {
    maxDistance = 600, -- Increased range
    tolerance = 0.08,
})
```

---

### GetSnapshotAt

```lua
Server.GetSnapshotAt(timestamp: number): Snapshot?
```

Get the snapshot closest to the given timestamp.

**Returns:** `Snapshot` or `nil` if no valid snapshot exists.

---

### ForceSnapshot

```lua
Server.ForceSnapshot(): ()
```

Force an immediate snapshot capture (useful for testing).

---

## Events

### OnValidation

```lua
Server.OnValidation: Signal<ValidationResult>
```

Fired after every validation attempt.

**Example:**

```lua
Server.OnValidation:Connect(function(result)
    if result.accepted then
        print("Hit accepted!")
    else
        print("Hit rejected:", result.reason)
    end
end)
```

---

### OnValidationDebug

```lua
Server.OnValidationDebug: Signal<DebugInfo>
```

Fired with debug information after validation (when debugMode is enabled).

---

## Properties

### Stats

```lua
Server.Stats: StatsModule
```

Access to server statistics.

```lua
print(Server.Stats.GetValidationsPerSecond())
print(Server.Stats.GetAverageValidationTime())
print(Server.Stats.GetSnapshotCount())
```

---

## Type Definitions

### ServerConfig

```lua
type ServerConfig = {
    maxRewindTime: number?,
    snapshotRate: number?,
    maxOriginDrift: number?,
    debugMode: boolean?,
    verboseLogging: boolean?,
    weaponProfiles: { [string]: WeaponProfile }?,
}
```

### RaycastParams

```lua
type RaycastParams = {
    origin: Vector3,
    direction: Vector3,
    targetIds: { number },
    timestamp: number,
    weaponId: string?,
    maxDistance: number?,
    tolerance: number?,
}
```

### ProjectileParams

```lua
type ProjectileParams = RaycastParams & {
    velocity: number,
}
```

### CapsuleParams

```lua
type CapsuleParams = RaycastParams & {
    capsuleRadius: number?,
    capsuleSteps: number?,
}
```

### MeleeParams

```lua
type MeleeParams = {
    origin: Vector3,
    lookVector: Vector3,
    targetIds: { number },
    timestamp: number,
    weaponId: string?,
    meleeRange: number?,
    meleeAngleDeg: number?,
    meleeRays: number?,
}
```
