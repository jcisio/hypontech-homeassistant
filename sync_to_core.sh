#!/bin/bash

# Sync script to copy changes from custom component to Home Assistant core
# Usage: ./sync_to_core.sh [--dry-run]

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Directories
CUSTOM_DIR="/workspaces/hypontech-homeassistant/custom_components/hypontech"
CORE_DIR="/workspaces/home-assistant-core/homeassistant/components/hypontech"
TEST_CUSTOM_DIR="/workspaces/hypontech-homeassistant/tests/hypontech"
TEST_CORE_DIR="/workspaces/home-assistant-core/tests/components/hypontech"

# Check if running in dry-run mode
DRY_RUN=false
if [ "$1" == "--dry-run" ]; then
    DRY_RUN=true
    echo -e "${YELLOW}Running in DRY-RUN mode - no files will be modified${NC}\n"
fi

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if directories exist
if [ ! -d "$CUSTOM_DIR" ]; then
    print_error "Custom component directory not found: $CUSTOM_DIR"
    exit 1
fi

if [ ! -d "$CORE_DIR" ]; then
    print_error "Core component directory not found: $CORE_DIR"
    exit 1
fi

print_status "Syncing from custom component to core..."
echo -e "  Source: ${CUSTOM_DIR}"
echo -e "  Target: ${CORE_DIR}\n"

# List of files to sync (excluding manifest.json and quality_scale.yaml)
FILES_TO_SYNC=(
    "__init__.py"
    "config_flow.py"
    "const.py"
    "coordinator.py"
    "sensor.py"
    "strings.json"
)

# Track changes
CHANGES_MADE=0

# Sync Python and JSON files
for file in "${FILES_TO_SYNC[@]}"; do
    SOURCE="$CUSTOM_DIR/$file"
    TARGET="$CORE_DIR/$file"

    if [ ! -f "$SOURCE" ]; then
        print_warning "Source file not found: $file (skipping)"
        continue
    fi

    # Check if files are different
    if ! cmp -s "$SOURCE" "$TARGET"; then
        print_status "Syncing $file..."

        if [ "$DRY_RUN" = false ]; then
            cp "$SOURCE" "$TARGET"
            print_success "  ✓ Updated $file"
        else
            print_warning "  [DRY-RUN] Would update $file"
        fi

        CHANGES_MADE=$((CHANGES_MADE + 1))
    else
        echo -e "  ✓ $file (no changes)"
    fi
done

# Handle manifest.json specially - need to restore core-specific fields
print_status "Checking manifest.json..."
CUSTOM_MANIFEST="$CUSTOM_DIR/manifest.json"
CORE_MANIFEST="$CORE_DIR/manifest.json"

# Create a temporary manifest with core-specific modifications
TEMP_MANIFEST=$(mktemp)

# Read custom manifest and modify for core
python3 << 'EOF' > "$TEMP_MANIFEST"
import json

with open("/workspaces/hypontech-homeassistant/custom_components/hypontech/manifest.json") as f:
    manifest = json.load(f)

# Remove custom component specific fields
if "version" in manifest:
    del manifest["version"]

# Add core-specific fields
manifest["quality_scale"] = "bronze"
manifest["documentation"] = "https://www.home-assistant.io/integrations/hypontech"

# Pretty print
print(json.dumps(manifest, indent=2))
EOF

# Check if the modified manifest differs from core manifest
if ! cmp -s "$TEMP_MANIFEST" "$CORE_MANIFEST"; then
    if [ "$DRY_RUN" = false ]; then
        cp "$TEMP_MANIFEST" "$CORE_MANIFEST"
        print_success "  ✓ Updated manifest.json (with core-specific fields)"
    else
        print_warning "  [DRY-RUN] Would update manifest.json"
    fi
    CHANGES_MADE=$((CHANGES_MADE + 1))
else
    echo -e "  ✓ manifest.json (no changes)"
fi

rm "$TEMP_MANIFEST"

# Sync test files
if [ -d "$TEST_CUSTOM_DIR" ]; then
    print_status "Syncing test files..."

    for test_file in "$TEST_CUSTOM_DIR"/*.py; do
        if [ -f "$test_file" ]; then
            filename=$(basename "$test_file")
            SOURCE="$test_file"
            TARGET="$TEST_CORE_DIR/$filename"

            if ! cmp -s "$SOURCE" "$TARGET" 2>/dev/null; then
                if [ "$DRY_RUN" = false ]; then
                    mkdir -p "$TEST_CORE_DIR"
                    cp "$SOURCE" "$TARGET"
                    print_success "  ✓ Updated tests/$filename"
                else
                    print_warning "  [DRY-RUN] Would update tests/$filename"
                fi
                CHANGES_MADE=$((CHANGES_MADE + 1))
            else
                echo -e "  ✓ tests/$filename (no changes)"
            fi
        fi
    done
else
    print_warning "Test directory not found in custom component"
fi

echo ""
if [ $CHANGES_MADE -eq 0 ]; then
    print_success "No changes detected - core component is up to date!"
else
    if [ "$DRY_RUN" = false ]; then
        print_success "Successfully synced $CHANGES_MADE file(s) to core component!"
        echo ""
        print_warning "Remember to:"
        echo "  1. Review the changes in the core component"
        echo "  2. Run tests: pytest ./tests/components/hypontech"
        echo "  3. Run linters: pre-commit run --files homeassistant/components/hypontech/*"
        echo "  4. Commit the changes to the core repository"
    else
        print_warning "Would sync $CHANGES_MADE file(s) (run without --dry-run to apply)"
    fi
fi

echo ""
