---
sidebar_position: 3
---

# Installation

## Using Wally

Add Rewind to your `wally.toml`:

```toml
[dependencies]
Rewind = "text21/rewind@1.2.1"
```

Then run:

```bash
wally install
```

## Or Install RBXM (Recommended)

1. Download the latest release: [Rewindv1.2.1.rbxm](https://github.com/text21/Rewind/raw/main/docs/RobloxBuilds/Rewindv1.2.1.rbxm)
2. Insert the RBXM file into `ReplicatedStorage` in Roblox Studio
3. Done! The module is ready to use

## Dependencies

Rewind requires the following packages:

| Package | Version | Purpose                          |
| ------- | ------- | -------------------------------- |
| Promise | ^4.0.0  | Async operations                 |
| Signal  | ^2.0.0  | Event handling                   |
| Trove   | ^1.0.0  | Cleanup management               |
| t       | ^3.0.0  | Runtime type checking (optional) |

## Project Configuration

### Rojo Configuration

Add to your `default.project.json`:

```json
{
  "tree": {
    "$className": "DataModel",
    "ReplicatedStorage": {
      "$className": "ReplicatedStorage",
      "Packages": {
        "$path": "Packages"
      },
      "Rewind": {
        "$path": "src/shared/Rewind"
      }
    }
  }
}
```

### Creating RemoteEvents

Rewind requires specific RemoteEvents. They're auto-created if missing, but you can pre-create them:

```lua
-- In ReplicatedStorage.Remotes
local remotes = Instance.new("Folder")
remotes.Name = "RewindRemotes"
remotes.Parent = ReplicatedStorage

local clockSync = Instance.new("RemoteFunction")
clockSync.Name = "ClockSync"
clockSync.Parent = remotes

local hitValidation = Instance.new("RemoteEvent")
hitValidation.Name = "HitValidation"
hitValidation.Parent = remotes
```

## Verify Installation

Test that Rewind is installed correctly:

```lua
-- Server Script
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Rewind = require(ReplicatedStorage.Rewind)

print("Rewind version:", Rewind.Version) -- Should print "1.2.1"
```

## Next Steps

Continue to [Quick Start](/docs/quick-start) to set up your first hit validation!
