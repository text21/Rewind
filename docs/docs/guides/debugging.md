---
sidebar_position: 5
---

# Debugging

Rewind includes powerful debugging tools to visualize hitboxes, shot traces, and validation results.

## Iris Debug Panel

The built-in debug panel uses [Iris](https://github.com/SirMallard/Iris) for real-time visualization.

### Enabling Debug Mode

```lua
-- Server
Rewind.Start({
    debug = { enabled = true },
})
Rewind.ClockSync.StartServer()

-- Client
Rewind.ClockSync.StartClient()
```

### Panel Features

The debug panel shows:

- **Clock Sync Status** - Offset, RTT, lock status
- **Snapshot Stats** - Buffer size, oldest/newest timestamps
- **Validation Stats** - Hits accepted/rejected, reasons
- **Performance** - Validation time, memory usage

### Toggle Keybind

Press `F6` to toggle the debug panel (when debug mode is enabled on server).

## Visual Debugging

### Drawing Hitboxes

Visualize hitboxes for a character:

```lua
local Draw = require(Rewind.Debug.Draw)

-- Draw hitboxes for a character
Draw.Hitboxes(character, Color3.new(0, 1, 0)) -- Green

-- Draw for a specific duration
Draw.Hitboxes(character, Color3.new(1, 0, 0), 2) -- Red, 2 seconds
```

### Drawing Shot Traces

Visualize validation rays:

```lua
-- Draw a raycast
Draw.Ray(origin, direction, Color3.new(1, 1, 0), 1) -- Yellow, 1 second

-- Draw a capsule sweep
Draw.Capsule(origin, endPoint, radius, Color3.new(0, 1, 1), 1) -- Cyan

-- Draw hit point
Draw.Point(hitPosition, Color3.new(1, 0, 0), 0.5) -- Red, 0.5 seconds
```

### Drawing Melee Cones

```lua
-- Draw melee attack cone
Draw.Cone(origin, lookVector, angle, range, Color3.new(1, 0.5, 0), 0.5)
```

## Debug Events

Subscribe to debug events for custom visualization:

```lua
-- Server-side
Rewind.Server.OnValidation:Connect(function(result)
    if result.accepted then
        print("✓ Hit accepted:", result.victims)
    else
        print("✗ Hit rejected:", result.reason)
    end
end)

-- Log all validation details
Rewind.Server.OnValidationDebug:Connect(function(debugInfo)
    print("Timestamp:", debugInfo.timestamp)
    print("Rewind delta:", debugInfo.rewindDelta)
    print("Snapshot age:", debugInfo.snapshotAge)
    print("Targets checked:", debugInfo.targetsChecked)
end)
```

## Console Logging

Enable verbose logging:

```lua
Rewind.Start({
    debug = { enabled = true },
})
```

Output:

```
[Rewind] Validation request from Player1
[Rewind]   Mode: Raycast
[Rewind]   Timestamp: 1234567.89
[Rewind]   Rewind delta: 0.15s
[Rewind]   Checking 1 targets
[Rewind]   Target Player2: HIT (Head)
[Rewind] Result: Accepted, 1 victim(s)
```

## Performance Profiling

Track validation performance:

```lua
local Stats = Rewind.Server.Stats

-- Get current stats
print("Validations/sec:", Stats.GetValidationsPerSecond())
print("Avg validation time:", Stats.GetAverageValidationTime())
print("Snapshot memory:", Stats.GetSnapshotMemory())

-- Reset stats
Stats.Reset()
```

## Common Issues

### Hitboxes Not Showing

1. Ensure `debugMode = true` on both client and server
2. Check that Iris is installed: `Packages/_Index/sirmallard_iris`
3. Verify the debug panel is toggled on (F6)

### Clock Sync Issues

Check sync status:

```lua
local ClockSync = Rewind.ClockSync
print("Has lock:", ClockSync.HasLock())
print("Offset:", ClockSync.GetOffset())
print("RTT:", ClockSync.GetRTT())
```

### Validation Always Failing

Enable debug to see rejection reasons:

```lua
local result = Rewind.Validate(player, "Raycast", params)
if not result.accepted then
    warn("Rejected:", result.reason)
    warn("Debug info:", result.debugInfo)
end
```

## Testing Tools

### Simulate Lag

Test with artificial latency using Roblox Studio's Network Simulator (View > Network Simulator) or by adding delays in your hit validation code.

### Force Rewind

Test specific rewind scenarios:

```lua
-- Server-side: Force validate at specific time
local result = Rewind.Server.ValidateAtTime(timestamp, params)
```

## Best Practices

1. **Disable in production** - Set `debugMode = false` for release
2. **Use sparingly** - Debug visualization impacts performance
3. **Log suspicious patterns** - Track rejection reasons
4. **Test with lag** - Simulate high ping to verify compensation
