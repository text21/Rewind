---
sidebar_position: 5
---

# Client

Client-side module for clock synchronization and hit requests.

```lua
local Client = require(ReplicatedStorage.Rewind.Client)
-- or
local Client = Rewind.Client
```

## Functions

### Init

```lua
Client.Init(config: ClientConfig?): ()
```

Initialize the client module. Call this once at client startup.

**Parameters:**

- `config` - Optional configuration overrides

**Example:**

```lua
Client.Init({
    debugMode = true,
    debugToggleKey = Enum.KeyCode.F6,
})
```

---

### GetTimestamp

```lua
Client.GetTimestamp(): number
```

Get the current synchronized timestamp. Alias for `ClockSync.ClientNow()`.

**Returns:** Synchronized time in seconds.

**Example:**

```lua
local timestamp = Client.GetTimestamp()
HitRemote:FireServer({
    timestamp = timestamp,
    -- ...
})
```

---

### IsReady

```lua
Client.IsReady(): boolean
```

Check if the client is ready (clock synchronized).

**Returns:** `true` if clock is synchronized.

**Example:**

```lua
if Client.IsReady() then
    -- Safe to send hits
end
```

---

### WaitForReady

```lua
Client.WaitForReady(): ()
```

Yields until the client is ready.

**Example:**

```lua
Client.WaitForReady()
print("Client ready!")
```

---

## Events

### OnReady

```lua
Client.OnReady: Signal<>
```

Fired when the client becomes ready (clock synchronized).

**Example:**

```lua
Client.OnReady:Connect(function()
    print("Clock synchronized!")
end)
```

---

## Properties

### ClockSync

```lua
Client.ClockSync: ClockSyncModule
```

Access to clock synchronization. See [ClockSync API](./clock-sync).

---

## Debug Panel

When `debugMode` is enabled, the client shows an Iris debug panel.

### Toggle

Press the configured key (default: F6) to toggle the panel.

### Panel Sections

1. **Clock Sync** - Shows offset, RTT, lock status
2. **Stats** - Local hit statistics
3. **Performance** - Frame time, ping

### Manual Toggle

```lua
Client.ToggleDebugPanel()
```

---

## Type Definitions

### ClientConfig

```lua
type ClientConfig = {
    debugMode: boolean?,
    debugToggleKey: Enum.KeyCode?,
    simulatedLag: number?,  -- For testing
}
```

---

## Usage Example

```lua
-- StarterPlayerScripts/RewindClient.client.lua
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local Rewind = require(ReplicatedStorage.Rewind)

-- Initialize
Rewind.Client.Init({
    debugMode = game:GetService("RunService"):IsStudio(),
})

-- Wait for ready
Rewind.Client.WaitForReady()
print("Rewind client ready!")

-- Now safe to use timestamps
UserInputService.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        local timestamp = Rewind.Client.GetTimestamp()
        -- Send hit request with timestamp
    end
end)
```
