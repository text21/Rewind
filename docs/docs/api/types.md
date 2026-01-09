---
sidebar_position: 2
---

# Types

Type definitions and enums used throughout Rewind.

```lua
local Types = Rewind.Types
```

## Enums

### ValidationMode

```lua
type ValidationMode = "Ray" | "Sphere" | "Capsule" | "Cone" | "Fan"
```

| Mode      | Description                                          |
| --------- | ---------------------------------------------------- |
| `Ray`     | Instant hitscan raycast validation                   |
| `Sphere`  | Sphere overlap for explosions and AoE                |
| `Capsule` | Capsule sweep for thick bullets or projectile paths  |
| `Cone`    | Cone-based melee arc attack                          |
| `Fan`     | Multi-ray fan for sweeping melee attacks             |

---

### RejectReason

Reasons why a hit validation was rejected.

```lua
type RejectReason =
    | "rate_limited"      -- Player is firing too fast
    | "duplicate_shot"    -- Already processed this shotId
    | "no_hit"            -- No target was hit
    | "no_humanoid"       -- Hit target has no humanoid
    | "friendly_fire"     -- Target is on same team
    | "not_server"        -- Called from client (server only)
    | "out_of_range"      -- Target beyond weapon range
    | "invalid_params"    -- Invalid validation parameters
    | "vehicle_blocked"   -- Vehicle absorbed the hit
    | "armor_absorbed"    -- Armor fully absorbed damage
    | nil                 -- nil = success/hit
```

---

### EntityType

```lua
type EntityType = "Player" | "NPC" | "Vehicle" | "Mount"
```

---

### AbuseReason

```lua
type AbuseReason =
    | "rate_limited"
    | "duplicate_shot"
    | "impossible_distance"
    | "future_timestamp"
    | "past_timestamp"
    | "invalid_origin"
    | "speed_hack"
    | "teleport"
    | "fly_hack"
    | "invalid_target"
```

---

### AnomalyType

```lua
type AnomalyType =
    | "speed_hack"
    | "teleport"
    | "fly_hack"
    | "noclip"
    | "vertical_speed"
```

---

## Core Types

### Options

Configuration options for `Rewind.Start()`.

```lua
type Options = {
    enabled: boolean?,              -- Enable Rewind (default: true)
    snapshotHz: number?,            -- Snapshots per second (default: 20)
    windowMs: number?,              -- Snapshot window in ms (default: 1000)
    maxRewindMs: number?,           -- Max rewind allowed (default: 500)
    maxRayDistance: number?,        -- Max ray length (default: 1000)
    allowHeadshots: boolean?,       -- Enable headshot detection
    friendlyFire: boolean?,         -- Allow team damage
    teamCheck: boolean?,            -- Enable team checking
    antiSpam: {
        perSecond: number,
        burst: number,
    }?,
    mode: "Analytic" | "GhostParts"?,
    debug: {
        enabled: boolean?,
    }?,
    replication: ReplicationConfig?,
    movement: MovementConfig?,
    abuse: AbuseConfig?,
}
```

---

### HitResult

Result returned from all validation functions.

```lua
type HitResult = {
    hit: boolean,                   -- Whether the hit was valid
    character: Model?,              -- Hit character model
    humanoid: Humanoid?,            -- Hit humanoid
    player: Player?,                -- Hit player (nil for NPCs)
    part: BasePart?,                -- Hit body part
    partName: string?,              -- Name of hit part
    hitPosition: Vector3?,          -- World hit position
    hitNormal: Vector3?,            -- Hit surface normal
    serverNow: number,              -- Server timestamp
    rewindTo: number,               -- Timestamp rewound to
    usedRewindMs: number,           -- Amount of rewind used
    isHeadshot: boolean?,           -- Was it a headshot
    reason: RejectReason,           -- Rejection reason (nil = success)
    
    -- Vehicle hits
    vehicle: Model?,                -- Hit vehicle model
    vehicleInfo: VehicleInfo?,      -- Vehicle details
    
    -- Armor
    armorResult: DamageResult?,     -- Armor calculation result
}
```

