---
sidebar_position: 6
---

# RigAdapter

Utilities for working with character rigs and hitboxes.

```lua
local RigAdapter = require(ReplicatedStorage.Rewind.Rig.RigAdapter)
-- or
local RigAdapter = Rewind.RigAdapter
```

## Functions

### IsR15

```lua
RigAdapter.IsR15(character: Model): boolean
```

Detect if a character uses the R15 rig.

**Detection Method:**

1. Check `Humanoid.RigType` (if available)
2. Fallback: Check for R15-specific parts (UpperTorso, LowerTorso)

**Example:**

```lua
local isR15 = RigAdapter.IsR15(character)
if isR15 then
    print("R15 character")
else
    print("R6 character")
end
```

---

### ResolveProfileId

```lua
RigAdapter.ResolveProfileId(character: Model): string
```

Get the appropriate hitbox profile ID for a character.

**Returns:** `"R15_Default"` or `"R6_Default"`

**Example:**

```lua
local profileId = RigAdapter.ResolveProfileId(character)
local profile = Rewind.HitboxProfile[profileId]
```

---

### CollectParts

```lua
RigAdapter.CollectParts(
    character: Model,
    withScale: boolean?
): { [string]: PartInfo }
```

Collect all body parts from a character with their positions and sizes.

**Parameters:**

- `character` - The character model
- `withScale` - Whether to apply character scale (default: true)

**Returns:** Dictionary mapping part names to part info.

**Graceful Handling:** Missing parts are silently skipped rather than erroring.

**Example:**

```lua
local parts = RigAdapter.CollectParts(character)
for name, info in parts do
    print(name, info.cframe, info.size)
end
```

---

### GetScale

```lua
RigAdapter.GetScale(character: Model): number
```

Get the scale multiplier for a character.

**Detection Priority:**

1. `Humanoid.BodyHeightScale.Value`
2. `Humanoid.HeadScale.Value`
3. Head part size comparison
4. Default: 1.0

**Example:**

```lua
local scale = RigAdapter.GetScale(character)
print("Character scale:", scale) -- e.g., 1.0, 1.5, 2.0
```

---

### ApplyScale

```lua
RigAdapter.ApplyScale(
    pose: PlayerPose,
    scale: number
): PlayerPose
```

Apply a scale multiplier to a player pose.

**Parameters:**

- `pose` - The original pose
- `scale` - Scale multiplier

**Returns:** New pose with scaled part sizes.

**Example:**

```lua
local scaledPose = RigAdapter.ApplyScale(pose, 1.5)
```

---

### GetProfile

```lua
RigAdapter.GetProfile(character: Model): HitboxProfile
```

Get the hitbox profile for a character (auto-detected).

**Example:**

```lua
local profile = RigAdapter.GetProfile(character)
for partName, hitbox in profile do
    print(partName, hitbox.size)
end
```

---

### BuildPose

```lua
RigAdapter.BuildPose(character: Model): PlayerPose
```

Build a complete pose snapshot for a character.

**Returns:** `PlayerPose` with CFrame, velocity, parts, and scale.

**Example:**

```lua
local pose = RigAdapter.BuildPose(character)
print("Position:", pose.cframe.Position)
print("Velocity:", pose.velocity)
print("Scale:", pose.scale)
```

---

## Type Definitions

### PartInfo

```lua
type PartInfo = {
    cframe: CFrame,
    size: Vector3,
    part: BasePart?,  -- Reference to actual part (if available)
}
```

### PlayerPose

```lua
type PlayerPose = {
    cframe: CFrame,       -- HumanoidRootPart CFrame
    velocity: Vector3,    -- Movement velocity
    parts: { [string]: PartInfo },
    scale: number,        -- Character scale
}
```

---

## Supported Parts

### R15 Parts

- Head
- UpperTorso
- LowerTorso
- LeftUpperArm
- LeftLowerArm
- LeftHand
- RightUpperArm
- RightLowerArm
- RightHand
- LeftUpperLeg
- LeftLowerLeg
- LeftFoot
- RightUpperLeg
- RightLowerLeg
- RightFoot

### R6 Parts

- Head
- Torso
- Left Arm
- Right Arm
- Left Leg
- Right Leg

---

## Error Handling

RigAdapter gracefully handles edge cases:

```lua
-- Missing parts are skipped
local parts = RigAdapter.CollectParts(damagedCharacter)
-- Returns only the parts that exist

-- Invalid characters return empty
local parts = RigAdapter.CollectParts(nil)
-- Returns {}

-- Missing Humanoid handled
local scale = RigAdapter.GetScale(characterWithoutHumanoid)
-- Returns 1.0
```
