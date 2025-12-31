#!/usr/bin/env bash
# Fetch Minecraft mod information from Modrinth API
# Usage: fetch-mods.sh <mod-slug> [mod-slug...]
#
# Example: fetch-mods.sh sodium iris lithium
#
# Environment variables:
#   MC_VERSION - Minecraft version to fetch (default: 1.21.1)
#   LOADER     - Mod loader (default: fabric)

set -euo pipefail

# Configuration
MC_VERSION="${MC_VERSION:-1.21.1}"
LOADER="${LOADER:-fabric}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check dependencies
if ! command -v curl &> /dev/null; then
    echo -e "${RED}Error: curl is required but not installed${NC}" >&2
    exit 1
fi

if ! command -v jq &> /dev/null; then
    echo -e "${RED}Error: jq is required but not installed${NC}" >&2
    exit 1
fi

# Check if arguments provided
if [ $# -eq 0 ]; then
    echo "Usage: $0 <mod-slug> [mod-slug...]"
    echo ""
    echo "Example: $0 sodium iris lithium"
    echo ""
    echo "Environment variables:"
    echo "  MC_VERSION - Minecraft version (default: $MC_VERSION)"
    echo "  LOADER     - Mod loader (default: $LOADER)"
    exit 1
fi

echo "Fetching mods for Minecraft $MC_VERSION ($LOADER)..."
echo ""

# Process each mod slug
for slug in "$@"; do
    echo -e "${YELLOW}=== Fetching: $slug ===${NC}"

    # Fetch mod information from Modrinth API
    result=$(curl -s "https://api.modrinth.com/v2/project/$slug/version?game_versions=%5B%22$MC_VERSION%22%5D&loaders=%5B%22$LOADER%22%5D" | \
        jq -r '.[0] | select(. != null) | "\(.files[0].url)|\(.files[0].filename)|\(.files[0].hashes.sha512)"')

    if [ -z "$result" ]; then
        echo -e "${RED}   No compatible version found for $slug${NC}"
        echo -e "${YELLOW}   Tip: Try searching for the correct slug or check available versions${NC}"
        echo ""
        continue
    fi

    # Parse result
    url=$(echo "$result" | cut -d'|' -f1)
    filename=$(echo "$result" | cut -d'|' -f2)
    sha512=$(echo "$result" | cut -d'|' -f3)

    echo -e "${GREEN}   Found: $filename${NC}"
    echo ""
    echo "    # $filename"
    echo "    (pkgs.fetchurl {"
    echo "      url = \"$url\";"
    echo "      sha512 = \"$sha512\";"
    echo "      name = \"$filename\";"
    echo "    })"
    echo ""
done

echo -e "${GREEN}  Done! Copy the output above and paste it into the modpack array in minecraft-server.nix${NC}"
