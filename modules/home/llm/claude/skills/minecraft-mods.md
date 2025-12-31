# Minecraft Mod Management for NixOS

## Overview
This skill helps manage Minecraft server mods in the NixOS configuration using Modrinth API and packwiz approach.

## File Locations
- **Server Config**: `/home/curtbushko/workspace/github.com/curtbushko/nixos-config/modules/nixos/services/minecraft/minecraft-server.nix`
- **Mod List**: `/home/curtbushko/workspace/github.com/curtbushko/nixos-config/modules/nixos/services/minecraft/mods.txt`
- **Modrinth API**: `https://api.modrinth.com/v2`

## Configuration Pattern

The minecraft-server.nix follows this structure:
```nix
{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (lib) mkIf;
  cfg = config.curtbushko.services.minecraft;

  modpack = pkgs.linkFarmFromDrvs "modpack-mods" [
    # mod-name-version.jar
    (pkgs.fetchurl {
      url = "https://cdn.modrinth.com/data/{PROJECT_ID}/versions/{VERSION_ID}/{FILENAME}";
      sha512 = "{SHA512_HASH}";
      name = "{FILENAME}";
    })
    # ... more mods ...
  ];
in {
  config = mkIf cfg.enable {
    services.minecraft-servers = {
      enable = true;
      eula = true;
      dataDir = "/var/lib/minecraft";

      servers.main = {
        enable = true;
        package = pkgs.fabricServers.fabric-{VERSION}; # e.g., fabric-1_21_1
        # ... server config ...
        symlinks = {
          "mods" = modpack;
        };
      };
    };
  };
}
```

## Fetching Mod Information

### Using Modrinth API with curl and jq

**Get mod version for specific Minecraft version:**
```bash
curl -s "https://api.modrinth.com/v2/project/{SLUG}/version?game_versions=%5B%22{MC_VERSION}%22%5D&loaders=%5B%22fabric%22%5D" | \
  jq -r '.[0] | "\(.files[0].url)|\(.files[0].filename)|\(.files[0].hashes.sha512)"'
```

**Check all available versions for a mod:**
```bash
curl -s "https://api.modrinth.com/v2/project/{SLUG}/version" | \
  jq -r '.[] | select(.loaders | index("fabric")) | .game_versions[]' | sort -u
```

**Search for mods:**
```bash
curl -s "https://api.modrinth.com/v2/search?query={QUERY}&facets=%5B%5B%22categories:fabric%22%5D,%5B%22versions:{MC_VERSION}%22%5D%5D" | \
  jq -r '.hits[] | "\(.slug) - \(.title)"'
```

## Workflow for Adding/Updating Mods

### 1. Adding a New Mod

1. **Check mods.txt** for the mod entry
   ```bash
   grep -i "{MOD_NAME}" /path/to/mods.txt
   ```

2. **Fetch mod information** from Modrinth:
   ```bash
   curl -s "https://api.modrinth.com/v2/project/{SLUG}/version?game_versions=%5B%22{MC_VERSION}%22%5D&loaders=%5B%22fabric%22%5D" | \
     jq -r '.[0] | {url: .files[0].url, filename: .files[0].filename, sha512: .files[0].hashes.sha512}'
   ```

3. **Add to minecraft-server.nix** in the modpack array:
   ```nix
   # {filename}
   (pkgs.fetchurl {
     url = "{url}";
     sha512 = "{sha512}";
     name = "{filename}";
   })
   ```

4. **Mark as checked in mods.txt**:
   - Change `- [ ] https://modrinth.com/mod/{slug}`
   - To `- [x] https://modrinth.com/mod/{slug}`

### 2. Upgrading Minecraft Version

1. **Determine target version** (check mod compatibility)

2. **Batch fetch all mods** for new version:
   ```bash
   # Extract current mod IDs
   grep -oP 'https://cdn\.modrinth\.com/data/\K[^/]+' minecraft-server.nix | sort -u > mod_ids.txt

   # Check each mod for new version
   while read id; do
     result=$(curl -s "https://api.modrinth.com/v2/project/$id/version?game_versions=%5B%22{NEW_VERSION}%22%5D&loaders=%5B%22fabric%22%5D" | \
       jq -r '.[0] | select(. != null) | "\(.files[0].url)|\(.files[0].filename)|\(.files[0].hashes.sha512)"')
     echo "$id|$result"
   done < mod_ids.txt > upgrade_results.txt
   ```

3. **Update server package** in minecraft-server.nix:
   - Change `pkgs.fabricServers.fabric-1_20_1`
   - To `pkgs.fabricServers.fabric-1_21_1` (underscores, not dots!)

4. **Regenerate minecraft-server.nix** with new versions

