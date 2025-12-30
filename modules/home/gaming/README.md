# D&J Minecraft Server Modpack

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

