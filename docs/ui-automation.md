# UI Automation with `gj` Tool

You CAN interact with simulator UI. Use the `gj` tool with AXe integration.

## Commands Available

```bash
# Tap by accessibility label (PREFERRED)
gj ui tap-button <app> "label"

# Tap by coordinates
gj ui tap <app> <x> <y>

# Get UI hierarchy (find labels)
gj ui describe <app>

# Screenshot
gj ui screenshot <app>

# Press home/Digital Crown
gj ui home <app>
```

## Orchestrator Accessibility Labels

| Action | Command |
|--------|---------|
| Enable scanning | `gj ui tap-button orchestrator "Scan Devices"` |
| Play on device | `gj ui tap-button orchestrator "Play {deviceName}"` |
| Stop on device | `gj ui tap-button orchestrator "Stop {deviceName}"` |
| Choose media | `gj ui tap-button orchestrator "Choose media {deviceName}"` |
| Choose scene | `gj ui tap-button orchestrator "Choose scene {deviceName}"` |
| Select media item | `gj ui tap-button orchestrator "Select media {itemName}"` |
| Select scene item | `gj ui tap-button orchestrator "Select scene {itemName}"` |
| Select option | `gj ui tap-button orchestrator "Select option {optionName}"` |
| Play all (group) | `gj ui tap-button orchestrator "Play All {appName}"` |
| Stop all (group) | `gj ui tap-button orchestrator "Stop All {appName}"` |
| Content button | `gj ui tap-button orchestrator "Content"` |
| Close sheet | `gj ui tap-button orchestrator "Close"` |

## Example: Full Playback Test

```bash
# 1. Enable device scanning
gj ui tap-button orchestrator "Scan Devices"

# 2. Wait for devices to appear
sleep 3
gj ui screenshot orchestrator

# 3. Choose media for a device (replace "Jeanne" with actual device name)
gj ui tap-button orchestrator "Choose media Jeanne"

# 4. Select media item
gj ui tap-button orchestrator "Select media Introduction"

# 5. Play
gj ui tap-button orchestrator "Play Jeanne"

# 6. Check logs
gj logs orchestrator "playback"
gj logs gmp "playback"
```

## Finding Labels

If you don't know the exact label:

```bash
# Dump full UI tree
gj ui describe orchestrator

# Search for specific text
gj ui describe orchestrator 2>&1 | grep -i "play\|stop\|scan"

# Search for buttons
gj ui describe orchestrator 2>&1 | grep -i "button"
```

## Troubleshooting

### "No accessibility element matched"

1. **Label might be different** - use `gj ui describe` to find exact text
2. **Element not on screen** - take screenshot first, scroll if needed
3. **Element is disabled** - check if preconditions are met
4. **Fallback to coordinates** - `gj ui tap orchestrator <x> <y>`

### Finding Coordinates

```bash
# Take screenshot, note dimensions
gj ui screenshot orchestrator

# Get element frame from describe
gj ui describe orchestrator 2>&1 | grep -B5 -A5 "Scan Devices"
# Look for "frame" with x, y, width, height
# Tap center: x + width/2, y + height/2
```

### Element Types

From `gj ui describe` output:
- `Button` - tappable
- `StaticText` - display only (tap won't do anything)
- `CheckBox` / `AXSwitch` - toggle
- `TextField` - text input

If tapping `StaticText` does nothing, look for the adjacent `Button` or `CheckBox`.

## Supported Apps

| App | Aliases | Platform |
|-----|---------|----------|
| `orchestrator` | `o`, `orch` | iOS/iPad Simulator |
| `pfizer` | `p`, `pf` | visionOS Simulator |
| `gmp` | `g` | visionOS Simulator |

Note: `ms` (Media Server) is macOS, not a simulator - no UI automation.

## How It Works

`gj ui tap-button` uses [AXe](https://github.com/cameroncooke/AXe) under the hood:

1. Calls `axe describe-ui` to get accessibility hierarchy
2. Finds element matching the label
3. Calculates center coordinates
4. Calls `axe tap` at those coordinates

This is why accessibility labels on UI elements are critical for automation.
