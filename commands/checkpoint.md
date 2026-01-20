---
description: Mid-session snapshot (bead optional). Uses ~/.claude/scripts/cc-artifact.
---

Create a **checkpoint** artifact to preserve mid-session progress.

This command uses the unified artifact generator: `~/.claude/scripts/cc-artifact`.

## Requirements
- Bead is optional
- Artifact must be written to `thoughts/shared/handoffs/<session>/`
- Outcome is required
- Commit only if explicitly requested

## Steps

### 0) Capture session work summary (REQUIRED)
Use this to prefill the checkpoint and avoid amnesia.

```bash
python3 - <<'PY'
import json, os, pathlib, re

project = os.environ.get("CLAUDE_PROJECT_DIR") or os.environ.get("CODEX_PROJECT_DIR") or os.getcwd()
roots = []
codex_root = pathlib.Path.home() / ".codex" / "sessions"
claude_root = pathlib.Path.home() / ".claude" / "transcripts"
if codex_root.exists():
  roots.append(codex_root)
if claude_root.exists():
  roots.append(claude_root)

paths = []
for root in roots:
  paths.extend(root.rglob("*.jsonl"))
if not paths:
  print("SESSION_SUMMARY: {}")
  raise SystemExit

def matches_project(path: pathlib.Path) -> bool:
  try:
    with path.open() as f:
      first = f.readline()
    data = json.loads(first)
    if data.get("type") == "session_meta":
      cwd = data.get("payload", {}).get("cwd")
      if cwd and pathlib.Path(cwd).resolve() == pathlib.Path(project).resolve():
        return True
  except Exception:
    return False
  return False

candidates = [p for p in paths if matches_project(p)]
if not candidates:
  candidates = paths
session_path = max(candidates, key=lambda p: p.stat().st_mtime)

files = set()
commands = []
cmd_by_call = {}
test_attempts = []
errors = []
last_user = ""
last_assistant = ""

def is_test_cmd(cmd: str) -> bool:
  return bool(re.search(
    r'\\b(gj|pytest|jest|vitest|xcodebuild|ctest|cargo|go\\s+test|'
    r'npm\\s+(run\\s+)?(test|lint|build)|'
    r'pnpm\\s+(run\\s+)?(test|lint|build)|'
    r'yarn\\s+(run\\s+)?(test|lint|build)|'
    r'make\\s+(test|lint|build))\\b',
    cmd
  ))

def bead_candidates_from(text: str):
  tokens = re.findall(r'\\b[a-zA-Z0-9]+(?:-[a-zA-Z0-9]+){2,}\\b', text or "")
  return [t for t in tokens if any(ch.isdigit() for ch in t)]

with session_path.open() as f:
  for line in f:
    try:
      entry = json.loads(line)
    except Exception:
      continue
    if entry.get("type") == "response_item":
      payload = entry.get("payload", {})
      if payload.get("type") == "message":
        role = payload.get("role")
        content = payload.get("content", [])
        text = "".join(part.get("text", "") for part in content if part.get("type") == "input_text")
        if role == "user" and text:
          last_user = text
        if role == "assistant" and text:
          last_assistant = text
      if payload.get("type") == "function_call":
        name = payload.get("name", "")
        call_id = payload.get("call_id")
        try:
          args = json.loads(payload.get("arguments", "{}"))
        except Exception:
          args = {}
        if name in ("exec_command", "bash"):
          cmd = args.get("cmd") or args.get("command")
          if cmd:
            commands.append(cmd)
            if call_id:
              cmd_by_call[call_id] = cmd
        for key in ("path", "file_path", "filePath"):
          value = args.get(key)
          if isinstance(value, str):
            files.add(value)
        edits = args.get("edits")
        if isinstance(edits, list):
          for edit in edits:
            if isinstance(edit, dict):
              value = edit.get("path")
              if isinstance(value, str):
                files.add(value)
      if payload.get("type") == "function_call_output":
        call_id = payload.get("call_id")
        output = payload.get("output", "")
        if output is None:
          output = ""
        output = str(output)
        cmd = cmd_by_call.get(call_id)
        exit_code = None
        match = re.search(r'Process exited with code\\s+(\\d+)', output)
        if match:
          exit_code = match.group(1)
        if cmd and is_test_cmd(cmd):
          test_attempts.append({
            "command": cmd,
            "exit_code": exit_code or "unknown"
          })
        if exit_code and exit_code != "0":
          if cmd:
            errors.append(f\"{cmd} (exit {exit_code})\")
          else:
            errors.append(f\"exit {exit_code}\")

candidate_counts = {}
for source in (last_user, last_assistant, " ".join(commands)):
  for token in bead_candidates_from(source):
    candidate_counts[token] = candidate_counts.get(token, 0) + 1
bead_candidates = sorted(candidate_counts, key=lambda k: (-candidate_counts[k], k))
inferred_bead = bead_candidates[0] if bead_candidates else ""

summary = {
  "transcript": str(session_path),
  "files_modified": sorted(files),
  "recent_commands": commands[-8:],
  "test_attempts": test_attempts[-5:],
  "errors": errors[-5:],
  "inferred_bead": inferred_bead,
  "bead_candidates": bead_candidates,
  "last_user_message": (last_user or "")[:500],
  "last_assistant_message": (last_assistant or "")[:500],
}
print(f"INFERRED_BEAD: {inferred_bead}")
if bead_candidates:
  print("BEAD_CANDIDATES: " + ", ".join(bead_candidates))
print("SESSION_SUMMARY:", json.dumps(summary, indent=2))
PY
```

