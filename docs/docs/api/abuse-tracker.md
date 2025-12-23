# Abuse Tracker

The Abuse Tracker module provides persistent abuse tracking with DataStore integration for automatic kick/ban enforcement.

## Overview

```lua
local Rewind = require(ReplicatedStorage.Packages.Rewind)

-- Start abuse tracking (server only)
Rewind.StartAbuseTracking({
    dataStoreName = "RewindAbuseTracker",
    thresholds = {
        warn = 3,   -- Warn after 3 incidents
        kick = 5,   -- Kick after 5 incidents
        ban = 10,   -- Ban after 10 incidents
    },
    autoKick = true,
    autoBan = true,
    banDuration = 86400 * 7, -- 7 day ban
})

-- Record an abuse incident
Rewind.RecordAbuse(player, "speed_hack", {
    detectedSpeed = 100,
    maxAllowedSpeed = 16,
})

-- Listen for abuse events
Rewind.OnAbuseDetected:Connect(function(player, reason, details, totalCount)
    print(player.Name .. " detected for " .. reason .. " (" .. totalCount .. " total)")
end)

Rewind.OnAbuseThresholdReached:Connect(function(player, threshold, totalCount)
    if threshold == "warn" then
        warnPlayer(player, "You have been flagged for suspicious behavior")
    end
end)
```

## Types

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

## API Reference

### StartAbuseTracking

Initializes the abuse tracking system with DataStore persistence.

```lua
Rewind.StartAbuseTracking(config: AbuseConfig?): ()
```

**Parameters:**

- `config` - Optional configuration for abuse tracking

**Example:**

```lua
-- Strict configuration
Rewind.StartAbuseTracking({
    thresholds = {
        warn = 2,
        kick = 3,
        ban = 5,
    },
    autoKick = true,
    autoBan = true,
    banDuration = 86400 * 30, -- 30 day ban
})

-- Lenient configuration
Rewind.StartAbuseTracking({
    thresholds = {
        warn = 5,
        kick = 10,
        ban = 20,
    },
    autoKick = true,
    autoBan = false, -- Manual review before banning
    resetAfter = 86400 * 7, -- Reset after 7 days of good behavior
})
```

---

### RecordAbuse

Records an abuse incident for a player.

```lua
Rewind.RecordAbuse(player: Player, reason: AbuseReason, details: {[string]: any}?): ()
```

**Parameters:**

- `player` - The player who committed the abuse
- `reason` - The type of abuse detected
- `details` - Optional additional details about the incident

**Example:**

```lua
-- Speed hack detection
Rewind.RecordAbuse(player, "speed_hack", {
    detectedSpeed = 150,
    maxAllowedSpeed = 32,
    position = player.Character.PrimaryPart.Position,
})

-- Damage exploit
Rewind.RecordAbuse(player, "damage_exploit", {
    claimedDamage = 9999,
    maxAllowedDamage = 100,
    weaponUsed = "pistol",
})

-- Teleport detection
Rewind.RecordAbuse(player, "teleport", {
    previousPosition = Vector3.new(0, 0, 0),
    newPosition = Vector3.new(1000, 0, 1000),
    distanceMoved = 1414,
    timeDelta = 0.1,
})
```

---

### GetAbuseHistory

Gets the complete abuse history for a player.

```lua
Rewind.GetAbuseHistory(player: Player): PlayerAbuseHistory?
```

**Parameters:**

- `player` - The player to get history for

**Returns:** `PlayerAbuseHistory?` - The player's abuse history, or nil

**Example:**

```lua
local history = Rewind.GetAbuseHistory(player)
if history then
    print("Total incidents:", history.totalIncidents)
    print("Is banned:", history.isBanned)

    for _, record in ipairs(history.records) do
        print(" - " .. record.reason .. " at " .. record.timestamp)
    end
end
```

---

### IsPlayerBanned

Checks if a player is currently banned.

```lua
Rewind.IsPlayerBanned(player: Player): (boolean, number?, string?)
```

**Parameters:**

- `player` - The player to check

**Returns:**

- `boolean` - Whether the player is banned
- `number?` - Ban expiry timestamp (nil if permanent)
- `string?` - Ban reason

**Example:**

```lua
game.Players.PlayerAdded:Connect(function(player)
    local isBanned, expiry, reason = Rewind.IsPlayerBanned(player)
    if isBanned then
        local message = "You are banned"
        if expiry then
            local remaining = expiry - os.time()
            message = message .. " for " .. formatTime(remaining)
        end
        if reason then
            message = message .. ". Reason: " .. reason
        end
        player:Kick(message)
    end
end)
```

---

### BanPlayer

Manually bans a player.

```lua
Rewind.BanPlayer(player: Player, reason: string?, duration: number?): ()
```

**Parameters:**

- `player` - The player to ban
- `reason` - Optional ban reason
- `duration` - Optional ban duration in seconds (nil = permanent)

**Example:**

```lua
-- Temporary ban
Rewind.BanPlayer(player, "Repeated speed hacking", 86400 * 7)

-- Permanent ban
Rewind.BanPlayer(player, "Confirmed cheater")
```

---

### UnbanPlayer

Unbans a player by their UserId.

