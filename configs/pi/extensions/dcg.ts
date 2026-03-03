/**
 * dcg (Destructive Command Guard) extension for pi
 *
 * Two layers of protection:
 * 1. rm → trash rewrite: Blocks rm commands and tells the agent to use
 *    `trash` instead (files go to Trash, recoverable).
 * 2. dcg passthrough: Pipes commands through dcg to block destructive
 *    operations like `git reset --hard`, `git push --force`, etc.
 *
 * Install dcg first:
 *   curl -fsSL "https://raw.githubusercontent.com/Dicklesworthstone/destructive_command_guard/master/install.sh?$(date +%s)" | bash -s -- --easy-mode
 */

import type { ExtensionAPI } from "@mariozechner/pi-coding-agent";
import { isToolCallEventType } from "@mariozechner/pi-coding-agent";
import { execSync } from "node:child_process";

export default function (pi: ExtensionAPI) {
  // Check if dcg is available on startup
  let dcgAvailable = false;
  try {
    execSync("which dcg", { encoding: "utf-8", stdio: "pipe" });
    dcgAvailable = true;
  } catch {
    // dcg not found - will warn on first blocked attempt
  }

  // Check if trash is available
  let trashAvailable = false;
  try {
    execSync("which trash", { encoding: "utf-8", stdio: "pipe" });
    trashAvailable = true;
  } catch {
    // trash not found - will fall back to mv ~/.Trash/
  }

  pi.on("tool_call", async (event, ctx) => {
    // Only intercept bash tool calls
    if (!isToolCallEventType("bash", event)) {
      return;
    }

    const command = event.input.command;
    if (!command) return;

    // ─────────────────────────────────────────────────────────────
    // Layer 1: rm → trash rewrite
    // ─────────────────────────────────────────────────────────────
    // Match rm at the start of a command (with optional sudo prefix)
    const rmMatch = command.match(/^(?:sudo\s+)?rm\s+(.*)/s);
    if (rmMatch) {
      const args = rmMatch[1]!;

      // Allow rm on temp directories (safe cleanup)
      const isTempDir =
        /(?:^|\s)\/tmp\//.test(args) ||
        /(?:^|\s)\/var\/tmp\//.test(args) ||
        /\$TMPDIR/.test(args) ||
        /\$\{TMPDIR\}/.test(args);

      if (!isTempDir) {
        // Extract paths by stripping flags (anything starting with -)
        const paths = args
          .split(/\s+/)
          .filter((a) => !a.startsWith("-") && a.length > 0)
          .join(" ");

        const safeCommand = trashAvailable
          ? `trash ${paths}`
          : `mv ${paths} ~/.Trash/`;

        return {
          block: true,
          reason: `Use \`${safeCommand}\` instead of \`rm\`. Files go to Trash and can be recovered.\n\nOriginal: ${command}`,
        };
      }
    }

    // ─────────────────────────────────────────────────────────────
    // Layer 2: dcg passthrough for other destructive commands
    // ─────────────────────────────────────────────────────────────
    // Quick check - only spawn dcg for commands that might match its patterns
    const dcgKeywords = ["git", "docker", "kubectl", "aws", "gcloud", "terraform"];
    const mightBeDestructive = dcgKeywords.some((p) => command.includes(p));
    if (!mightBeDestructive) {
      return; // Allow - nothing to check
    }

    if (!dcgAvailable) {
      ctx.ui.notify(
        "dcg not found! Install: curl -fsSL https://raw.githubusercontent.com/Dicklesworthstone/destructive_command_guard/master/install.sh | bash -s -- --easy-mode",
        "warning"
      );
      return; // Allow but warn
    }

    try {
      // Build the hook input JSON (same format as Claude Code hooks)
      const hookInput = JSON.stringify({
        tool_name: "Bash",
        tool_input: { command },
      });

      // Run dcg and capture output
      // dcg outputs nothing (exit 0) for allowed commands
      // dcg outputs JSON to stdout for blocked commands
      const result = execSync(`echo '${hookInput.replace(/'/g, "'\\''")}' | dcg`, {
        encoding: "utf-8",
        stdio: ["pipe", "pipe", "pipe"],
        timeout: 5000,
      });

      // If we get here with output, the command was blocked
      if (result && result.trim()) {
        return parseDcgDenial(result, command);
      }
      // Empty output = allowed
    } catch (error: unknown) {
      const execError = error as { stdout?: string; stderr?: string; status?: number };

      if (execError.stdout && execError.stdout.trim()) {
        return parseDcgDenial(execError.stdout, command);
      }
      // No stdout = dcg allowed it or errored (fail-open)
    }

    // Allow if we get here
    return;
  });

  // Register a command to check dcg status
  pi.registerCommand("dcg", {
    description: "Check dcg status or explain a command",
    handler: async (args, ctx) => {
      if (!dcgAvailable) {
        ctx.ui.notify(
          "dcg not installed. Install with:\ncurl -fsSL https://raw.githubusercontent.com/Dicklesworthstone/destructive_command_guard/master/install.sh | bash -s -- --easy-mode",
          "error"
        );
        return;
      }

      if (!args || args.trim() === "") {
        try {
          const version = execSync("dcg --version", { encoding: "utf-8" });
          const trashStatus = trashAvailable ? "trash: available" : "trash: not found (using mv ~/.Trash/)";
          ctx.ui.notify(`dcg is active\n${version}\n${trashStatus}`, "success");
        } catch {
          ctx.ui.notify("dcg is installed but version check failed", "warning");
        }
        return;
      }

      try {
        const result = execSync(`dcg explain "${args.replace(/"/g, '\\"')}"`, {
          encoding: "utf-8",
          stdio: ["pipe", "pipe", "pipe"],
        });
        ctx.ui.notify(result || "Command would be allowed", "info");
      } catch (error: unknown) {
        const execError = error as { stdout?: string; stderr?: string };
        ctx.ui.notify(execError.stderr || execError.stdout || "Error running dcg explain", "error");
      }
    },
  });
}

/** Parse dcg JSON denial output into a block response */
function parseDcgDenial(output: string, command: string) {
  try {
    const denial = JSON.parse(output);
    const reason =
      denial?.hookSpecificOutput?.permissionDecisionReason ||
      denial?.reason ||
      "Command blocked by dcg";

    const lines = reason.split("\n").filter((l: string) => l.trim());
    const reasonLine = lines.find((l: string) => l.startsWith("Reason:")) || lines[0];

    return {
      block: true,
      reason: `dcg blocked: ${reasonLine?.replace("Reason:", "").trim() || "Destructive command detected"}\n\nRun 'dcg explain "${command}"' for details.`,
    };
  } catch {
    return {
      block: true,
      reason: `dcg blocked this command. Run 'dcg explain "${command}"' for details.`,
    };
  }
}
