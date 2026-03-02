/**
 * Tests for main() - checks handoffs FIRST for embedded Ledger sections
 */

import { describe, it, expect, beforeEach, afterEach } from 'vitest';
import * as fs from 'fs';
import * as path from 'path';
import * as os from 'os';
import { execSync } from 'child_process';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

describe('main() handoff-first behavior', () => {
  let testDir: string;
  let originalProjectDir: string | undefined;

  beforeEach(() => {
    testDir = fs.mkdtempSync(path.join(os.tmpdir(), 'mainHandoffFirst-test-'));
    originalProjectDir = process.env.CLAUDE_PROJECT_DIR;
    process.env.CLAUDE_PROJECT_DIR = testDir;
  });

  afterEach(() => {
    if (originalProjectDir !== undefined) {
      process.env.CLAUDE_PROJECT_DIR = originalProjectDir;
    } else {
      delete process.env.CLAUDE_PROJECT_DIR;
    }
    fs.rmSync(testDir, { recursive: true, force: true });
  });

  function runHook(input: object): { stdout: string; stderr: string } {
    const inputJson = JSON.stringify(input);
    const hookPath = path.resolve(__dirname, '../../dist/session-start-continuity.mjs');

    try {
      const stdout = execSync(`echo '${inputJson}' | CLAUDE_PROJECT_DIR="${testDir}" node "${hookPath}"`, {
        encoding: 'utf-8',
        timeout: 5000,
        env: { ...process.env, CLAUDE_PROJECT_DIR: testDir }
      });
      return { stdout, stderr: '' };
    } catch (error: any) {
      return { stdout: error.stdout || '', stderr: error.stderr || '' };
    }
  }

  describe('when handoff has Ledger section', () => {
    it('should use handoff Ledger section', () => {
      const sessionName = 'test-session';
      const handoffDir = path.join(testDir, 'thoughts', 'shared', 'handoffs', sessionName);
      fs.mkdirSync(handoffDir, { recursive: true });

      const handoffContent = `# Work Stream: ${sessionName}

## Ledger
**Updated:** 2025-12-30T12:00:00Z
**Goal:** Handoff goal (NEW)
**Branch:** feature/handoff
**Test:** npm test

### Now
[->] Working from handoff Ledger

### Next
- [ ] Next item from handoff

---

## Context
Detailed context from handoff.
`;
      fs.writeFileSync(path.join(handoffDir, 'current.md'), handoffContent);

      const result = runHook({ source: 'resume', session_id: 'test-123' });
      const output = JSON.parse(result.stdout);

      expect(output.result).toBe('continue');
      const fullOutput = JSON.stringify(output);
      expect(
        fullOutput.includes('Handoff goal') || fullOutput.includes('Working from handoff')
      ).toBe(true);
    });

    it('should select most recent handoff when multiple sessions have Ledger sections', async () => {
      const session1Dir = path.join(testDir, 'thoughts', 'shared', 'handoffs', 'session-old');
      const session2Dir = path.join(testDir, 'thoughts', 'shared', 'handoffs', 'session-new');
      fs.mkdirSync(session1Dir, { recursive: true });
      fs.mkdirSync(session2Dir, { recursive: true });

      const oldHandoff = `# Work Stream: session-old

## Ledger
**Updated:** 2025-12-29T00:00:00Z
**Goal:** Old session goal
**Branch:** old-branch

### Now
[->] Old session focus

---

## Context
Old context.
`;
      fs.writeFileSync(path.join(session1Dir, 'current.md'), oldHandoff);

      await new Promise(resolve => setTimeout(resolve, 50));

      const newHandoff = `# Work Stream: session-new

## Ledger
**Updated:** 2025-12-30T12:00:00Z
**Goal:** New session goal
**Branch:** new-branch

### Now
[->] New session focus

---

## Context
New context.
`;
      fs.writeFileSync(path.join(session2Dir, 'current.md'), newHandoff);

      const result = runHook({ source: 'resume', session_id: 'test-123' });
      const output = JSON.parse(result.stdout);

      const fullOutput = JSON.stringify(output);
      expect(
        fullOutput.includes('New session goal') || fullOutput.includes('New session focus')
      ).toBe(true);
    });
  });

  describe('when no handoff exists', () => {
    it('should return continue with no message when no ledger or handoff exists', () => {
      const result = runHook({ source: 'resume', session_id: 'test-123' });
      const output = JSON.parse(result.stdout);

      expect(output.result).toBe('continue');
    });
  });

  describe('handoff directory edge cases', () => {
    it('should handle non-existent handoffs directory gracefully', () => {
      const result = runHook({ source: 'resume', session_id: 'test-123' });
      const output = JSON.parse(result.stdout);

      expect(output.result).toBe('continue');
    });

    it('should handle empty handoffs directory', () => {
      const handoffsDir = path.join(testDir, 'thoughts', 'shared', 'handoffs');
      fs.mkdirSync(handoffsDir, { recursive: true });

      const result = runHook({ source: 'resume', session_id: 'test-123' });
      const output = JSON.parse(result.stdout);

      expect(output.result).toBe('continue');
    });
  });

  describe('startup vs resume behavior', () => {
    it('should show brief notification on startup when handoff Ledger available', () => {
      const sessionName = 'startup-test';
      const handoffDir = path.join(testDir, 'thoughts', 'shared', 'handoffs', sessionName);
      fs.mkdirSync(handoffDir, { recursive: true });

      const handoffContent = `# Work Stream: ${sessionName}

## Ledger
**Updated:** 2025-12-30T12:00:00Z
**Goal:** Startup test goal
**Branch:** main

### Now
[->] Current startup task

---

## Context
Context details.
`;
      fs.writeFileSync(path.join(handoffDir, 'current.md'), handoffContent);

      const result = runHook({ source: 'startup', session_id: 'test-123' });
      const output = JSON.parse(result.stdout);

      expect(output.result).toBe('continue');
      if (output.message) {
        expect(output.message.length).toBeLessThan(500);
      }
    });

    it('should load full Ledger content on clear/compact', () => {
      const sessionName = 'resume-test';
      const handoffDir = path.join(testDir, 'thoughts', 'shared', 'handoffs', sessionName);
      fs.mkdirSync(handoffDir, { recursive: true });

      const handoffContent = `# Work Stream: ${sessionName}

## Ledger
**Updated:** 2025-12-30T12:00:00Z
**Goal:** Resume test goal with detailed info
**Branch:** feature/resume

### Now
[->] Working on resume functionality

### This Session
- [x] Completed task 1
- [x] Completed task 2

### Next
- [ ] Priority 1
- [ ] Priority 2

### Decisions
- Important decision: reasoning

---

## Context
Full context that should be available on resume.
`;
      fs.writeFileSync(path.join(handoffDir, 'current.md'), handoffContent);

      const result = runHook({ source: 'clear', session_id: 'test-123' });
      const output = JSON.parse(result.stdout);

      expect(output.result).toBe('continue');
      expect(output.hookSpecificOutput).toBeDefined();
      expect(output.hookSpecificOutput.additionalContext).toContain('Ledger');
    });
  });
});
