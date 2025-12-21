---
description: Show gj tool status with readable formatting
---

Display the status of simulators, devices, and log files using the `gj` tool.

## Usage

```
/gj-status
```

## Step 1: Run gj status

```bash
gj status
```

## Step 2: Format Output

Present the output in a clean, readable format:

```markdown
## GJ Status

### Simulators
| Name | State | Platform |
|------|-------|----------|
| ... | ... | ... |

### Devices
| Name | State | Connection |
|------|-------|------------|
| ... | ... | ... |

### Recent Logs
| App | File | Age |
|-----|------|-----|
| ... | ... | ... |
```

## Tips

- If no simulators are running, suggest: `xcrun simctl boot "Apple Vision Pro"`
- If logs are old (>1 hour), note they may be stale
- Highlight any errors or warnings in the status output
