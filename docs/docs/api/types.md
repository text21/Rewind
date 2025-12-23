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

## Replication Types (v1.1.0)

### EntityType

```lua
type EntityType = "Player" | "NPC"
```

### EntityInfo

Information about a registered entity.

```lua
type EntityInfo = {
    id: string,              -- Unique entity ID (e.g., "player_123")
    entityType: EntityType,  -- "Player" or "NPC"
    model: Model,            -- The character/NPC model
    player: Player?,         -- Player instance (nil for NPCs)
    priority: number,        -- Bandwidth priority (higher = more updates)
    lastUpdate: number,      -- Last update timestamp
}
```

### EntityState

Captured state of an entity at a point in time.

```lua
type EntityState = {
    t: number,                      -- Server timestamp
    rootCf: CFrame,                 -- HumanoidRootPart CFrame
    velocity: Vector3,              -- Movement velocity
    parts: { [string]: CFrame }?,   -- Optional detailed part CFrames
}
```

### CompressedState

Network-optimized entity state.

```lua
type CompressedState = {
    t: number,             -- Server timestamp
    pos: Vector3,          -- Position
    rot: { number },       -- Euler angles {rx, ry, rz}
    vel: Vector3?,         -- Velocity (optional)
}
```

### ReplicationConfig

Configuration for the replication system.

```lua
type ReplicationConfig = {
    enabled: boolean?,               -- Enable replication (default: true)
    tickRate: number?,               -- Updates per second (default: 20)
    interpolationDelay: number?,     -- Client render delay in ms (default: 100)
    maxExtrapolation: number?,       -- Max prediction time in ms (default: 200)

    -- Bandwidth optimization
    deltaCompression: boolean?,      -- Only send changes (default: true)
    proximityBased: boolean?,        -- Reduce distant updates (default: true)
    nearDistance: number?,           -- Full update distance (default: 100)
    farDistance: number?,            -- Minimum update distance (default: 500)
    farTickDivisor: number?,         -- Far entity tick divisor (default: 4)

    -- Network ownership
    clientAuthoritative: boolean?,   -- Client controls own movement (default: true)
    reconciliationThreshold: number?, -- Drift before correction (default: 5)
}
```

### HitPriority

Per-part hit priority configuration.

```lua
type HitPriority = {
    priority: number,          -- Higher = preferred target
    damageMultiplier: number?, -- Optional damage scaling
}
```

---

## Vehicle Types (v1.2.0)

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

---

## Armor Types (v1.2.0)

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

---

## Abuse Tracker Types (v1.2.0)

### AbuseReason

```lua
type AbuseReason =
    | "speed_hack"          -- Moving faster than allowed
    | "teleport"            -- Sudden position change
    | "aimbot"              -- Suspicious aim patterns
    | "damage_exploit"      -- Invalid damage values
    | "clip"                -- Moving through solid objects
    | "fly_hack"            -- Flying without permission
    | "packet_manipulation" -- Invalid network packets
```

### AbuseRecord

```lua
type AbuseRecord = {
    reason: AbuseReason,    -- Type of abuse
    timestamp: number,      -- When it occurred
    details: {[string]: any}?, -- Additional details
    sessionId: string?,     -- Game session ID
}
```

### PlayerAbuseHistory

```lua
type PlayerAbuseHistory = {
    userId: number,
    totalIncidents: number,
    records: {AbuseRecord},
    isBanned: boolean,
    banExpiry: number?,     -- Unix timestamp when ban expires
    banReason: string?,
    firstIncident: number?, -- Timestamp of first incident
    lastIncident: number?,  -- Timestamp of most recent
}
```

### AbuseConfig

```lua
type AbuseConfig = {
    dataStoreName: string?, -- DataStore name (default "RewindAbuseTracker")
    thresholds: {
        warn: number?,      -- Incidents before warning (default 3)
        kick: number?,      -- Incidents before kick (default 5)
        ban: number?,       -- Incidents before ban (default 10)
    }?,
    autoKick: boolean?,     -- Auto-kick at threshold (default true)
    autoBan: boolean?,      -- Auto-ban at threshold (default true)
    banDuration: number?,   -- Ban duration in seconds (default 7 days)
    resetAfter: number?,    -- Reset incidents after X seconds (default nil = never)
    persistLocally: boolean?, -- Also cache locally (default true)
}
```

---

## Movement Validator Types (v1.2.0)

### AnomalyType

```lua
type AnomalyType =
    | "speed_hack"   -- Moving faster than allowed
    | "teleport"     -- Sudden large position change
    | "fly_hack"     -- Sustained air time without ground contact
    | "noclip"       -- Moving through solid objects
```

