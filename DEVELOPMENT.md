# Development Guide

This document describes the development workflow for maintaining both the custom component and the Home Assistant core integration.

## Repository Structure

```
hypontech-homeassistant/
├── custom_components/hypontech/    # Custom component (synced from core)
├── tests/hypontech/                # Tests for the integration
├── sync_from_core.sh               # Script to sync changes from core
└── README.md                       # User documentation
```

## Development Workflow

### Making Changes

1. **Develop in Core Component**
   - Primary development work is done in the Home Assistant core repository
   - Make changes in `/workspaces/home-assistant-core/homeassistant/components/hypontech/`
   - Write or update tests in `/workspaces/home-assistant-core/tests/components/hypontech/`

2. **Sync to Custom Component**
   ```bash
   # Dry run to see what will change
   ./sync_from_core.sh --dry-run

   # Actually sync the changes
   ./sync_from_core.sh
   ```

### What the Sync Script Does

The `sync_from_core.sh` script:

- ✅ Copies Python files from core to custom component (`__init__.py`, `config_flow.py`, `const.py`, etc.)
- ✅ Syncs test files from core tests to `tests/hypontech/`
- ✅ Updates `manifest.json` with custom component specific fields:
  - Removes `quality_scale` field (core only)
  - Updates documentation URL to GitHub repository
  - Adds/increments `version` field (automatically bumps patch version)
- ❌ Does NOT copy `quality_scale.yaml` (core only)

### File-Specific Notes

#### manifest.json
The manifest differs between core and custom component:

**Core Integration:**
```json
{
  "domain": "hypontech",
  "documentation": "https://www.home-assistant.io/integrations/hypontech",
  "quality_scale": "bronze"
}
```

**Custom Component:**
```json
{
  "domain": "hypontech",
  "documentation": "https://github.com/jcisio/hypontech-homeassistant",
  "version": "1.0.0"
}
```

The sync script handles this automatically and increments the patch version with each sync.

## Testing

Use Home Assistant workflow.

## Release Workflow

### Custom Component Release

1. Sync changes from core (version is auto-incremented):
   ```bash
   ./sync_from_core.sh
   ```
2. Update `README.md` with any new features or changes if needed
3. Commit changes:
   ```bash
   git add .
   git commit -m "Sync from core - Release v1.x.x"
   ```
4. Create and push tag:
   ```bash
   git tag -a v1.x.x -m "Release v1.x.x"
   git push origin main --tags
   ```

Note: The version is automatically incremented by the sync script, so you don't need to manually update `manifest.json`.
