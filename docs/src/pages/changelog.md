---
title: Changelog
---

# Changelog

All notable changes to Rewind are documented here.

## [1.2.1] - Documentation & API Fixes 📚

### Fixes

- Fixed `ClockSync.WaitForSync()` - now properly implemented
- Added `ClockSync.GetTime()` alias for `ClientNow()`
- Fixed documentation to use correct `ValidationMode` values (`"Ray"`, `"Sphere"`, `"Capsule"`, `"Cone"`, `"Fan"`)
- Fixed all documentation examples to use `result.hit` instead of `result.accepted`
- Fixed documentation to use `clientTime` instead of `timestamp` in params
- Removed non-existent `Rewind.Server` module references from docs
- Updated `RejectReason` enum values in documentation
- Complete documentation audit for accuracy

---

## [1.0.0] - 2025-18-12

### 🎉 Initial Release

First public release of Rewind - a server-authoritative lag compensation framework for Roblox.

### Features

#### Core

- **Server-side hit validation** with configurable rewind window
- **Clock synchronization** using rolling median filter
- **Snapshot ring buffer** for efficient memory usage

#### Validation Modes

- **Ray** - Instant hitscan validation
- **Sphere** - Area of effect / explosion validation
- **Capsule** - Thick bullet sweep validation
- **Cone / Fan** - Melee attack validation

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

## [1.2.0] - Anti-Cheat & Vehicles 🛡️🚗

### New Features

- [x] **Vehicle & Mount Support** - Register vehicles with custom hitboxes, damage multipliers, and weak spots
- [x] **Armor System** - Multiple hitbox layers with damage reduction, regeneration, and armor breaking
- [x] **DataStore Abuse Tracking** - Persistent abuse tracking with automatic kick/ban enforcement
- [x] **Movement Anomaly Detection** - Speed hack, teleport, fly hack, and noclip detection

### Vehicle System

- Register vehicles and mounts for hit validation
- Custom hitboxes with damage multipliers and weak spots
- Passenger protection and targeting
- Mount rider registration
- Vehicle damage and destruction events

### Armor System

- Define armor layers for hitbox parts
- Configurable damage reduction (0-1 scale)
- Armor regeneration over time
- Layer breaking with minimum health thresholds
- Armor penetration support in weapon profiles
- Repair armor programmatically

### Abuse Tracker

- Automatic DataStore persistence
- Track abuse reasons: speed_hack, teleport, aimbot, damage_exploit, clip, fly_hack, packet_manipulation
- Configurable thresholds for warn/kick/ban
- Auto-kick and auto-ban enforcement
- `OnAbuseDetected` and `OnThresholdReached` events
- Ban/unban players programmatically

### Movement Validator

- Speed hack detection with tolerance
- Teleport detection with configurable distance threshold
- Fly hack detection based on air time
- Noclip detection through obstructed parts
- Speed multiplier support for abilities
- Violation tracking per player
- `OnAnomalyDetected` event

### API Additions

**Vehicle API:**

- `Rewind.RegisterVehicle(model, config)` - Register vehicle with custom hitboxes
- `Rewind.UnregisterVehicle(model)` - Remove vehicle from registry
- `Rewind.RegisterMount(model, config)` - Register mount (single rider)
- `Rewind.AddPassengerToVehicle(vehicle, player, seat?)` - Add passenger
- `Rewind.RemovePassengerFromVehicle(vehicle, player)` - Remove passenger
- `Rewind.SetMountRider(mount, player?)` - Set or clear mount rider
- `Rewind.GetPlayerVehicle(player)` - Get player's current vehicle/mount

**Armor API:**

- `Rewind.DefineArmor(entity, config)` - Define armor layers for entity
- `Rewind.RemoveArmor(entity)` - Remove armor from entity
- `Rewind.GetArmor(entity)` - Get current armor state
- `Rewind.ApplyDamageWithArmor(entity, partName, damage, armorPenetration?)` - Apply damage through armor
- `Rewind.RepairArmor(entity, partName?, amount?)` - Repair armor layers

**Abuse Tracker API:**

- `Rewind.StartAbuseTracking(config?)` - Start abuse tracking with DataStore
- `Rewind.RecordAbuse(player, reason, details?)` - Record abuse incident
- `Rewind.GetAbuseHistory(player)` - Get player's abuse history
- `Rewind.IsPlayerBanned(player)` - Check if player is banned
- `Rewind.BanPlayer(player, reason, duration?)` - Ban player
- `Rewind.UnbanPlayer(userId)` - Unban player by UserId
- `Rewind.OnAbuseDetected` - Signal fired on abuse detection
- `Rewind.OnAbuseThresholdReached` - Signal fired when threshold reached

**Movement Validator API:**

- `Rewind.ConfigureMovementValidation(config)` - Configure movement validation
- `Rewind.StartMovementMonitoring(player)` - Start monitoring player
- `Rewind.StopMovementMonitoring(player)` - Stop monitoring player
- `Rewind.ValidateMovement(player, position, velocity?)` - Validate movement
- `Rewind.SetPlayerSpeedMultiplier(player, multiplier, duration?)` - Set speed multiplier
- `Rewind.GetMovementViolations(player)` - Get violation count
- `Rewind.ClearMovementViolations(player)` - Clear violations
- `Rewind.OnMovementAnomaly` - Signal fired on anomaly detection

### Type Additions

- `VehicleHitbox`, `VehicleConfig`, `MountConfig`, `VehicleInfo`, `MountInfo`
- `ArmorLayer`, `ArmorConfig`, `ArmorState`, `DamageResult`
- `AbuseReason`, `AbuseRecord`, `PlayerAbuseHistory`, `AbuseConfig`
- `AnomalyType`, `MovementValidationResult`, `MovementConfig`, `PlayerMovementState`
- Updated `EntityType` to include "Vehicle" | "Mount"
- Updated `RejectReason` to include "vehicle_blocked" | "armor_absorbed"
- Updated `HitResult` with vehicle and armor information
- Updated `WeaponProfile` with `armorPenetration` field

---

## Planned Features

### v1.3.0

- [ ] Projectile simulation and validation
- [ ] Area-of-effect (AoE) hit validation

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

| Version | Date       | Highlights                         |
| ------- | ---------- | ---------------------------------- |
| 1.0.0   | 2025-18-12 | Initial release                    |
| 1.1.0   | 2025-20-12 | Physics Replication (Major Update) |
| 1.2.0   | 2025-21-12 | Anti-Cheat & Vehicles              |

---

## Contributing

Found a bug? Have a feature request?

- [Open an issue](https://github.com/text21/Rewind/issues)
- [Submit a PR](https://github.com/text21/Rewind/pulls)
