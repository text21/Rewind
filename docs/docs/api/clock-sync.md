---
sidebar_position: 8
---

# ClockSync

Clock synchronization module for accurate time reconciliation between client and server.

```lua
local ClockSync = Rewind.ClockSync
```

## Server Functions

### StartServer

```lua
ClockSync.StartServer(): ()
```

Start the clock sync server. Call this once on server startup.

**Example:**

```lua
-- Server
Rewind.ClockSync.StartServer()
```

---

## Client Functions

### StartClient

```lua
ClockSync.StartClient(opts: ClockSyncOptions?): ()
```

Start the clock sync client. Call this once on client startup.

**Parameters:**

- `opts` - Optional configuration

**Options:**

```lua
type ClockSyncOptions = {
    syncInterval: number?,    -- Resync interval in seconds (default 2.0)
    burstSamples: number?,    -- Samples per burst (default 5)
    alpha: number?,           -- EMA smoothing factor (default 0.12)
    useBestRtt: boolean?,     -- Use best RTT sample (default true)
    minGoodSamples: number?,  -- Min samples before lock (default 2)
}
```

**Example:**

```lua
-- Client
Rewind.ClockSync.StartClient()

-- With custom options
Rewind.ClockSync.StartClient({
    syncInterval = 5.0,
    burstSamples = 8,
})
```

---

### WaitForSync

```lua
ClockSync.WaitForSync(timeout: number?): boolean
```

Wait for the clock to synchronize (blocking).

**Parameters:**

- `timeout` - Optional timeout in seconds (default 10)

**Returns:** `true` if synced, `false` if timed out.

**Example:**

```lua
local synced = Rewind.ClockSync.WaitForSync()
if synced then
    print("Clock synchronized!")
else
    warn("Clock sync timed out")
end

-- With custom timeout
Rewind.ClockSync.WaitForSync(5) -- 5 second timeout
```

---

### ClientNow

```lua
ClockSync.ClientNow(): number
```

Get the current synchronized server time from the client.

**Returns:** Estimated server time in seconds.

**Safe Default:** Returns `os.clock()` if clock hasn't synchronized yet.

**Example:**

```lua
local timestamp = Rewind.ClockSync.ClientNow()
```

---

### GetTime

```lua
ClockSync.GetTime(): number
```

Alias for `ClientNow()`. Get the current synchronized time.

**Returns:** Estimated server time in seconds.

**Example:**

```lua
local timestamp = Rewind.ClockSync.GetTime()
```

---

### GetOffset

```lua
ClockSync.GetOffset(): number
```

Get the calculated time offset between client and server.

**Returns:** Offset in seconds.

**Safe Default:** Returns `0` before lock is acquired.

**Example:**

```lua
local offset = Rewind.ClockSync.GetOffset()
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
local rtt = Rewind.ClockSync.GetRTT()
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
if Rewind.ClockSync.HasLock() then
    print("Clock is synchronized!")
else
    print("Still synchronizing...")
end
```

---

### Stop

```lua
ClockSync.Stop(): ()
```

Stop the clock sync (client or server).

**Example:**

```lua
Rewind.ClockSync.Stop()
```

---

## How It Works

### Algorithm

1. Client sends ping with local timestamp `t0`
2. Server records receive time `t1` and send time `t2`
3. Client records receive time `t3`
4. RTT = `(t3 - t0) - (t2 - t1)`
5. Offset = `t1 - midpoint(t0, t3)`

### Exponential Moving Average

Samples are smoothed using EMA to handle network jitter:

```lua
offset = offset + (newSample - offset) * alpha
```

The default alpha of 0.12 provides good smoothing while still responding to changes.

---

## Safe Defaults

All functions have safe fallbacks before synchronization:

| Function      | Before Lock  | After Lock        |
| ------------- | ------------ | ----------------- |
| `ClientNow()` | `os.clock()` | Synchronized time |
| `GetTime()`   | `os.clock()` | Synchronized time |
| `GetOffset()` | `0`          | Calculated offset |
| `GetRTT()`    | `0`          | Measured RTT      |
| `HasLock()`   | `false`      | `true`            |

This ensures your code won't error if called before sync completes.

---

## Usage Patterns

### Pattern 1: Wait for Sync (Recommended)

```lua
Rewind.ClockSync.StartClient()
Rewind.ClockSync.WaitForSync()
local timestamp = Rewind.ClockSync.GetTime()
```

### Pattern 2: Check Before Use

```lua
if Rewind.ClockSync.HasLock() then
    local timestamp = Rewind.ClockSync.GetTime()
    -- Use timestamp
end
```

### Pattern 3: Non-Blocking Start

```lua
Rewind.ClockSync.StartClient()
-- Clock will sync in background
-- ClientNow() returns os.clock() until lock acquired
```

---

## Complete Example

```lua
-- Server
local Rewind = require(ReplicatedStorage.Packages.Rewind)
Rewind.Start()
Rewind.ClockSync.StartServer()
```

```lua
-- Client
local Rewind = require(ReplicatedStorage.Packages.Rewind)
Rewind.ClockSync.StartClient()
Rewind.ClockSync.WaitForSync()

print("Synced! Offset:", Rewind.ClockSync.GetOffset())
print("RTT:", Rewind.ClockSync.GetRTT() * 1000, "ms")

-- Now safe to send timestamps
local function onShoot()
    local timestamp = Rewind.ClockSync.GetTime()
    HitRemote:FireServer({ timestamp = timestamp, ... })
end
```
