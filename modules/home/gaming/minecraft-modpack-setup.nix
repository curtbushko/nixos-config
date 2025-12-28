{
  config,
  lib,
  pkgs,
  ...
}: let
  # Reference the server modpack
  modpackPath = ../../nixos/services/minecraft/modpack;

  # Platform-specific PrismLauncher directory
  prismDir = if pkgs.stdenv.isDarwin
    then "$HOME/Library/Application Support/PrismLauncher"
    else "$HOME/.local/share/PrismLauncher";

  # Combined script to manage Minecraft modpack - handles both setup and sync
  modpackScript = pkgs.writeShellScriptBin "minecraft-modpack" ''
    set -e

    INSTANCE_NAME="DnJ-Server-Modpack"
    PRISM_DIR="${prismDir}"
    INSTANCE_DIR="$PRISM_DIR/instances/$INSTANCE_NAME"

    # Parse command line arguments
    FORCE_SETUP=false
    SYNC_ONLY=false

    show_help() {
      cat <<HELP
    Usage: minecraft-modpack [OPTIONS]

    Manage the Minecraft modpack for Prism Launcher.

    OPTIONS:
      --setup, -s     Force full setup (recreate instance from scratch)
      --sync          Sync mods only (fail if instance doesn't exist)
      --help, -h      Show this help message

    With no options, the script will:
      - Set up the instance if it doesn't exist
      - Sync mods if it already exists
HELP
      exit 0
    }

    while [[ $# -gt 0 ]]; do
      case $1 in
        --setup|-s)
          FORCE_SETUP=true
          shift
          ;;
        --sync)
          SYNC_ONLY=true
          shift
          ;;
        --help|-h)
          show_help
          ;;
        *)
          echo "Unknown option: $1"
          show_help
          ;;
      esac
    done

    # Function to sync mods for an existing instance
    sync_mods() {
      if [ ! -d "$INSTANCE_DIR" ]; then
        echo "Error: Instance '$INSTANCE_NAME' not found."
        echo "Run 'minecraft-modpack --setup' to create it first."
        exit 1
      fi

      if [ ! -f "$INSTANCE_DIR/.minecraft/install-mods.sh" ]; then
        echo "Error: install-mods.sh script not found."
        echo "Run 'minecraft-modpack --setup' to recreate the instance."
        exit 1
      fi

      echo "Syncing mods from server modpack..."
      bash "$INSTANCE_DIR/.minecraft/install-mods.sh"
      echo "✓ Mods synced!"
    }

    # Function to set up the instance from scratch
    setup_instance() {
      TEMP_DIR=$(${pkgs.coreutils}/bin/mktemp -d)
      PACK_DIR="$TEMP_DIR/$INSTANCE_NAME"

      echo "Setting up Minecraft modpack for Prism Launcher..."

      # Create temporary pack directory
      mkdir -p "$PACK_DIR/.minecraft/mods"

      # Create instance.cfg
      cat > "$PACK_DIR/instance.cfg" <<EOF
      InstanceType=OneSix
      name=$INSTANCE_NAME
      iconKey=default
      notes=D&J Minecraft Server Modpack - Auto-generated from nixos-config
      IntendedVersion=1.21
      JavaPath=${pkgs.openjdk25}/bin/java
EOF

      # Create mmc-pack.json with proper format
      cat > "$PACK_DIR/mmc-pack.json" <<'EOF'
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

      # Copy packwiz manifest files
      echo "Copying packwiz manifest..."
      mkdir -p "$PACK_DIR/.minecraft/packwiz"
      cp -r ${modpackPath}/* "$PACK_DIR/.minecraft/packwiz/"

      # Create a packwiz bootstrap script
      cat > "$PACK_DIR/.minecraft/install-mods.sh" <<MODSCRIPT
      #!/usr/bin/env bash
      set -e

      INSTANCE_NAME="DnJ-Server-Modpack"
      PRISM_DIR="${prismDir}"
      PACKWIZ_DIR="\$PRISM_DIR/instances/\$INSTANCE_NAME/.minecraft/packwiz"
      MODS_DIR="\$PRISM_DIR/instances/\$INSTANCE_NAME/.minecraft/mods"

      echo "Installing mods from packwiz manifest..."

      # Parse the .pw.toml files and download mods
      if [ -d "$PACKWIZ_DIR/mods" ]; then
        for modfile in "$PACKWIZ_DIR/mods"/*.pw.toml; do
          # Skip if no .pw.toml files found (glob didn't match)
          [ -f "$modfile" ] || continue

          # Extract URL and filename using basic parsing
          url=$(grep '^url = ' "$modfile" 2>/dev/null | cut -d'"' -f2)
          filename=$(grep '^filename = ' "$modfile" 2>/dev/null | cut -d'"' -f2)

          if [ -n "$url" ] && [ -n "$filename" ]; then
            echo "Downloading $filename..."
            curl -L -o "$MODS_DIR/$filename" "$url"
          fi
        done
      fi

      echo "Mods installed successfully!"
MODSCRIPT

      chmod +x "$PACK_DIR/.minecraft/install-mods.sh"

      # Create zip file
      echo "Creating instance package..."
      cd "$TEMP_DIR"
      ${pkgs.zip}/bin/zip -r "$TEMP_DIR/instance.zip" "$INSTANCE_NAME" > /dev/null

      # Check if instance already exists and remove it
      if [ -d "$INSTANCE_DIR" ]; then
        echo "Removing existing instance '$INSTANCE_NAME'..."
        chmod -R u+w "$INSTANCE_DIR" 2>/dev/null || true
        rm -rf "$INSTANCE_DIR"
      fi

      # Import the instance by directly unzipping to instances directory
      echo "Importing instance to PrismLauncher..."
      mkdir -p "$PRISM_DIR/instances"
      cd "$PRISM_DIR/instances"
      ${pkgs.unzip}/bin/unzip -q "$TEMP_DIR/instance.zip"

      # Install mods
      echo ""
      echo "Installing mods..."
      bash "$INSTANCE_DIR/.minecraft/install-mods.sh"

      echo ""
      echo "✓ Setup complete!"
      echo ""
      echo "Instance '$INSTANCE_NAME' has been imported to Prism Launcher."

      # Cleanup (make files writable first since they come from Nix store)
      chmod -R u+w "$TEMP_DIR"
      rm -rf "$TEMP_DIR"

      echo ""
      echo "Next steps:"
      echo "1. Open Prism Launcher (if not already open)"
      echo "2. Look for the '$INSTANCE_NAME' instance"
      echo "3. Launch it and enjoy!"
      echo ""
      echo "To update mods in the future, run:"
      echo "  minecraft-modpack"
      echo ""
    }

    # Main logic
    if [ "$SYNC_ONLY" = true ]; then
      # Sync only mode - fail if instance doesn't exist
      sync_mods
    elif [ "$FORCE_SETUP" = true ]; then
      # Force setup mode - always recreate
      setup_instance
    else
      # Auto mode - setup if missing, sync if exists
      if [ -d "$INSTANCE_DIR" ]; then
        sync_mods
      else
        setup_instance
      fi
    fi
  '';

in {
  home.packages = [
    modpackScript
  ];
}
