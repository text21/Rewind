---
sidebar_position: 2
---

# Getting Started

This guide will walk you through integrating Rewind into your Roblox game.

## Prerequisites

- A Roblox game project
- [Wally](https://wally.run/) package manager installed
- Basic understanding of server/client architecture

## Overview

Rewind consists of three main components:

1. **Server Module** - Handles snapshot storage and hit validation
2. **Client Module** - Manages clock synchronization and sends hit requests
3. **Shared Modules** - Types, config, and utility functions

## Project Structure

After installation, your project should include:

```
src/
├── server/
│   └── RewindServer.server.lua   -- Initialize server
├── client/
│   └── RewindClient.client.lua   -- Initialize client
└── shared/
    └── Rewind/                   -- The Rewind package
        ├── init.lua
        ├── Config.lua
        ├── Types.lua
        ├── Server/
        ├── Client/
        ├── ClockSync/
        └── ...
```

## Basic Flow

```
1. Server starts → Begins capturing snapshots
2. Client starts → Synchronizes clock with server
3. Player attacks → Client sends timestamp + attack params
4. Server receives → Rewinds to timestamp, validates hit
5. Server responds → Returns accepted/rejected + reason
```

## Next Steps

- [Installation](./installation) - Install Rewind with Wally
- [Quick Start](./quick-start) - Basic integration example
- [Weapon Profiles](./guides/weapon-profiles) - Configure per-weapon settings