```lua
Rewind.UnbanPlayer(userId: number): boolean
```

**Parameters:**

- `userId` - The UserId of the player to unban

**Returns:** `boolean` - Whether the player was found and unbanned

**Example:**

```lua
local success = Rewind.UnbanPlayer(123456789)
if success then
    print("Player unbanned successfully")
end
```

---

## Events

### OnAbuseDetected

Fired when any abuse incident is recorded.

```lua
Rewind.OnAbuseDetected:Connect(function(player: Player, reason: AbuseReason, details: {[string]: any}?, totalCount: number)
    print(player.Name .. " detected for " .. reason)
    print("Total incidents:", totalCount)

    -- Log to external service
    logToDiscord({
        player = player.Name,
        userId = player.UserId,
        reason = reason,
        details = details,
        total = totalCount,
    })
end)
```

### OnAbuseThresholdReached

Fired when a player reaches a threshold (warn/kick/ban).

```lua
Rewind.OnAbuseThresholdReached:Connect(function(player: Player, threshold: "warn" | "kick" | "ban", totalCount: number)
    if threshold == "warn" then
        -- Send warning to player
        game.ReplicatedStorage.ShowWarning:FireClient(player,
            "Suspicious activity detected. Further violations may result in a kick or ban."
        )
    elseif threshold == "kick" then
        -- Auto-kick is handled, but you can add logging
        logToDiscord({
            event = "PLAYER_KICKED",
            player = player.Name,
            userId = player.UserId,
            incidents = totalCount,
        })
    elseif threshold == "ban" then
        -- Auto-ban is handled, but you can add logging
        logToDiscord({
            event = "PLAYER_BANNED",
            player = player.Name,
            userId = player.UserId,
            incidents = totalCount,
        })
    end
end)
```

---

## Integration with Movement Validator

The Abuse Tracker integrates seamlessly with the Movement Validator:

```lua
-- Start abuse tracking
Rewind.StartAbuseTracking({
    thresholds = { warn = 3, kick = 5, ban = 10 },
})

-- Configure movement validation
Rewind.ConfigureMovementValidation({
    speedTolerance = 1.2,
    teleportThreshold = 50,
})

-- Connect movement anomalies to abuse tracker
Rewind.OnMovementAnomaly:Connect(function(player, anomalyType, data)
    -- Map anomaly types to abuse reasons
    local reasonMap = {
        speed_hack = "speed_hack",
        teleport = "teleport",
        fly_hack = "fly_hack",
        noclip = "clip",
    }

    local reason = reasonMap[anomalyType]
    if reason then
        Rewind.RecordAbuse(player, reason, data)
    end
end)
```

## Best Practices

### 1. Configure Appropriate Thresholds

```lua
-- For competitive games - strict
Rewind.StartAbuseTracking({
    thresholds = { warn = 1, kick = 2, ban = 3 },
    banDuration = 86400 * 30, -- 30 days
})

-- For casual games - lenient
Rewind.StartAbuseTracking({
    thresholds = { warn = 5, kick = 10, ban = 25 },
    banDuration = 86400 * 7, -- 7 days
    resetAfter = 86400 * 14, -- Reset after 2 weeks
})
```

### 2. Include Detailed Information

```lua
Rewind.RecordAbuse(player, "speed_hack", {
    -- Always include these
    timestamp = os.time(),
    position = player.Character.PrimaryPart.Position,

    -- Specific to detection type
    detectedSpeed = currentSpeed,
    maxAllowedSpeed = maxSpeed,
    speedMultiplier = activeMultiplier,

    -- Context
    isInVehicle = Rewind.GetPlayerVehicle(player) ~= nil,
    gameMode = currentGameMode,
})
```

### 3. Handle False Positives

```lua
Rewind.OnAbuseDetected:Connect(function(player, reason, details, totalCount)
    -- Don't immediately act on first offense
    if totalCount == 1 then
        -- Just log it
        return
    end

    -- Check for legitimate reasons
    if reason == "teleport" and isInTeleporter(player) then
        -- This is expected, clear the violation
        Rewind.ClearMovementViolations(player)
        return
    end
end)
```

### 4. Implement Appeals

```lua
-- In your appeal system
local function handleAppeal(userId, adminId)
    -- Check if appeal is valid
    local history = getAbuseHistoryByUserId(userId)
    if not history then return false end

    -- Admin reviews and decides to unban
    local success = Rewind.UnbanPlayer(userId)

    if success then
        logAppealAccepted(userId, adminId)
    end

    return success
end
```

### 5. External Logging

```lua
local HttpService = game:GetService("HttpService")

Rewind.OnAbuseDetected:Connect(function(player, reason, details, totalCount)
    -- Send to Discord webhook
    local payload = HttpService:JSONEncode({
        content = string.format(
            "**Abuse Detected**\nPlayer: %s (%d)\nReason: %s\nTotal: %d\nDetails: %s",
            player.Name, player.UserId, reason, totalCount,
            HttpService:JSONEncode(details or {})
        )
    })

    pcall(function()
        HttpService:PostAsync(DISCORD_WEBHOOK_URL, payload, Enum.HttpContentType.ApplicationJson)
    end)
end)
```
