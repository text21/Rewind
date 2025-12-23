# Movement Validator

The Movement Validator module provides real-time detection of movement anomalies including speed hacks, teleports, fly hacks, and noclip.

## Overview

```lua
local Rewind = require(ReplicatedStorage.Packages.Rewind)

-- Configure movement validation (server only)
Rewind.ConfigureMovementValidation({
    speedTolerance = 1.3, -- Allow 30% over base speed
    teleportThreshold = 50, -- Flag teleports over 50 studs
    maxAirTime = 3, -- Flag flying after 3 seconds
    checkNoclip = true,
})

-- Start monitoring a player
Rewind.StartMovementMonitoring(player)

-- Listen for anomalies
Rewind.OnMovementAnomaly:Connect(function(player, anomalyType, data)
    print(player.Name .. " detected: " .. anomalyType)

    -- Record to abuse tracker
    Rewind.RecordAbuse(player, anomalyType, data)
end)
```

## Types

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

## API Reference

### ConfigureMovementValidation

Configures the movement validation system.

```lua
Rewind.ConfigureMovementValidation(config: MovementConfig): ()
```

**Parameters:**

- `config` - The movement validation configuration

**Example:**

```lua
-- Strict configuration for competitive games
Rewind.ConfigureMovementValidation({
    speedTolerance = 1.1, -- Only 10% tolerance
    teleportThreshold = 30,
    maxAirTime = 2,
    checkNoclip = true,
    checkInterval = 0.05, -- Check every 50ms
    violationThreshold = 2, -- Flag after 2 violations
})

-- Lenient configuration for casual games
Rewind.ConfigureMovementValidation({
    speedTolerance = 1.5, -- 50% tolerance for laggy players
    teleportThreshold = 100,
    maxAirTime = 5,
    checkNoclip = true,
    checkInterval = 0.2,
    violationThreshold = 5,
})
```

---

### StartMovementMonitoring

Starts monitoring a player for movement anomalies.

```lua
Rewind.StartMovementMonitoring(player: Player): ()
```

**Parameters:**

- `player` - The player to start monitoring

**Example:**

```lua
game.Players.PlayerAdded:Connect(function(player)
    player.CharacterAdded:Connect(function(character)
        -- Wait for character to load
        character:WaitForChild("HumanoidRootPart")

        -- Start monitoring
        Rewind.StartMovementMonitoring(player)
    end)
end)
```

---

### StopMovementMonitoring

Stops monitoring a player.

```lua
Rewind.StopMovementMonitoring(player: Player): ()
```

**Parameters:**

- `player` - The player to stop monitoring

**Example:**

```lua
game.Players.PlayerRemoving:Connect(function(player)
    Rewind.StopMovementMonitoring(player)
end)

-- Or when entering a safe zone
local function enterSafeZone(player)
    Rewind.StopMovementMonitoring(player)
end
```

---

### ValidateMovement

Manually validates a player's current movement.

```lua
Rewind.ValidateMovement(player: Player, position: Vector3?, velocity: Vector3?): MovementValidationResult
```

**Parameters:**

- `player` - The player to validate
- `position` - Optional override position (uses current if nil)
- `velocity` - Optional velocity vector

**Returns:** `MovementValidationResult` - The validation result

**Example:**

```lua
-- Manual validation check
local result = Rewind.ValidateMovement(player)
if not result.valid then
    print("Invalid movement:", result.anomalyType)
    print("Details:", result.details)
end

-- Validate client-reported position
remotes.MoveRequest.OnServerEvent:Connect(function(player, reportedPosition)
    local result = Rewind.ValidateMovement(player, reportedPosition)
    if result.valid then
        -- Accept the movement
        player.Character:MoveTo(reportedPosition)
    else
        -- Reject and correct
        correctPlayerPosition(player)
    end
end)
```

---

### SetPlayerSpeedMultiplier

Sets a temporary speed multiplier for a player (for abilities like sprinting).

```lua
Rewind.SetPlayerSpeedMultiplier(player: Player, multiplier: number, duration: number?): ()
```

**Parameters:**

- `player` - The player to set multiplier for
- `multiplier` - The speed multiplier (e.g., 2.0 for double speed)
- `duration` - Optional duration in seconds (nil = permanent until changed)

**Example:**

