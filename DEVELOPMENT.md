# Development Guide

This document describes the development workflow for maintaining both the custom component and the Home Assistant core integration.

## Repository Structure

```
hypontech-homeassistant/
├── custom_components/hypontech/    # Custom component (development version)
├── tests/hypontech/                # Tests for the integration
├── sync_to_core.sh                 # Script to sync changes to core
└── README.md                       # User documentation
```

## Development Workflow

### Making Changes

1. **Develop in Custom Component**
   - All development work should be done in `custom_components/hypontech/`
   - Write or update tests in `tests/hypontech/`

2. **Sync to Core Integration**
   ```bash
   # Dry run to see what will change
   ./sync_to_core.sh --dry-run

   # Actually sync the changes
   ./sync_to_core.sh
   ```

### What the Sync Script Does

The `sync_to_core.sh` script:

- ✅ Copies Python files (`__init__.py`, `config_flow.py`, `const.py`, etc.)
- ✅ Syncs test files from `tests/hypontech/` to core tests
- ✅ Updates `manifest.json` with core-specific fields:
  - Adds `quality_scale: bronze`
  - Updates documentation URL to Home Assistant website
  - Removes `version` field (custom component only)
- ❌ Does NOT copy `quality_scale.yaml` (core only)

### File-Specific Notes

#### manifest.json
The manifest differs between custom component and core:

**Custom Component:**
```json
{
  "domain": "hypontech",
  "documentation": "https://github.com/jcisio/hypontech-homeassistant",
  "version": "1.0.0"
}
```

**Core Integration:**
```json
{
  "domain": "hypontech",
  "documentation": "https://www.home-assistant.io/integrations/hypontech",
  "quality_scale": "bronze"
}
```

The sync script handles this automatically.

## Testing

### Running Tests

From the Home Assistant core directory:

```bash
# Run all tests for hypontech
pytest ./tests/components/hypontech \
  --cov=homeassistant.components.hypontech \
  --cov-report term-missing
```

### Writing Tests

- Place test files in `tests/hypontech/`
- Follow Home Assistant testing patterns
- Use fixtures from `conftest.py`
- Import from `homeassistant.components.hypontech` (works for both custom and core)

## Release Workflow

### Custom Component Release

1. Update version in `custom_components/hypontech/manifest.json`
2. Update `README.md` with any new features or changes
3. Commit changes:
   ```bash
   git add .
   git commit -m "Release v1.x.x"
   ```
4. Create and push tag:
   ```bash
   git tag -a v1.x.x -m "Release v1.x.x"
   git push origin main --tags
   ```
