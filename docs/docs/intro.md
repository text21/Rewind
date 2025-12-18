---
sidebar_position: 1
slug: /
---

# Introduction

**Rewind** is a server-authoritative lag compensation framework for Roblox games. It handles the complex task of validating player attacks (shots, projectiles, melee) by rewinding the game state to match what the attacker saw at the time of the attack.

## Why Lag Compensation?

In networked games, there's always latency between what a player sees and what's happening on the server. When a player shoots at an enemy, by the time that information reaches the server, the enemy may have already moved.

**Without lag compensation:**

- Hits that looked perfect on the client get rejected
- Players feel like the game is "eating" their shots
- High-ping players are at a massive disadvantage

**With Rewind:**

- The server rewinds player positions to the attacker's view time
- Hits are validated against where targets _were_, not where they _are_
- Fair gameplay regardless of connection quality

## Key Features

- 🛡️ **Server-Authoritative** - All validation on server, never trust the client
- ⏰ **Clock Synchronization** - Accurate time reconciliation between client and server
- 🎯 **Multi-Mode Validation** - Raycast, projectile, capsule, and melee support
- 🤖 **Automatic Rig Detection** - Built-in R6 and R15 hitbox profiles
- 📏 **Scaled Avatar Support** - Proper hitbox scaling for custom character sizes
- 🔧 **Debug Tools** - Real-time visualization with Iris debug panel
- 🚫 **Anti-Abuse** - Duplicate detection, distance sanity, rate limiting

## Quick Example

```lua
-- Server Script
local Rewind = require(ReplicatedStorage.Rewind)

-- Initialize the server
Rewind.Server.Init({
    maxRewindTime = 1.0,
    snapshotRate = 20,
})

-- Validate a raycast hit
local result = Rewind.Validate(player, "Raycast", {
    origin = origin,
    direction = direction,
    targetIds = { targetPlayer.UserId },
    weaponId = "Rifle",
    timestamp = timestamp,
})

if result.accepted then
    for _, victim in result.victims do
        victim.character:FindFirstChild("Humanoid"):TakeDamage(25)
    end
end
```

## Architecture Overview

```
┌─────────────┐         ┌─────────────┐
│   Client    │◄───────►│   Server    │
│             │         │             │
│ ClockSync   │         │ ClockSync   │
│ Input       │         │ Validation  │
│ Prediction  │         │ SnapshotStore│
└─────────────┘         └─────────────┘
                              │
                              ▼
                    ┌─────────────────┐
                    │  Snapshot Store │
                    │  (Ring Buffer)  │
                    │                 │
                    │ t-1000ms ──────►│
                    │ t-950ms  ──────►│
                    │ t-900ms  ──────►│
                    │    ...          │
                    │ t-0ms    ──────►│
                    └─────────────────┘
```

## Getting Started

Ready to integrate Rewind into your game? Head to the [Getting Started](./getting-started) guide!
