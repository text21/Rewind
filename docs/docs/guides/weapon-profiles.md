---
sidebar_position: 2
---

# Weapon Profiles

Weapon profiles let you configure per-weapon validation parameters. Different weapons have different characteristics that affect hit validation.

## Overview

A weapon profile contains:

- Maximum effective range
- Tolerance values
- Hitbox scaling
- Validation mode (hitscan vs projectile vs melee)

## Defining Profiles

Register weapon profiles on the server:

```lua
local Rewind = require(ReplicatedStorage.Rewind)

-- Define weapon profiles
local WeaponProfiles = {
    Rifle = {
        maxDistance = 500,
        tolerance = 0.1,
        capsuleRadius = 0.3,
        capsuleSteps = 10,
        scaleMultiplier = 1.0,
        isMelee = false,
    },
    Shotgun = {
        maxDistance = 50,
        tolerance = 0.15,
        capsuleRadius = 0.5,
        capsuleSteps = 5,
        scaleMultiplier = 1.1,  -- Slightly larger hitboxes
        isMelee = false,
    },
    Sword = {
        maxDistance = 8,
        tolerance = 0.2,
        meleeRange = 6,
        meleeAngleDeg = 90,
        meleeRays = 5,
        scaleMultiplier = 1.0,
        isMelee = true,
    },
}

-- Initialize with profiles
Rewind.Server.Init({
    weaponProfiles = WeaponProfiles,
})
```

## Profile Properties

### Common Properties

| Property          | Type    | Default | Description                    |
| ----------------- | ------- | ------- | ------------------------------ |
| `maxDistance`     | number  | 1000    | Maximum effective range        |
| `tolerance`       | number  | 0.1     | Hit tolerance (seconds)        |
| `scaleMultiplier` | number  | 1.0     | Hitbox scale multiplier        |
| `isMelee`         | boolean | false   | Whether this is a melee weapon |

### Ranged Weapon Properties

| Property        | Type   | Default | Description                     |
| --------------- | ------ | ------- | ------------------------------- |
| `capsuleRadius` | number | 0.3     | Capsule sweep radius            |
| `capsuleSteps`  | number | 10      | Interpolation steps for capsule |

### Melee Weapon Properties

| Property        | Type   | Default | Description                  |
| --------------- | ------ | ------- | ---------------------------- |
| `meleeRange`    | number | 5       | Maximum melee reach          |
| `meleeAngleDeg` | number | 90      | Cone angle for melee hits    |
| `meleeRays`     | number | 5       | Number of rays in melee cone |

## Using Profiles

When validating a hit, specify the weapon ID:

```lua
local result = Rewind.Validate(player, "Raycast", {
    origin = origin,
    direction = direction,
    targetIds = { targetId },
    weaponId = "Rifle",  -- Uses Rifle profile
    timestamp = timestamp,
})
```

## Creating Params from Weapon

Use the helper to create validation params from a weapon profile:

```lua
local profile = WeaponProfiles.Rifle
local params = Rewind.CreateParamsFromWeapon(profile, {
    origin = origin,
    direction = direction,
    targetIds = targetIds,
    timestamp = timestamp,
})

local result = Rewind.Validate(player, "Raycast", params)
```

## Dynamic Profiles

You can modify profiles at runtime:

```lua
-- Buff weapon range
WeaponProfiles.Rifle.maxDistance = 600

-- Apply to Rewind
Rewind.Server.UpdateWeaponProfile("Rifle", WeaponProfiles.Rifle)
```

## Default Fallback

If a weapon ID isn't found, Rewind uses these defaults:

```lua
local DefaultProfile = {
    maxDistance = 1000,
    tolerance = 0.1,
    capsuleRadius = 0.3,
    capsuleSteps = 10,
    scaleMultiplier = 1.0,
    isMelee = false,
}
```

## Example: Full Weapon System

```lua
-- Define all weapons
local Weapons = {
    AssaultRifle = {
        damage = 25,
        fireRate = 10,
        profile = {
            maxDistance = 300,
            tolerance = 0.08,
            capsuleRadius = 0.25,
            isMelee = false,
        },
    },
    Sniper = {
        damage = 100,
        fireRate = 0.5,
        profile = {
            maxDistance = 1000,
            tolerance = 0.05,
            capsuleRadius = 0.15,
            isMelee = false,
        },
    },
    Katana = {
        damage = 50,
        fireRate = 2,
        profile = {
            maxDistance = 10,
            tolerance = 0.15,
            meleeRange = 8,
            meleeAngleDeg = 120,
            meleeRays = 7,
            isMelee = true,
        },
    },
}

-- Extract profiles for Rewind
local profiles = {}
for name, weapon in Weapons do
    profiles[name] = weapon.profile
end

Rewind.Server.Init({
    weaponProfiles = profiles,
})
```
