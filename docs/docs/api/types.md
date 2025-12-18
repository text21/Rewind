---
sidebar_position: 2
---

# Types

Type definitions and enums used throughout Rewind.

```lua
local Types = require(ReplicatedStorage.Rewind.Types)
-- or
local Types = Rewind.Types
```

## Enums

### RejectReason

Reasons why a hit validation was rejected.

```lua
Types.RejectReason = {
    NoSnapshot = "NoSnapshot",         -- No snapshot data for timestamp
    TooFarBack = "TooFarBack",         -- Timestamp exceeds rewind window
    FutureTimestamp = "FutureTimestamp", -- Timestamp is in the future
    InvalidOrigin = "InvalidOrigin",   -- Origin position is suspicious
    Duplicate = "Duplicate",           -- Already processed this hit
    OutOfRange = "OutOfRange",         -- Target beyond weapon range
    NoLineOfSight = "NoLineOfSight",   -- Target not visible from origin
    InvalidTarget = "InvalidTarget",   -- Target doesn't exist or invalid
}
```

---

### ValidationMode

```lua
type ValidationMode = "Raycast" | "Projectile" | "Capsule" | "Melee"
```

| Mode         | Description                        |
| ------------ | ---------------------------------- |
| `Raycast`    | Instant hitscan validation         |
| `Projectile` | Travel-time projectile validation  |
| `Capsule`    | Capsule sweep for thick bullets    |
| `Melee`      | Cone-based melee attack validation |

---

## Type Definitions

### WeaponProfile

Configuration for a weapon's validation behavior.

```lua
type WeaponProfile = {
    -- Common fields
    maxDistance: number?,      -- Maximum effective range (default: 1000)
    tolerance: number?,        -- Hit tolerance in seconds (default: 0.1)
    scaleMultiplier: number?,  -- Hitbox scale multiplier (default: 1.0)
    isMelee: boolean?,         -- Is this a melee weapon? (default: false)

    -- Ranged weapon fields
    capsuleRadius: number?,    -- Capsule sweep radius (default: 0.3)
    capsuleSteps: number?,     -- Capsule interpolation steps (default: 10)

    -- Melee weapon fields
    meleeRange: number?,       -- Melee attack range (default: 5)
    meleeAngleDeg: number?,    -- Melee cone angle in degrees (default: 90)
    meleeRays: number?,        -- Number of rays in melee cone (default: 5)
}
```

---

### ValidationParams

Parameters passed to validation functions.

```lua
type ValidationParams = {
    origin: Vector3,           -- Shot origin position
    direction: Vector3,        -- Shot direction (or end point for projectiles)
    targetIds: { number },     -- Array of target UserIds
    timestamp: number,         -- Client timestamp of the attack
    weaponId: string?,         -- Weapon identifier for profile lookup
    maxDistance: number?,      -- Override max distance
    tolerance: number?,        -- Override tolerance

    -- Projectile-specific
    velocity: number?,         -- Projectile velocity (studs/sec)

    -- Capsule-specific
    capsuleRadius: number?,    -- Sweep radius
    capsuleSteps: number?,     -- Interpolation steps

    -- Melee-specific
    meleeRange: number?,       -- Attack range
    meleeAngleDeg: number?,    -- Cone angle
    meleeRays: number?,        -- Number of rays
}
```

---

### ValidationResult

Result returned from validation functions.

```lua
type ValidationResult = {
    accepted: boolean,         -- Whether the hit was accepted
    victims: { Victim }?,      -- Array of hit victims (if accepted)
    reason: RejectReason?,     -- Rejection reason (if not accepted)
    debugInfo: DebugInfo?,     -- Debug information (if debug mode)
}
```

---

### Victim

Information about a hit victim.

```lua
type Victim = {
    player: Player,            -- The victim player
    character: Model,          -- The victim's character
    hitPart: string,           -- Name of the hit body part
    hitPosition: Vector3,      -- World position of the hit
    damage: number?,           -- Suggested damage (if configured)
}
```

---

### Snapshot

A point-in-time record of player positions.

```lua
type Snapshot = {
    timestamp: number,         -- Server timestamp
    players: { [number]: PlayerPose }, -- UserId -> Pose mapping
}
```

---

### PlayerPose

A player's pose at a specific time.

```lua
type PlayerPose = {
    cframe: CFrame,            -- HumanoidRootPart CFrame
    velocity: Vector3,         -- Movement velocity
    parts: { [string]: PartPose }, -- Body part poses
    scale: number,             -- Character scale multiplier
}
```

---

### PartPose

A body part's pose.

```lua
type PartPose = {
    cframe: CFrame,            -- Part CFrame
    size: Vector3,             -- Part size
}
```

---

### HitboxDef

Definition of a hitbox in a profile.

```lua
type HitboxDef = {
    size: Vector3,             -- Hitbox size
    offset: Vector3?,          -- Offset from part center
    damageMultiplier: number?, -- Damage multiplier for this part
    priority: number?,         -- Hit detection priority
}
```

---

### DebugInfo

Debug information returned with validation results.

```lua
type DebugInfo = {
    timestamp: number,         -- Original timestamp
    serverTime: number,        -- Server time at validation
    rewindDelta: number,       -- Seconds rewound
    snapshotAge: number,       -- Age of used snapshot
    targetsChecked: number,    -- Number of targets checked
    rayscast: number,          -- Number of rays cast
    validationTime: number,    -- Time spent validating (ms)
}
```

---

## Usage Example

```lua
local Types = Rewind.Types

-- Check rejection reason
local result = Rewind.Validate(player, "Raycast", params)
if not result.accepted then
    if result.reason == Types.RejectReason.OutOfRange then
        print("Target was too far away")
    elseif result.reason == Types.RejectReason.Duplicate then
        print("Already hit this target")
    end
end

-- Create a weapon profile
local myWeapon: Types.WeaponProfile = {
    maxDistance = 200,
    tolerance = 0.1,
    capsuleRadius = 0.4,
    isMelee = false,
}
```
