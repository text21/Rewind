---
sidebar_position: 1
---

# Rewind

The main entry point for the Rewind framework.

```lua
local Rewind = require(ReplicatedStorage.Packages.Rewind)
```

## Properties

### Version

```lua
Rewind.Version: string -- e.g., "1.2.0"
```

The current version of Rewind.

---

### VersionName

```lua
Rewind.VersionName: string -- e.g., "Anti-Cheat & Vehicles"
```

The name of the current version.

---

### ClockSync

```lua
Rewind.ClockSync: ClockSyncModule
```

Clock synchronization module. See [ClockSync API](/docs/api/clock-sync).

---

### Types

```lua
Rewind.Types: TypeDefinitions
```

Type definitions and enums. See [Types](/docs/api/types).

---

### Config

```lua
Rewind.Config: ConfigTable
```

Configuration values. See [Config](/docs/api/config).

---

### RigAdapter

```lua
Rewind.RigAdapter: RigAdapterModule
```

Character rig utilities. See [RigAdapter API](/docs/api/rig-adapter).

---

### HitboxProfile

```lua
Rewind.HitboxProfile: HitboxProfileModule
```

Hitbox profile management. See [HitboxProfile](/docs/api/hitbox-profile).

---

### Replication

```lua
Rewind.Replication: ReplicationModule
```

Custom character replication system. See [Replication](/docs/api/replication).

---

### VehicleAdapter

```lua
Rewind.VehicleAdapter: VehicleAdapterModule
```

Vehicle and mount registration. See [Vehicles](/docs/api/vehicles).

---

### ArmorSystem (Server Only)

```lua
Rewind.ArmorSystem: ArmorSystemModule?
```

Armor layer system. Only available on server. See [Armor](/docs/api/armor).

---

### AbuseTracker (Server Only)

```lua
Rewind.AbuseTracker: AbuseTrackerModule?
```

Abuse tracking with DataStore. Only available on server. See [Abuse Tracker](/docs/api/abuse-tracker).

---

### MovementValidator (Server Only)

```lua
Rewind.MovementValidator: MovementValidatorModule?
```

Movement anomaly detection. Only available on server. See [Movement Validator](/docs/api/movement-validator).

---

## Core Functions

### Start

```lua
Rewind.Start(opts: Options?): ()
```

Initialize the Rewind server. Call this once on server startup.

**Parameters:**

- `opts` - Optional configuration overrides

**Example:**

```lua
Rewind.Start({
    snapshotHz = 30,      -- Snapshots per second
    windowMs = 1000,      -- Snapshot window in ms
    maxRewindMs = 500,    -- Max rewind allowed
    maxRayDistance = 1000,
    friendlyFire = false,
    teamCheck = true,
})
```

---

### Stop

```lua
Rewind.Stop(): ()
```

Stop the Rewind server.

---

### GetOptions

```lua
Rewind.GetOptions(): Options
```

Get the current configuration options.

---

### Configure

```lua
Rewind.Configure(opts: Options): ()
```

Update configuration options at runtime.

---

### ServerNow

```lua
Rewind.ServerNow(): number
```

Get the current server time.

---

## Validation Functions

### Validate

```lua
Rewind.Validate(
    player: Player,
    mode: ValidationMode,
    params: ValidateParams
): HitResult
```

High-level validation dispatcher.

**Parameters:**

- `player` - The attacking player
- `mode` - `"Ray"`, `"Sphere"`, `"Capsule"`, `"Cone"`, or `"Fan"`
- `params` - Validation parameters (varies by mode)

**Returns:** `HitResult`

**Example:**

```lua
local result = Rewind.Validate(player, "Ray", {
    origin = firePosition,
    direction = fireDirection,
    clientTime = timestamp,
    weaponId = "Rifle",
})

if result.hit then
    result.humanoid:TakeDamage(25)
end
```

---

### ValidateRay

```lua
Rewind.ValidateRay(player: Player, params: ValidateRayParams): HitResult
```

Validate a raycast (hitscan) attack.

**Parameters:**

```lua
type ValidateRayParams = {
    origin: Vector3,
    direction: Vector3,
    clientTime: number?,
    clientShotId: string?,
    weaponId: string?,
    ignore: { Instance }?,
}
```