```lua
-- Sprint ability
local function activateSprint(player)
    -- Allow 2x speed for 10 seconds
    Rewind.SetPlayerSpeedMultiplier(player, 2.0, 10)

    -- Also update the humanoid
    player.Character.Humanoid.WalkSpeed = 32

    task.delay(10, function()
        player.Character.Humanoid.WalkSpeed = 16
    end)
end

-- Speed boost pickup
local function collectSpeedBoost(player)
    Rewind.SetPlayerSpeedMultiplier(player, 1.5, 30)
    player.Character.Humanoid.WalkSpeed = 24
end

-- Reset speed
local function resetSpeed(player)
    Rewind.SetPlayerSpeedMultiplier(player, 1.0)
    player.Character.Humanoid.WalkSpeed = 16
end
```

---

### GetMovementViolations

Gets the current violation counts for a player.

```lua
Rewind.GetMovementViolations(player: Player): {speed: number, teleport: number, fly: number, noclip: number}?
```

**Parameters:**

- `player` - The player to get violations for

**Returns:** Violation counts by type, or nil if not monitoring

**Example:**

```lua
local violations = Rewind.GetMovementViolations(player)
if violations then
    print("Speed violations:", violations.speed)
    print("Teleport violations:", violations.teleport)
    print("Fly violations:", violations.fly)
    print("Noclip violations:", violations.noclip)

    local total = violations.speed + violations.teleport + violations.fly + violations.noclip
    if total > 10 then
        -- Take action
        Rewind.RecordAbuse(player, "speed_hack", violations)
    end
end
```

---

### ClearMovementViolations

Clears all violations for a player.

```lua
Rewind.ClearMovementViolations(player: Player): ()
```

**Parameters:**

- `player` - The player to clear violations for

**Example:**

```lua
-- Clear after legitimate teleport
local function teleportPlayer(player, destination)
    -- Stop monitoring during teleport
    Rewind.StopMovementMonitoring(player)

    -- Teleport
    player.Character:MoveTo(destination)

    -- Wait for physics to settle
    task.wait(0.5)

    -- Clear any violations and resume
    Rewind.ClearMovementViolations(player)
    Rewind.StartMovementMonitoring(player)
end
```

---

## Events

### OnMovementAnomaly

Fired when a movement anomaly is detected.

```lua
Rewind.OnMovementAnomaly:Connect(function(player: Player, anomalyType: AnomalyType, data: {[string]: any})
    print(player.Name .. " anomaly: " .. anomalyType)

    if anomalyType == "speed_hack" then
        print("Speed:", data.currentSpeed, "Max:", data.maxAllowedSpeed)
    elseif anomalyType == "teleport" then
        print("Distance:", data.distanceMoved)
    elseif anomalyType == "fly_hack" then
        print("Air time:", data.airTime)
    elseif anomalyType == "noclip" then
        print("Collided with:", data.collidedPart.Name)
    end
end)
```

---

## Integration Examples

### With Abuse Tracker

```lua
-- Start both systems
Rewind.StartAbuseTracking({
    thresholds = { warn = 3, kick = 5, ban = 10 },
})

Rewind.ConfigureMovementValidation({
    speedTolerance = 1.2,
    teleportThreshold = 50,
})

-- Connect movement anomalies to abuse tracker
Rewind.OnMovementAnomaly:Connect(function(player, anomalyType, data)
    -- Map to abuse reasons
    local reasonMap = {
        speed_hack = "speed_hack",
        teleport = "teleport",
        fly_hack = "fly_hack",
        noclip = "clip",
    }

    Rewind.RecordAbuse(player, reasonMap[anomalyType], data)
end)

-- Monitor all players
game.Players.PlayerAdded:Connect(function(player)
    player.CharacterAdded:Connect(function()
        task.wait(1) -- Wait for character to load
        Rewind.StartMovementMonitoring(player)
    end)
end)
```

### With Game Abilities

