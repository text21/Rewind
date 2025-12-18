---
sidebar_position: 3
---

# Config

Configuration values for Rewind. Modify these before calling `Init()`.

```lua
local Config = require(ReplicatedStorage.Rewind.Config)
-- or
local Config = Rewind.Config
```

## Server Configuration

### MaxRewindTime

```lua
Config.MaxRewindTime: number = 1.0
```

Maximum time in seconds that the server can rewind. Attacks with timestamps older than this are rejected.

---

### SnapshotRate

```lua
Config.SnapshotRate: number = 20
```

How many snapshots per second to capture. Higher values = more accurate but more memory.

---

### MaxSnapshots

```lua
Config.MaxSnapshots: number = 30
```

Maximum number of snapshots to store in the ring buffer. Calculated as `MaxRewindTime * SnapshotRate * 1.5`.

---

### MaxOriginDrift

```lua
Config.MaxOriginDrift: number = 10
```

Maximum allowed distance between claimed origin and actual player position. Used for anti-abuse.

---

### DebugMode

```lua
Config.DebugMode: boolean = false
```

Enable debug logging and visualization.

---

### VerboseLogging

```lua
Config.VerboseLogging: boolean = false
```

Enable detailed console logging for every validation.

---

## Clock Sync Configuration

### ClockSync.SampleCount

```lua
Config.ClockSync.SampleCount: number = 8
```

Number of ping samples to collect before calculating offset.

---

### ClockSync.SyncInterval

```lua
Config.ClockSync.SyncInterval: number = 5.0
```

Seconds between periodic resyncs after initial lock.

---

### ClockSync.Timeout

```lua
Config.ClockSync.Timeout: number = 2.0
```

Timeout in seconds for individual ping requests.

---

## Validation Configuration

### Validation.DefaultTolerance

```lua
Config.Validation.DefaultTolerance: number = 0.1
```

Default hit tolerance in seconds for timestamp matching.

---

### Validation.DefaultMaxDistance

```lua
Config.Validation.DefaultMaxDistance: number = 1000
```

Default maximum weapon range in studs.

---

### Validation.CapsuleRadius

```lua
Config.Validation.CapsuleRadius: number = 0.3
```

Default capsule sweep radius for ranged weapons.

---

### Validation.CapsuleSteps

```lua
Config.Validation.CapsuleSteps: number = 10
```

Default interpolation steps for capsule sweeps.

---

### Validation.MeleeRange

```lua
Config.Validation.MeleeRange: number = 5
```

Default melee attack range.

---

### Validation.MeleeAngle

```lua
Config.Validation.MeleeAngle: number = 90
```

Default melee cone angle in degrees.

---

### Validation.MeleeRays

```lua
Config.Validation.MeleeRays: number = 5
```

Default number of rays for melee cone checks.

---

## Debug Configuration

### Debug.ToggleKey

```lua
Config.Debug.ToggleKey: Enum.KeyCode = Enum.KeyCode.F6
```

Key to toggle the debug panel.

---

### Debug.DrawDuration

```lua
Config.Debug.DrawDuration: number = 1.0
```

Default duration for debug visualizations.

---

### Debug.HitboxColor

```lua
Config.Debug.HitboxColor: Color3 = Color3.new(0, 1, 0)
```

Default color for hitbox visualization.

---

### Debug.RayColor

```lua
Config.Debug.RayColor: Color3 = Color3.new(1, 1, 0)
```

Default color for ray visualization.

---

## Modifying Config

Modify config values before initialization:

```lua
local Rewind = require(ReplicatedStorage.Rewind)
local Config = Rewind.Config

-- Modify values
Config.MaxRewindTime = 0.8
Config.SnapshotRate = 30
Config.DebugMode = true

-- Then initialize
Rewind.Server.Init()
```

Or pass config to `Init()`:

```lua
Rewind.Server.Init({
    maxRewindTime = 0.8,
    snapshotRate = 30,
    debugMode = true,
})
```

## Full Default Config

```lua
local DefaultConfig = {
    MaxRewindTime = 1.0,
    SnapshotRate = 20,
    MaxSnapshots = 30,
    MaxOriginDrift = 10,
    DebugMode = false,
    VerboseLogging = false,

    ClockSync = {
        SampleCount = 8,
        SyncInterval = 5.0,
        Timeout = 2.0,
    },

    Validation = {
        DefaultTolerance = 0.1,
        DefaultMaxDistance = 1000,
        CapsuleRadius = 0.3,
        CapsuleSteps = 10,
        MeleeRange = 5,
        MeleeAngle = 90,
        MeleeRays = 5,
    },

    Debug = {
        ToggleKey = Enum.KeyCode.F6,
        DrawDuration = 1.0,
        HitboxColor = Color3.new(0, 1, 0),
        RayColor = Color3.new(1, 1, 0),
    },
}
```