### 3. Handling Compatibility Layers

**For NeoForge mods on Fabric** (e.g., Create):
- Add **Sinytra Connector**: Compatibility layer
- Add **Forgified Fabric API**: Required dependency
- Add the **NeoForge mod**: Will run through Connector

```nix
# connector-{version}.jar (Sinytra Connector)
(pkgs.fetchurl { ... })
# forgified-fabric-api-{version}.jar
(pkgs.fetchurl { ... })
# {neoforge-mod-name}.jar
(pkgs.fetchurl { ... })
```

## Common Issues and Solutions

### Mod doesn't have Fabric version
- Check if NeoForge version exists
- Use Sinytra Connector if NeoForge version available
- Check if mod supports older Minecraft versions (1.20.1 vs 1.21.1)

### Version notation
- Modrinth uses dots: `1.21.1`
- NixOS package names use underscores: `fabric-1_21_1`
- Always encode versions in URLs: `%5B%22{VERSION}%22%5D` = `["{VERSION}"]`

### SHA512 hash format
- Must be lowercase hex string
- Exactly 128 characters long
- Provided by Modrinth API in `.files[0].hashes.sha512`

## mods.txt Format

```markdown
- [x] https://modrinth.com/mod/{slug}          # Installed
- [ ] https://modrinth.com/mod/{slug}          # Not installed
- [ ] https://modrinth.com/datapack/{slug}     # Datapack (different handling)
- [ ] https://modrinth.com/resourcepack/{slug} # Resource pack (not a mod)
```

## Critical Checklist

When working with Minecraft mods, ALWAYS:

1. ✓ Use Modrinth API to get official download URLs and hashes
2. ✓ Check mod loader compatibility (Fabric vs NeoForge)
3. ✓ Verify Minecraft version support (1.20.1, 1.21, 1.21.1, etc.)
4. ✓ Update both minecraft-server.nix AND mods.txt
5. ✓ Use correct NixOS package name format (underscores not dots)
6. ✓ Test mod dependencies (some mods require others)
7. ✓ Check for Sinytra Connector if Fabric version unavailable
8. ✓ Maintain alphabetical or logical ordering in modpack array

## Example Commands

**Quick mod lookup:**
```bash
curl -s "https://api.modrinth.com/v2/project/sodium/version?game_versions=%5B%221.21.1%22%5D&loaders=%5B%22fabric%22%5D" | jq '.[0] | {version: .version_number, file: .files[0].filename}'
```

**Find project ID from URL:**
```bash
curl -s "https://api.modrinth.com/v2/project/sodium" | jq -r '.id'
```

**Check mod's latest version:**
```bash
curl -s "https://api.modrinth.com/v2/project/sodium/version" | jq -r '.[0] | "\(.version_number) - MC \(.game_versions | join(", "))"'
```

## Utility Scripts

### Fetch Mods Script

This script fetches mod information from Modrinth API and outputs Nix fetchurl expressions ready to paste into minecraft-server.nix.

**Script Location:** `modules/nixos/services/minecraft/fetch-mods.sh`

**Usage:**
```bash
# From nixos-config directory
./modules/nixos/services/minecraft/fetch-mods.sh sodium

# Fetch multiple mods
./modules/nixos/services/minecraft/fetch-mods.sh sodium iris lithium

# Specify Minecraft version (default: 1.21.1)
MC_VERSION=1.21 ./modules/nixos/services/minecraft/fetch-mods.sh sodium

# Specify loader (default: fabric)
LOADER=neoforge ./modules/nixos/services/minecraft/fetch-mods.sh create

# Fetch all missing dependencies at once
./modules/nixos/services/minecraft/fetch-mods.sh \
  azurelib-armor player-animator pneumonocore \
  resourcefullib architectury-api puffish-skills
```

**Output Format:**
The script outputs ready-to-paste Nix expressions:
```nix
# filename.jar
(pkgs.fetchurl {
  url = "https://cdn.modrinth.com/...";
  sha512 = "abc123...";
  name = "filename.jar";
})
```

**Common Issues:**

1. **Mod not found**: The slug might be incorrect. Search for the correct slug:
   ```bash
   curl -s "https://api.modrinth.com/v2/search?query=<search-term>&facets=%5B%5B%22categories:fabric%22%5D%5D" | jq -r '.hits[] | "\(.slug) - \(.title)"'
   ```

2. **No version for Minecraft version**: Check available versions:
   ```bash
   curl -s "https://api.modrinth.com/v2/project/<slug>/version" | jq -r '.[] | select(.loaders | index("fabric")) | .game_versions[]' | sort -u
   ```

3. **Wrong loader**: Some mods are only available for NeoForge. Use `LOADER=neoforge` when fetching.
