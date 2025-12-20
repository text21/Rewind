---
title: Changelog
---

# Changelog

All notable changes to Rewind are documented here.

## [1.0.0] - 2025-18-12

### 🎉 Initial Release

First public release of Rewind - a server-authoritative lag compensation framework for Roblox.

### Features

#### Core

- **Server-side hit validation** with configurable rewind window
- **Clock synchronization** using rolling median filter
- **Snapshot ring buffer** for efficient memory usage

#### Validation Modes

- **Raycast** - Instant hitscan validation
- **Projectile** - Travel-time projectile validation
- **Capsule** - Thick bullet sweep validation
- **Melee** - Cone-based melee attack validation

#### Rig Support

- **Automatic rig detection** (R6/R15)
- **Built-in hitbox profiles** for both rig types
- **Scaled avatar support** with automatic hitbox adjustment

#### Anti-Abuse

- **Duplicate hit detection** (weapon-mode aware)
- **Distance sanity checks** for origin validation
- **Timestamp validation** (past/future bounds)
- **Rate limiting utilities**

#### Debug Tools

- **Iris debug panel** with real-time stats
- **Visual hitbox rendering**
- **Shot trace visualization**
- **Graceful degradation** if Iris unavailable

#### API

- **High-level `Validate()` dispatcher**
- **Per-weapon profiles** with custom parameters
- **`CreateParamsFromWeapon()` helper**
- **Comprehensive type definitions**

---

## [1.1.0] - Physics Replication (Major Update) 🚀

### New Features

- [x] **Interpolated snapshots** - Smooth rewind sampling with hermite interpolation
- [x] **Configurable Hit Priority** - Per body part priority and damage multipliers
- [x] **Custom Character Replication** - Replace Roblox's default physics replication
- [x] **Entity Registry** - Register players/NPCs for custom replication
- [x] **Server Replicator** - Broadcasts positions at configurable tick rate
- [x] **Client Interpolator** - Smooth interpolation between network updates
- [x] **State Buffer** - Unified history for interpolation AND hit validation
- [x] **Bandwidth Optimization** - Delta compression, proximity-based updates
- [x] **Network Ownership** - Client-authoritative movement with server reconciliation
- [x] **NPC Support** - Full replication support for AI entities
- [x] **Configurable Tick Rate** - Control network update frequency (default 20 Hz)

### API Additions

- `Rewind.Replication` - New replication module
- `Rewind.StartReplication(config)` - Start server-side replication
- `Rewind.StartReplicationClient(config)` - Start client interpolation
- `Rewind.RegisterPlayerForReplication(player)` - Register player for custom replication
- `Rewind.RegisterNPCForReplication(model)` - Register NPC for custom replication
- `HitboxProfile.GetHitPriority(profileId, partName)` - Get hit priority for body part
- `HitboxProfile.CompareByPriority(profileId, partA, partB)` - Compare parts by priority

### New Remotes

- `StateUpdate` (UnreliableRemoteEvent) - Server broadcasts entity states
- `StateCorrection` (RemoteEvent) - Server sends authoritative corrections
- `ClientState` (UnreliableRemoteEvent) - Client sends own state
- `EntityAdded` / `EntityRemoved` - Entity lifecycle events

---

## Planned Features

### v1.2.0

- [ ] Vehicle/mount support
- [ ] Multiple hitbox layers (armor system)

---

## Migration Guide

### From Custom Lag Compensation

If you're migrating from a custom solution:

1. **Replace clock sync** with `Rewind.ClockSync`
2. **Move validation** to server with `Rewind.Validate()`
3. **Update hit remotes** to send timestamps
4. **Configure weapon profiles** for your weapons

### From No Lag Compensation

If you're adding lag compensation for the first time:

1. Follow the [Quick Start](/docs/quick-start) guide
2. Start with default config
3. Test with simulated lag
4. Tune tolerances for your game feel

---

## Version History

| Version | Date       | Highlights      |
| ------- | ---------- | --------------- |
| 1.0.0   | 2025-18-12 | Initial release |

---

## Contributing

Found a bug? Have a feature request?

- [Open an issue](https://github.com/text21/Rewind/issues)
- [Submit a PR](https://github.com/text21/Rewind/pulls)
