# Hypontech Cloud Integration for Home Assistant

Custom component for integrating Hypontech Cloud energy storage systems with Home Assistant.

## Installation

### HACS (Recommended)

1. Open HACS in your Home Assistant instance
2. Go to "Integrations"
3. Click the three dots in the top right corner
4. Select "Custom repositories"
5. Add this repository URL: `https://github.com/jcisio/hypontech-homeassistant`
6. Select category "Integration"
7. Click "Add"
8. Find "Hypontech Cloud" in the list and click "Install"
9. Restart Home Assistant

### Manual Installation

1. Copy the `custom_components/hypontech` directory to your Home Assistant's `custom_components` directory
2. Restart Home Assistant

## Configuration

1. Go to Settings -> Devices & Services
2. Click "+ Add Integration"
3. Search for "Hypontech Cloud"
4. Follow the configuration steps to enter your credentials

## Features

- Monitor your Hypontech energy storage system
- Real-time data updates
- Sensor entities for battery status, power, energy, and more

## Requirements

- Home Assistant 2024.1.0 or later
- Hypontech Cloud account with valid credentials

## Support

For issues and feature requests, please use the [GitHub issue tracker](https://github.com/jcisio/hypontech-homeassistant/issues).

## License

This project is licensed under the Apache License 2.0.