```lua
-- Track active abilities to prevent false positives
local activeAbilities = {}

local function activateAbility(player, abilityName)
    activeAbilities[player] = abilityName

    if abilityName == "Sprint" then
        Rewind.SetPlayerSpeedMultiplier(player, 2.0, 10)
    elseif abilityName == "Dash" then
        -- Dash might trigger teleport detection
        Rewind.StopMovementMonitoring(player)

        -- Perform dash
        performDash(player)

        task.wait(0.5)
        Rewind.ClearMovementViolations(player)
        Rewind.StartMovementMonitoring(player)
    elseif abilityName == "Flight" then
        -- Flight ability - disable fly detection
        Rewind.SetPlayerSpeedMultiplier(player, 1.5, 30)
        -- You might want to track this separately
    end

    activeAbilities[player] = nil
end

-- Filter anomalies based on active abilities
Rewind.OnMovementAnomaly:Connect(function(player, anomalyType, data)
    local ability = activeAbilities[player]

    -- Don't flag if ability explains the anomaly
    if ability == "Flight" and anomalyType == "fly_hack" then
        return
    end

    if ability == "Dash" and anomalyType == "teleport" then
        return
    end

    -- Record legitimate violations
    Rewind.RecordAbuse(player, anomalyType, data)
end)
```

### Custom Zones

```lua
-- Define zones where certain checks are disabled
local safeZones = {
    lobby = { position = Vector3.new(0, 0, 0), radius = 100 },
    spawn = { position = Vector3.new(500, 0, 0), radius = 50 },
}

local noFlyZones = {} -- Zones where flying IS allowed

local function isInSafeZone(position)
    for _, zone in pairs(safeZones) do
        if (position - zone.position).Magnitude <= zone.radius then
            return true
        end
    end
    return false
end

Rewind.OnMovementAnomaly:Connect(function(player, anomalyType, data)
    local character = player.Character
    if not character then return end

    local position = character.PrimaryPart.Position

    -- Ignore anomalies in safe zones
    if isInSafeZone(position) then
        return
    end

    -- Process the anomaly
    Rewind.RecordAbuse(player, anomalyType, data)
end)
```

## Best Practices

### 1. Account for Lag

```lua
Rewind.ConfigureMovementValidation({
    -- Higher tolerance for laggier games
    speedTolerance = 1.3,

    -- Higher threshold for teleport
    teleportThreshold = 75,

    -- More violations before flagging
    violationThreshold = 5,

    -- Less frequent checks
    checkInterval = 0.2,
})
```

### 2. Handle Legitimate Teleports

```lua
local function safeTeleport(player, destination)
    -- Pause monitoring
    Rewind.StopMovementMonitoring(player)

    -- Teleport
    player.Character:SetPrimaryPartCFrame(CFrame.new(destination))

    -- Wait for physics
    task.wait(1)

    -- Clear and resume
    Rewind.ClearMovementViolations(player)
    Rewind.StartMovementMonitoring(player)
end
```

### 3. Speed Ability Management

```lua
local playerSpeeds = {}

local function setPlayerSpeed(player, speed, duration)
    local baseSpeed = 16
    local multiplier = speed / baseSpeed

    playerSpeeds[player] = multiplier
    Rewind.SetPlayerSpeedMultiplier(player, multiplier, duration)
    player.Character.Humanoid.WalkSpeed = speed

    if duration then
        task.delay(duration, function()
            if playerSpeeds[player] == multiplier then
                playerSpeeds[player] = 1
                player.Character.Humanoid.WalkSpeed = baseSpeed
            end
        end)
    end
end
```

### 4. Vehicle Integration

```lua
-- Vehicles have different speed limits
local function onVehicleEnter(player, vehicle)
    local vehicleMaxSpeed = vehicle:GetAttribute("MaxSpeed") or 100
    local baseSpeed = 16

    Rewind.SetPlayerSpeedMultiplier(player, vehicleMaxSpeed / baseSpeed)
end

local function onVehicleExit(player)
    Rewind.SetPlayerSpeedMultiplier(player, 1.0)
end
```

### 5. Debug Mode

```lua
local DEBUG_MODE = true

if DEBUG_MODE then
    Rewind.OnMovementAnomaly:Connect(function(player, anomalyType, data)
        -- Don't actually record, just log
        warn(string.format(
            "[DEBUG] %s - %s: %s",
            player.Name,
            anomalyType,
            game:GetService("HttpService"):JSONEncode(data)
        ))
    end)
else
    Rewind.OnMovementAnomaly:Connect(function(player, anomalyType, data)
        Rewind.RecordAbuse(player, anomalyType, data)
    end)
end
```
