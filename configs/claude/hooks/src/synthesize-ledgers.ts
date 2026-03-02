/**
 * Ledger Synthesis System (Phase 2)
 *
 * Synthesizes multiple event files from parallel agents into a unified current.md.
 * Uses CRDT-like merge semantics to avoid conflicts:
 * - Now: LWW (Last-Writer-Wins by timestamp)
 * - This Session: Grow-only set (union, dedupe by content hash)
 * - Decisions: LWW map (merge by key, newest timestamp wins)
 * - Checkpoints: Grow-only list (concatenate, sort by timestamp)
 * - Open Questions: Grow-only set (union, dedupe exact matches)
 */

import * as fs from 'fs';
import * as path from 'path';
import * as crypto from 'crypto';

// ============================================================================
// Types
// ============================================================================

interface EventFrontmatter {
  ts: string;           // ISO timestamp
  agent: string;        // Agent ID (8 chars)
  branch: string;       // Git branch
  type: string;         // Event type (session_end, checkpoint, etc.)
  reason?: string;      // For session_end: clear, logout, etc.
}

interface EventBody {
  now?: string;
  this_session?: string[];
  decisions?: Record<string, string>;
  checkpoints?: Array<{ phase: number; status: string; updated: string }>;
  open_questions?: string[];
}

interface ParsedEvent {
  frontmatter: EventFrontmatter;
  body: EventBody;
  filePath: string;
}

interface SynthesizedLedger {
  now: string;
  thisSession: string[];
  decisions: Record<string, { value: string; ts: string }>;
  checkpoints: Array<{ phase: number; status: string; updated: string }>;
  openQuestions: string[];
  metadata: {
    eventCount: number;
    latestTs: string;
    generatedAt: string;
    branches: string[];
  };
}

// ============================================================================
// Event Parsing
// ============================================================================

/**
 * Parse YAML frontmatter from markdown content.
 * Returns the frontmatter object and the remaining body.
 */
function parseFrontmatter(content: string): { frontmatter: EventFrontmatter | null; body: string } {
  const fmMatch = content.match(/^---\n([\s\S]*?)\n---\n([\s\S]*)$/);
  if (!fmMatch) {
    return { frontmatter: null, body: content };
  }

  const [, fmContent, body] = fmMatch;
  const frontmatter: Partial<EventFrontmatter> = {};

  // Simple YAML parsing for our known fields
  for (const line of fmContent.split('\n')) {
    const match = line.match(/^(\w+):\s*(.*)$/);
    if (match) {
      const [, key, value] = match;
      (frontmatter as Record<string, string>)[key] = value.trim();
    }
  }

  return {
    frontmatter: frontmatter as EventFrontmatter,
    body: body.trim()
  };
}

/**
 * Parse the body of an event file into structured sections.
 * Uses line-by-line parsing for robustness.
 */
function parseEventBody(body: string): EventBody {
  const result: EventBody = {};
  const lines = body.split('\n');

  let currentSection: string | null = null;
  let currentCheckpoint: Partial<{ phase: number; status: string; updated: string }> | null = null;

  for (let i = 0; i < lines.length; i++) {
    const line = lines[i];

    // Single-line fields
    if (line.startsWith('now:')) {
      result.now = line.slice(4).trim();
      continue;
    }

    // Section headers
    if (line === 'this_session:') {
      currentSection = 'this_session';
      result.this_session = [];
      continue;
    }
    if (line === 'decisions:') {
      currentSection = 'decisions';
      result.decisions = {};
      continue;
    }
    if (line === 'checkpoints:') {
      currentSection = 'checkpoints';
      result.checkpoints = [];
      continue;
    }
    if (line === 'open_questions:') {
      currentSection = 'open_questions';
      result.open_questions = [];
      continue;
    }

    // New top-level key resets section
    if (/^[a-z_]+:/.test(line) && !line.startsWith('  ') && !line.startsWith('-')) {
      if (currentCheckpoint && result.checkpoints) {
        if (currentCheckpoint.phase !== undefined && currentCheckpoint.status) {
          result.checkpoints.push(currentCheckpoint as { phase: number; status: string; updated: string });
        }
        currentCheckpoint = null;
      }
      currentSection = null;
      continue;
    }

    // List items for simple sections
    if (line.startsWith('- ') && currentSection === 'this_session' && result.this_session) {
      result.this_session.push(line.slice(2).trim());
      continue;
    }
    if (line.startsWith('- ') && currentSection === 'open_questions' && result.open_questions) {
      result.open_questions.push(line.slice(2).trim());
      continue;
    }

    // Decision key-value pairs
    if (currentSection === 'decisions' && result.decisions) {
      const match = line.match(/^\s+(\w+):\s*"?([^"]*)"?$/);
      if (match) {
        result.decisions[match[1]] = match[2];
      }
      continue;
    }

    // Checkpoint parsing
    if (currentSection === 'checkpoints' && result.checkpoints) {
      // New checkpoint item
      if (line.startsWith('- phase:')) {
        if (currentCheckpoint?.phase !== undefined && currentCheckpoint.status) {
          result.checkpoints.push(currentCheckpoint as { phase: number; status: string; updated: string });
        }
        currentCheckpoint = { phase: parseInt(line.match(/phase:\s*(\d+)/)?.[1] || '0', 10), updated: '' };
        continue;
      }
      // Checkpoint properties
      if (currentCheckpoint) {
        const statusMatch = line.match(/^\s+status:\s*(\w+)/);
        if (statusMatch) {
          currentCheckpoint.status = statusMatch[1];
          continue;
        }
        const updatedMatch = line.match(/^\s+updated:\s*(\S+)/);
        if (updatedMatch) {
          currentCheckpoint.updated = updatedMatch[1];
          continue;
        }
      }
    }
  }

  // Push final checkpoint if any
  if (currentCheckpoint && result.checkpoints) {
    if (currentCheckpoint.phase !== undefined && currentCheckpoint.status) {
      result.checkpoints.push(currentCheckpoint as { phase: number; status: string; updated: string });
    }
  }

  return result;
}

