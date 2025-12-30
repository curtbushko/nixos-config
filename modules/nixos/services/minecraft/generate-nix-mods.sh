#!/usr/bin/env bash

# Script to generate Nix fetchurl calls from packwiz .pw.toml files

set -e

cd "$(dirname "$0")/modpack/mods"

echo "Generating Nix fetchurl calls for all mods..."
echo ""

# Output file
OUTPUT=$(mktemp)

# Header
cat >> "$OUTPUT" << 'EOF'
  # Modpack configuration using linkFarmFromDrvs
  # All mods are fetched individually and linked together
  modpack = pkgs.linkFarmFromDrvs "modpack-mods" [
EOF

# Process each .pw.toml file
for mod_file in *.pw.toml; do
  # Extract information from the .pw.toml file
  NAME=$(grep '^name = ' "$mod_file" | cut -d'"' -f2)
  FILENAME=$(grep '^filename = ' "$mod_file" | cut -d'"' -f2)
  URL=$(grep '^url = ' "$mod_file" | cut -d'"' -f2)
  HASH=$(grep '^hash = ' "$mod_file" | cut -d'"' -f2)

  if [ -z "$NAME" ] || [ -z "$FILENAME" ] || [ -z "$URL" ] || [ -z "$HASH" ]; then
    echo "Warning: Incomplete data for $mod_file, skipping"
    continue
  fi

  # Generate Nix code
  cat >> "$OUTPUT" << EOF
    # $FILENAME
    (pkgs.fetchurl {
      url = "$URL";
      sha512 = "$HASH";
      name = "$FILENAME";
    })
EOF
done

# Footer
cat >> "$OUTPUT" << 'EOF'
  ];
EOF

echo "Generated Nix code written to: $OUTPUT"
echo ""
echo "To update minecraft-server.nix:"
echo "1. Open minecraft-server.nix"
echo "2. Replace the modpack definition (lines 11-386) with the contents of $OUTPUT"
echo "3. Save and rebuild your NixOS configuration"
echo ""
cat "$OUTPUT"
