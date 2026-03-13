#!/usr/bin/env node
/**
 * gate-check.ts — Claude Code UserPromptSubmit hook for workflow command gates
 *
 * Part of spec 019 (Command Compliance Gates).
 *
 * Intercepts slash commands (/plan, /codex-review, /implement) and runs
 * scripts/gate.sh gate <command> <spec-dir> before the command executes.
 *
 * Exit behavior:
 *   gate.sh exit 1 → hard-block via { result: 'block', reason: ... }
 *   gate.sh exit 2 → advisory context via { hookSpecificOutput: { ... } }
 *   gate.sh exit 0 → silent pass-through
 *   no spec dir   → silent pass-through
 */
import { readFileSync, existsSync, readdirSync } from 'fs';
import { resolve, basename } from 'path';
import { execSync } from 'child_process';

interface HookInput {
  session_id: string;
  transcript_path: string;
  cwd: string;
  prompt: string;
}

// Commands that have gate_requires or gate_sentinels (worth checking)
const GATED_COMMANDS = ['plan', 'codex-review', 'implement'] as const;

// Match /command at start of prompt, with optional argument
const SLASH_CMD_PATTERN = /^\/(\S+)\s*(.*)/;

function resolveSpecDir(arg: string, cwd: string): string | null {
  if (!arg || arg.trim() === '') return null;

  let cleaned = arg.trim();

  // Strip leading @ (some models prepend it)
  cleaned = cleaned.replace(/^@/, '');

  // Expand ~/
  const home = process.env.HOME || '';
  if (cleaned.startsWith('~/')) {
    cleaned = resolve(home, cleaned.slice(2));
  }

  // Resolve to absolute path
  const resolved = resolve(cwd, cleaned);

  // Containment check: must be under a specs/ directory
  const specsDir = resolve(cwd, 'specs');
  if (resolved.startsWith(specsDir) && existsSync(resolved)) {
    return resolved;
  }

  // Try direct match: specs/<arg>/
  const directPath = resolve(cwd, 'specs', cleaned);
  if (existsSync(directPath)) {
    return directPath;
  }

  // Glob fallback: specs/*<arg>*/
  if (existsSync(specsDir)) {
    try {
      const entries = readdirSync(specsDir, { withFileTypes: true });
      const matches = entries
        .filter(e => e.isDirectory() && e.name.includes(cleaned))
        .map(e => resolve(specsDir, e.name));
      if (matches.length === 1) return matches[0];
      // Ambiguous or no match — pass through silently
    } catch {
      // readdirSync failed — pass through
    }
  }

  return null;
}

function main() {
  try {
    const input = readFileSync(0, 'utf-8');
    const data: HookInput = JSON.parse(input);
    const prompt = data.prompt.trim();

    // Match slash commands
    const match = prompt.match(SLASH_CMD_PATTERN);
    if (!match) return; // Not a slash command

    const command = match[1];
    const arg = match[2]?.trim() || '';

    // Check if this is a gated command
    if (!GATED_COMMANDS.includes(command as typeof GATED_COMMANDS[number])) {
      return; // Not a gated command — pass through
    }

    // Resolve spec directory
    const specDir = resolveSpecDir(arg, data.cwd);
    if (!specDir) return; // Can't resolve — pass through silently

    // Locate gate.sh relative to the project
    const gateScript = resolve(data.cwd, 'scripts', 'gate.sh');
    if (!existsSync(gateScript)) {
      // gate.sh not installed — pass through
      return;
    }

    // Run gate.sh gate <command> <spec-dir>
    let gateOutput = '';
    let exitCode = 0;
    try {
      gateOutput = execSync(
        `bash "${gateScript}" gate "${command}" "${specDir}"`,
        {
          cwd: data.cwd,
          encoding: 'utf-8',
          timeout: 10000, // 10s timeout
          stdio: ['pipe', 'pipe', 'pipe'],
        }
      );
    } catch (err: unknown) {
      const execErr = err as { status?: number; stdout?: string; stderr?: string };
      exitCode = execErr.status ?? 1;
      gateOutput = (execErr.stdout || '') + (execErr.stderr || '');
    }

    if (exitCode === 1) {
      // FAIL — hard block
      const reason = `⛔ GATE CHECK FAILED for /${command} ${basename(specDir)}\n\n` +
        gateOutput.trim() + '\n\n' +
        'HARD CONSTRAINT: Do NOT create the missing files. Do NOT offer to create them. ' +
        'Do NOT proceed with workarounds. Show this output to the user and wait.';

      console.log(JSON.stringify({
        result: 'block',
        reason
      }));
    } else if (exitCode === 2) {
      // WARN — advisory context (user decides)
      const warning = `⚠️ GATE WARNING for /${command} ${basename(specDir)}\n\n` +
        gateOutput.trim() + '\n\n' +
        'Show this warning to the user and ask THEM whether to proceed. ' +
        'This is the USER\'s decision, not yours.';

      console.log(JSON.stringify({
        hookSpecificOutput: {
          hookEventName: 'UserPromptSubmit',
          additionalContext: warning
        }
      }));
    }
    // exit 0 = PASS — silent pass-through (no output)

  } catch {
    // Hook errors should never block the user — fail silently
  }
}

main();
