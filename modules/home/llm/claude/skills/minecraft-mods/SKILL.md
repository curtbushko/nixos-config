# Minecraft Mod Management for NixOS (Packwiz)

## Overview
This skill helps manage Minecraft server mods in the NixOS configuration using packwiz as the source of truth. The minecraft-server.nix module automatically parses packwiz `.pw.toml` files to build the server modpack.

## File Locations
- **Server Module**: `/home/curtbushko/workspace/github.com/curtbushko/nixos-config/modules/nixos/services/minecraft/minecraft-server.nix`
- **Packwiz Modpack**: `/home/curtbushko/workspace/github.com/curtbushko/nixos-config/modules/nixos/services/minecraft/modpack/`
  - `pack.toml` - Modpack metadata (Minecraft version, Fabric version)
  - `index.toml` - Auto-generated index of all mods (managed by packwiz)
  - `mods/*.pw.toml` - Individual mod metadata files with URLs and hashes
- **Update Script**: `/home/curtbushko/workspace/github.com/curtbushko/nixos-config/modules/nixos/services/minecraft/packwiz-update.sh`
- **README**: `/home/curtbushko/workspace/github.com/curtbushko/nixos-config/modules/nixos/services/minecraft/README.md`

## How It Works

### Architecture

The minecraft-server.nix module uses a functional approach to build the modpack:

1. **Parsing .pw.toml files**: The `parseModToml` function reads each mod's `.pw.toml` file
2. **Server-side filtering**: Only includes mods where `side = "both"` or `side = "server"`
3. **Hash verification**: Supports sha256, sha512, and sha1 hash formats
4. **Automatic building**: Creates a `linkFarmFromDrvs` with all server mods

```nix
# Key components from minecraft-server.nix
parseModToml = tomlFile: let
  tomlContent = builtins.fromTOML (builtins.readFile tomlFile);
  isServerMod = tomlContent.side == "both" || tomlContent.side == "server";
  # ... hash handling ...
in
  if isServerMod
  then pkgs.fetchurl { url = ...; sha512 = ...; name = ...; }
  else null;

# All server mods automatically loaded
serverMods = builtins.filter (mod: mod != null) (
  map (file: parseModToml (modpackPath + "/mods/${file}"))
  (builtins.filter (file: lib.hasSuffix ".pw.toml" file) modFiles)
);
```

### Packwiz Workflow

Packwiz manages mod metadata in `.pw.toml` files. Each file contains:
- Download URL (typically Modrinth CDN)
- Filename
- Hash (for verification)
- Side (client, server, or both)
- Update information

## Common Operations

### Prerequisites
All packwiz commands should be run in the modpack directory:
```bash
cd /home/curtbushko/workspace/github.com/curtbushko/nixos-config/modules/nixos/services/minecraft/modpack
```

You can run packwiz via nix-shell:
```bash
nix-shell -p packwiz --run "packwiz <command>"
# or enter a shell
nix-shell -p packwiz
```

### Adding a Mod

```bash
# Add from Modrinth (recommended)
packwiz modrinth add <mod-slug>

# Example: Add Sodium
packwiz modrinth add sodium

# Non-interactive mode (auto-accept dependencies)
packwiz modrinth add -y sodium

# Add from CurseForge
packwiz curseforge add <mod-name>
```

Packwiz will:
1. Download mod metadata
2. Create a `.pw.toml` file in `mods/`
3. Update `index.toml` automatically
4. Prompt for required dependencies (unless using `-y`)

### Removing a Mod

```bash
packwiz remove <mod-name>

# Example
packwiz remove sodium
```

### Updating Mods

**Update all mods:**
```bash
# Using packwiz directly
packwiz update --all

# Using the update script (recommended - has better progress tracking)
cd /home/curtbushko/workspace/github.com/curtbushko/nixos-config/modules/nixos/services/minecraft
./packwiz-update.sh
```

**Update a specific mod:**
```bash
packwiz update <mod-name>
```

**The packwiz-update.sh script:**
- Updates all mods with progress tracking
- Shows which mods updated successfully
- Identifies mods stuck on older Minecraft versions
- Includes delay between updates to avoid rate limiting
- Configurable via environment variables:
  ```bash
  DELAY_SECONDS=3 ./packwiz-update.sh
  DRY_RUN=true ./packwiz-update.sh  # See what would happen
  ```

### Listing Mods

```bash
# List all mods
packwiz list

# Count mods
packwiz list | wc -l
```

### Refreshing Index

After manually editing `.pw.toml` files:
```bash
packwiz refresh
```

## Changing Minecraft Version

To upgrade to a new Minecraft version (e.g., 1.20.1 → 1.21.1):

**1. Update pack.toml:**
```bash
cd modpack
nano pack.toml
# Change:
# [versions]
# minecraft = "1.21.1"
```

**2. Update all mods for new version:**
```bash
# Refresh to pick up new Minecraft version
packwiz refresh

# Update all mods (they'll fetch versions for new MC version)
cd ..
./packwiz-update.sh
```

