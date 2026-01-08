#!/usr/bin/env bash
# Update all packwiz mods to latest versions
# Checks both exact version (e.g., "1.21.1") and wildcard version (e.g., "1.21.x") on Modrinth
# This handles cases where mods are tagged with either format on Modrinth

set -euo pipefail

# Configuration
MODPACK_DIR="modpack"
DELAY_SECONDS="${DELAY_SECONDS:-2}"  # Delay between updates to avoid rate limiting
DRY_RUN="${DRY_RUN:-false}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Check dependencies
if ! command -v packwiz &> /dev/null; then
    echo -e "${RED}Error: packwiz is not installed${NC}" >&2
    echo "Install it with: go install github.com/packwiz/packwiz@latest" >&2
    exit 1
fi

if ! command -v curl &> /dev/null; then
    echo -e "${RED}Error: curl is not installed${NC}" >&2
    exit 1
fi

if ! command -v jq &> /dev/null; then
    echo -e "${RED}Error: jq is not installed (needed for Modrinth API queries)${NC}" >&2
    exit 1
fi

# Check if modpack directory exists
if [ ! -d "$MODPACK_DIR" ]; then
    echo -e "${RED}Error: Modpack directory '$MODPACK_DIR' not found${NC}" >&2
    exit 1
fi

cd "$MODPACK_DIR"

# Get Minecraft version from pack.toml and derive wildcard version
MC_VERSION=$(grep '^minecraft = ' pack.toml | cut -d'"' -f2)
# Convert 1.21.1 to 1.21.x by replacing the patch version with 'x'
MC_VERSION_WILDCARD=$(echo "$MC_VERSION" | sed -E 's/\.[0-9]+$/\.x/')

echo -e "${BLUE}Minecraft version: ${YELLOW}$MC_VERSION${NC}"
echo -e "${BLUE}Will also check for mods tagged with: ${YELLOW}$MC_VERSION_WILDCARD${NC}"
echo ""

# Get loader type
LOADER="neoforge"
if ! grep -q '^neoforge = ' pack.toml; then
    if grep -q '^fabric = ' pack.toml; then
        LOADER="fabric"
    fi
fi

