/**
 * Installed Binary Guard Hook
 *
 * Blocks edits to installed binaries and redirects to source repos.
 * Prevents the pattern of editing ~/bin/* directly instead of tracked source.
 */
import { readFileSync } from 'fs';

interface HookInput {
  session_id: string;
  hook_event_name: string;
  tool_name: string;
  tool_input: {
    file_path?: string;
    path?: string;
  };
}

const HOME = process.env.HOME || '/Users/' + process.env.USER;

// Map of installed paths → source repo locations
const BINARY_SOURCE_MAP: Record<string, { source: string; install: string }> = {
  [`${HOME}/bin/gj`]: {
    source: `${HOME}/Groove Jones Dropbox/Dale Carman/Projects/dev/gj-tool/bin/gj`,
    install: `cd "${HOME}/Groove Jones Dropbox/Dale Carman/Projects/dev/gj-tool" && ./install.sh`,
  },
  // Add more mappings as needed:
  // [`${HOME}/bin/other-tool`]: {
  //   source: `${HOME}/path/to/repo/bin/other-tool`,
  //   install: `cd "${HOME}/path/to/repo" && ./install.sh`,
  // },
};

function readStdin(): string {
  return readFileSync(0, 'utf-8');
}

function normalizePath(path: string): string {
  // Resolve ~ to home directory
  if (path.startsWith('~/')) {
    path = path.replace('~', HOME);
  }
  return path;
}

async function main() {
  const input: HookInput = JSON.parse(readStdin());
  const rawPath = input.tool_input?.file_path || input.tool_input?.path;

  if (!rawPath) {
    console.log('{}');
    return;
  }

  const filePath = normalizePath(rawPath);
  const mapping = BINARY_SOURCE_MAP[filePath];

  if (mapping) {
    // Block the edit and redirect to source
    console.error(`🚫 BLOCKED: Cannot edit installed binary directly.

This file is an INSTALLED copy. Edit the SOURCE instead:

  Source: ${mapping.source}
  
After editing source, deploy with:
  ${mapping.install}

This prevents untracked drift between source and installed versions.`);
    process.exit(2);
  }

  // Not a protected path, allow
  console.log('{}');
}

main().catch(() => process.exit(1));
