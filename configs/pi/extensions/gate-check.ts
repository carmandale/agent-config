/**
 * Gate Check Extension — Pi detect/warn for workflow command gates
 *
 * Part of spec 019 (Command Compliance Gates).
 *
 * Monitors bash tool calls for spec-dir file operations and warns if
 * gate.sh wasn't run first. Does NOT block preflight — only detects/warns.
 *
 * Unlike the Claude Code hook (which hard-blocks on exit 1), the Pi extension
 * provides observability only: it detects when an agent is writing to a spec
 * directory without having run gate.sh gate first in this session.
 */
import type { ExtensionAPI } from "@mariozechner/pi-coding-agent";
import { existsSync, readFileSync } from "node:fs";
import { resolve, join } from "node:path";
import { homedir } from "node:os";
import { execSync } from "node:child_process";

const HOME = homedir();

// Track which spec dirs have had gate checks this session
const gateCheckedDirs = new Set<string>();

// Commands that should trigger gate checking
const GATED_COMMANDS = ["plan", "codex-review", "implement"];

function normalizePath(path: string): string {
  let p = path;
  if (p.startsWith("@")) p = p.slice(1);
  if (p.startsWith("~/")) p = join(HOME, p.slice(2));
  return resolve(p);
}

function findSpecDir(path: string, cwd: string): string | null {
  const normalized = normalizePath(path);
  const specsDir = resolve(cwd, "specs");

  // Check if the path is under a specs/ directory
  if (!normalized.startsWith(specsDir)) return null;

  // Extract the spec dir (first directory component under specs/)
  const relative = normalized.slice(specsDir.length + 1);
  const specSlug = relative.split("/")[0];
  if (!specSlug) return null;

  const specDir = join(specsDir, specSlug);
  return existsSync(specDir) ? specDir : null;
}

export default function (pi: ExtensionAPI) {
  // Track gate.sh invocations in bash calls
  pi.on("tool_call", async (event, ctx) => {
    if (event.toolName !== "bash") return;

    const command = (event.input as { command?: string }).command;
    if (!command) return;

    const cwd = ctx.cwd || process.cwd();

    // Detect gate.sh gate invocations — mark the spec dir as checked
    const gateMatch = command.match(
      /gate\.sh\s+gate\s+(\S+)\s+(\S+)/
    );
    if (gateMatch) {
      const specDir = normalizePath(gateMatch[2]);
      gateCheckedDirs.add(specDir);
      return;
    }

    // Detect slash command patterns being executed (e.g., agent reading command file)
    // This is informational — we can't block bash calls in Pi extensions
  });

  // Monitor write/edit calls to spec directories
  pi.on("tool_call", async (event, ctx) => {
    if (event.toolName !== "write" && event.toolName !== "edit") return;

    const rawPath =
      (event.input as { file_path?: string; path?: string }).file_path ||
      (event.input as { file_path?: string; path?: string }).path;

    if (!rawPath) return;

    const cwd = ctx.cwd || process.cwd();
    const specDir = findSpecDir(rawPath, cwd);
    if (!specDir) return; // Not writing to a spec dir

    // Check if gate.sh was run for this spec dir
    if (!gateCheckedDirs.has(specDir)) {
      // Warn — but do NOT block (Pi extension is detect/warn only)
      return {
        warning: `⚠️ GATE WARNING: Writing to spec directory without prior gate check.

File: ${rawPath}
Spec dir: ${specDir}

No gate.sh invocation was detected for this spec directory in this session.
If you're running a pipeline command (/plan, /codex-review, /implement),
run scripts/gate.sh gate <command> ${specDir} first.

This is a warning — the write is allowed to proceed.`,
      };
    }
  });

  pi.on("session_start", async (_event, _ctx) => {
    // Clear tracked gate checks on new session
    gateCheckedDirs.clear();
  });
}