**3. Update server package in minecraft-server.nix:**
```nix
# Change from:
package = pkgs.fabricServers.fabric-1_20_1;
# To:
package = pkgs.fabricServers.fabric-1_21_1;
# Note: Use underscores, not dots!
```

**4. Check for mods without 1.21.1 versions:**
The packwiz-update.sh script will report mods stuck on older versions. You may need to:
- Find alternative mods
- Wait for mod updates
- Use compatibility layers (e.g., Sinytra Connector for NeoForge mods)

## Understanding .pw.toml Files

Example mod file (`mods/sodium.pw.toml`):
```toml
name = "Sodium"
filename = "sodium-fabric-0.6.5+mc1.21.1.jar"
side = "both"

[download]
url = "https://cdn.modrinth.com/data/AANobbMI/versions/abc123/sodium-fabric-0.6.5+mc1.21.1.jar"
hash-format = "sha512"
hash = "abc123..."

[update]
[update.modrinth]
mod-id = "AANobbMI"
version = "abc123"
```

**Key fields:**
- `side` - Determines if mod loads on server: "both", "server", or "client"
- `download.url` - Direct download URL (usually Modrinth CDN)
- `download.hash-format` - Hash type (sha256, sha512, or sha1)
- `download.hash` - Hash for verification
- `update.modrinth.mod-id` - Used by packwiz to check for updates

## Client Modpack

The packwiz modpack can be shared with clients:

**Option 1: Packwiz Installer (Recommended)**
Clients run packwiz-installer in their `.minecraft` directory to auto-download all client-compatible mods.

**Option 2: Export to modpack format**
```bash
cd modpack
packwiz modrinth export     # Creates .mrpack file
packwiz curseforge export   # Creates .zip for CurseForge
```

## Troubleshooting

### Mod not found for Minecraft version
Some mods may not support the target version yet:
```bash
# Search for alternatives
packwiz modrinth search <name>

# Check mod page manually
# https://modrinth.com/mod/<slug>
```

### Dependencies
Packwiz prompts for dependencies automatically:
```
Mod X requires dependency Y. Install? [Y/n]
```

Use `-y` flag to auto-accept: `packwiz modrinth add -y <mod>`

### Side Configuration
If a mod should be server-only but packwiz marks it as "both":
1. Edit the `.pw.toml` file manually
2. Change `side = "both"` to `side = "server"`
3. Run `packwiz refresh`

### NixOS Build Integration
When you rebuild NixOS:
1. The module reads all `.pw.toml` files in `modpack/mods/`
2. Filters for server-compatible mods (`side = "both"` or `side = "server"`)
3. Downloads and verifies each mod using hashes
4. Creates symlink farm for the Minecraft server

**No manual hash management needed** - packwiz handles all hashes automatically!

## Resource Packs and Datapacks

These are still manually configured in minecraft-server.nix:

**Resource packs** (lines 54-115):
```nix
resourcepacks = pkgs.linkFarmFromDrvs "resourcepacks" [
  (pkgs.fetchurl { url = "..."; sha512 = "..."; name = "..."; })
];
```

**Datapacks** (lines 118-125):
```nix
datapacks = pkgs.linkFarmFromDrvs "datapacks" [
  (pkgs.fetchurl { url = "..."; sha512 = "..."; name = "..."; })
];
```

These can be found on Modrinth but aren't managed by packwiz in this configuration.

## Critical Checklist

When working with Minecraft server mods:

1. ✓ Always work in the `modpack/` directory for packwiz commands
2. ✓ Use `packwiz modrinth add` to add mods (not manual editing)
3. ✓ Use `packwiz-update.sh` for bulk updates with progress tracking
4. ✓ Check `side` field in `.pw.toml` - client-only mods won't load on server
5. ✓ Update `pack.toml` Minecraft version before migrating versions
6. ✓ Update server package in minecraft-server.nix to match Minecraft version
7. ✓ Let packwiz handle all dependencies automatically
8. ✓ Don't manually edit index.toml (auto-generated)
9. ✓ NixOS rebuild will automatically pick up packwiz changes

## Quick Reference

```bash
# Navigate to modpack
cd /home/curtbushko/.../nixos-config/modules/nixos/services/minecraft/modpack

# Add mod
nix-shell -p packwiz --run "packwiz modrinth add <slug>"

# Remove mod
nix-shell -p packwiz --run "packwiz remove <name>"

# Update all mods
cd .. && ./packwiz-update.sh

# List mods
nix-shell -p packwiz --run "packwiz list"

# Change Minecraft version
# 1. Edit modpack/pack.toml
# 2. Run ./packwiz-update.sh
# 3. Update minecraft-server.nix server package
```

## Resources

- [Packwiz Documentation](https://packwiz.infra.link/)
- [Modrinth](https://modrinth.com/)
- [Module README](../../../nixos/services/minecraft/README.md)
