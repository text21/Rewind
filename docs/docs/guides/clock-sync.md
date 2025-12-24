---
sidebar_position: 1
---

# Clock Synchronization

Accurate time synchronization is critical for lag compensation. Rewind uses a rolling median filter to calculate the time offset between client and server.

## How It Works

```
Client                              Server
  │                                   │
  ├──── t1: Send ping ───────────────►│
  │                                   │
  │◄─────────────── t2: Receive ──────┤
  │                                   │
  │     RTT = t2 - t1                 │
  │     Offset = serverTime - localTime - RTT/2
  │                                   │
```

The client sends multiple pings to build up a sample set, then uses the median offset to filter out outliers caused by network jitter.

## Configuration

Clock sync settings are in `Config.lua`:

```lua
Config.ClockSync = {
    SampleCount = 8,        -- Samples before lock
    SyncInterval = 5.0,     -- Seconds between resyncs
    Timeout = 2.0,          -- Ping timeout
}
```

## Client API

### Checking Sync Status

```lua
local Rewind = require(ReplicatedStorage.Rewind)
local ClockSync = Rewind.ClockSync

-- Check if clock is synchronized
if ClockSync.HasLock() then
    print("Clock is synchronized!")
end

-- Wait for synchronization
ClockSync.OnLockAcquired:Wait()
```

### Getting Synchronized Time

```lua
-- Get current time (synchronized)
local now = ClockSync.ClientNow()

-- Get offset from server
local offset = ClockSync.GetOffset()

-- Get round-trip time
local rtt = ClockSync.GetRTT()
```

## Safe Defaults

All ClockSync methods have safe fallbacks before the clock is synchronized:

| Method        | Before Lock  | After Lock        |
| ------------- | ------------ | ----------------- |
| `ClientNow()` | `os.clock()` | Synchronized time |
| `GetOffset()` | `0`          | Calculated offset |
| `GetRTT()`    | `0`          | Measured RTT      |
| `HasLock()`   | `false`      | `true`            |

This means your code won't break if you call these before sync completes.

## Manual Resync

Force a resync if needed:

```lua
ClockSync.Resync()
```

## Server-Side

The server automatically responds to clock sync requests. No setup required!

```lua
-- Start clock sync server
Rewind.ClockSync.StartServer() -- Call this after Rewind.Start()
```

## Debugging

Enable debug mode to see sync progress:

```lua
Rewind.Start({
    debug = { enabled = true },
})
```

You'll see output like:

```
[Rewind] ClockSync: Sample 1/8, offset = 0.023s
[Rewind] ClockSync: Sample 2/8, offset = 0.021s
...
[Rewind] ClockSync: Lock acquired, final offset = 0.022s
```

## Best Practices

1. **Always wait for lock** before sending hits:

   ```lua
   if not ClockSync.HasLock() then
       ClockSync.OnLockAcquired:Wait()
   end
   ```

2. **Use ClientNow()** for all timestamps sent to server

3. **Don't cache timestamps** - always get fresh values

4. **Handle resync gracefully** - the offset might change slightly
