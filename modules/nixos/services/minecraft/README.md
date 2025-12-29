# Minecraft Server Module

This module configures a Fabric Minecraft server with a packwiz-managed modpack.

## Files

### Configuration
- **`minecraft-server.nix`** - Main NixOS module for the Minecraft server
  - Configures Fabric server for Minecraft 1.20.1
  - Uses `pkgs.fetchPackwizModpack` to load mods from packwiz
  - Server properties and whitelist configuration

- **`default.nix`** - Module export

### Packwiz Modpack

- **`modpack/`** - Packwiz modpack directory
  - `pack.toml` - Modpack metadata (name, version, Minecraft/Fabric versions)
  - `index.toml` - Auto-generated index of all mods (managed by packwiz)
  - `mods/*.pw.toml` - Individual mod metadata files

### Resources

- **`mods.txt`** - Original mod wishlist (reference only, now managed by packwiz)

## Current Configuration

- **Minecraft Version**: 1.20.1
- **Mod Loader**: Fabric 0.16.9
- **Total Mods**: ~79 mods
- **Server Package**: `pkgs.fabricServers.fabric-1_20_1`
- **Modpack Management**: Packwiz

## Managing Mods with Packwiz

All mod management is done through packwiz CLI. You'll need packwiz available:

```bash
# Run packwiz commands via nix-shell
nix-shell -p packwiz --run "packwiz <command>"

# Or enter a shell with packwiz
nix-shell -p packwiz
```

### Common Operations

#### Add a Mod
```bash
cd modpack
nix-shell -p packwiz --run "packwiz modrinth add <mod-slug>"

# Example:
nix-shell -p packwiz --run "packwiz modrinth add sodium"
```

#### Remove a Mod
```bash
cd modpack
nix-shell -p packwiz --run "packwiz remove <mod-name>"
```

#### List All Mods
```bash
cd modpack
nix-shell -p packwiz --run "packwiz list"
```

#### Update All Mods
```bash
cd modpack
nix-shell -p packwiz --run "packwiz update --all"
```

#### Update a Specific Mod
```bash
cd modpack
nix-shell -p packwiz --run "packwiz update <mod-name>"
```

#### Refresh Index
After manually editing mod files, refresh the index:
```bash
cd modpack
nix-shell -p packwiz --run "packwiz refresh"
```

### Changing Minecraft Version

To update to a new Minecraft version:

1. **Update pack.toml**:
   ```bash
   cd modpack
   nano pack.toml
   # Change minecraft = "1.20.1" to desired version
   ```

2. **Migrate mods**:
   ```bash
   nix-shell -p packwiz --run "packwiz migrate <new-version>"
   ```

3. **Update server package** in `minecraft-server.nix`:
   ```nix
   package = pkgs.fabricServers.fabric-1_20_1;  # Change to match version
   ```

4. **Update hash** in `minecraft-server.nix`:
   - The first build will fail with the correct hash
   - Copy the hash from the error message
   - Update `packHash` in minecraft-server.nix

## Building the Server

When you rebuild your NixOS configuration, it will:
1. Fetch the packwiz pack.toml
2. Download all mods listed in index.toml
3. Verify all hashes
4. Create the modpack symlink for the server

## Client Modpack

The same packwiz modpack can be used for clients:

### Using Packwiz (Recommended)
Clients can use packwiz-installer or download directly:
```bash
# In client .minecraft directory
packwiz-installer
```

### Manual Export
```bash
cd modpack
nix-shell -p packwiz --run "packwiz curseforge export"
# or
nix-shell -p packwiz --run "packwiz modrinth export"
```

## Troubleshooting

### Build fails with hash mismatch
The packHash needs to be updated when mods change:
1. Set `packHash = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";`
2. Try to build
3. Copy the correct hash from the error message
4. Update packHash in minecraft-server.nix

### Mod not found
Some mods may not be available for your Minecraft version:
- Check mod compatibility on Modrinth
- Try `packwiz modrinth search <name>` to find alternatives

### Dependencies
Packwiz automatically handles mod dependencies:
- When adding a mod, it will prompt to add required dependencies
- Use `-y` flag for non-interactive mode: `packwiz modrinth add -y <mod>`

## Reference

- [Packwiz Documentation](https://packwiz.infra.link/)
- [Modrinth](https://modrinth.com/)
- [nixpkgs Minecraft](https://github.com/Infinidoge/nix-minecraft)
