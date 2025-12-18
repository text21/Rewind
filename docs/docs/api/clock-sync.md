---
sidebar_position: 8
---

# ClockSync

Clock synchronization module for accurate time reconciliation between client and server.

```lua
local ClockSync = require(ReplicatedStorage.Rewind.ClockSync)
-- or
local ClockSync = Rewind.ClockSync
```

## Client Functions

### ClientNow

```lua
ClockSync.ClientNow(): number
```

Get the current synchronized time.

**Returns:** Server-synchronized time in seconds.

**Safe Default:** Returns `os.clock()` if clock hasn't synchronized yet.

**Example:**

```lua
local timestamp = ClockSync.ClientNow()
```

---

### GetOffset

```lua
ClockSync.GetOffset(): number
```

Get the calculated time offset between client and server.

**Returns:** Offset in seconds (serverTime - clientTime).

**Safe Default:** Returns `0` before lock is acquired.

**Example:**

```lua
local offset = ClockSync.GetOffset()
print("Time offset:", offset, "seconds")
```

---

### GetRTT

```lua
ClockSync.GetRTT(): number
```

Get the measured round-trip time.

**Returns:** RTT in seconds.

**Safe Default:** Returns `0` before lock is acquired.

**Example:**

```lua
local rtt = ClockSync.GetRTT()
print("Ping:", rtt * 1000, "ms")
```

---

### HasLock

```lua
ClockSync.HasLock(): boolean
```

Check if the clock has synchronized.

**Returns:** `true` if enough samples have been collected.

**Example:**

```lua
if ClockSync.HasLock() then
    print("Clock is synchronized!")
else
    print("Still synchronizing...")
end
```

---

### Resync

```lua
ClockSync.Resync(): ()
```

Force a resynchronization of the clock.

**Example:**

```lua
-- After network issues
ClockSync.Resync()
```

---

## Client Events

### OnLockAcquired

```lua
ClockSync.OnLockAcquired: Signal<>
```

Fired when the clock first synchronizes.

**Example:**

```lua
ClockSync.OnLockAcquired:Connect(function()
    print("Clock synchronized!")
end)

-- Or wait for it
ClockSync.OnLockAcquired:Wait()
```

---

### OnResync

```lua
ClockSync.OnResync: Signal<number>
```

Fired after each resync with the new offset.

**Example:**

```lua
ClockSync.OnResync:Connect(function(newOffset)
    print("Resynced, new offset:", newOffset)
end)
```

---

## Server Functions

### ServerNow

```lua
ClockSync.ServerNow(): number
```

Get the current server time. Used internally for timestamps.

**Returns:** Current server time in seconds.

---

### Init

```lua
ClockSync.Init(): ()
```

Initialize the server-side clock sync responder. Called automatically by `Server.Init()`.

---

## Configuration

Configure in `Config.ClockSync`:

```lua
Config.ClockSync = {
    SampleCount = 8,      -- Samples before lock
    SyncInterval = 5.0,   -- Resync interval (seconds)
    Timeout = 2.0,        -- Ping timeout (seconds)
}
```

---

## How It Works

### Algorithm

1. Client sends ping with local timestamp `t1`
2. Server responds with server time `t2`
3. Client records receive time `t3`
4. RTT = `t3 - t1`
5. Offset = `t2 - t1 - RTT/2`

### Median Filter

Multiple samples are collected and the median offset is used to filter out outliers caused by network jitter.

```
Samples: [0.021, 0.023, 0.150, 0.022, 0.024, 0.021, 0.023, 0.022]
                          ^^^
                      outlier (lag spike)

Median: 0.022 (accurate offset)
```

---

## Safe Defaults

All functions have safe fallbacks before synchronization:

| Function      | Before Lock  | After Lock        |
| ------------- | ------------ | ----------------- |
| `ClientNow()` | `os.clock()` | Synchronized time |
| `GetOffset()` | `0`          | Calculated offset |
| `GetRTT()`    | `0`          | Measured RTT      |
| `HasLock()`   | `false`      | `true`            |

This ensures your code won't error if called before sync completes.

---

## Usage Patterns

### Pattern 1: Wait for Lock

```lua
-- Block until ready
ClockSync.OnLockAcquired:Wait()
local timestamp = ClockSync.ClientNow()
```

### Pattern 2: Check Before Use

```lua
if ClockSync.HasLock() then
    local timestamp = ClockSync.ClientNow()
    -- Use timestamp
end
```

### Pattern 3: Event-Driven

```lua
ClockSync.OnLockAcquired:Connect(function()
    enableWeaponFiring()
end)
```

---

## Debugging

Enable debug mode to see sync progress:

```lua
-- In console:
-- [Rewind] ClockSync: Sample 1/8, offset = 0.023s
-- [Rewind] ClockSync: Sample 2/8, offset = 0.021s
-- ...
-- [Rewind] ClockSync: Lock acquired, offset = 0.022s, RTT = 0.045s
```

Check current state:

```lua
print("Has lock:", ClockSync.HasLock())
print("Offset:", ClockSync.GetOffset())
print("RTT:", ClockSync.GetRTT())
print("Current time:", ClockSync.ClientNow())
```
