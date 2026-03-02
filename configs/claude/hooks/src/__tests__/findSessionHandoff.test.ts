/**
 * Tests for findSessionHandoff() function
 */

import { describe, it, expect, beforeEach, afterEach } from 'vitest';
import * as fs from 'fs';
import * as path from 'path';
import * as os from 'os';

import { findSessionHandoff } from '../session-start-continuity.js';

describe('findSessionHandoff', () => {
  let testDir: string;
  let originalProjectDir: string | undefined;

  beforeEach(() => {
    testDir = fs.mkdtempSync(path.join(os.tmpdir(), 'findSessionHandoff-test-'));
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

  it('should return null for nonexistent session directory', () => {
    const result = findSessionHandoff('nonexistent-session');
    expect(result).toBeNull();
  });

  it('should return null for empty directory (no .md files)', () => {
    const handoffDir = path.join(testDir, 'thoughts', 'shared', 'handoffs', 'empty-session');
    fs.mkdirSync(handoffDir, { recursive: true });

    const result = findSessionHandoff('empty-session');
    expect(result).toBeNull();
  });

  it('should return null for directory with only non-.md files', () => {
    const sessionName = 'non-md-session';
    const handoffDir = path.join(testDir, 'thoughts', 'shared', 'handoffs', sessionName);
    fs.mkdirSync(handoffDir, { recursive: true });

    fs.writeFileSync(path.join(handoffDir, 'notes.txt'), 'some notes');
    fs.writeFileSync(path.join(handoffDir, 'data.json'), '{}');
    fs.writeFileSync(path.join(handoffDir, '.gitkeep'), '');

    const result = findSessionHandoff(sessionName);
    expect(result).toBeNull();
  });

  it('should return the most recent handoff by mtime', async () => {
    const sessionName = 'mtime-test-session';
    const handoffDir = path.join(testDir, 'thoughts', 'shared', 'handoffs', sessionName);
    fs.mkdirSync(handoffDir, { recursive: true });

    const olderFile = path.join(handoffDir, '2025-12-29_handoff.md');
    fs.writeFileSync(olderFile, '# Older handoff');

    await new Promise(resolve => setTimeout(resolve, 50));

    const newerFile = path.join(handoffDir, '2025-12-30_handoff.md');
    fs.writeFileSync(newerFile, '# Newer handoff');

    const result = findSessionHandoff(sessionName);

    expect(result).not.toBeNull();
    expect(result).toBe(newerFile);
  });

  it('should return current.md if it is the most recent (by mtime)', async () => {
    const sessionName = 'current-session';
    const handoffDir = path.join(testDir, 'thoughts', 'shared', 'handoffs', sessionName);
    fs.mkdirSync(handoffDir, { recursive: true });

    const olderFile = path.join(handoffDir, '2025-12-28_old-handoff.md');
    fs.writeFileSync(olderFile, '# Old handoff');

    await new Promise(resolve => setTimeout(resolve, 50));

    const currentFile = path.join(handoffDir, 'current.md');
    fs.writeFileSync(currentFile, '# Current handoff');

    const result = findSessionHandoff(sessionName);

    expect(result).not.toBeNull();
    expect(result).toBe(currentFile);
  });

  it('should handle single .md file correctly', () => {
    const sessionName = 'single-file-session';
    const handoffDir = path.join(testDir, 'thoughts', 'shared', 'handoffs', sessionName);
    fs.mkdirSync(handoffDir, { recursive: true });

    const singleFile = path.join(handoffDir, 'only-handoff.md');
    fs.writeFileSync(singleFile, '# The only handoff');

    const result = findSessionHandoff(sessionName);

    expect(result).not.toBeNull();
    expect(result).toBe(singleFile);
  });

  it('should ignore non-.md files when selecting most recent', async () => {
    const sessionName = 'mixed-files-session';
    const handoffDir = path.join(testDir, 'thoughts', 'shared', 'handoffs', sessionName);
    fs.mkdirSync(handoffDir, { recursive: true });

    const mdFile = path.join(handoffDir, 'handoff.md');
    fs.writeFileSync(mdFile, '# Handoff');

    await new Promise(resolve => setTimeout(resolve, 50));

    fs.writeFileSync(path.join(handoffDir, 'newer-notes.txt'), 'notes');
    fs.writeFileSync(path.join(handoffDir, 'even-newer.json'), '{}');

    const result = findSessionHandoff(sessionName);

    expect(result).not.toBeNull();
    expect(result).toBe(mdFile);
  });

  it('should return absolute path to the handoff file', () => {
    const sessionName = 'absolute-path-session';
    const handoffDir = path.join(testDir, 'thoughts', 'shared', 'handoffs', sessionName);
    fs.mkdirSync(handoffDir, { recursive: true });

    const handoffFile = path.join(handoffDir, 'handoff.md');
    fs.writeFileSync(handoffFile, '# Handoff content');

    const result = findSessionHandoff(sessionName);

    expect(result).not.toBeNull();
    expect(path.isAbsolute(result!)).toBe(true);
    expect(result!.endsWith('.md')).toBe(true);
  });

  it('should handle session name with special characters', () => {
    const sessionName = 'my-feature_v2.0';
    const handoffDir = path.join(testDir, 'thoughts', 'shared', 'handoffs', sessionName);
    fs.mkdirSync(handoffDir, { recursive: true });

    const handoffFile = path.join(handoffDir, 'current.md');
    fs.writeFileSync(handoffFile, '# Handoff');

    const result = findSessionHandoff(sessionName);

    expect(result).not.toBeNull();
    expect(result).toBe(handoffFile);
  });

  it('should use CLAUDE_PROJECT_DIR environment variable', () => {
    const sessionName = 'env-var-test';
    const handoffDir = path.join(testDir, 'thoughts', 'shared', 'handoffs', sessionName);
    fs.mkdirSync(handoffDir, { recursive: true });

    const handoffFile = path.join(handoffDir, 'handoff.md');
    fs.writeFileSync(handoffFile, '# Handoff');

    const result = findSessionHandoff(sessionName);

    expect(result).not.toBeNull();
    expect(result!.startsWith(testDir)).toBe(true);
  });
});