**Example:**

```lua
local result = Rewind.ValidateRay(player, {
    origin = gun.Muzzle.Position,
    direction = lookVector * 1000,
    clientTime = timestamp,
    weaponId = "Rifle",
})
```

---

### ValidateSphere

```lua
Rewind.ValidateSphere(player: Player, params: ValidateSphereParams): HitResult
```

Validate a sphere overlap (explosions, AoE).

**Parameters:**

```lua
type ValidateSphereParams = {
    center: Vector3,
    radius: number,
    clientTime: number?,
    clientShotId: string?,
    weaponId: string?,
    ignore: { Instance }?,
}
```

**Example:**

```lua
local result = Rewind.ValidateSphere(player, {
    center = explosionPosition,
    radius = 15,
    clientTime = timestamp,
})
```

---

### ValidateCapsule

```lua
Rewind.ValidateCapsule(player: Player, params: ValidateCapsuleParams): HitResult
```

Validate a capsule sweep (thick bullets, projectile paths).

**Parameters:**

```lua
type ValidateCapsuleParams = {
    a: Vector3,           -- Start point
    b: Vector3,           -- End point
    radius: number,
    steps: number?,       -- Interpolation steps
    clientTime: number?,
    clientShotId: string?,
    weaponId: string?,
    ignore: { Instance }?,
}
```

**Example:**

```lua
local result = Rewind.ValidateCapsule(player, {
    a = startPosition,
    b = endPosition,
    radius = 0.5,
    steps = 10,
    clientTime = timestamp,
})
```

---

### ValidateMeleeArc / ValidateCone

```lua
Rewind.ValidateMeleeArc(player: Player, params: ValidateMeleeArcParams): HitResult
Rewind.ValidateCone(player: Player, params: ValidateMeleeArcParams): HitResult
```

Validate a melee arc/cone attack.

**Parameters:**

```lua
type ValidateMeleeArcParams = {
    origin: CFrame,
    range: number,
    angleDeg: number,
    clientTime: number?,
    clientShotId: string?,
    weaponId: string?,
}
```

**Example:**

```lua
local result = Rewind.ValidateMeleeArc(player, {
    origin = character.HumanoidRootPart.CFrame,
    range = 6,
    angleDeg = 90,
    clientTime = timestamp,
    weaponId = "Sword",
})
```

---

### ValidateMeleeFan / ValidateFan

```lua
Rewind.ValidateMeleeFan(player: Player, params: ValidateMeleeFanParams): HitResult
Rewind.ValidateFan(player: Player, params: ValidateMeleeFanParams): HitResult
```

Validate a melee fan attack (multiple rays in a cone).

**Parameters:**

```lua
type ValidateMeleeFanParams = {
    origin: CFrame,
    range: number,
    angleDeg: number,
    rays: number,         -- Number of rays in the fan
    clientTime: number?,
    clientShotId: string?,
    weaponId: string?,
}
```

---

## Character Registration

### RegisterCharacter

```lua
Rewind.RegisterCharacter(character: Model, profileId: string?): ()
```

Register a character for hit validation.

**Parameters:**

- `character` - The character model
- `profileId` - Optional hitbox profile ID (auto-detects R6/R15 if nil)

---

### UnregisterCharacter

```lua
Rewind.UnregisterCharacter(character: Model): ()
```

Unregister a character.

---

### RegisterNPC

```lua
Rewind.RegisterNPC(model: Model, profileId: string?): ()
```

Register an NPC for hit validation.

---

## Weapon Profiles

### DefineWeapon

```lua
Rewind.DefineWeapon(profile: WeaponProfile): ()
```

Define a weapon profile.

**Example:**

```lua
Rewind.DefineWeapon({
    id = "Rifle",
    maxDistance = 500,
    maxRewindMs = 200,
    capsuleRadius = 0.3,
})
```

---

### GetWeapon

```lua
Rewind.GetWeapon(id: string): WeaponProfile?
```

Get a weapon profile by ID.

---

### DefineHitboxProfile

```lua
Rewind.DefineHitboxProfile(id: string, def: Profile): ()
```

Define a custom hitbox profile.

**Example:**

