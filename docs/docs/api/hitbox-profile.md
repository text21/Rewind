---
sidebar_position: 7
---

# HitboxProfile

Built-in hitbox profiles for R6 and R15 characters.

```lua
local HitboxProfile = require(ReplicatedStorage.Rewind.Rig.HitboxProfile)
-- or
local HitboxProfile = Rewind.HitboxProfile
```

## Built-in Profiles

### R15_Default

Standard hitbox profile for R15 characters.

```lua
HitboxProfile.R15_Default = {
    Head = {
        size = Vector3.new(1.2, 1.2, 1.2),
        damageMultiplier = 2.0,
        priority = 1,
    },
    UpperTorso = {
        size = Vector3.new(2, 1.6, 1),
        damageMultiplier = 1.0,
        priority = 2,
    },
    LowerTorso = {
        size = Vector3.new(2, 0.8, 1),
        damageMultiplier = 1.0,
        priority = 3,
    },
    LeftUpperArm = {
        size = Vector3.new(1, 1.2, 1),
        damageMultiplier = 0.8,
        priority = 4,
    },
    LeftLowerArm = {
        size = Vector3.new(1, 1.2, 1),
        damageMultiplier = 0.8,
        priority = 5,
    },
    LeftHand = {
        size = Vector3.new(1, 0.6, 1),
        damageMultiplier = 0.6,
        priority = 6,
    },
    RightUpperArm = {
        size = Vector3.new(1, 1.2, 1),
        damageMultiplier = 0.8,
        priority = 4,
    },
    RightLowerArm = {
        size = Vector3.new(1, 1.2, 1),
        damageMultiplier = 0.8,
        priority = 5,
    },
    RightHand = {
        size = Vector3.new(1, 0.6, 1),
        damageMultiplier = 0.6,
        priority = 6,
    },
    LeftUpperLeg = {
        size = Vector3.new(1, 1.5, 1),
        damageMultiplier = 0.7,
        priority = 7,
    },
    LeftLowerLeg = {
        size = Vector3.new(1, 1.5, 1),
        damageMultiplier = 0.7,
        priority = 8,
    },
    LeftFoot = {
        size = Vector3.new(1, 0.5, 1),
        damageMultiplier = 0.5,
        priority = 9,
    },
    RightUpperLeg = {
        size = Vector3.new(1, 1.5, 1),
        damageMultiplier = 0.7,
        priority = 7,
    },
    RightLowerLeg = {
        size = Vector3.new(1, 1.5, 1),
        damageMultiplier = 0.7,
        priority = 8,
    },
    RightFoot = {
        size = Vector3.new(1, 0.5, 1),
        damageMultiplier = 0.5,
        priority = 9,
    },
}
```

---

### R6_Default

Standard hitbox profile for R6 characters.

```lua
HitboxProfile.R6_Default = {
    Head = {
        size = Vector3.new(2, 1, 1),
        damageMultiplier = 2.0,
        priority = 1,
    },
    Torso = {
        size = Vector3.new(2, 2, 1),
        damageMultiplier = 1.0,
        priority = 2,
    },
    ["Left Arm"] = {
        size = Vector3.new(1, 2, 1),
        damageMultiplier = 0.8,
        priority = 3,
    },
    ["Right Arm"] = {
        size = Vector3.new(1, 2, 1),
        damageMultiplier = 0.8,
        priority = 3,
    },
    ["Left Leg"] = {
        size = Vector3.new(1, 2, 1),
        damageMultiplier = 0.7,
        priority = 4,
    },
    ["Right Leg"] = {
        size = Vector3.new(1, 2, 1),
        damageMultiplier = 0.7,
        priority = 4,
    },
}
```

---

## HitboxDef Type

```lua
type HitboxDef = {
    size: Vector3,             -- Hitbox size
    offset: Vector3?,          -- Offset from part center (optional)
    damageMultiplier: number?, -- Damage multiplier (optional, default: 1.0)
    priority: number?,         -- Hit detection priority (optional)
}
```

---

## Creating Custom Profiles

### Method 1: Extend Built-in

```lua
local customR15 = table.clone(HitboxProfile.R15_Default)

-- Make head hitbox larger
customR15.Head = {
    size = Vector3.new(1.5, 1.5, 1.5),
    damageMultiplier = 3.0,
    priority = 1,
}

HitboxProfile.Custom_BigHead = customR15
```

### Method 2: Full Custom

```lua
HitboxProfile.Custom_Robot = {
    Core = {
        size = Vector3.new(2, 2, 2),
        damageMultiplier = 1.0,
        priority = 1,
    },
    WeakPoint = {
        size = Vector3.new(0.5, 0.5, 0.5),
        offset = Vector3.new(0, 1, 0),
        damageMultiplier = 5.0,
        priority = 0, -- Highest priority
    },
}
```

---

## Registering Custom Profiles

```lua
-- Add to HitboxProfile table
HitboxProfile.MyCustomProfile = {
    -- ...
}

-- Use with RigAdapter override
RigAdapter.RegisterProfile("MyCharacterType", "MyCustomProfile")
```

---

## Usage with Validation

Profiles are automatically used during validation:

```lua
-- Validation automatically uses appropriate profile
local result = Rewind.Validate(player, "Raycast", params)

-- Result includes hit part info
if result.accepted then
    for _, victim in result.victims do
        print("Hit part:", victim.hitPart)

        -- Get damage multiplier from profile
        local profile = RigAdapter.GetProfile(victim.character)
        local hitbox = profile[victim.hitPart]
        local damage = baseDamage * (hitbox.damageMultiplier or 1.0)
    end
end
```

---

## Damage Multiplier Guidelines

| Body Part     | Suggested Multiplier |
| ------------- | -------------------- |
| Head          | 2.0 - 3.0            |
| Torso (Upper) | 1.0                  |
| Torso (Lower) | 1.0                  |
| Arms          | 0.7 - 0.8            |
| Hands         | 0.5 - 0.6            |
| Legs          | 0.6 - 0.7            |
| Feet          | 0.4 - 0.5            |

---

## Priority System

Lower priority numbers are checked first. This is useful for:

- Ensuring headshots register before body shots
- Weak points on bosses
- Critical hit zones

```lua
-- Priority 0 = checked first
-- Priority 9 = checked last

WeakPoint = { priority = 0 },  -- Check first
Head = { priority = 1 },
Torso = { priority = 2 },
Limbs = { priority = 3 },
```
