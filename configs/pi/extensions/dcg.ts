/**
 * dcg (Destructive Command Guard) extension for pi
 *
 * Intercepts bash tool calls and runs them through dcg to block
 * destructive commands like `git reset --hard`, `rm -rf`, etc.
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

  pi.on("tool_call", async (event, ctx) => {
    // Only intercept bash tool calls
    if (!isToolCallEventType("bash", event)) {
      return;
    }

    const command = event.input.command;
    if (!command) return;

    // Quick check - dcg only cares about commands containing these
    // This avoids spawning a process for every command
    const quickRejectPatterns = ["git", "rm", "docker", "kubectl", "aws", "gcloud", "terraform"];
    const mightBeDestructive = quickRejectPatterns.some((p) => command.includes(p));
    if (!mightBeDestructive) {
      return; // Allow - no need to check dcg
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
        timeout: 5000, // 5 second timeout
      });

      // If we get here with output, the command was blocked
      if (result && result.trim()) {
        try {
          const denial = JSON.parse(result);
          const reason =
            denial?.hookSpecificOutput?.permissionDecisionReason ||
            denial?.reason ||
            "Command blocked by dcg";

          // Extract just the key info for a cleaner message
          const lines = reason.split("\n").filter((l: string) => l.trim());
          const reasonLine = lines.find((l: string) => l.startsWith("Reason:")) || lines[0];

          return {
            block: true,
            reason: `🛡️ dcg blocked: ${reasonLine?.replace("Reason:", "").trim() || "Destructive command detected"}\n\nRun 'dcg explain "${command}"' for details.`,
          };
        } catch {
          // JSON parse failed but we got output - still block
          return {
            block: true,
            reason: `🛡️ dcg blocked this command. Run 'dcg explain "${command}"' for details.`,
          };
        }
      }
      // Empty output = allowed
    } catch (error: unknown) {
      // execSync throws if the command exits non-zero or times out
      // For dcg, exit 0 with no output = allowed
      // Any error here means we should check if there was stdout
      const execError = error as { stdout?: string; stderr?: string; status?: number };

      if (execError.stdout && execError.stdout.trim()) {
        try {
          const denial = JSON.parse(execError.stdout);
          const reason =
            denial?.hookSpecificOutput?.permissionDecisionReason ||
            denial?.reason ||
            "Command blocked by dcg";

          const lines = reason.split("\n").filter((l: string) => l.trim());
          const reasonLine = lines.find((l: string) => l.startsWith("Reason:")) || lines[0];

          return {
            block: true,
            reason: `🛡️ dcg blocked: ${reasonLine?.replace("Reason:", "").trim() || "Destructive command detected"}\n\nRun 'dcg explain "${command}"' for details.`,
          };
        } catch {
          return {
            block: true,
            reason: `🛡️ dcg blocked this command. Run 'dcg explain "${command}"' for details.`,
          };
        }
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
        // Show dcg version
        try {
          const version = execSync("dcg --version", { encoding: "utf-8" });
          ctx.ui.notify(`dcg is active\n${version}`, "success");
        } catch {
          ctx.ui.notify("dcg is installed but version check failed", "warning");
        }
        return;
      }

      // Run dcg explain on the provided command
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
