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

  # Bash script to generate servers.dat file with NBT format
  # NBT structure: root compound { servers: List<Compound> }
  serversGenerator = pkgs.writeShellScript "generate-servers.sh" ''
    #!/usr/bin/env bash
    set -e

    if [ $# -ne 3 ]; then
      echo "Usage: generate-servers.sh <output_path> <server_name> <server_ip>"
      exit 1
    fi

    OUTPUT_PATH="$1"
    SERVER_NAME="$2"
    SERVER_IP="$3"

    # Helper function to write big-endian 16-bit integer
    write_short() {
      printf '\x%02x\x%02x' $(($1 >> 8)) $(($1 & 0xFF))
    }

    # Helper function to write big-endian 32-bit integer
    write_int() {
      printf '\x%02x\x%02x\x%02x\x%02x' $(($1 >> 24)) $((($1 >> 16) & 0xFF)) $((($1 >> 8) & 0xFF)) $(($1 & 0xFF))
    }

    # Helper function to write NBT string (length + data)
    write_nbt_string() {
      local str="$1"
      local len=''${#str}
      write_short "$len"
      printf '%s' "$str"
    }

    # Create servers.dat with NBT format
    {
      # Root TAG_Compound (0x0A) with empty name
      printf '\x0a'
      write_short 0  # Root compound has no name

      # TAG_List (0x09) named "servers"
      printf '\x09'
      write_nbt_string "servers"
      printf '\x0a'  # List type: TAG_Compound
      write_int 1    # List length: 1 server

      # Server entry TAG_Compound (already started by list)

      # TAG_String (0x08) "name"
      printf '\x08'
      write_nbt_string "name"
      write_nbt_string "$SERVER_NAME"

      # TAG_String (0x08) "ip"
      printf '\x08'
      write_nbt_string "ip"
      write_nbt_string "$SERVER_IP"

      # TAG_End (0x00) - end of server compound
      printf '\x00'

      # TAG_End (0x00) - end of root compound
      printf '\x00'
    } > "$OUTPUT_PATH"
  '';

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
      --sync          Sync content only (fail if instance doesn't exist)
      --help, -h      Show this help message

    With no options, the script will:
      - Set up the instance if it doesn't exist
      - Sync content (mods, shader packs, resource packs) if it already exists
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

      echo "Syncing mods, shader packs, and resource packs from server modpack..."
      bash "$INSTANCE_DIR/.minecraft/install-mods.sh"
      echo "✓ Content synced!"
    }

    # Function to set up the instance from scratch
    setup_instance() {
      TEMP_DIR=$(${pkgs.coreutils}/bin/mktemp -d)
      PACK_DIR="$TEMP_DIR/$INSTANCE_NAME"

      echo "Setting up Minecraft modpack for Prism Launcher..."

      # Create temporary pack directory
      mkdir -p "$PACK_DIR/.minecraft/mods"
      mkdir -p "$PACK_DIR/.minecraft/shaderpacks"
      mkdir -p "$PACK_DIR/.minecraft/resourcepacks"

      # Create instance.cfg
      cat > "$PACK_DIR/instance.cfg" <<EOF
      InstanceType=OneSix
      name=$INSTANCE_NAME
      iconKey=default
      notes=D&J Minecraft Server Modpack - Auto-generated from nixos-config (NeoForge)
      IntendedVersion=1.21.1
      JavaPath=${pkgs.openjdk25}/bin/java
EOF

      # Create mmc-pack.json with proper format (using NeoForge to match server)
      cat > "$PACK_DIR/mmc-pack.json" <<'EOF'
      {
        "components": [
          {
            "uid": "net.minecraft",
            "version": "1.21.1"
          },
          {
            "uid": "net.neoforged",
            "version": "21.1.217"
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
      SHADERPACKS_DIR="\$PRISM_DIR/instances/\$INSTANCE_NAME/.minecraft/shaderpacks"
      RESOURCEPACKS_DIR="\$PRISM_DIR/instances/\$INSTANCE_NAME/.minecraft/resourcepacks"

      echo "Installing content from packwiz manifest..."

      # Parse the .pw.toml files and download mods
      if [ -d "\$PACKWIZ_DIR/mods" ]; then
        echo "Processing mods..."
        for modfile in "\$PACKWIZ_DIR/mods"/*.pw.toml; do
          # Skip if no .pw.toml files found (glob didn't match)
          [ -f "\$modfile" ] || continue

          # Extract URL and filename using basic parsing
          url=\$(grep '^url = ' "\$modfile" 2>/dev/null | cut -d'"' -f2)
          filename=\$(grep '^filename = ' "\$modfile" 2>/dev/null | cut -d'"' -f2)

          if [ -n "\$url" ] && [ -n "\$filename" ]; then
            echo "  Downloading \$filename..."
            curl -L -o "\$MODS_DIR/\$filename" "\$url"
          fi
        done
      fi

      # Parse and download shader packs
      if [ -d "\$PACKWIZ_DIR/shaderpacks" ]; then
        echo "Processing shader packs..."
        for shaderfile in "\$PACKWIZ_DIR/shaderpacks"/*.pw.toml; do
          # Skip if no .pw.toml files found (glob didn't match)
          [ -f "\$shaderfile" ] || continue

          # Extract URL and filename using basic parsing
          url=\$(grep '^url = ' "\$shaderfile" 2>/dev/null | cut -d'"' -f2)
          filename=\$(grep '^filename = ' "\$shaderfile" 2>/dev/null | cut -d'"' -f2)

          if [ -n "\$url" ] && [ -n "\$filename" ]; then
            echo "  Downloading \$filename..."
            curl -L -o "\$SHADERPACKS_DIR/\$filename" "\$url"
          fi
        done
      fi

      # Parse and download resource packs
      if [ -d "\$PACKWIZ_DIR/resourcepacks" ]; then
        echo "Processing resource packs..."
        for resourcefile in "\$PACKWIZ_DIR/resourcepacks"/*.pw.toml; do
          # Skip if no .pw.toml files found (glob didn't match)
          [ -f "\$resourcefile" ] || continue

          # Extract URL and filename using basic parsing
          url=\$(grep '^url = ' "\$resourcefile" 2>/dev/null | cut -d'"' -f2)
          filename=\$(grep '^filename = ' "\$resourcefile" 2>/dev/null | cut -d'"' -f2)

          if [ -n "\$url" ] && [ -n "\$filename" ]; then
            echo "  Downloading \$filename..."
            curl -L -o "\$RESOURCEPACKS_DIR/\$filename" "\$url"
          fi
        done
      fi

      echo "All content installed successfully!"
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

      # Install mods, shader packs, and resource packs
      echo ""
      echo "Installing mods, shader packs, and resource packs..."
      bash "$INSTANCE_DIR/.minecraft/install-mods.sh"

      # Create servers.dat with gamingrig server
      echo ""
      echo "Adding gamingrig server to server list..."
      ${serversGenerator} "$INSTANCE_DIR/.minecraft/servers.dat" "D&J Server (gamingrig)" "gamingrig:25565"

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
      echo "3. Launch it and join the D&J Server (gamingrig) - it's already in your server list!"
      echo ""
      echo "To update content (mods, shader packs, resource packs) in the future, run:"
      echo "  minecraft-modpack"
      echo ""
      echo "Note: The gamingrig server is pre-configured and ready to join."
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

  cfg = config.curtbushko.gaming;
  inherit (lib) mkIf;
in {
  config = mkIf cfg.enable {
    home.packages = [
      modpackScript
    ];
  };
}
