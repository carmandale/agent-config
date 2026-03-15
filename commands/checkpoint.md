---
description: Mid-session snapshot (bead optional). Uses agent-artifact (via tools-bin/).
---

Create a **checkpoint** artifact to preserve mid-session progress.

This command uses the unified artifact generator: `agent-artifact` (in `tools-bin/`, on PATH).

## Requirements
- Bead is optional
- Artifact must be written to `thoughts/shared/handoffs/<session>/`
- Outcome is required
- Commit/push are required to complete `/checkpoint`
- Include related planning artifacts in the same commit (for example: `specs/`, `tasks/`, `thoughts/shared/plans/`)

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
br list --status in_progress --sort updated --limit 5 --json
```

If you can infer **one** bead, state it and proceed:
"I believe the bead is <ID> based on [evidence]. Proceeding unless you say otherwise."

If multiple plausible beads or none, ask **once** whether to include a bead or proceed without one.

### 2) Generate the checkpoint artifact
```bash
python3 - <<'PY'
import os
import pathlib
import shutil
import subprocess

bead = ""  # optional; set to BEAD_ID if known
session_title = ""  # optional

# Resolve agent-artifact with anti-shadow guard
artifact_cmd = shutil.which("agent-artifact")
if not artifact_cmd:
    raise SystemExit("agent-artifact not found on PATH. Is ~/.agent-config/tools-bin/ on PATH?")
expected_path = os.path.realpath(os.path.expanduser("~/.agent-config/tools-bin/agent-artifact"))
actual_path = os.path.realpath(artifact_cmd)
if actual_path != expected_path:
    raise SystemExit(
        f"agent-artifact resolved to {artifact_cmd} (real: {actual_path}) — "
        f"expected {expected_path}. Check for shadowing binaries in earlier PATH entries."
    )

cmd = [
    artifact_cmd,
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
print(f"Artifact created: {artifact_path}")
PY
```
Now use the Read tool to read the artifact file, then use the Edit tool to fill in `goal`, `now`, and `outcome` using SESSION_SUMMARY. Add optional fields (`done_this_session`, `next`, `worked`, `failed`, etc.) as needed.

IMPORTANT: Only edit the file path returned by `agent-artifact`. Do not open or modify any existing checkpoint artifact.
If `agent-artifact` exits non-zero, show the error and stop. If it exits 0, the printed path is guaranteed correct — the script self-validates.

### 3) Propose outcome, allow override
State your inferred outcome from SESSION_SUMMARY, then let the user confirm or change it:

"I think the outcome is <inferred_outcome> because <outcome_reason>. Want to change it?"

### 4) Commit and push
```bash
git add thoughts/shared/handoffs/*/*.yaml
if [ -d specs ]; then git add specs; fi
if [ -d docs/specs ]; then git add docs/specs; fi
if [ -d tasks ]; then git add tasks; fi
if [ -d thoughts/shared/plans ]; then git add thoughts/shared/plans; fi
git commit -m "checkpoint: <short description>"
```

### 5) Push (required)
```bash
git push
```

## Output
Report:
- Artifact path
- Primary bead (if any)
- Outcome
- Commit SHA
- Resume command: `/resume-handoff <artifact-path>`