---

### WeaponProfile

Configuration for a weapon.

```lua
type WeaponProfile = {
    id: string,                     -- Unique weapon ID
    maxRewindMs: number?,           -- Override max rewind
    maxDistance: number?,           -- Max effective range
    extraForgivenessStuds: number?, -- Extra hit tolerance
    
    -- Melee weapons
    meleeRange: number?,
    meleeAngleDeg: number?,
    meleeRays: number?,
    isMelee: boolean?,
    
    -- Capsule weapons
    capsuleRadius: number?,
    capsuleSteps: number?,
    
    -- Other
    requireLineOfSight: boolean?,
    scaleMultiplier: number?,
    armorPenetration: number?,      -- Bypass armor %
}
```

---

## Validation Parameter Types

### ValidateRayParams

```lua
type ValidateRayParams = {
    weaponId: string?,
    origin: Vector3,
    direction: Vector3,
    clientTime: number?,
    clientShotId: string?,
    ignore: { Instance }?,
}
```

---

### ValidateSphereParams

```lua
type ValidateSphereParams = {
    weaponId: string?,
    center: Vector3,
    radius: number,
    clientTime: number?,
    clientShotId: string?,
    ignore: { Instance }?,
}
```

---

### ValidateCapsuleParams

```lua
type ValidateCapsuleParams = {
    weaponId: string?,
    a: Vector3,                     -- Start point
    b: Vector3,                     -- End point
    radius: number,
    steps: number?,                 -- Interpolation steps
    clientTime: number?,
    clientShotId: string?,
    ignore: { Instance }?,
}
```

---

### ValidateArcParams / ValidateMeleeArcParams

```lua
type ValidateArcParams = {
    weaponId: string?,
    origin: CFrame,
    range: number,
    angleDeg: number,
    clientTime: number?,
    clientShotId: string?,
}

type ValidateMeleeArcParams = ValidateArcParams
```

---

### ValidateFanParams / ValidateMeleeFanParams

```lua
type ValidateFanParams = {
    weaponId: string?,
    origin: CFrame,
    range: number,
    angleDeg: number,
    rays: number,
    clientTime: number?,
    clientShotId: string?,
}

type ValidateMeleeFanParams = ValidateFanParams
```

---

### ValidateParams

Generic validation parameters for `Rewind.Validate()`.

```lua
type ValidateParams = {
    mode: ValidationMode,
    weaponId: string?,
    clientTime: number?,
    clientShotId: string?,
    
    -- Ray
    origin: (Vector3 | CFrame)?,
    direction: Vector3?,
    
    -- Sphere
    center: Vector3?,
    radius: number?,
    
    -- Capsule
    a: Vector3?,
    b: Vector3?,
    steps: number?,
    
    -- Cone/Fan
    range: number?,
    angleDeg: number?,
    rays: number?,
}
```

---

## Replication Types

### ReplicationConfig

```lua
type ReplicationConfig = {
    enabled: boolean?,
    tickRate: number?,              -- Updates per second
    interpolationDelay: number?,    -- Interpolation buffer (ms)
    maxExtrapolation: number?,      -- Max extrapolation (ms)
    
    deltaCompression: boolean?,
    proximityBased: boolean?,
    nearDistance: number?,
    farDistance: number?,
    farTickDivisor: number?,
    
    clientAuthoritative: boolean?,
    reconciliationThreshold: number?,
}
```

---

### EntityInfo

```lua
type EntityInfo = {
    id: string,
    entityType: EntityType,
    model: Model,
    player: Player?,
    priority: number,
    lastUpdate: number,
}
```

---

### EntityState

```lua
type EntityState = {
    t: number,                      -- Timestamp
    rootCf: CFrame,                 -- Root CFrame
    velocity: Vector3,
    parts: { [string]: CFrame }?,   -- Optional part CFrames
}
```

---

### CompressedState

```lua
type CompressedState = {
    t: number,
    pos: Vector3,
    rot: { number },                -- Compressed rotation
    vel: Vector3?,
}
```