### MovementValidationResult

```lua
type MovementValidationResult = {
    valid: boolean,           -- Whether movement is valid
    anomalyType: AnomalyType?, -- Type of anomaly if invalid
    details: {
        currentSpeed: number?,
        maxAllowedSpeed: number?,
        distanceMoved: number?,
        airTime: number?,
        collidedPart: BasePart?,
    }?,
}
```

### MovementConfig

```lua
type MovementConfig = {
    speedTolerance: number?,      -- Multiplier above base speed (default 1.2)
    teleportThreshold: number?,   -- Distance in studs (default 50)
    maxAirTime: number?,          -- Seconds before fly detection (default 3)
    checkNoclip: boolean?,        -- Check for noclip (default true)
    checkInterval: number?,       -- How often to check (default 0.1)
    violationThreshold: number?,  -- Violations before flagging (default 3)
    baseWalkSpeed: number?,       -- Base walk speed (default 16)
    baseJumpPower: number?,       -- Base jump power (default 50)
    groundRayDistance: number?,   -- Ray distance for ground check (default 5)
    noclipRayDistance: number?,   -- Ray distance for noclip check (default 2)
}
```

### PlayerMovementState

```lua
type PlayerMovementState = {
    player: Player,
    lastPosition: Vector3,
    lastGroundedTime: number,
    lastValidationTime: number,
    airTime: number,
    violations: {
        speed: number,
        teleport: number,
        fly: number,
        noclip: number,
    },
    speedMultiplier: number, -- Current speed multiplier (for abilities)
    isMonitoring: boolean,
}
```

---

## Updated Types (v1.2.0)

### EntityType (Updated)

```lua
type EntityType = "Player" | "NPC" | "Vehicle" | "Mount"
```

### RejectReason (Updated)

```lua
Types.RejectReason = {
    -- Existing reasons
    NoSnapshot = "NoSnapshot",
    TooFarBack = "TooFarBack",
    FutureTimestamp = "FutureTimestamp",
    InvalidOrigin = "InvalidOrigin",
    Duplicate = "Duplicate",
    OutOfRange = "OutOfRange",
    NoLineOfSight = "NoLineOfSight",
    InvalidTarget = "InvalidTarget",

    -- v1.2.0 additions
    VehicleBlocked = "vehicle_blocked",   -- Vehicle absorbed the hit
    ArmorAbsorbed = "armor_absorbed",     -- Armor absorbed all damage
}
```

### WeaponProfile (Updated)

```lua
type WeaponProfile = {
    -- Existing fields...
    maxDistance: number?,
    tolerance: number?,
    scaleMultiplier: number?,
    isMelee: boolean?,
    capsuleRadius: number?,
    capsuleSteps: number?,
    meleeRange: number?,
    meleeAngleDeg: number?,
    meleeRays: number?,

    -- v1.1.0 additions
    hitPriority: { [string]: HitPriority }?,

    -- v1.2.0 additions
    armorPenetration: number?, -- 0-1, bypasses that % of armor
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

-- v1.1.0: Configure replication
local replicationConfig: Types.ReplicationConfig = {
    tickRate = 20,
    deltaCompression = true,
    proximityBased = true,
}
Rewind.StartReplication(replicationConfig)

-- v1.2.0: Register vehicle with armor
local vehicleConfig: Types.VehicleConfig = {
    maxPassengers = 4,
    passengerProtection = 0.5,
    hitboxes = {
        { part = car.Body, damageMultiplier = 1.0 },
        { part = car.Engine, damageMultiplier = 2.0, isWeakSpot = true },
    },
}
Rewind.RegisterVehicle(car, vehicleConfig)

-- v1.2.0: Define armor
local armorConfig: Types.ArmorConfig = {
    layers = {
        { partName = "UpperTorso", reduction = 0.5, maxHealth = 100 },
        { partName = "Head", reduction = 0.3, maxHealth = 50 },
    },
}
Rewind.DefineArmor(player.Character, armorConfig)

-- v1.2.0: Start abuse tracking
local abuseConfig: Types.AbuseConfig = {
    thresholds = { warn = 3, kick = 5, ban = 10 },
    autoKick = true,
    autoBan = true,
}
Rewind.StartAbuseTracking(abuseConfig)

-- v1.2.0: Configure movement validation
local movementConfig: Types.MovementConfig = {
    speedTolerance = 1.2,
    teleportThreshold = 50,
    maxAirTime = 3,
}
Rewind.ConfigureMovementValidation(movementConfig)
```
