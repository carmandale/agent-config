/**
 * Tests for ledger synthesis functions
 */

import { describe, it, expect, beforeEach, afterEach } from 'vitest';
import * as fs from 'fs';
import * as path from 'path';
import * as os from 'os';
import {
  parseEventFile,
  readAllEvents,
  pickLatest,
  unionByHash,
  mergeByKey,
  sortByTime,
  synthesize,
  formatLedger
} from '../synthesize-ledgers.js';

// Test fixtures
const EVENT_WITH_FULL_BODY = `---
ts: 2026-01-11T10:00:00Z
agent: abc12345
branch: feat/feature-a
type: session_end
reason: clear
---

now: Implement the auth flow

this_session:
- Added login endpoint
- Created user model
- Fixed password hashing

decisions:
  auth_method: "JWT with refresh tokens"
  session_storage: "Redis"

checkpoints:
- phase: 1
  status: completed
  updated: 2026-01-11T09:00:00Z
- phase: 2
  status: in_progress
  updated: 2026-01-11T10:00:00Z

open_questions:
- How should we handle token refresh?
- What's the session timeout?
`;

const EVENT_WITH_MINIMAL_BODY = `---
ts: 2026-01-11T08:00:00Z
agent: def67890
branch: main
type: session_end
reason: clear
---

## Session End
Updated: 2026-01-11T08:00:00Z
`;

const EVENT_WITH_DIFFERENT_NOW = `---
ts: 2026-01-11T12:00:00Z
agent: ghi11111
branch: feat/feature-b
type: session_end
reason: clear
---

now: Deploy to staging

this_session:
- Added deployment script
- Updated CI/CD

decisions:
  auth_method: "OAuth2 instead"
  deploy_target: "AWS ECS"
`;

let testDir: string;

beforeEach(() => {
  // Create a temp directory for test files
  testDir = fs.mkdtempSync(path.join(os.tmpdir(), 'synthesize-test-'));
});

afterEach(() => {
  // Clean up temp directory
  fs.rmSync(testDir, { recursive: true, force: true });
});

function writeTestEvent(filename: string, content: string): string {
  const filePath = path.join(testDir, filename);
  fs.writeFileSync(filePath, content);
  return filePath;
}

describe('parseEventFile', () => {
  it('should parse event with full body', () => {
    const filePath = writeTestEvent('event1.md', EVENT_WITH_FULL_BODY);
    const event = parseEventFile(filePath);

    expect(event).not.toBeNull();
    expect(event!.frontmatter.ts).toBe('2026-01-11T10:00:00Z');
    expect(event!.frontmatter.agent).toBe('abc12345');
    expect(event!.frontmatter.branch).toBe('feat/feature-a');
    expect(event!.frontmatter.type).toBe('session_end');
    expect(event!.body.now).toBe('Implement the auth flow');
    expect(event!.body.this_session).toHaveLength(3);
    expect(event!.body.this_session).toContain('Added login endpoint');
    expect(event!.body.decisions?.auth_method).toBe('JWT with refresh tokens');
    expect(event!.body.checkpoints).toHaveLength(2);
    expect(event!.body.open_questions).toHaveLength(2);
  });

  it('should parse event with minimal body', () => {
    const filePath = writeTestEvent('event2.md', EVENT_WITH_MINIMAL_BODY);
    const event = parseEventFile(filePath);

    expect(event).not.toBeNull();
    expect(event!.frontmatter.ts).toBe('2026-01-11T08:00:00Z');
    expect(event!.frontmatter.agent).toBe('def67890');
    expect(event!.body.now).toBeUndefined();
    expect(event!.body.this_session).toBeUndefined();
  });

  it('should return null for invalid file', () => {
    const filePath = writeTestEvent('invalid.md', 'no frontmatter here');
    const event = parseEventFile(filePath);

    expect(event).toBeNull();
  });

  it('should return null for non-existent file', () => {
    const event = parseEventFile('/nonexistent/path.md');
    expect(event).toBeNull();
  });
});

