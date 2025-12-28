{
  config,
  lib,
  pkgs,
  ...
}: let
  # Reference the server modpack
  modpackPath = ../../nixos/services/minecraft/modpack;

  # Create a script to set up Prism Launcher with the modpack
  setupScript = pkgs.writeShellScriptBin "minecraft-setup-modpack" ''
    set -e

    INSTANCE_NAME="DnJ-Server-Modpack"
    PRISM_DIR="$HOME/.local/share/PrismLauncher"
    INSTANCE_DIR="$PRISM_DIR/instances/$INSTANCE_NAME"

    echo "Setting up Minecraft modpack for Prism Launcher..."

    # Create Prism Launcher directory if it doesn't exist
    mkdir -p "$PRISM_DIR/instances"

    # Check if instance already exists
    if [ -d "$INSTANCE_DIR" ]; then
      echo "Instance '$INSTANCE_NAME' already exists."
      read -p "Do you want to update it? (y/N): " -n 1 -r
      echo
      if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Aborted."
        exit 0
      fi
    else
      echo "Creating new instance '$INSTANCE_NAME'..."
      mkdir -p "$INSTANCE_DIR"
    fi

    # Create instance.cfg
    cat > "$INSTANCE_DIR/instance.cfg" <<EOF
    InstanceType=OneSix
    name=$INSTANCE_NAME
    iconKey=default
    notes=D&J Minecraft Server Modpack - Auto-generated from nixos-config

    # Minecraft settings
    IntendedVersion=1.21
    JavaPath=${pkgs.openjdk25}/bin/java

    # Fabric loader
    ComponentDisplayName=Fabric Loader
    ComponentName=net.fabricmc.fabric-loader
    ComponentVersion=0.16.9
    EOF

    # Create mmc-pack.json
    cat > "$INSTANCE_DIR/mmc-pack.json" <<EOF
    {
      "components": [
        {
          "uid": "net.minecraft",
          "version": "1.21"
        },
        {
          "uid": "net.fabricmc.fabric-loader",
          "version": "0.16.9"
        }
      ],
      "formatVersion": 1
    }
    EOF

    # Create .minecraft directory structure
    mkdir -p "$INSTANCE_DIR/.minecraft/mods"

    # Copy packwiz manifest files
    echo "Copying packwiz manifest..."
    mkdir -p "$INSTANCE_DIR/.minecraft/packwiz"
    cp -r ${modpackPath}/* "$INSTANCE_DIR/.minecraft/packwiz/"

    # Create a packwiz bootstrap script
    cat > "$INSTANCE_DIR/.minecraft/install-mods.sh" <<'MODSCRIPT'
    #!/usr/bin/env bash
    set -e

    PACKWIZ_DIR="$HOME/.local/share/PrismLauncher/instances/$INSTANCE_NAME/.minecraft/packwiz"
    MODS_DIR="$HOME/.local/share/PrismLauncher/instances/$INSTANCE_NAME/.minecraft/mods"

    echo "Installing mods from packwiz manifest..."

    # Parse the .pw.toml files and download mods
    for modfile in "$PACKWIZ_DIR/mods"/*.pw.toml; do
      if [ -f "$modfile" ]; then
        # Extract URL and filename using basic parsing
        url=$(grep '^url = ' "$modfile" | cut -d'"' -f2)
        filename=$(grep '^filename = ' "$modfile" | cut -d'"' -f2)

        if [ -n "$url" ] && [ -n "$filename" ]; then
          echo "Downloading $filename..."
          ${pkgs.curl}/bin/curl -L -o "$MODS_DIR/$filename" "$url"
        fi
      fi
    done

    echo "Mods installed successfully!"
    MODSCRIPT

    chmod +x "$INSTANCE_DIR/.minecraft/install-mods.sh"

    # Automatically install mods
    echo ""
    echo "Installing mods..."
    bash "$INSTANCE_DIR/.minecraft/install-mods.sh"

    echo ""
    echo "✓ Setup complete!"
    echo ""
    echo "Instance '$INSTANCE_NAME' has been created/updated in Prism Launcher."
    echo ""
    echo "Next steps:"
    echo "1. Open Prism Launcher"
    echo "2. Look for the '$INSTANCE_NAME' instance"
    echo "3. Launch it and enjoy!"
    echo ""
    echo "To update mods in the future, run:"
    echo "  minecraft-setup-modpack"
    echo ""
  '';

  # Create a simpler sync-only script for updates
  syncScript = pkgs.writeShellScriptBin "minecraft-sync-mods" ''
    set -e

    INSTANCE_NAME="DnJ-Server-Modpack"
    INSTANCE_DIR="$HOME/.local/share/PrismLauncher/instances/$INSTANCE_NAME"

    if [ ! -d "$INSTANCE_DIR" ]; then
      echo "Error: Instance '$INSTANCE_NAME' not found."
      echo "Run 'minecraft-setup-modpack' first to create it."
      exit 1
    fi

    echo "Syncing mods from server modpack..."
    bash "$INSTANCE_DIR/.minecraft/install-mods.sh"
    echo "✓ Mods synced!"
  '';

in {
  home.packages = [
    setupScript
    syncScript
  ];
}