# Function to get the latest version for a mod checking both exact and wildcard MC versions
get_latest_mod_version() {
    local mod_id="$1"
    local exact_version="$2"
    local wildcard_version="$3"
    local loader="$4"

    # Query Modrinth API for all versions of this mod
    local api_response=$(curl -s "https://api.modrinth.com/v2/project/${mod_id}/version")

    # Find the latest version that matches our criteria
    # Check for versions supporting either exact version OR wildcard version
    local latest=$(echo "$api_response" | jq -r --arg exact "$exact_version" --arg wildcard "$wildcard_version" --arg loader "$loader" '
        [.[] |
         select(.loaders[] | contains($loader)) |
         select(.game_versions[] | (. == $exact or . == $wildcard)) |
         {
           id: .id,
           version_number: .version_number,
           date_published: .date_published,
           filename: .files[0].filename,
           game_versions: .game_versions
         }
        ] |
        sort_by(.date_published) |
        last')

    if [ "$latest" != "null" ] && [ -n "$latest" ]; then
        echo "$latest"
        return 0
    else
        return 1
    fi
}

# Refresh packwiz index to pick up any pack.toml changes (like Minecraft version)
echo -e "${BLUE}Refreshing packwiz index...${NC}"
if ! packwiz refresh 2>&1 | grep -v "^$"; then
    echo -e "${RED}Warning: packwiz refresh had issues, but continuing...${NC}"
fi
echo ""

# Get all .pw.toml files
mod_files=$(find mods -name "*.pw.toml" -type f | sort)
total_mods=$(echo "$mod_files" | wc -l)

echo -e "${BLUE}=====================================${NC}"
echo -e "${BLUE}Packwiz Mod Updater${NC}"
echo -e "${BLUE}=====================================${NC}"
echo -e "Modpack: $(pwd)"
echo -e "Total mods to update: $total_mods"
echo -e "Delay between updates: ${DELAY_SECONDS}s"
if [ "$DRY_RUN" = "true" ]; then
    echo -e "${YELLOW}DRY RUN MODE - No changes will be made${NC}"
fi
echo ""

# Counters
success_count=0
error_count=0
skip_count=0
old_version_count=0
current=0

# Track mods stuck on old versions
declare -a old_version_mods

# Update each mod
for mod_file in $mod_files; do
    current=$((current + 1))
    mod_name=$(basename "$mod_file" .pw.toml)

    echo -e "${BLUE}[$current/$total_mods]${NC} Updating ${YELLOW}$mod_name${NC}..."

    if [ "$DRY_RUN" = "true" ]; then
        echo -e "  ${YELLOW}[DRY RUN]${NC} Would run: packwiz update $mod_name"
        skip_count=$((skip_count + 1))
    else
        # Get current version before update
        old_version=""
        current_version_id=""
        mod_id=""
        if [ -f "$mod_file" ]; then
            old_version=$(grep '^filename = ' "$mod_file" | cut -d'"' -f2 | head -1)
            # Extract Modrinth mod ID from [update.modrinth] section
            mod_id=$(grep -A 2 '^\[update\.modrinth\]' "$mod_file" | grep '^mod-id = ' | cut -d'"' -f2)
            current_version_id=$(grep -A 2 '^\[update\.modrinth\]' "$mod_file" | grep '^version = ' | cut -d'"' -f2)
        fi

        # Try to find latest version using Modrinth API (checking both exact and wildcard versions)
        latest_version_info=""
        if [ -n "$mod_id" ]; then
            latest_version_info=$(get_latest_mod_version "$mod_id" "$MC_VERSION" "$MC_VERSION_WILDCARD" "$LOADER" 2>/dev/null || echo "")
        fi

        # Determine which update method to use
        update_cmd="packwiz update \"$mod_name\""
        use_api_version=false
        if [ -n "$latest_version_info" ]; then
            latest_version_id=$(echo "$latest_version_info" | jq -r '.id')
            latest_filename=$(echo "$latest_version_info" | jq -r '.filename')

            # Only use specific version if it's different from current
            if [ -n "$latest_version_id" ] && [ "$latest_version_id" != "null" ] && [ "$latest_version_id" != "$current_version_id" ]; then
                update_cmd="packwiz modrinth install --project-id \"$mod_id\" --version-id \"$latest_version_id\" -y"
                use_api_version=true
                echo -e "  ${BLUE}→${NC} Found newer version via API: $latest_filename"
            fi
        fi

        # Run packwiz update and capture output
        if output=$(eval "$update_cmd" 2>&1); then
            # Get new version after update
            new_version=""
            if [ -f "$mod_file" ]; then
                new_version=$(grep '^filename = ' "$mod_file" | cut -d'"' -f2 | head -1)
            fi

            # Check if version changed
            if [ "$old_version" = "$new_version" ]; then
                # Check if it's still on an old Minecraft version
                if echo "$new_version" | grep -qE '1\.20|1\.19|1\.18'; then
                    echo -e "  ${YELLOW}⚠${NC}  No 1.21.1 version available - still on ${BLUE}($new_version)${NC}"
                    old_version_mods+=("$mod_name: $new_version")
                    old_version_count=$((old_version_count + 1))
                else
                    echo -e "  ${GREEN}✓${NC} Already up to date ${BLUE}($new_version)${NC}"
                fi
                success_count=$((success_count + 1))
            else
                echo -e "  ${GREEN}✓${NC} Updated successfully"
                echo -e "    ${YELLOW}Old:${NC} $old_version"
                echo -e "    ${GREEN}New:${NC} $new_version"
                success_count=$((success_count + 1))
            fi
        else
            echo -e "  ${RED}✗${NC} Error updating $mod_name"
            echo -e "  ${RED}Error:${NC} $output"
            error_count=$((error_count + 1))
        fi

        # Delay to avoid rate limiting (except for last mod)
        if [ $current -lt $total_mods ]; then
            sleep "$DELAY_SECONDS"
        fi
    fi
done

# Summary
echo ""
echo -e "${BLUE}=====================================${NC}"
echo -e "${BLUE}Update Summary${NC}"
echo -e "${BLUE}=====================================${NC}"
echo -e "Total mods: $total_mods"
if [ "$DRY_RUN" = "true" ]; then
    echo -e "${YELLOW}Dry run - no changes made${NC}"
else
    echo -e "${GREEN}Successful: $success_count${NC}"
    echo -e "${RED}Failed: $error_count${NC}"
    if [ "$old_version_count" -gt 0 ]; then
        echo -e "${YELLOW}Stuck on old MC versions: $old_version_count${NC}"
    fi
fi
echo ""

if [ "$old_version_count" -gt 0 ]; then
    echo -e "${YELLOW}=====================================${NC}"
    echo -e "${YELLOW}Mods Not Yet Updated to 1.21.1${NC}"
    echo -e "${YELLOW}=====================================${NC}"
    for mod_info in "${old_version_mods[@]}"; do
        echo -e "  ${YELLOW}⚠${NC}  $mod_info"
    done
    echo ""
    echo -e "${YELLOW}These mods may not have 1.21.1 versions yet.${NC}"
    echo -e "${YELLOW}Check Modrinth or consider alternative mods.${NC}"
    echo ""
fi

if [ "$error_count" -gt 0 ]; then
    echo -e "${YELLOW}Some mods failed to update. You may need to:${NC}"
    echo -e "  - Check the Modrinth page for those mods"
    echo -e "  - Increase DELAY_SECONDS if hitting rate limits"
    echo -e "  - Manually update problem mods"
    exit 1
fi

if [ "$old_version_count" -eq 0 ]; then
    echo -e "${GREEN}All mods updated successfully to 1.21.1!${NC}"
else
    echo -e "${GREEN}Update complete!${NC} ${YELLOW}($old_version_count mods still on older MC versions)${NC}"
fi
