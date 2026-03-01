/**
 * Installed Binary Guard Extension
 *
 * Blocks edits to installed binaries and redirects to source repos.
 * Prevents the pattern of editing ~/bin/* directly instead of tracked source.
 */
import type { ExtensionAPI } from "@mariozechner/pi-coding-agent";

// Map of installed paths → source repo locations
const BINARY_SOURCE_MAP: Record<string, { source: string; install: string }> = {
  "/Users/dalecarman/bin/gj": {
    source: "/Users/dalecarman/Groove Jones Dropbox/Dale Carman/Projects/dev/gj-tool/bin/gj",
    install: 'cd "/Users/dalecarman/Groove Jones Dropbox/Dale Carman/Projects/dev/gj-tool" && ./install.sh',
  },
  // Add more mappings as needed
};

function normalizePath(path: string): string {
  if (path.startsWith("~/")) {
    return path.replace("~", "/Users/dalecarman");
  }
  // Strip leading @ (some models include it)
  if (path.startsWith("@")) {
    return path.slice(1);
  }
  return path;
}

export default function (pi: ExtensionAPI) {
  pi.on("tool_call", async (event, ctx) => {
    // Only check edit and write tools
    if (event.toolName !== "edit" && event.toolName !== "write") {
      return;
    }

    const rawPath = (event.input as { file_path?: string; path?: string }).file_path 
                 || (event.input as { file_path?: string; path?: string }).path;
    
    if (!rawPath) return;

    const filePath = normalizePath(rawPath);
    const mapping = BINARY_SOURCE_MAP[filePath];

    if (mapping) {
      return {
        block: true,
        reason: `🚫 BLOCKED: Cannot edit installed binary directly.

This file is an INSTALLED copy at:
  ${filePath}

Edit the SOURCE instead:
  ${mapping.source}

After editing source, deploy with:
  ${mapping.install}

This prevents untracked drift between source and installed versions.`,
      };
    }
  });

  pi.on("session_start", async (_event, ctx) => {
    // Silent load - no notification needed
  });
}