### 1) Infer bead (optional)
Goal: include the bead if it is obvious, without asking.

Use this order:
1. If `/checkpoint <bead-id>` was provided, use it.
2. Use `INFERRED_BEAD` from SESSION_SUMMARY if present.
3. Otherwise, from SESSION_SUMMARY: look for bead IDs in `recent_commands` or `last_*_message`.
4. From git branch name (if it contains a bead ID).
5. If still unknown, check most-recent in_progress bead:
```bash
bd list --status in_progress --sort updated --limit 5 --json
```

If you can infer **one** bead, state it and proceed:
"I believe the bead is <ID> based on [evidence]. Proceeding unless you say otherwise."

If multiple plausible beads or none, ask **once** whether to include a bead or proceed without one.

### 2) Generate the checkpoint artifact
```bash
python3 - <<'PY'
import os
import pathlib
import shlex
import subprocess

bead = ""  # optional; set to BEAD_ID if known
session_title = ""  # optional

cmd = [
    os.path.expanduser("~/.claude/scripts/cc-artifact"),
    "--no-edit",
    "--mode",
    "checkpoint",
]
if bead:
    cmd += ["--bead", bead]
if session_title:
    cmd += ["--session-title", session_title]

result = subprocess.run(cmd, capture_output=True, text=True)
if result.returncode != 0:
    raise SystemExit(result.stderr.strip() or result.stdout.strip())

artifact_path = result.stdout.strip().splitlines()[-1]
path = pathlib.Path(artifact_path)
if not path.exists():
    raise SystemExit(f"Missing artifact path: {path}")
if not path.name.endswith("_checkpoint.yaml"):
    raise SystemExit(f"Unexpected artifact filename: {path.name}")

text = path.read_text()
parts = text.split("---", 2)
if len(parts) < 3:
    raise SystemExit("Missing frontmatter")
front = parts[1]
mode = None
primary = None
for line in front.splitlines():
    if line.startswith("mode:"):
        mode = line.split(":", 1)[1].strip().strip('"')
    if line.startswith("primary_bead:"):
        primary = line.split(":", 1)[1].strip().strip('"')
if mode != "checkpoint":
    raise SystemExit(f"Unexpected mode: {mode}")
if bead:
    if bead not in path.name:
        raise SystemExit(f"Unexpected artifact filename: {path.name}")
    if primary and primary != bead:
        raise SystemExit(f"primary_bead mismatch: {primary} != {bead}")
print(f"Verified artifact: {path}")

editor = os.environ.get("EDITOR") or "vi"
editor_cmd = shlex.split(editor)
subprocess.run(editor_cmd + [str(path)])
PY
```
Fill in `goal`, `now`, and `outcome` using SESSION_SUMMARY. Add optional fields (`done_this_session`, `next`, `worked`, `failed`, etc.) as needed.

IMPORTANT: Only edit the file path returned by `cc-artifact`. Do not open or modify any existing checkpoint artifact.
If the returned path does not end with `_checkpoint.yaml`, stop and re-run `cc-artifact`.

### 3) Propose outcome, allow override
State your inferred outcome from SESSION_SUMMARY, then let the user confirm or change it:

"I think the outcome is <inferred_outcome> because <outcome_reason>. Want to change it?"

### 4) Commit only if user requests
```bash
git add thoughts/shared/handoffs/*/*.yaml
git commit -m "checkpoint: <short description>"
```

### 5) (Optional) Push
If the user wants it shared immediately:
```bash
git push
```

## Output
Report:
- Artifact path
- Primary bead (if any)
- Outcome
- Commit SHA
- Resume command: `/resume_handoff <artifact-path>`
