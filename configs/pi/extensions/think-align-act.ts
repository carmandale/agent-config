/**
 * Think-Align-Act Protocol Enforcement for Pi
 *
 * Forces pi to get explicit user approval before ANY code modifications.
 * Intercepts write, edit, and bash commands that modify files.
 *
 * Protocol:
 *   THINK  - Agent analyzes the problem (no gate)
 *   ALIGN  - Agent proposes changes, user approves (THIS EXTENSION)
 *   ACT    - Agent executes approved changes
 *
 * Commands:
 *   /taa-reset  - Clear all approvals, require re-approval
 *   /taa-status - Show approved operations this session
 *   /taa-auto   - Toggle auto-approve mode (when you trust the agent)
 */

import type { ExtensionAPI } from "@mariozechner/pi-coding-agent";
import { isToolCallEventType } from "@mariozechner/pi-coding-agent";

export default function (pi: ExtensionAPI) {
  // Track approved operations for this session
  const approvedOperations = new Set<string>();

  // Auto-approve mode (trust mode)
  let autoApproveAll = false;

  // Files/patterns that don't need approval
  const autoApprovePatterns = [
    /^\.claude\//,           // Claude config
    /^\.pi\//,               // Pi config
    /^thoughts\//,           // Thoughts directory
    /^\.beads\//,            // Beads tracking
    /^\.git\//,              // Git internals
    /^\/tmp\//,              // Temp files
    /^\/var\/tmp\//,         // Temp files
    /\/node_modules\//,      // Dependencies
    /\/target\//,            // Rust build
    /\/\.build\//,           // Swift build
  ];

  // Bash commands that modify files and need approval
  const modifyingBashPatterns = [
    /\bcat\s+>/, /\becho\s+>/, /\btee\b/,           // Redirects
    /\bcp\b/, /\bmv\b/, /\brm\b/,                   // File operations
    /\bsed\s+-i/, /\bawk\s+-i/,                     // In-place edits
    /\bchmod\b/, /\bchown\b/,                       // Permission changes
    /\bgit\s+(checkout|reset|clean|stash)/,        // Git modifications
    /\bnpm\s+(install|uninstall|update)/,          // Package changes
    /\byarn\s+(add|remove)/,                       // Yarn changes
    /\bcargo\s+(add|remove)/,                      // Cargo changes
    /\bpip\s+(install|uninstall)/,                 // Python packages
  ];

  function shouldAutoApprove(path: string): boolean {
    return autoApprovePatterns.some((pattern) => pattern.test(path));
  }

  function isModifyingBash(command: string): boolean {
    return modifyingBashPatterns.some((pattern) => pattern.test(command));
  }

  function preview(content: string, maxLines = 10): string {
    const lines = content.split("\n");
    if (lines.length <= maxLines) return content;
    return lines.slice(0, maxLines).join("\n") + `\n... (${lines.length - maxLines} more lines)`;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // WRITE tool gate
  // ═══════════════════════════════════════════════════════════════════════════
  pi.on("tool_call", async (event, ctx) => {
    if (!isToolCallEventType("write", event)) return;
    if (autoApproveAll) return; // Trust mode

    const path = event.input.path;
    const content = event.input.content;
    const key = `write:${path}`;

    if (approvedOperations.has(key)) return;
    if (shouldAutoApprove(path)) return;

    const contentPreview = preview(content, 15);

    const approved = await ctx.ui.confirm(
      "📝 ALIGN: Approve file write?",
      `Path: ${path}\n\n${contentPreview}`
    );

    if (!approved) {
      return {
        block: true,
        reason: "❌ Write blocked - user did not approve.\n\nPlease ALIGN first: explain what you want to write and why, then wait for my approval before trying again.",
      };
    }

    approvedOperations.add(key);
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // EDIT tool gate
  // ═══════════════════════════════════════════════════════════════════════════
  pi.on("tool_call", async (event, ctx) => {
    if (!isToolCallEventType("edit", event)) return;
    if (autoApproveAll) return; // Trust mode

    const path = event.input.path;
    const oldText = event.input.oldText;
    const newText = event.input.newText;
    const key = `edit:${path}:${oldText.slice(0, 50)}`;

    if (approvedOperations.has(key)) return;
    if (shouldAutoApprove(path)) return;

    const oldPreview = preview(oldText, 8);
    const newPreview = preview(newText, 8);

    const approved = await ctx.ui.confirm(
      "✏️ ALIGN: Approve edit?",
      `File: ${path}\n\n--- OLD ---\n${oldPreview}\n\n+++ NEW +++\n${newPreview}`
    );

    if (!approved) {
      return {
        block: true,
        reason: "❌ Edit blocked - user did not approve.\n\nPlease ALIGN first: explain the change and why it's needed, then wait for my approval.",
      };
    }

    approvedOperations.add(key);
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // BASH tool gate (for file-modifying commands)
  // ═══════════════════════════════════════════════════════════════════════════
  pi.on("tool_call", async (event, ctx) => {
    if (!isToolCallEventType("bash", event)) return;
    if (autoApproveAll) return; // Trust mode

    const command = event.input.command;
    if (!isModifyingBash(command)) return;

    const key = `bash:${command}`;
    if (approvedOperations.has(key)) return;

    const approved = await ctx.ui.confirm(
      "🖥️ ALIGN: Approve bash command?",
      `Command: ${command}`
    );

    if (!approved) {
      return {
        block: true,
        reason: "❌ Bash command blocked - user did not approve.\n\nPlease ALIGN first: explain what this command does and why it's needed.",
      };
    }

    approvedOperations.add(key);
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // Commands
  // ═══════════════════════════════════════════════════════════════════════════

  pi.registerCommand("taa-reset", {
    description: "Reset Think-Align-Act approvals (require re-approval for all operations)",
    handler: async (_args, ctx) => {
      const count = approvedOperations.size;
      approvedOperations.clear();
      ctx.ui.notify(`🔄 Cleared ${count} approvals. All operations require approval again.`, "info");
    },
  });

  pi.registerCommand("taa-status", {
    description: "Show Think-Align-Act approved operations this session",
    handler: async (_args, ctx) => {
      const mode = autoApproveAll ? "⚡ AUTO-APPROVE MODE" : "🛡️ GATED MODE";
      if (approvedOperations.size === 0) {
        ctx.ui.notify(`${mode}\nNo operations approved yet this session.`, "info");
        return;
      }
      const list = Array.from(approvedOperations)
        .map((op) => `  • ${op}`)
        .join("\n");
      ctx.ui.notify(`${mode}\n✅ Approved (${approvedOperations.size}):\n${list}`, "info");
    },
  });

  pi.registerCommand("taa-auto", {
    description: "Toggle auto-approve mode (trust mode - skip all confirmations)",
    handler: async (_args, ctx) => {
      autoApproveAll = !autoApproveAll;
      if (autoApproveAll) {
        ctx.ui.notify(
          "⚡ AUTO-APPROVE ON\n\nAll operations allowed without confirmation.\nRun /taa-auto again to re-enable gates.",
          "warning"
        );
      } else {
        ctx.ui.notify("🛡️ GATED MODE restored. Operations require your approval.", "success");
      }
    },
  });

  // Startup notification
  pi.on("session_start", async (_event, ctx) => {
    ctx.ui.notify(
      "🧠 Think-Align-Act protocol active\n\nCode changes require your approval.\nCommands: /taa-status, /taa-reset, /taa-auto",
      "info"
    );
  });
}
