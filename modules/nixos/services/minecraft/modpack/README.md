# D&J Minecraft Server Modpack

This directory contains a Packwiz modpack for the Minecraft server running Fabric 1.21.

## Architecture Overview

**Single Source of Truth**: The `.pw.toml` files in the `mods/` directory are the single source of truth for both client and server mods.

### How It Works

1. **Packwiz Modpack** (`modpack/mods/*.pw.toml`)
   - Contains metadata for all mods (URL, hash, side, etc.)
   - Managed using `packwiz` CLI tool
   - Updated with the `packwiz-update.sh` script

2. **Server Configuration** (`minecraft-server.nix`)
   - Automatically reads all `.pw.toml` files
   - Parses them and generates `fetchurl` derivations
   - Filters for server-compatible mods (`side = "both"` or `side = "server"`)
   - Handles multiple hash formats (SHA1, SHA256, SHA512)

3. **Client Configuration** (`modules/home/gaming/minecraft-modpack-setup.nix`)
   - References the same packwiz modpack
   - Uses `minecraft-modpack` script to sync with PrismLauncher
   - Installs all mods (client + both)

## Current Configuration

- **Minecraft Version**: 1.21
- **Mod Loader**: Fabric 0.16.9
- **Pack Format**: packwiz:1.1.0
- **Total Mods**: ~112 mods

## Managing Mods

### Adding a New Mod

Use packwiz to add mods from Modrinth:

```bash
cd modules/nixos/services/minecraft/modpack

# Add a mod by its Modrinth slug
packwiz modrinth add <mod-slug>

# Example: Add Lithium
packwiz modrinth add lithium
```

This will:
1. Create a new `.pw.toml` file in `mods/`
2. Automatically update `index.toml`
3. Update the pack hash in `pack.toml`

Then rebuild:
```bash
# Rebuild NixOS (server)
sudo nixos-rebuild switch

# Update client modpack
minecraft-modpack --setup
```

### Removing a Mod

```bash
cd modules/nixos/services/minecraft/modpack

# Remove a mod
packwiz remove <mod-name>

# Example: Remove lithium
packwiz remove lithium
```

This will:
1. Delete the `.pw.toml` file
2. Update `index.toml`
3. Update pack hash

Then rebuild as above.

### Updating All Mods

Use the provided update script to update all mods to the latest versions compatible with Minecraft 1.21:

```bash
cd modules/nixos/services/minecraft

# Run the update script
./packwiz-update.sh

# With custom delay to avoid rate limiting
DELAY_SECONDS=5 ./packwiz-update.sh

# Dry run to preview changes
DRY_RUN=true ./packwiz-update.sh
```

The script will:
1. Refresh the packwiz index (picks up `pack.toml` changes)
2. Update each mod using `packwiz update <mod-name>`
3. Show which mods were updated with version changes
4. Warn about mods that don't have 1.21 versions yet
5. Provide a summary of mods stuck on older Minecraft versions

After updating, rebuild:
```bash
sudo nixos-rebuild switch
minecraft-modpack --setup
```

### Manually Updating a Specific Mod

```bash
cd modules/nixos/services/minecraft/modpack

# Update a specific mod
packwiz update <mod-name>

# Example: Update sodium
packwiz update sodium
```

### Changing Minecraft Version

To change the target Minecraft version for mod updates:

1. Edit `pack.toml`:
   ```toml
   [versions]
   fabric = "0.16.9"
   minecraft = "1.21"  # Change this
   ```

2. Run the update script:
   ```bash
   cd modules/nixos/services/minecraft
   ./packwiz-update.sh
   ```

3. Update the client instance configuration in `modules/home/gaming/minecraft-modpack-setup.nix`:
   - Change `IntendedVersion=1.21` to match
   - Change `version: "1.21"` in `mmc-pack.json` to match

4. Rebuild everything:
   ```bash
   sudo nixos-rebuild switch
   minecraft-modpack --setup
   ```

## How the Server Build Works

The server automatically uses the packwiz modpack through Nix:

```nix
# From minecraft-server.nix
parseModToml = tomlFile: let
  tomlContent = builtins.fromTOML (builtins.readFile tomlFile);
  isServerMod = tomlContent.side == "both" || tomlContent.side == "server";
  # ... handles different hash formats (sha1, sha256, sha512) ...
in
  if isServerMod
  then pkgs.fetchurl { url = ...; sha512 = ...; name = ...; }
  else null;

# Reads all .pw.toml files
serverMods = map (file: parseModToml (modpackPath + "/mods/${file}")) modFiles;

# Creates modpack
modpack = pkgs.linkFarmFromDrvs "modpack-mods" serverMods;
```

