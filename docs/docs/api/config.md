---
sidebar_position: 3
---

# Config

Configuration module containing version information and default settings.

```lua
local Config = Rewind.Config
```

## Version Properties

### Version

```lua
Config.Version: string -- "1.2.0"
```

The current semantic version string.

---

### VersionName

```lua
Config.VersionName: string -- "Anti-Cheat & Vehicles"
```

Human-readable name for the current version.

---

## Default Configuration

All options can be passed to `Rewind.Start()` to override these defaults.

### Config.Defaults

```lua
Config.Defaults = {
    enabled = true,             -- Enable hit validation

    snapshotHz = 30,            -- Snapshots captured per second
    windowMs = 750,             -- Total snapshot window (milliseconds)
    maxRewindMs = 500,          -- Maximum rewind allowed (milliseconds)

    maxRayDistance = 1000,      -- Maximum ray/weapon range (studs)
    allowHeadshots = true,      -- Enable headshot detection

    teamCheck = true,           -- Check team before allowing hits
    friendlyFire = false,       -- Allow damage to teammates

    antiSpam = {
        perSecond = 30,         -- Max shots per second
        burst = 60,             -- Burst allowance
    },

    mode = "Analytic",          -- "Analytic" | "GhostParts"

    debug = {
        enabled = false,        -- Enable debug visualization
    },
}
```

---

## Options Reference

### enabled

```lua
enabled: boolean = true
```

Master toggle for hit validation. Set to `false` to bypass all validation.

---

### snapshotHz

```lua
snapshotHz: number = 30
```

How many character snapshots to capture per second. Higher values mean more accurate rewinding at the cost of memory.

**Recommended:** 20-30 for most games.

---

### windowMs

```lua
windowMs: number = 750
```

Total duration of snapshots to keep in memory (milliseconds). Older snapshots are discarded.

---

### maxRewindMs

```lua
maxRewindMs: number = 500
```

Maximum time the server will rewind to validate a hit (milliseconds). Hits claiming older timestamps are rejected.

**Note:** This should be less than or equal to `windowMs`.

---

### maxRayDistance

```lua
maxRayDistance: number = 1000
```

Default maximum distance for ray-based validation. Individual weapons can override this via `WeaponProfile`.

---

### allowHeadshots

```lua
allowHeadshots: boolean = true
```

Enable headshot detection and `isHeadshot` in `HitResult`.

---

### teamCheck

```lua
teamCheck: boolean = true
```

Check if attacker and victim are on different teams before accepting hits.

---

### friendlyFire

```lua
friendlyFire: boolean = false
```

Allow hits on teammates. If `true`, team checks are ignored.

---

### antiSpam

```lua
antiSpam: {
    perSecond: number,
    burst: number,
}
```

Rate limiting for validation requests.

- `perSecond` - Maximum sustained shots per second
- `burst` - Maximum burst allowance

---

### mode

```lua
mode: "Analytic" | "GhostParts" = "Analytic"
```

Validation mode:

- `Analytic` - Uses mathematical intersection testing (faster, recommended)
- `GhostParts` - Creates temporary parts for Roblox raycasting (slower, more accurate edge cases)

---

### debug

```lua
debug: {
    enabled: boolean,
}
```

Debug settings. Enable to see hitbox visualizations and logging.

---

## Usage Example

Pass options to `Rewind.Start()`:

```lua
Rewind.Start({
    snapshotHz = 20,
    windowMs = 1000,
    maxRewindMs = 300,
    maxRayDistance = 500,
    friendlyFire = false,
    teamCheck = true,
    debug = {
        enabled = true,
    },
})
```

Or modify at runtime with `Rewind.Configure()`:

```lua
Rewind.Configure({
    debug = { enabled = false },
})
```