describe('readAllEvents', () => {
  it('should read all events from directory', () => {
    writeTestEvent('event1.md', EVENT_WITH_FULL_BODY);
    writeTestEvent('event2.md', EVENT_WITH_MINIMAL_BODY);
    writeTestEvent('event3.md', EVENT_WITH_DIFFERENT_NOW);

    const events = readAllEvents(testDir);

    expect(events).toHaveLength(3);
  });

  it('should ignore non-md files', () => {
    writeTestEvent('event1.md', EVENT_WITH_FULL_BODY);
    fs.writeFileSync(path.join(testDir, 'readme.txt'), 'not an event');
    fs.writeFileSync(path.join(testDir, '.synth.lock'), 'lock file');

    const events = readAllEvents(testDir);

    expect(events).toHaveLength(1);
  });

  it('should return empty array for non-existent directory', () => {
    const events = readAllEvents('/nonexistent/dir');
    expect(events).toHaveLength(0);
  });

  it('should skip malformed events', () => {
    writeTestEvent('good.md', EVENT_WITH_FULL_BODY);
    writeTestEvent('bad.md', 'no frontmatter');

    const events = readAllEvents(testDir);

    expect(events).toHaveLength(1);
    expect(events[0].frontmatter.agent).toBe('abc12345');
  });
});

describe('pickLatest (LWW)', () => {
  it('should pick the most recent now value', () => {
    writeTestEvent('early.md', EVENT_WITH_FULL_BODY); // ts: 10:00
    writeTestEvent('later.md', EVENT_WITH_DIFFERENT_NOW); // ts: 12:00

    const events = readAllEvents(testDir);
    const result = pickLatest(events, 'now');

    expect(result).toBe('Deploy to staging');
  });

  it('should return empty string when no now values', () => {
    writeTestEvent('minimal.md', EVENT_WITH_MINIMAL_BODY);

    const events = readAllEvents(testDir);
    const result = pickLatest(events, 'now');

    expect(result).toBe('');
  });
});

describe('unionByHash (Grow-only Set)', () => {
  it('should union all this_session items', () => {
    writeTestEvent('event1.md', EVENT_WITH_FULL_BODY);
    writeTestEvent('event2.md', EVENT_WITH_DIFFERENT_NOW);

    const events = readAllEvents(testDir);
    const result = unionByHash(events, 'this_session');

    // Should have items from both events, sorted
    expect(result).toContain('Added login endpoint');
    expect(result).toContain('Added deployment script');
    expect(result).toHaveLength(5); // 3 from first + 2 from second
  });

  it('should dedupe identical items', () => {
    const eventWithDupe = `---
ts: 2026-01-11T11:00:00Z
agent: dup11111
branch: main
type: session_end
---

this_session:
- Added login endpoint
- Duplicate item
`;
    writeTestEvent('event1.md', EVENT_WITH_FULL_BODY);
    writeTestEvent('event2.md', eventWithDupe);

    const events = readAllEvents(testDir);
    const result = unionByHash(events, 'this_session');

    // "Added login endpoint" should only appear once
    const loginCount = result.filter(item => item === 'Added login endpoint').length;
    expect(loginCount).toBe(1);
  });

  it('should return sorted results', () => {
    writeTestEvent('event1.md', EVENT_WITH_FULL_BODY);
    writeTestEvent('event2.md', EVENT_WITH_DIFFERENT_NOW);

    const events = readAllEvents(testDir);
    const result = unionByHash(events, 'this_session');

    // Check that result is sorted
    const sorted = [...result].sort();
    expect(result).toEqual(sorted);
  });
});

describe('mergeByKey (LWW Map)', () => {
  it('should merge decisions with latest timestamp winning', () => {
    writeTestEvent('early.md', EVENT_WITH_FULL_BODY); // ts: 10:00, auth_method: JWT
    writeTestEvent('later.md', EVENT_WITH_DIFFERENT_NOW); // ts: 12:00, auth_method: OAuth2

    const events = readAllEvents(testDir);
    const result = mergeByKey(events);

    // Later event should win for auth_method
    expect(result.auth_method.value).toBe('OAuth2 instead');

    // First event's session_storage should be preserved
    expect(result.session_storage.value).toBe('Redis');

    // Later event's deploy_target should be included
    expect(result.deploy_target.value).toBe('AWS ECS');
  });

  it('should include timestamp with each decision', () => {
    writeTestEvent('event.md', EVENT_WITH_FULL_BODY);

    const events = readAllEvents(testDir);
    const result = mergeByKey(events);

    expect(result.auth_method.ts).toBe('2026-01-11T10:00:00Z');
  });
});

