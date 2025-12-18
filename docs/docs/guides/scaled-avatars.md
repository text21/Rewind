---
sidebar_position: 3
---

# Scaled Avatars

Rewind fully supports scaled avatars. Hitboxes automatically adjust to match character scale.

## How It Works

When a character is scaled (via Humanoid scale values or direct resizing), Rewind detects the scale and adjusts hitbox positions and sizes accordingly.

```lua
-- Character with 2x scale will have:
-- - Hitbox positions scaled by 2x from HumanoidRootPart
-- - Hitbox sizes scaled by 2x
```

## Automatic Detection

The `RigAdapter` module automatically detects character scale:

```lua
local RigAdapter = Rewind.RigAdapter

-- Get scale multiplier for a character
local scale = RigAdapter.GetScale(character)
-- Returns: number (1.0 = normal, 2.0 = double size, etc.)
```

Scale is detected from:

1. `Humanoid.BodyHeightScale` (if present)
2. `Humanoid.HeadScale` (fallback)
3. Direct part size comparison to defaults

## Per-Weapon Scale Multiplier

Weapon profiles can specify additional scale adjustment:

```lua
local WeaponProfiles = {
    -- Normal hitboxes
    Rifle = {
        scaleMultiplier = 1.0,
    },

    -- Forgiving hitboxes (good for shotguns)
    Shotgun = {
        scaleMultiplier = 1.2, -- 20% larger hitboxes
    },

    -- Precise hitboxes (for snipers)
    Sniper = {
        scaleMultiplier = 0.9, -- 10% smaller hitboxes
    },
}
```

## Validation with Scale

When validating hits, scale is automatically applied:

```lua
local result = Rewind.Validate(player, "Raycast", {
    origin = origin,
    direction = direction,
    targetIds = { targetId },
    weaponId = "Rifle",
    timestamp = timestamp,
})
-- Hitboxes are automatically scaled based on target character scale
-- and weapon profile's scaleMultiplier
```

## Manual Scale Application

For advanced use cases, you can manually apply scale:

```lua
local RigAdapter = Rewind.RigAdapter

-- Get base hitbox profile
local profile = RigAdapter.GetProfile(character)

-- Apply scale to a pose
local scaledPose = RigAdapter.ApplyScale(pose, 1.5)

-- Or get scaled parts directly
local parts = RigAdapter.CollectParts(character, true) -- withScale = true
```

## Hitbox Profile Scaling

The built-in R6 and R15 hitbox profiles define relative positions and sizes. These are scaled based on character scale:

```lua
-- R15 default profile (unscaled)
local R15_Default = {
    Head = { size = Vector3.new(1.2, 1.2, 1.2) },
    UpperTorso = { size = Vector3.new(2, 1.6, 1) },
    -- ...
}

-- At 2x scale, Head hitbox becomes:
-- size = Vector3.new(2.4, 2.4, 2.4)
```

## Example: Giant Boss

```lua
-- Create a giant boss character
local boss = createBoss()
local humanoid = boss:FindFirstChild("Humanoid")

-- Scale the boss to 3x size
humanoid.BodyHeightScale.Value = 3
humanoid.BodyWidthScale.Value = 3
humanoid.BodyDepthScale.Value = 3
humanoid.HeadScale.Value = 3

-- Rewind automatically detects this scale
-- All hits against the boss use 3x scaled hitboxes
```

## Debugging Scale

Check detected scale in the debug panel:

```lua
Rewind.Server.Init({
    debugMode = true,
})
```

The Iris debug panel shows:

- Character scale for each tracked player
- Hitbox sizes (scaled)
- Visual hitbox outlines

## Best Practices

1. **Use Humanoid scale properties** when possible - they're the most reliable
2. **Test at different scales** to ensure hitboxes feel right
3. **Adjust weapon scaleMultiplier** for weapon-specific feel
4. **Consider minimum scale** for very small characters to prevent unfair advantages

```lua
-- Ensure minimum hitbox scale
local function getClampedScale(character)
    local scale = RigAdapter.GetScale(character)
    return math.max(scale, 0.5) -- Never smaller than 50%
end
```
