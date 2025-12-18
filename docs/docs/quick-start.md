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
Rewind.Server.Init()

-- Or with custom config
Rewind.Server.Init({
    maxRewindTime = 1.0,      -- Max rewind window (seconds)
    snapshotRate = 20,        -- Snapshots per second
    debugMode = false,        -- Enable debug logging
})

print("Rewind Server initialized!")
```

## 2. Client Setup

Create a client script to sync the clock:

```lua
-- StarterPlayerScripts/RewindClient.client.lua
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Rewind = require(ReplicatedStorage.Rewind)

-- Initialize clock sync
Rewind.Client.Init()

-- Wait for clock to synchronize
Rewind.ClockSync.OnLockAcquired:Wait()
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
    local result = Rewind.Validate(player, "Raycast", {
        origin = hitData.origin,
        direction = hitData.direction,
        targetIds = { hitData.targetUserId },
        weaponId = "Rifle",
        timestamp = hitData.timestamp,
    })

    if result.accepted then
        -- Hit was valid!
        for _, victim in result.victims do
            local humanoid = victim.character:FindFirstChild("Humanoid")
            if humanoid then
                humanoid:TakeDamage(25)
            end
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

- [Clock Sync Guide](./guides/clock-sync) - Understand time synchronization
- [Weapon Profiles](./guides/weapon-profiles) - Configure per-weapon settings
- [API Reference](./api/rewind) - Full API documentation