---

### InterpolationState

```lua
type InterpolationState = {
    entity: EntityInfo,
    buffer: { EntityState },
    bufferSize: number,
    renderTime: number,
    lastReceivedTime: number,
}
```

---

## Vehicle & Mount Types

### VehicleConfig

```lua
type VehicleConfig = {
    hitboxes: { [string]: VehicleHitbox }?,
    hitboxProfile: string?,
    protectsPassengers: boolean?,
    damageMultiplier: number?,
    health: number?,
}
```

---

### VehicleHitbox

```lua
type VehicleHitbox = {
    size: Vector3,
    offset: Vector3?,
    damageMultiplier: number?,
    isWeakSpot: boolean?,
}
```

---

### VehicleInfo

```lua
type VehicleInfo = {
    id: string,
    model: Model,
    config: VehicleConfig,
    passengers: { Player },
    health: number,
    maxHealth: number,
    destroyed: boolean,
}
```

---

### MountConfig

```lua
type MountConfig = {
    hitboxProfile: string?,
    exposeRider: boolean?,
    riderOffset: Vector3?,
}
```

---

### MountInfo

```lua
type MountInfo = {
    id: string,
    model: Model,
    config: MountConfig,
    rider: Player?,
}
```

---

## Armor Types

### ArmorConfig

```lua
type ArmorConfig = {
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
```

---

### ArmorLayer

```lua
type ArmorLayer = {
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
```

---

### ArmorState

```lua
type ArmorState = {
    entityId: string,
    model: Model,
    layers: { ArmorLayer },
}
```

---

### DamageResult

```lua
type DamageResult = {
    finalDamage: number,
    armorDamage: number,
    brokenLayers: { string },
    penetrated: boolean,
}
```

---

## Abuse Tracking Types

### AbuseConfig

```lua
type AbuseConfig = {
    enabled: boolean?,
    useDataStore: boolean?,
    dataStoreName: string?,
    thresholds: {
        warnAt: number?,
        kickAt: number?,
        banAt: number?,
    }?,
    autoKick: boolean?,
    autoBan: boolean?,
    saveInterval: number?,
}
```

---

### AbuseRecord

```lua
type AbuseRecord = {
    reason: AbuseReason,
    count: number,
    firstOccurrence: number,
    lastOccurrence: number,
    metadata: { [string]: any }?,
}
```

---

### PlayerAbuseHistory

```lua
type PlayerAbuseHistory = {
    playerId: number,
    playerName: string,
    records: { [string]: AbuseRecord },
    totalViolations: number,
    sessionViolations: number,
    isBanned: boolean,
    lastSeen: number,
}
```

---

## Movement Validation Types

### MovementConfig

```lua
type MovementConfig = {
    maxSpeed: number?,
    maxVerticalSpeed: number?,
    teleportThreshold: number?,
    flyCheckInterval: number?,
    maxAirTime: number?,
    noclipCheckEnabled: boolean?,
    speedTolerance: number?,
    enableMonitoring: boolean?,
}
```

---

### MovementValidationResult

```lua
type MovementValidationResult = {
    valid: boolean,
    anomaly: AnomalyType?,
    details: {
        speed: number?,
        distance: number?,
        airTime: number?,
        expectedMax: number?,
    }?,
}
```

---

### PlayerMovementState

```lua
type PlayerMovementState = {
    lastPosition: Vector3,
    lastTimestamp: number,
    airStartTime: number?,
    isInAir: boolean,
    violations: {
        speed: number,
        teleport: number,
        fly: number,
        noclip: number,
    },
    lastGroundPosition: Vector3?,
}
```

---

## Hitbox Profile Types

### Profile

```lua
type Profile = {
    id: string,
    parts: { string },
    forgiveness: { [string]: number }?,
    hitPriority: { [string]: HitPriority }?,
}
```

---

### HitPriority

```lua
type HitPriority = {
    partName: string,
    priority: number,
    damageMultiplier: number?,
}
```