```lua
Rewind.DefineHitboxProfile("CustomRig", {
    parts = { "Head", "Core", "LeftWing", "RightWing" },
    hitPriority = {
        Head = { priority = 10, damageMultiplier = 2.0 },
        Core = { priority = 5, damageMultiplier = 1.0 },
    },
})
```

---

### CreateParamsFromWeapon

```lua
Rewind.CreateParamsFromWeapon(weaponId: string, baseParams: table): table
```

Create validation params from a weapon profile.

---

## Replication Functions

### StartReplication

```lua
Rewind.StartReplication(config: ReplicationConfig?): ()
```

Start the server-side replication system.

---

### StartReplicationClient

```lua
Rewind.StartReplicationClient(config: ReplicationConfig?): ()
```

Start the client-side interpolation system.

---

### RegisterPlayerForReplication

```lua
Rewind.RegisterPlayerForReplication(player: Player, priority: number?): ()
```

Register a player for custom replication.

---

### RegisterNPCForReplication

```lua
Rewind.RegisterNPCForReplication(model: Model, priority: number?): ()
```

Register an NPC for custom replication.

---

### UnregisterFromReplication

```lua
Rewind.UnregisterFromReplication(modelOrPlayer: Model | Player): ()
```

Unregister from custom replication.

---

## Vehicle Functions

See [Vehicles API](/docs/api/vehicles) for full documentation.

```lua
Rewind.RegisterVehicle(model, config)
Rewind.UnregisterVehicle(model)
Rewind.RegisterMount(model, config)
Rewind.AddPassengerToVehicle(player, vehicle)
Rewind.RemovePassengerFromVehicle(player)
Rewind.SetMountRider(player, mount)
Rewind.GetPlayerVehicle(player)
```

---

## Armor Functions

See [Armor API](/docs/api/armor) for full documentation.

```lua
Rewind.DefineArmor(model, config, entityId?)
Rewind.RemoveArmor(model)
Rewind.GetArmor(model)
Rewind.ApplyDamageWithArmor(model, partName, rawDamage)
Rewind.RepairArmor(model, layerName?, amount?)
```

---

## Abuse Tracker Functions

See [Abuse Tracker API](/docs/api/abuse-tracker) for full documentation.

```lua
Rewind.StartAbuseTracking(config?)
Rewind.RecordAbuse(player, reason, metadata?)
Rewind.GetAbuseHistory(player)
Rewind.IsPlayerBanned(userId)
Rewind.BanPlayer(userId, reason?)
Rewind.UnbanPlayer(userId)

-- Events
Rewind.OnAbuseDetected       -- Signal<Player, AbuseReason, metadata>
Rewind.OnAbuseThresholdReached -- Signal<Player, threshold, count>
```

---

## Movement Validator Functions

See [Movement Validator API](/docs/api/movement-validator) for full documentation.

```lua
Rewind.ConfigureMovementValidation(config?)
Rewind.StartMovementMonitoring()
Rewind.StopMovementMonitoring()
Rewind.ValidateMovement(player, fromPos, toPos, deltaTime)
Rewind.SetPlayerSpeedMultiplier(player, multiplier)
Rewind.GetMovementViolations(player)
Rewind.ClearMovementViolations(player)

-- Events
Rewind.OnMovementAnomaly -- Signal<Player, AnomalyType, details>
```

---

## Type Definitions

### HitResult

```lua
type HitResult = {
    hit: boolean,
    character: Model?,
    humanoid: Humanoid?,
    player: Player?,
    part: BasePart?,
    partName: string?,
    hitPosition: Vector3?,
    hitNormal: Vector3?,
    serverNow: number,
    rewindTo: number,
    usedRewindMs: number,
    isHeadshot: boolean?,
    reason: RejectReason,
    vehicle: Model?,
    vehicleInfo: VehicleInfo?,
    armorResult: DamageResult?,
}
```

### RejectReason

```lua
type RejectReason =
    | "rate_limited"
    | "duplicate_shot"
    | "no_hit"
    | "no_humanoid"
    | "friendly_fire"
    | "not_server"
    | "out_of_range"
    | "invalid_params"
    | "vehicle_blocked"
    | "armor_absorbed"
    | nil  -- nil = success/hit
```

### ValidationMode

```lua
type ValidationMode = "Ray" | "Sphere" | "Capsule" | "Cone" | "Fan"
```
