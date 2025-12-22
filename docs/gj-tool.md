# gj Tool - Complete Reference

> Build, run, test, and debug GrooveTech apps. Use `gj` for everything - never raw xcodebuild.

## Installation

```bash
gj version
# Expected: gj version 1.5.0+

# If not installed:
cd "/Users/dalecarman/Groove Jones Dropbox/Dale Carman/Projects/dev/gj-tool"
./install.sh
```

---

## Quick Reference

| Command | Description |
|---------|-------------|
| `gj run <app>` | Build + install + launch + stream logs |
| `gj run --device <app>` | Build + install + launch on physical device |
| `gj run --clean <app>` | Clean build then run |
| `gj build <app>` | Build only (no launch) |
| `gj launch <app>` | Launch only (skip build) |
| `gj stop <app>` | Stop log streaming |
| `gj logs <app>` | View recent logs |
| `gj logs <app> "pattern"` | Search logs (use as assertions) |
| `gj clear <app>` | Clear logs and screenshots |
| `gj devices` | List connected physical devices |
| `gj status` | Show simulators, devices, active streams |
| `gj test <suite>` | Run E2E tests |
| `gj ui describe <app>` | Dump accessibility tree |
| `gj ui tap-button <app> "label"` | Tap by accessibility label |
| `gj ui screenshot <app>` | Capture screen |

## Supported Apps

| App | Aliases | Platform |
|-----|---------|----------|
| `orchestrator` | `o`, `orch` | iOS/iPad |
| `pfizer` | `p`, `pf` | visionOS |
| `gmp` | `g` | visionOS |
| `ms` | `s`, `server` | macOS |
| `all` | `a` | All 4 apps |

---

## Testing Philosophy

**Core Principle:** Prefer quick validation over full E2E tests during development iteration.

### Testing Decision Tree

```
Need to verify something?
├── Quick check (< 30 sec)?
│   └── Use: gj logs <app> "pattern"
├── Visual verification needed?
│   └── Use: gj ui screenshot <app>
├── Test specific interaction?
│   └── Use: gj ui tap-button + gj logs
├── Comprehensive validation?
│   └── Use: gj test P0 (takes 2-5 min)
└── Pre-commit / CI?
    └── Use: gj test all
```

### Quick Validation Pattern (Use First)

```bash
# 1. Run the apps
gj run orchestrator
gj run pfizer

# 2. Check for errors immediately
gj logs orchestrator "error"
gj logs pfizer "error"

# 3. Take a screenshot for visual verification
gj ui screenshot orchestrator

# 4. Test specific behavior
gj ui tap-button orchestrator "Scan Devices"
sleep 5
gj logs orchestrator "discover"
```

### Using Logs as Assertions

Log searches serve as assertion-like checks:

```bash
# ASSERT: Connection established
gj logs orchestrator "tcp_connection_established"
# If output is empty → assertion failed

# ASSERT: No errors occurred
gj logs orchestrator "error"
# If output is NOT empty → assertion failed

# ASSERT: Specific event happened
gj logs orchestrator "headset_connected"
# If output is empty → assertion failed

# ASSERT: Event count
gj logs orchestrator "connection_progress" | wc -l
# Compare count to expected
```

---

## E2E Tests

```bash
gj test --list    # List available tests
gj test P0        # Connection lifecycle suite
gj test P0.1      # Single test
gj test all       # Run all tests
```

### Available Test Suites

| Suite | Tests | Description |
|-------|-------|-------------|
| P0 | P0.1-P0.4 | Connection lifecycle (discovery, disconnect, reconnect, rapid cycling) |
| P1 | P1.1-P1.2 | Playback (scene selection, scene stop) |
| all | All | Complete test suite |

### When to Use E2E Tests

| ✅ Use E2E Tests | ❌ Skip E2E Tests |
|-----------------|------------------|
| Changes are stable, need final validation | Quick iteration/debugging |
| Testing connection lifecycle changes | Testing UI layout changes |
| Before committing significant changes | Coordinates may be stale |
| CI/automated validation | Testing GMP (no tests exist) |

### Understanding Test Results