/**
 * Read and parse a single event file.
 */
export function parseEventFile(filePath: string): ParsedEvent | null {
  try {
    const content = fs.readFileSync(filePath, 'utf-8');
    const { frontmatter, body } = parseFrontmatter(content);

    if (!frontmatter || !frontmatter.ts || !frontmatter.agent) {
      return null;
    }

    return {
      frontmatter,
      body: parseEventBody(body),
      filePath
    };
  } catch {
    return null;
  }
}

/**
 * Read all event files from a directory.
 */
export function readAllEvents(eventsDir: string): ParsedEvent[] {
  if (!fs.existsSync(eventsDir)) {
    return [];
  }

  const files = fs.readdirSync(eventsDir)
    .filter(f => f.endsWith('.md') && !f.startsWith('.'))
    .sort(); // Sort for deterministic order

  const events: ParsedEvent[] = [];
  for (const file of files) {
    const event = parseEventFile(path.join(eventsDir, file));
    if (event) {
      events.push(event);
    }
  }

  return events;
}

// ============================================================================
// Merge Functions (CRDT-like semantics)
// ============================================================================

/**
 * LWW Register: Pick the value from the event with the latest timestamp.
 */
export function pickLatest(events: ParsedEvent[], field: 'now'): string {
  let latest: { value: string; ts: string } | null = null;

  for (const event of events) {
    const value = event.body[field];
    if (value) {
      const ts = event.frontmatter.ts;
      if (!latest || ts > latest.ts) {
        latest = { value, ts };
      }
    }
  }

  return latest?.value || '';
}

/**
 * Grow-only Set: Union all items, dedupe by content hash.
 */
export function unionByHash(events: ParsedEvent[], field: 'this_session' | 'open_questions'): string[] {
  const seen = new Map<string, string>(); // hash -> original content

  for (const event of events) {
    const items = event.body[field] || [];
    for (const item of items) {
      const hash = crypto.createHash('md5').update(item).digest('hex').slice(0, 8);
      if (!seen.has(hash)) {
        seen.set(hash, item);
      }
    }
  }

  // Sort for deterministic output
  return Array.from(seen.values()).sort();
}

/**
 * LWW Map: Merge by key, newest timestamp wins per key.
 */
export function mergeByKey(events: ParsedEvent[]): Record<string, { value: string; ts: string }> {
  const result: Record<string, { value: string; ts: string }> = {};

  for (const event of events) {
    const decisions = event.body.decisions || {};
    const ts = event.frontmatter.ts;

    for (const [key, value] of Object.entries(decisions)) {
      if (!result[key] || ts > result[key].ts) {
        result[key] = { value, ts };
      }
    }
  }

  return result;
}

/**
 * Grow-only List: Concatenate all, sort by timestamp, dedupe by phase.
 */
export function sortByTime(events: ParsedEvent[]): Array<{ phase: number; status: string; updated: string }> {
  const all: Array<{ phase: number; status: string; updated: string }> = [];

  for (const event of events) {
    const checkpoints = event.body.checkpoints || [];
    all.push(...checkpoints);
  }

  // Sort by updated timestamp
  all.sort((a, b) => (a.updated || '').localeCompare(b.updated || ''));

  // Dedupe by phase (keep latest for each phase)
  const byPhase = new Map<number, { phase: number; status: string; updated: string }>();
  for (const cp of all) {
    byPhase.set(cp.phase, cp);
  }

  return Array.from(byPhase.values()).sort((a, b) => a.phase - b.phase);
}

