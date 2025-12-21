---
description: Build, install, launch, and capture debug logs for the app in the simulator
---

Build, install, launch, and capture debug-level logs for iOS/visionOS apps in the simulator.

## Usage

```
/sim-run              # Auto-detect app from working directory
/sim-run orchestrator # Explicitly run Orchestrator
/sim-run pfizer       # Explicitly run Pfizer
/sim-run gmp          # Explicitly run GMP
```

The input is: $ARGUMENTS

## Supported Apps

| App | Repo Path Contains | Platform | Simulator | Bundle ID |
|-----|-------------------|----------|-----------|-----------|
| Orchestrator | `orchestrator` | iOS | iPad Pro 13-inch (M5) | `com.groovejones.orchestrator` |
| Pfizer | `PfizerOutdoCancerV2` | visionOS | Apple Vision Pro | `com.groovejones.PfizerOutdoCancer` |
| GMP | `groovetech-media-player` | visionOS | Apple Vision Pro | `com.groovetech.media-player` |

## Step 1: Detect App

If `$ARGUMENTS` contains `orchestrator`, `pfizer`, or `gmp`, use that app.

Otherwise, determine from current working directory path:
- Contains `orchestrator` (but not `groovetech-media-player`) → **Orchestrator** (iOS/iPad)
- Contains `PfizerOutdoCancerV2` → **Pfizer** (visionOS)
- Contains `groovetech-media-player` → **GMP** (visionOS)

If none match, abort with error listing supported repos.

## Step 2: Set Configuration Variables

**Orchestrator:**
```
PROJECT_FILE=orchestrator.xcodeproj
SCHEME=orchestrator
PLATFORM=iOS Simulator
SIMULATOR_NAME=iPad Pro 13-inch (M5)
APP_PRODUCT_NAME=Orchestrator
BUNDLE_ID=com.groovejones.orchestrator
PLATFORM_SUFFIX=iphonesimulator
REPO_PATH=/Users/dalecarman/Groove Jones Dropbox/Dale Carman/Projects/dev/orchestrator
```

**Pfizer:**
```
PROJECT_FILE=PfizerOutdoCancer.xcodeproj
SCHEME=PfizerOutdoCancer
PLATFORM=visionOS Simulator
SIMULATOR_NAME=Apple Vision Pro
APP_PRODUCT_NAME=PfizerOutdoCancer
BUNDLE_ID=com.groovejones.PfizerOutdoCancer
PLATFORM_SUFFIX=xrsimulator
REPO_PATH=/Users/dalecarman/Groove Jones Dropbox/Dale Carman/Projects/dev/PfizerOutdoCancerV2
```

**GMP:**
```
PROJECT_FILE=groovetech-media-player.xcodeproj
SCHEME=groovetech-media-player
PLATFORM=visionOS Simulator
SIMULATOR_NAME=Apple Vision Pro
APP_PRODUCT_NAME=groovetech-media-player
BUNDLE_ID=com.groovetech.media-player
PLATFORM_SUFFIX=xrsimulator
REPO_PATH=/Users/dalecarman/Groove Jones Dropbox/Dale Carman/Projects/dev/groovetech-media-player
```

## Step 3: Check Simulator Status

```bash
xcrun simctl list devices booted
```

Look for the target `SIMULATOR_NAME` in the output. Extract its UDID.

If the target simulator is NOT booted:
```bash
xcrun simctl boot "<SIMULATOR_NAME>"
```

Wait a few seconds for boot to complete, then re-check to get the UDID.

## Step 4: Build the App

**CRITICAL:** Run from the repo root directory and use the wrapper script:

```bash
cd "<REPO_PATH>"
./.claude/scripts/xcodebuild \
  -project "<PROJECT_FILE>" \
  -scheme "<SCHEME>" \
  -destination "platform=<PLATFORM>,id=<SIMULATOR_UDID>" \
  -derivedDataPath ./build/DerivedData \
  build
```

Check for `** BUILD SUCCEEDED **` in output. If build fails, report error and abort.

## Step 5: Install the App

```bash
xcrun simctl install <SIMULATOR_UDID> "<REPO_PATH>/build/DerivedData/Build/Products/Debug-<PLATFORM_SUFFIX>/<APP_PRODUCT_NAME>.app"
```

## Step 6: Terminate Existing Instance

```bash
xcrun simctl terminate <SIMULATOR_UDID> <BUNDLE_ID> 2>/dev/null
```

(Ignore errors if app wasn't running)

## Step 7: Launch the App

```bash
xcrun simctl launch <SIMULATOR_UDID> <BUNDLE_ID>
```

This returns the PID. Capture it for reporting.

## Step 8: Wait for Logs

Wait 10 seconds for the app to initialize and emit startup logs.

## Step 9: Capture and Verify Logs (CRITICAL)

**THIS IS THE STEP AGENTS ALWAYS GET WRONG. USE EXACTLY THIS COMMAND:**

```bash
xcrun simctl spawn <SIMULATOR_UDID> log show --last 15s --style compact --predicate "subsystem == '<BUNDLE_ID>'" --debug --info
```

**Key points:**
- Use `log show` (NOT `log stream`) for reliable capture
- Use `--debug --info` flags (NOT `--level debug`)
- The predicate subsystem should match the `BUNDLE_ID`

**Verification:**
- Output should contain multiple log lines
- Lines should have format: `[subsystem:category]` with actual messages
- Should see startup logs (e.g., `subsystems_ready`, `stream_receiver_listening`, app init messages)

**If output is empty or only shows the header:**
1. Check that the app actually launched (verify PID)
2. Try a broader predicate: `subsystem BEGINSWITH 'com.groovejones'` or `subsystem BEGINSWITH 'com.groovetech'`
3. Verify the bundle ID matches the app's actual logging subsystem

## Step 10: Report Results

Output a summary:
```
## Results

- App: <APP_NAME>
- Simulator: <SIMULATOR_NAME> (<SIMULATOR_UDID>)
- Build: SUCCESS
- Install: SUCCESS
- Launch: SUCCESS (PID: <PID>)
- Logs: CAPTURED

## Sample Logs (first 20 lines)
<LOG_OUTPUT>

## Commands for Further Analysis

# View more logs (last 60 seconds)
xcrun simctl spawn <UDID> log show --last 60s --style compact --predicate "subsystem == '<BUNDLE_ID>'" --debug --info

# Search for errors
xcrun simctl spawn <UDID> log show --last 60s --style compact --predicate "subsystem == '<BUNDLE_ID>'" --debug --info 2>&1 | grep -i error

# Real-time streaming (for ongoing debugging)
xcrun simctl spawn <UDID> log stream --level debug --style compact --predicate "subsystem == '<BUNDLE_ID>'"
```

## Error Handling

| Error | Solution |
|-------|----------|
| Unknown repo | List supported repos and their paths |
| Build failure | Show last 50 lines of build output, check `./build/xcodebuild/build-*.txt` |
| Simulator not available | Run `xcrun simctl list devices available`, boot the correct one |
| Install failure | Verify app was built for correct platform (check PLATFORM_SUFFIX) |
| Launch failure | Check bundle ID with `xcrun simctl listapps <UDID>` |
| Empty logs | Try broader predicate, verify subsystem name matches app's logging config |

## Important Notes

1. **Log command syntax**: `log show` uses `--debug --info` flags, NOT `--level debug`
2. **Subsystem must match**: The predicate subsystem must exactly match the app's OSLog subsystem
3. **GMP bundle ID**: GMP uses `com.groovetech.media-player` (NOT `com.groovejones.groovetech-media-player`)
4. **Always run from repo root**: The wrapper script expects to be run from the repository root directory