```bash
# Find the latest report
ls -la ~/gj/logs/orchestrator/build/e2e-reports/

# Read a report
cat ~/gj/logs/orchestrator/build/e2e-reports/P0-*.json
```

Report structure:
```json
{
  "suite": "P0",
  "passed": 3,
  "failed": 1,
  "results": [
    {"id": "P0.1", "status": "PASS", "duration": "45s"},
    {"id": "P0.2", "status": "FAIL", "duration": "12s"}
  ]
}
```

### Debugging Failed Tests

1. **Check the JSON report** for which test failed
2. **Check captured logs** in the reports directory
3. **Run manually** to see the actual state:

```bash
# Reproduce the test scenario manually
gj run orchestrator
gj run pfizer

# Check UI state
gj ui describe orchestrator

# Check what logs were captured
gj logs orchestrator

# Take screenshot to see current state
gj ui screenshot orchestrator
```

---

## Common Workflows

### Build and test an app
```bash
gj run orchestrator
gj logs orchestrator
```

### Clean rebuild after dependency changes
```bash
gj run --clean orchestrator
```

### Check for errors after a change
```bash
gj run orchestrator
gj logs orchestrator "error"
```

### Test device discovery
```bash
gj run orchestrator
gj run pfizer
gj ui tap-button orchestrator "Scan Devices"
gj logs orchestrator "discover"
```

### Full E2E media playback test
```bash
gj run orchestrator
gj run gmp
gj ui tap-button orchestrator "Scan Devices"
# Wait for device to appear...
gj ui tap-button orchestrator "Choose media Jeanne"
gj ui tap-button orchestrator "Select media Introduction"
gj ui tap-button orchestrator "Play Jeanne"
gj logs orchestrator "playback"
gj ui tap-button orchestrator "Stop Jeanne"
```

### Run all apps together
```bash
gj run all
gj status
```

### Stop everything and clear logs
```bash
gj stop all
gj clear all
```

---

## Device Deployment (Physical Apple Vision Pro)

```bash
# List connected devices
gj devices

# Build and deploy to device
gj run --device pfizer
gj run --device gmp

# Launch already-installed app
gj launch --device pfizer

# View device logs
gj logs pfizer

# Stop device log stream
gj stop pfizer
```

Device logs are saved to `~/gj/logs/<app>/device-*.log`

**Note:** Vision Pro doesn't support CLI log streaming. Use Console.app for real-time logs.

---

## UI Automation

See: `~/.agent-config/docs/ui-automation.md` for full UI automation reference.

Quick reference:
```bash
gj ui describe orchestrator           # Dump accessibility tree
gj ui tap-button orchestrator "Scan"  # Tap by label
gj ui tap orchestrator 500 400        # Tap coordinates
gj ui screenshot orchestrator         # Capture screen
gj ui home pfizer                     # Press Digital Crown
```

---

## Extension / Broadcast Logs

For apps with broadcast extensions (GMP, Pfizer):

```bash
# Run with extension logs
gj run --ext gmp
gj run --ext pfizer
```

---

## Log Locations

```
~/gj/logs/
├── orchestrator/
│   ├── app-YYYYMMDD-HHMMSS.log    # App logs
│   └── screenshot-*.png            # Screenshots
├── pfizer/
├── gmp/
└── ms/
```

---

## Configuration

Edit `~/bin/gj-config.env` to change:
- Project paths
- Simulator names
- Bundle IDs
- OS version requirements

---

## Troubleshooting

| Problem | Solution |
|---------|----------|
| `gj: command not found` | Run installer or `export PATH="$HOME/bin:$PATH"` |
| Build fails | Check `~/gj/logs/<app>/build-*.log` |
| Wrong simulator | Edit `~/bin/gj-config.env` |
| Simulator not visible | Don't use `--headless` |
| Empty logs | Check bundle ID matches app's logging subsystem |
| visionOS build fails | May need `SIMULATOR_OS` for correct OS version |

---

## DO NOT

- ❌ Run `xcodebuild` directly
- ❌ Run `xcrun simctl` directly
- ❌ Construct complex build commands

## DO

- ✅ Use `gj run <app>`
- ✅ Use `gj logs <app>` for debugging
- ✅ Use `gj version` to verify installation
- ✅ Report if gj commands fail
