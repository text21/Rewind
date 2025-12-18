---
sidebar_position: 4
---

# Anti-Abuse

Rewind includes multiple layers of protection against cheating and abuse.

## Built-in Protections

### 1. Duplicate Detection

Prevents players from registering multiple hits with the same shot:

```lua
-- Same attack can't hit the same target twice
-- Tracked by: attackerId + targetId + timestamp + weaponId + mode
```

For melee weapons, duplicate detection is weapon-aware:

- Same melee swing can hit multiple targets
- But can't hit the same target twice per swing

### 2. Distance Sanity Checks

Validates that the claimed origin is reasonable:

```lua
-- Server checks:
-- distance(claimedOrigin, actualPosition) < maxAllowedDrift

Rewind.Server.Init({
    maxOriginDrift = 10, -- studs
})
```

If the claimed shot origin is too far from where the player actually is, the hit is rejected with `RejectReason.InvalidOrigin`.

### 3. Timestamp Validation

Ensures timestamps are within acceptable bounds:

```lua
-- Checks:
-- 1. Timestamp is not in the future
-- 2. Timestamp is not too far in the past
-- 3. Timestamp is within rewind window

Rewind.Server.Init({
    maxRewindTime = 1.0, -- Maximum 1 second rewind
})
```

### 4. Rate Limiting

Prevents spam attacks:

```lua
local RateLimiter = require(Rewind.Util.RateLimiter)

local limiter = RateLimiter.new({
    maxRequests = 20,    -- Max requests
    windowSize = 1.0,    -- Per second
})

-- In hit handler
if not limiter:check(player) then
    return -- Rate limited
end
```

## Rejection Reasons

When a hit is rejected, you get a specific reason:

```lua
local result = Rewind.Validate(player, "Raycast", params)

if not result.accepted then
    print("Rejected:", result.reason)
    -- Possible reasons:
    -- "NoSnapshot" - No snapshot data for timestamp
    -- "TooFarBack" - Timestamp too old
    -- "FutureTimestamp" - Timestamp in the future
    -- "InvalidOrigin" - Origin position suspicious
    -- "Duplicate" - Already processed this hit
    -- "OutOfRange" - Target too far away
    -- "NoLineOfSight" - Target not visible
    -- "InvalidTarget" - Target doesn't exist
end
```

### RejectReason Enum

```lua
local Types = Rewind.Types

Types.RejectReason = {
    NoSnapshot = "NoSnapshot",
    TooFarBack = "TooFarBack",
    FutureTimestamp = "FutureTimestamp",
    InvalidOrigin = "InvalidOrigin",
    Duplicate = "Duplicate",
    OutOfRange = "OutOfRange",
    NoLineOfSight = "NoLineOfSight",
    InvalidTarget = "InvalidTarget",
}
```

## Custom Validation

Add your own validation logic:

```lua
local function customValidate(player, params)
    -- Check weapon ownership
    if not playerOwnsWeapon(player, params.weaponId) then
        return false, "WeaponNotOwned"
    end

    -- Check ammo
    if not hasAmmo(player, params.weaponId) then
        return false, "NoAmmo"
    end

    -- Check if weapon is on cooldown
    if isOnCooldown(player, params.weaponId) then
        return false, "OnCooldown"
    end

    return true
end

-- Apply before Rewind validation
HitRemote.OnServerEvent:Connect(function(player, hitData)
    local valid, reason = customValidate(player, hitData)
    if not valid then
        warn("Custom validation failed:", reason)
        return
    end

    -- Continue with Rewind validation
    local result = Rewind.Validate(player, "Raycast", hitData)
    -- ...
end)
```

## Logging Suspicious Activity

Track potentially abusive behavior:

```lua
local suspiciousPlayers = {}

local function trackSuspicious(player, reason)
    if not suspiciousPlayers[player] then
        suspiciousPlayers[player] = {}
    end

    table.insert(suspiciousPlayers[player], {
        time = os.time(),
        reason = reason,
    })

    -- Flag if too many suspicious actions
    if #suspiciousPlayers[player] > 10 then
        flagForReview(player)
    end
end

-- In validation
local result = Rewind.Validate(player, "Raycast", params)
if not result.accepted then
    if result.reason == "InvalidOrigin" or
       result.reason == "FutureTimestamp" then
        trackSuspicious(player, result.reason)
    end
end
```

## Best Practices

1. **Never trust client data** - Always validate everything server-side

2. **Log rejections** - Track patterns that might indicate cheating

3. **Use rate limiting** - Prevent spam even if hits are rejected

4. **Layer defenses** - Combine Rewind with your own checks

5. **Test edge cases** - High ping, packet loss, rapid movement

```lua
-- Example: Full validation pipeline
local function handleHit(player, hitData)
    -- Layer 1: Rate limiting
    if not rateLimiter:check(player) then
        return { accepted = false, reason = "RateLimited" }
    end

    -- Layer 2: Basic sanity
    if not hitData or type(hitData) ~= "table" then
        return { accepted = false, reason = "InvalidData" }
    end

    -- Layer 3: Custom validation
    local valid, reason = customValidate(player, hitData)
    if not valid then
        return { accepted = false, reason = reason }
    end

    -- Layer 4: Rewind validation
    return Rewind.Validate(player, hitData.mode, hitData)
end
```
