---
sidebar_position: 8
---

# Replication

Rewind v1.1.0 introduces a custom physics replication system that replaces Roblox's default character replication. This provides **unified state buffers** for both client interpolation AND server-side hit validation.

## Why Custom Replication?

Roblox's default character replication has limitations:

- **No access to historical positions** - Can't validate hits against past states
- **Fixed update rate** - No control over network bandwidth
- **No interpolation buffer** - Clients see raw updates with jitter

Rewind's replication system solves these problems:

- **Unified State Buffer** - Same history used for interpolation AND hit validation
- **Configurable Tick Rate** - Control updates per second (default 20)
- **Delta Compression** - Only send changed data to reduce bandwidth
- **Proximity-Based Updates** - Far entities update less frequently
- **Smooth Interpolation** - Clients render 100ms behind for smooth motion

## Quick Start

### Server Setup

```lua
local Rewind = require(ReplicatedStorage.Rewind)

-- Start with default settings
Rewind.StartReplication()

-- Or customize
Rewind.StartReplication({
    tickRate = 20,              -- updates per second
    deltaCompression = true,    -- only send changes
    proximityBased = true,      -- reduce distant updates
    clientAuthoritative = true, -- client controls own movement
})

-- Register players for custom replication
Players.PlayerAdded:Connect(function(player)
    player.CharacterAdded:Connect(function(character)
        Rewind.RegisterPlayerForReplication(player)
    end)
end)

-- Register NPCs
Rewind.RegisterNPCForReplication(npcModel)
```

### Client Setup

```lua
local Rewind = require(ReplicatedStorage.Rewind)

-- Start client-side interpolation
Rewind.StartReplicationClient({
    interpolationDelay = 100, -- ms behind server
    maxExtrapolation = 200,   -- max ms to predict
})
```

## Configuration

### ReplicationConfig

| Option                    | Type    | Default | Description                       |
| ------------------------- | ------- | ------- | --------------------------------- |
| `enabled`                 | boolean | true    | Enable/disable replication        |
| `tickRate`                | number  | 20      | Updates per second                |
| `interpolationDelay`      | number  | 100     | Client render delay (ms)          |
| `maxExtrapolation`        | number  | 200     | Max prediction time (ms)          |
| `deltaCompression`        | boolean | true    | Only send changed data            |
| `proximityBased`          | boolean | true    | Reduce distant updates            |
| `nearDistance`            | number  | 100     | Full update distance (studs)      |
| `farDistance`             | number  | 500     | Minimum update distance           |
| `farTickDivisor`          | number  | 4       | Divide tick rate for far entities |
| `clientAuthoritative`     | boolean | true    | Client controls own movement      |
| `reconciliationThreshold` | number  | 5       | Studs drift before correction     |

## Architecture

### Components

```
┌─────────────────────────────────────────────────────────┐
│                      SERVER                              │
│  ┌──────────────┐  ┌─────────────────┐  ┌────────────┐  │
│  │ EntityRegistry│→│ ServerReplicator │→│ StateBuffer │  │
│  └──────────────┘  └─────────────────┘  └────────────┘  │
│                            │                  ↓          │
│                            │         Hit Validation      │
└────────────────────────────┼────────────────────────────┘
                             │ StateUpdate (unreliable)
                             ↓
┌─────────────────────────────────────────────────────────┐
│                      CLIENT                              │
│  ┌──────────────────┐  ┌────────────┐                   │
│  │ ClientInterpolator│→│ StateBuffer │                   │
│  └──────────────────┘  └────────────┘                   │
│           │                                              │
│           ↓                                              │
│    Smooth Rendering                                      │
└─────────────────────────────────────────────────────────┘
```

### EntityRegistry

Central registry tracking all entities in the replication system.

```lua
local Replication = Rewind.Replication
local registry = Replication.GetRegistry()

-- Get all entities
local entities = registry:GetAll()

-- Get by type
local players = registry:GetByType("Player")
local npcs = registry:GetByType("NPC")

-- Get by model
local info = registry:GetByModel(characterModel)
print(info.id, info.entityType, info.priority)
```

