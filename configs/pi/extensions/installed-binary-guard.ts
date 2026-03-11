/**
 * Installed Binary Guard Extension
 *
 * Blocks edits to installed binaries and redirects to source repos.
 * Prevents the pattern of editing ~/bin/* directly instead of tracked source.
 */
import type { ExtensionAPI } from "@mariozechner/pi-coding-agent";
import { homedir } from "node:os";
import { join, resolve } from "node:path";

const HOME = homedir();

// Map of installed paths → source repo locations
const BINARY_SOURCE_MAP: Record<string, { source: string; install: string }> = {
  [join(HOME, "bin", "gj")]: {
    source: join(HOME, "Groove Jones Dropbox/Dale Carman/Projects/dev/gj-tool/bin/gj"),
    install: `cd "${join(HOME, "Groove Jones Dropbox/Dale Carman/Projects/dev/gj-tool")}" && ./install.sh`,
  },
  // Add more mappings as needed
};

function normalizePath(path: string): string {
  // Canonicalization order matters for bypass resistance:
  // 1. Strip leading @ (some models prepend it)
  // 2. Expand ~/ to home directory
  // 3. Resolve to absolute canonical path
  let p = path;
  if (p.startsWith("@")) {
    p = p.slice(1);
  }
  if (p.startsWith("~/")) {
    p = join(HOME, p.slice(2));
  }
  return resolve(p);
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
