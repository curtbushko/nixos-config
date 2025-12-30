#!/usr/bin/env bash

# Script to update all 1.21/1.21.1 mods to 1.20.1 compatible versions
# This script uses packwiz to remove and re-add mods with the correct version

set -e

cd "$(dirname "$0")/modpack"

# List of mods that need to be updated to 1.20.1
MODS_TO_UPDATE=(
  "fabric-api"
  "geckolib"
  "paxi"
  "ribbits"
  "terrablender"
  "travelers-titles"
  "yungs-api"
  "yungs-better-caves"
  "yungs-better-desert-temples"
  "yungs-better-dungeons"
  "yungs-better-end-island"
  "yungs-better-jungle-temples"
  "yungs-better-mineshafts"
  "yungs-better-nether-fortresses"
  "yungs-better-ocean-monuments"
  "yungs-better-strongholds"
  "yungs-better-witch-huts"
  "yungs-bridges"
  "yungs-cave-biomes"
  "yungs-extras"
  "yungs-menu-tweaks"
)

# Get the Modrinth project ID from each .pw.toml file
get_modrinth_id() {
  local mod_file="$1"
  grep "mod-id" "mods/${mod_file}.pw.toml" | cut -d'"' -f2
}

echo "Updating ${#MODS_TO_UPDATE[@]} mods to Minecraft 1.20.1 compatible versions..."
echo ""

for mod in "${MODS_TO_UPDATE[@]}"; do
  echo "Processing: $mod"

  if [ ! -f "mods/${mod}.pw.toml" ]; then
    echo "  Warning: mods/${mod}.pw.toml not found, skipping"
    continue
  fi

  # Get the Modrinth project ID
  MOD_ID=$(get_modrinth_id "$mod")

  if [ -z "$MOD_ID" ]; then
    echo "  Error: Could not find Modrinth ID for $mod"
    continue
  fi

  echo "  Modrinth ID: $MOD_ID"
  echo "  Removing current version..."
  nix-shell -p packwiz --run "packwiz remove $mod" || true

  echo "  Adding 1.20.1 compatible version..."
  # Try to add the mod for 1.20.1
  # Packwiz should automatically pick a compatible version based on pack.toml
  nix-shell -p packwiz --run "packwiz modrinth install $MOD_ID -y" || {
    echo "  Warning: Failed to add $mod automatically, may need manual intervention"
  }

  echo ""
done

echo "Refreshing packwiz index..."
nix-shell -p packwiz --run "packwiz refresh"

echo ""
echo "Update complete! Check the mods directory to verify versions."
echo "Next, you'll need to update minecraft-server.nix with the new mod URLs and hashes."