### StateBuffer

Unified circular buffer for entity states. Used for BOTH interpolation and hit validation.

```lua
local StateBuffer = Rewind.Replication.StateBuffer

-- Create buffer (done automatically by ServerReplicator)
local buffer = StateBuffer.new("entity_123", 1000, 20) -- 1s window, 20 tick

-- Sample for interpolation (client)
local state = buffer:SampleInterpolated(targetTime)

-- Sample for rewind (server hit validation)
local state = buffer:SampleRewind(rewindTime)

-- Extrapolate when updates are late
local state = buffer:Extrapolate(targetTime, 200)
```

### ServerReplicator

Server-side broadcaster with optimization features.

```lua
local replicator = Rewind.Replication.GetServerReplicator()

-- Get buffer for hit validation
local buffer = replicator:GetBuffer(entityId)
local state = buffer:SampleRewind(rewindTime)

-- Sample directly
local state = replicator:SampleForRewind(entityId, rewindTime)
```

### ClientInterpolator

Client-side smooth rendering.

```lua
local interpolator = Rewind.Replication.GetClientInterpolator()

-- Get current interpolated position
local cf = interpolator:GetInterpolatedCFrame(entityId)

-- Configure smoothing
interpolator:Configure({
    smoothingFactor = 0.15, -- lower = smoother
    teleportThreshold = 10, -- studs
})
```

## Bandwidth Optimization

### Delta Compression

Only sends data when entities move:

```lua
Rewind.StartReplication({
    deltaCompression = true,
})
```

State updates include:

- Position (Vector3)
- Rotation (3 floats, euler angles)
- Velocity (Vector3, optional)

Typical payload: ~40 bytes per entity per update.

### Proximity-Based Updates

Reduce bandwidth for distant entities:

```lua
Rewind.StartReplication({
    proximityBased = true,
    nearDistance = 100,    -- full 20 tick/s
    farDistance = 500,     -- 5 tick/s (20/4)
    farTickDivisor = 4,
})
```

Example with 50 players:

- 10 nearby (< 100 studs): 20 updates/sec each = 200 updates/sec
- 40 distant (> 500 studs): 5 updates/sec each = 200 updates/sec
- **Total**: 400 updates/sec vs 1000 without optimization

## Network Ownership

When `clientAuthoritative = true`:

1. **Client sends own position** via `ClientState` remote
2. **Server validates** movement speed and distance
3. **Server corrects** if drift exceeds threshold

```lua
Rewind.StartReplication({
    clientAuthoritative = true,
    reconciliationThreshold = 5, -- studs before correction
})
```

## Integration with Hit Validation

The replication system integrates seamlessly with Rewind's hit validation:

```lua
-- Server: Validate hit using replication state buffer
local result = Rewind.ValidateRay(player, {
    origin = origin,
    direction = direction,
    clientTime = timestamp,
})

-- Behind the scenes, Rewind uses the unified StateBuffer
-- to sample the target's position at the rewind time
```

## NPC Support

NPCs are fully supported with the same replication system:

```lua
-- Server
local npc = createNPC()
Rewind.RegisterNPCForReplication(npc, 3) -- priority 3

-- Clients automatically receive NPC state updates
-- and apply interpolation for smooth movement
```

## Best Practices

1. **Start replication before registering entities**

   ```lua
   Rewind.StartReplication()
   Rewind.RegisterPlayerForReplication(player)
   ```

2. **Use appropriate tick rates**

   - Fast-paced shooters: 20-30 tick/s
   - Casual games: 10-15 tick/s
   - Turn-based: 5-10 tick/s

3. **Tune interpolation delay**

   - Lower (50ms): More responsive, more jitter
   - Higher (150ms): Smoother, more delay

4. **Enable proximity optimization for large servers**

   ```lua
   Rewind.StartReplication({
       proximityBased = true,
       farDistance = 300, -- reduce for smaller maps
   })
   ```

5. **Monitor bandwidth** using Stats:
   ```lua
   local stats = Rewind.GetStats()
   print("Updates/sec:", stats.replicationUpdates)
   ```