Benefits:
- ✅ Single source of truth (no duplicate mod lists)
- ✅ Automatic filtering (client-only mods excluded from server)
- ✅ Always in sync (client and server use same mod versions)
- ✅ Easy maintenance (just use `packwiz` commands)
- ✅ Declarative (all managed through Nix)

## Troubleshooting

### Hash Mismatch Errors

If you get hash mismatch errors when building:
1. The `.pw.toml` files may have been updated by packwiz
2. Rebuild with `sudo nixos-rebuild switch`
3. Nix will automatically fetch new hashes

### Mods Not Updating to 1.21

Some mods may not have 1.21 versions yet. The update script will warn you:
```
⚠ No 1.21 version available - still on (mod-name-1.20.1.jar)
```

Options:
- Wait for the mod author to update
- Find an alternative mod
- Remove the mod if not essential
- Use `side = "client"` if it's only needed on client

### Rate Limiting from Modrinth API

If you hit rate limits when updating many mods:
```bash
# Increase delay between requests
DELAY_SECONDS=5 ./packwiz-update.sh
```

### Client/Server Version Mismatch

Both must use the same Minecraft version:
- Check `pack.toml` has `minecraft = "1.21"`
- Check `minecraft-modpack-setup.nix` has `version: "1.21"`
- Run `packwiz refresh` in the modpack directory
- Rebuild both server and client

## File Structure

```
modpack/
├── pack.toml              # Main pack configuration (MC version, etc.)
├── index.toml             # Index of all mod files (auto-generated)
├── README.md              # This file
└── mods/
    ├── fabric-api.pw.toml # Individual mod metadata
    ├── sodium.pw.toml     # (auto-managed by packwiz)
    ├── lithium.pw.toml
    └── ...
```

Each `.pw.toml` file contains:
```toml
name = "Mod Name"
filename = "mod-name-1.21-version.jar"
side = "both"  # or "server" or "client"

[download]
url = "https://cdn.modrinth.com/data/..."
hash-format = "sha512"  # or "sha256" or "sha1"
hash = "..."

[update]
[update.modrinth]
mod-id = "..."
version = "..."
```

## Scripts

- **`packwiz-update.sh`**: Updates all mods to latest compatible versions
  - Location: `modules/nixos/services/minecraft/packwiz-update.sh`
  - Supports dry-run mode and configurable delays
  - Shows version changes and warnings

- **`minecraft-modpack`**: Syncs client mods with PrismLauncher
  - Installed via home-manager
  - Run `minecraft-modpack --setup` to create/recreate instance
  - Run `minecraft-modpack` to sync mods only

- **`fetch-mods.sh`**: Helper to fetch individual mod info for server
  - Location: `modules/nixos/services/minecraft/fetch-mods.sh`
  - Useful for debugging or manual additions

## Best Practices

1. **Always use packwiz commands** to add/remove mods (not manual file edits)
2. **Test updates** on a local server before deploying to production
3. **Commit changes** to git after adding/removing mods
4. **Document** any manual modifications in this README
5. **Keep backups** of working configurations
6. **Update regularly** but test first
7. **Check mod compatibility** - some mods conflict with each other

## Adding Client-Only Mods

For mods that should only be on the client (like shaders or minimap):

```bash
cd modules/nixos/services/minecraft/modpack
packwiz modrinth add <mod-slug>
```

Then edit the `.pw.toml` file and change:
```toml
side = "client"  # Instead of "both"
```

The server will automatically exclude it when building.

## Performance Mods Included

This modpack includes several performance optimization mods:
- Sodium (rendering optimization)
- Lithium (server/game optimization)
- Ferrite Core (memory optimization)
- EntityCulling (render optimization)
- MoreCulling (additional culling)
- ImmediatelyFast (various optimizations)
- ModernFix (bug fixes and optimizations)

## Common Mod Categories

- **Performance**: sodium, lithium, ferrite-core, immediatelyfast
- **World Gen**: YUNG's mods, Biomes O' Plenty, terrablender
- **Gameplay**: cobblemon, create, waystones
- **QoL**: xaeros-minimap, shulkerboxtooltip, appleskin
- **Server Utils**: fabric-api, fabric-carpet, simple-voice-chat