describe('sortByTime (Grow-only List)', () => {
  it('should sort checkpoints by timestamp', () => {
    const eventWithCheckpoints = `---
ts: 2026-01-11T13:00:00Z
agent: chk11111
branch: main
type: session_end
---

checkpoints:
- phase: 3
  status: completed
  updated: 2026-01-11T12:00:00Z
- phase: 4
  status: in_progress
  updated: 2026-01-11T13:00:00Z
`;
    writeTestEvent('event1.md', EVENT_WITH_FULL_BODY);
    writeTestEvent('event2.md', eventWithCheckpoints);

    const events = readAllEvents(testDir);
    const result = sortByTime(events);

    // Should have 4 phases total, but dedupe keeps latest per phase
    expect(result.find(c => c.phase === 1)?.status).toBe('completed');
    expect(result.find(c => c.phase === 2)?.status).toBe('in_progress');
    expect(result.find(c => c.phase === 3)?.status).toBe('completed');
    expect(result.find(c => c.phase === 4)?.status).toBe('in_progress');
  });

  it('should dedupe by phase, keeping latest', () => {
    const laterEvent = `---
ts: 2026-01-11T14:00:00Z
agent: late1111
branch: main
type: session_end
---

checkpoints:
- phase: 1
  status: validated
  updated: 2026-01-11T14:00:00Z
`;
    writeTestEvent('early.md', EVENT_WITH_FULL_BODY);
    writeTestEvent('later.md', laterEvent);

    const events = readAllEvents(testDir);
    const result = sortByTime(events);

    // Phase 1 should be 'validated' from later event
    expect(result.find(c => c.phase === 1)?.status).toBe('validated');
  });
});

describe('synthesize', () => {
  it('should synthesize multiple events into unified ledger', () => {
    writeTestEvent('event1.md', EVENT_WITH_FULL_BODY);
    writeTestEvent('event2.md', EVENT_WITH_DIFFERENT_NOW);

    const ledger = synthesize(testDir);

    expect(ledger.now).toBe('Deploy to staging'); // From later event
    expect(ledger.thisSession.length).toBeGreaterThan(0);
    expect(ledger.decisions.auth_method.value).toBe('OAuth2 instead');
    expect(ledger.metadata.eventCount).toBe(2);
    expect(ledger.metadata.branches).toContain('feat/feature-a');
    expect(ledger.metadata.branches).toContain('feat/feature-b');
  });

  it('should handle empty events directory', () => {
    const ledger = synthesize(testDir);

    expect(ledger.now).toBe('');
    expect(ledger.thisSession).toHaveLength(0);
    expect(ledger.metadata.eventCount).toBe(0);
  });
});

describe('formatLedger', () => {
  it('should format ledger as markdown', () => {
    writeTestEvent('event.md', EVENT_WITH_FULL_BODY);

    const ledger = synthesize(testDir);
    const formatted = formatLedger(ledger);

    expect(formatted).toContain('## Ledger');
    expect(formatted).toContain('**Updated:**');
    expect(formatted).toContain('**Now:** Implement the auth flow');
    expect(formatted).toContain('### This Session');
    expect(formatted).toContain('- Added login endpoint');
    expect(formatted).toContain('### Decisions');
    expect(formatted).toContain('**auth_method:** JWT with refresh tokens');
    expect(formatted).toContain('### Checkpoints');
    expect(formatted).toContain('Phase 1: completed');
    expect(formatted).toContain('### Open Questions');
    expect(formatted).toContain('_Synthesized from:_');
    expect(formatted).toContain('- Events: 1');
  });

  it('should omit empty sections', () => {
    writeTestEvent('minimal.md', EVENT_WITH_MINIMAL_BODY);

    const ledger = synthesize(testDir);
    const formatted = formatLedger(ledger);

    // Should not have sections that are empty
    expect(formatted).not.toContain('### This Session');
    expect(formatted).not.toContain('### Decisions');
    expect(formatted).not.toContain('### Checkpoints');
  });

  it('should be deterministic', () => {
    writeTestEvent('event1.md', EVENT_WITH_FULL_BODY);
    writeTestEvent('event2.md', EVENT_WITH_DIFFERENT_NOW);

    const ledger1 = synthesize(testDir);
    const ledger2 = synthesize(testDir);

    // Override generatedAt for comparison
    ledger1.metadata.generatedAt = '2026-01-11T00:00:00Z';
    ledger2.metadata.generatedAt = '2026-01-11T00:00:00Z';

    const formatted1 = formatLedger(ledger1);
    const formatted2 = formatLedger(ledger2);

    expect(formatted1).toBe(formatted2);
  });
});
