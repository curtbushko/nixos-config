# D&J Minecraft Server Modpack

This directory contains a Packwiz modpack for the Minecraft server running Fabric 1.21.

## Current Mods

- **Fabric API** (v0.100.4+1.21) - Required for most Fabric mods

## Using the Modpack with Prism Launcher (Client)

Automatic setup scripts are included to sync the server modpack to your Prism Launcher client.

### Initial Setup

After rebuilding your home-manager configuration, run:

```bash
minecraft-setup-modpack
```

This will:
1. Create a new Prism Launcher instance called "DnJ-Server-Modpack"
2. Configure it for Minecraft 1.21 with Fabric 0.16.9
3. Download and install all mods from the server modpack
4. Set up Java paths automatically

### Updating Mods

When you add new mods to the server modpack, sync them to your client:

```bash
minecraft-sync-mods
```

Or run the full setup again to rebuild everything:

```bash
minecraft-setup-modpack
```

### Manual Launch

1. Open Prism Launcher
2. Find the "DnJ-Server-Modpack" instance
3. Click "Launch"

## Adding New Mods

### Method 1: Using Packwiz CLI (Recommended)

If you have packwiz installed:

```bash
cd modules/nixos/services/minecraft/modpack
packwiz modrinth add <mod-slug>
```

This will:
1. Download the mod metadata
2. Create a `.pw.toml` file in the `mods/` directory
3. Update `index.toml` automatically

Then update the hashes:
```bash
packwiz refresh
```

### Method 2: Manual Addition

1. Find the mod on Modrinth and get the version ID
2. Create a new `.pw.toml` file in `mods/` directory:

```toml
name = "Mod Name"
filename = "mod-name-version.jar"
side = "both"  # or "server", "client"

[download]
url = "https://cdn.modrinth.com/data/MOD_ID/versions/VERSION_ID/mod-name-version.jar"
hash-format = "sha512"
hash = "..."

[update]
[update.modrinth]
mod-id = "MOD_ID"
version = "VERSION_ID"
```

3. Update `index.toml` with the new mod file and its hash:

```bash
cd modules/nixos/services/minecraft/modpack
sha256sum mods/your-new-mod.pw.toml
```

Add to `index.toml`:
```toml
[[files]]
file = "mods/your-new-mod.pw.toml"
hash = "<hash-from-above>"
metafile = true
```

4. Update the hash in `pack.toml`:

```bash
sha256sum index.toml
```

Update the `hash` value in the `[index]` section of `pack.toml`.

5. Add the mod to `minecraft-server.nix`:

```nix
modpack = pkgs.linkFarmFromDrvs "modpack-mods" [
  # ... existing mods ...
  (pkgs.fetchurl {
    url = "https://cdn.modrinth.com/data/MOD_ID/versions/VERSION_ID/mod-name-version.jar";
    sha512 = "...";
    name = "mod-name-version.jar";
  })
];
```

## Using fetchPackwizModpack (Future)

Once this modpack is committed to GitHub, you can use nix-minecraft's `fetchPackwizModpack` for easier management:

1. Commit and push the modpack directory
2. Get a stable GitHub URL (using a commit hash):
   ```
   https://raw.githubusercontent.com/curtbushko/nixos-config/<COMMIT>/modules/nixos/services/minecraft/modpack/pack.toml
   ```
3. Update `minecraft-server.nix`:
   ```nix
   modpack = pkgs.fetchPackwizModpack {
     url = "https://raw.githubusercontent.com/...";
     packHash = "sha256-0000000000000000000000000000000000000000000=";
   };
   ```
4. Build - Nix will show the correct `packHash` in the error
5. Update with the correct hash
6. Change symlinks to: `"mods" = "${modpack}/mods";`

This approach automatically downloads all mods and keeps them in sync with the manifest.

## Server Information

- **Minecraft Version**: 1.21
- **Mod Loader**: Fabric 0.16.9
- **Pack Format**: packwiz:1.1.0