// ============================================================================
// Synthesis
// ============================================================================

/**
 * Synthesize all event files into a unified ledger.
 */
export function synthesize(eventsDir: string): SynthesizedLedger {
  const events = readAllEvents(eventsDir);

  const latestTs = events.reduce((max, e) =>
    e.frontmatter.ts > max ? e.frontmatter.ts : max, '');

  const branches = [...new Set(events.map(e => e.frontmatter.branch))].sort();
  const decisionsMap = mergeByKey(events);

  return {
    now: pickLatest(events, 'now'),
    thisSession: unionByHash(events, 'this_session'),
    decisions: decisionsMap,
    checkpoints: sortByTime(events),
    openQuestions: unionByHash(events, 'open_questions'),
    metadata: {
      eventCount: events.length,
      latestTs,
      generatedAt: new Date().toISOString(),
      branches
    }
  };
}

/**
 * Format a synthesized ledger as markdown (current.md format).
 */
export function formatLedger(ledger: SynthesizedLedger): string {
  const lines: string[] = [];

  lines.push('## Ledger');
  lines.push(`**Updated:** ${ledger.metadata.generatedAt}`);

  if (ledger.now) {
    lines.push(`**Now:** ${ledger.now}`);
  }

  lines.push('');

  if (ledger.thisSession.length > 0) {
    lines.push('### This Session');
    for (const item of ledger.thisSession) {
      lines.push(`- ${item}`);
    }
    lines.push('');
  }

  if (Object.keys(ledger.decisions).length > 0) {
    lines.push('### Decisions');
    for (const [key, { value }] of Object.entries(ledger.decisions).sort()) {
      lines.push(`- **${key}:** ${value}`);
    }
    lines.push('');
  }

  if (ledger.checkpoints.length > 0) {
    lines.push('### Checkpoints');
    for (const cp of ledger.checkpoints) {
      lines.push(`- Phase ${cp.phase}: ${cp.status} (${cp.updated})`);
    }
    lines.push('');
  }

  if (ledger.openQuestions.length > 0) {
    lines.push('### Open Questions');
    for (const q of ledger.openQuestions) {
      lines.push(`- ${q}`);
    }
    lines.push('');
  }

  // Metadata footer
  lines.push('---');
  lines.push('_Synthesized from:_');
  lines.push(`- Events: ${ledger.metadata.eventCount}`);
  lines.push(`- Latest: ${ledger.metadata.latestTs}`);
  lines.push(`- Branches: ${ledger.metadata.branches.join(', ') || 'none'}`);
  lines.push(`- Generated: ${ledger.metadata.generatedAt}`);

  return lines.join('\n');
}

/**
 * Write synthesized ledger to current.md (atomic write).
 */
export function writeLedger(ledger: SynthesizedLedger, outputPath: string): void {
  const content = formatLedger(ledger);
  const tempPath = `${outputPath}.tmp`;

  fs.writeFileSync(tempPath, content, 'utf-8');
  fs.renameSync(tempPath, outputPath);
}

/**
 * Main synthesis function: read events, synthesize, write current.md.
 */
export function synthesizeAndWrite(
  eventsDir: string,
  outputPath: string
): { ledger: SynthesizedLedger; written: boolean } {
  const ledger = synthesize(eventsDir);

  try {
    writeLedger(ledger, outputPath);
    return { ledger, written: true };
  } catch {
    return { ledger, written: false };
  }
}

// ============================================================================
// CLI Entry Point
// ============================================================================

async function main() {
  const eventsDir = process.argv[2] || 'thoughts/shared/handoffs/events';
  const outputPath = process.argv[3] || 'thoughts/shared/handoffs/current.md';

  console.error(`Synthesizing ledger from: ${eventsDir}`);
  const { ledger, written } = synthesizeAndWrite(eventsDir, outputPath);

  console.error(`Events processed: ${ledger.metadata.eventCount}`);
  console.error(`Branches: ${ledger.metadata.branches.join(', ') || 'none'}`);
  console.error(`Written: ${written ? outputPath : 'FAILED'}`);

  if (written) {
    console.log(JSON.stringify({ success: true, eventCount: ledger.metadata.eventCount }));
  } else {
    console.log(JSON.stringify({ success: false, error: 'Failed to write ledger' }));
    process.exit(1);
  }
}

// Only run main if executed directly as synthesize-ledgers
// Check that we're not being bundled into another hook
const scriptName = process.argv[1] || '';
const isSynthesizerScript = scriptName.includes('synthesize-ledgers');
if (isSynthesizerScript) {
  void main();
}
