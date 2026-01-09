---
sidebar_position: 4
---

# Quick Start

Get Rewind running in your game with this minimal example.

## 1. Server Setup

Create a server script to initialize Rewind:

```lua
-- ServerScriptService/RewindServer.server.lua
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Rewind = require(ReplicatedStorage.Rewind)

-- Initialize with default config
Rewind.Start()
Rewind.ClockSync.StartServer()

-- Or with custom config
Rewind.Start({
    snapshotHz = 20,          -- Snapshots per second
    windowMs = 1000,          -- Max rewind window (milliseconds)
    maxRewindMs = 500,        -- Max rewind allowed
})
Rewind.ClockSync.StartServer()

print("Rewind Server initialized!")
```

## 2. Client Setup

Create a client script to sync the clock:

```lua
-- StarterPlayerScripts/RewindClient.client.lua
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Rewind = require(ReplicatedStorage.Rewind)

-- Initialize clock sync
Rewind.ClockSync.StartClient()

-- Wait for clock to synchronize
Rewind.ClockSync.WaitForSync()
print("Clock synchronized!")
```

## 3. Weapon Script (Server)

Handle hit validation on the server:

```lua
-- Server weapon handler
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Rewind = require(ReplicatedStorage.Rewind)

local HitRemote = -- your hit remote

HitRemote.OnServerEvent:Connect(function(player, hitData)
    -- Use the high-level Validate API
    local result = Rewind.Validate(player, "Ray", {
        origin = hitData.origin,
        direction = hitData.direction,
        clientTime = hitData.timestamp,
        weaponId = "Rifle",
    })

    if result.hit then
        -- Hit was valid!
        if result.humanoid then
            result.humanoid:TakeDamage(25)
        end
    else
        -- Hit rejected
        warn("Hit rejected:", result.reason)
    end
end)
```

## 4. Weapon Script (Client)

Send hit requests from the client:

```lua
-- Client weapon handler
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Rewind = require(ReplicatedStorage.Rewind)

local HitRemote = -- your hit remote
local LocalPlayer = Players.LocalPlayer

local function onFire(mousePosition)
    local character = LocalPlayer.Character
    if not character then return end

    local origin = character:FindFirstChild("Head").Position
    local direction = (mousePosition - origin).Unit * 1000

    -- Get synchronized timestamp
    local timestamp = Rewind.ClockSync.ClientNow()

    -- Raycast locally for prediction (optional)
    local rayResult = workspace:Raycast(origin, direction)

    if rayResult and rayResult.Instance then
        local targetPlayer = Players:GetPlayerFromCharacter(
            rayResult.Instance:FindFirstAncestorOfClass("Model")
        )

        if targetPlayer then
            -- Send to server for validation
            HitRemote:FireServer({
                origin = origin,
                direction = direction,
                targetUserId = targetPlayer.UserId,
                timestamp = timestamp,
            })
        end
    end
end
```

## 5. Test It!

1. Start a local server with 2 players
2. Have one player shoot at the other
3. Check the server output for validation results

## What's Next?

- [Clock Sync Guide](/docs/guides/clock-sync) - Understand time synchronization
- [Weapon Profiles](/docs/guides/weapon-profiles) - Configure per-weapon settings
- [API Reference](/docs/api/rewind) - Full API documentation
