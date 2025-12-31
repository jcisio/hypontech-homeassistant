#!/bin/bash

# Sync script to copy changes from Home Assistant core to custom component
# Usage: ./sync_from_core.sh [--dry-run]

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Directories
CORE_DIR="/workspaces/home-assistant-core/homeassistant/components/hypontech"
CUSTOM_DIR="/workspaces/hypontech-homeassistant/custom_components/hypontech"
TEST_CORE_DIR="/workspaces/home-assistant-core/tests/components/hypontech"
TEST_CUSTOM_DIR="/workspaces/hypontech-homeassistant/tests/hypontech"

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
if [ ! -d "$CORE_DIR" ]; then
    print_error "Core component directory not found: $CORE_DIR"
    exit 1
fi

if [ ! -d "$CUSTOM_DIR" ]; then
    print_error "Custom component directory not found: $CUSTOM_DIR"
    exit 1
fi

print_status "Syncing from core component to custom component..."
echo -e "  Source: ${CORE_DIR}"
echo -e "  Target: ${CUSTOM_DIR}\n"

# List of files to sync (excluding manifest.json)
FILES_TO_SYNC=(
    "__init__.py"
    "config_flow.py"
    "const.py"
    "coordinator.py"
    "entity.py"
    "sensor.py"
    "strings.json"
)

# Track changes
CHANGES_MADE=0

# Sync Python and JSON files
for file in "${FILES_TO_SYNC[@]}"; do
    SOURCE="$CORE_DIR/$file"
    TARGET="$CUSTOM_DIR/$file"

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

# Handle manifest.json specially - need to add custom component specific fields
print_status "Checking manifest.json..."
CORE_MANIFEST="$CORE_DIR/manifest.json"
CUSTOM_MANIFEST="$CUSTOM_DIR/manifest.json"

# Get the current version and increment patch number
CURRENT_VERSION="1.0.0"
NEW_VERSION=""

if [ -f "$CUSTOM_MANIFEST" ]; then
    CURRENT_VERSION=$(python3 -c "import json; print(json.load(open('$CUSTOM_MANIFEST')).get('version', '1.0.0'))" 2>/dev/null || echo "1.0.0")
fi

# Increment patch version
NEW_VERSION=$(python3 << VEOF
version = "$CURRENT_VERSION"
parts = version.split('.')
if len(parts) == 3:
    major, minor, patch = parts
    patch = str(int(patch) + 1)
    print(f"{major}.{minor}.{patch}")
else:
    print("1.0.1")
VEOF
)

# Create a temporary manifest with custom component specific modifications
TEMP_MANIFEST=$(mktemp)

# Read core manifest and modify for custom component
python3 << EOF > "$TEMP_MANIFEST"
import json

with open("$CORE_MANIFEST") as f:
    manifest = json.load(f)

# Remove core-specific fields
if "quality_scale" in manifest:
    del manifest["quality_scale"]

# Add custom component specific fields
manifest["version"] = "$NEW_VERSION"
manifest["documentation"] = "https://github.com/jcisio/hypontech-homeassistant"

# Pretty print
print(json.dumps(manifest, indent=2))
EOF

# Check if the modified manifest differs from custom manifest
if ! cmp -s "$TEMP_MANIFEST" "$CUSTOM_MANIFEST"; then
    if [ "$DRY_RUN" = false ]; then
        cp "$TEMP_MANIFEST" "$CUSTOM_MANIFEST"
        print_success "  ✓ Updated manifest.json (version: $CURRENT_VERSION → $NEW_VERSION)"
    else
        print_warning "  [DRY-RUN] Would update manifest.json (version: $CURRENT_VERSION → $NEW_VERSION)"
    fi
    CHANGES_MADE=$((CHANGES_MADE + 1))
else
    echo -e "  ✓ manifest.json (no changes)"
fi

rm "$TEMP_MANIFEST"

# Sync test files
if [ -d "$TEST_CORE_DIR" ]; then
    print_status "Syncing test files..."

    for test_file in "$TEST_CORE_DIR"/*.py; do
        if [ -f "$test_file" ]; then
            filename=$(basename "$test_file")
            SOURCE="$test_file"
            TARGET="$TEST_CUSTOM_DIR/$filename"

            if ! cmp -s "$SOURCE" "$TARGET" 2>/dev/null; then
                if [ "$DRY_RUN" = false ]; then
                    mkdir -p "$TEST_CUSTOM_DIR"
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
    print_warning "Test directory not found in core component"
fi

echo ""
if [ $CHANGES_MADE -eq 0 ]; then
    print_success "No changes detected - custom component is up to date!"
else
    if [ "$DRY_RUN" = false ]; then
        print_success "Successfully synced $CHANGES_MADE file(s) to custom component!"
        git add .
        git ci -am "Bump to version $NEW_VERSION"
        git tag $NEW_VERSION
        git push --follow-tags
        print_success "Tagged and pushed new version $NEW_VERSION"
    else
        print_warning "Would sync $CHANGES_MADE file(s) (run without --dry-run to apply)"
    fi
fi

echo ""
