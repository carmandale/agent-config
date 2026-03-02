/**
 * Background Learning Extractor
 *
 * Runs as a detached process spawned by session-end-cleanup.ts.
 * Parses transcript for thinking blocks with perception signals and stores learnings.
 *
 * Usage: node background-learning-extractor.mjs <transcript_path> <session_id> <project_dir>
 */

import * as fs from 'fs';
import * as path from 'path';
import { spawn } from 'child_process';

// ============================================================================
// Types
// ============================================================================

interface Learning {
  type: LearningType;
  content: string;
  preview: string;
  stored: boolean;
  error?: string;
}

type LearningType =
  | 'REALIZATION'
  | 'CORRECTION'
  | 'INSIGHT'
  | 'DEBUGGING_APPROACH'
  | 'WORKING_SOLUTION'
  | 'FAILED_APPROACH';

interface ExtractionResult {
  timestamp: string;
  session_id: string;
  learnings: Learning[];
  error: string | null;
}

interface TranscriptEntry {
  type?: string;
  role?: string;
  content?: unknown;
  message?: {
    content?: Array<{ type: string; text?: string; thinking?: string }>;
  };
}

// ============================================================================
// Perception Signal Patterns
// ============================================================================

// Patterns that indicate valuable learnings in thinking blocks
const PERCEPTION_PATTERNS: Array<{ pattern: RegExp; type: LearningType }> = [
  // Realizations - moments of understanding
  { pattern: /\bI (now |just )?(realize|understand|see|notice)\b/i, type: 'REALIZATION' },
  { pattern: /\bthis (means|explains|shows|indicates)\b/i, type: 'REALIZATION' },
  { pattern: /\baha[!,]?\b/i, type: 'REALIZATION' },

  // Corrections - fixing mistakes or misconceptions
  { pattern: /\b(wait|actually|no,? wait|hmm)\b.*\b(wrong|incorrect|mistake|misunderstood)\b/i, type: 'CORRECTION' },
  { pattern: /\bI was wrong\b/i, type: 'CORRECTION' },
  { pattern: /\bthat's not (right|correct)\b/i, type: 'CORRECTION' },

  // Insights - patterns and connections
  { pattern: /\bthe (pattern|key|trick|solution) (is|here is)\b/i, type: 'INSIGHT' },
  { pattern: /\bthis (pattern|approach) works because\b/i, type: 'INSIGHT' },
  { pattern: /\binteresting(ly)?\b.*\b(pattern|connection|relationship)\b/i, type: 'INSIGHT' },

  // Debugging approaches - what worked for solving problems
  { pattern: /\bthe (fix|solution) (is|was) to\b/i, type: 'DEBUGGING_APPROACH' },
  { pattern: /\bfixed (by|it by|this by)\b/i, type: 'DEBUGGING_APPROACH' },
  { pattern: /\bresolved (by|it by|this by)\b/i, type: 'DEBUGGING_APPROACH' },

  // Working solutions
  { pattern: /\bthis works because\b/i, type: 'WORKING_SOLUTION' },
  { pattern: /\bthe (right|correct) (way|approach) is\b/i, type: 'WORKING_SOLUTION' },

  // Failed approaches
  { pattern: /\bthis (doesn't|won't|didn't) work because\b/i, type: 'FAILED_APPROACH' },
  { pattern: /\btried .* but (it )?(failed|didn't work)\b/i, type: 'FAILED_APPROACH' },
];

// ============================================================================
// Transcript Parsing
// ============================================================================

/**
 * Extract thinking blocks from transcript.
 */
function extractThinkingBlocks(transcriptPath: string): string[] {
  if (!fs.existsSync(transcriptPath)) {
    return [];
  }

  const content = fs.readFileSync(transcriptPath, 'utf-8');
  const lines = content.split('\n').filter(line => line.trim());
  const thinkingBlocks: string[] = [];

  for (const line of lines) {
    try {
      const entry: TranscriptEntry = JSON.parse(line);

      // Check for thinking content in message
      if (entry.message?.content && Array.isArray(entry.message.content)) {
        for (const block of entry.message.content) {
          if (block.type === 'thinking' && block.thinking) {
            thinkingBlocks.push(block.thinking);
          }
        }
      }

      // Also check direct content if it looks like thinking
      if (entry.type === 'thinking' && typeof entry.content === 'string') {
        thinkingBlocks.push(entry.content);
      }
    } catch {
      // Skip malformed JSON lines
      continue;
    }
  }

  return thinkingBlocks;
}

/**
 * Classify a text block and extract learnings.
 */
function classifyAndExtract(thinkingBlock: string): Learning[] {
  const learnings: Learning[] = [];

  // Split into sentences for more granular analysis
  const sentences = thinkingBlock.split(/[.!?]+/).filter(s => s.trim().length > 20);

  for (const sentence of sentences) {
    for (const { pattern, type } of PERCEPTION_PATTERNS) {
      if (pattern.test(sentence)) {
        // Get surrounding context (the sentence and maybe a bit more)
        const content = sentence.trim();
        const preview = content.slice(0, 100) + (content.length > 100 ? '...' : '');

        learnings.push({
          type,
          content,
          preview,
          stored: false,
        });

        // Only match first pattern per sentence
        break;
      }
    }
  }

  return learnings;
}

// ============================================================================
// Learning Storage
// ============================================================================

/**
 * Store a learning via store_learning.py subprocess.
 */
async function storeLearning(
  learning: Learning,
  sessionId: string,
  projectDir: string
): Promise<boolean> {
  return new Promise((resolve) => {
    // Map our types to store_learning.py types
    const typeMap: Record<LearningType, string> = {
      REALIZATION: 'CODEBASE_PATTERN',
      CORRECTION: 'ERROR_FIX',
      INSIGHT: 'CODEBASE_PATTERN',
      DEBUGGING_APPROACH: 'WORKING_SOLUTION',
      WORKING_SOLUTION: 'WORKING_SOLUTION',
      FAILED_APPROACH: 'FAILED_APPROACH',
    };

    const storeScript = path.join(projectDir, 'scripts', 'core', 'store_learning.py');
    const opc = path.dirname(path.dirname(storeScript));

    if (!fs.existsSync(storeScript)) {
      resolve(false);
      return;
    }

    const args = [
      'run', 'python', storeScript,
      '--session-id', sessionId,
      '--type', typeMap[learning.type] || 'CODEBASE_PATTERN',
      '--content', learning.content,
      '--context', `auto-extracted from session thinking (${learning.type})`,
      '--tags', `auto-extracted,${learning.type.toLowerCase()}`,
      '--confidence', 'medium',
      '--json'
    ];

    const child = spawn('uv', args, {
      cwd: opc,
      stdio: ['ignore', 'pipe', 'pipe'],
      env: {
        ...process.env,
        PYTHONPATH: opc,
      }
    });

    let stdout = '';
    let stderr = '';

    child.stdout?.on('data', (data) => { stdout += data; });
    child.stderr?.on('data', (data) => { stderr += data; });

    child.on('close', (code) => {
      if (code === 0) {
        try {
          const result = JSON.parse(stdout.trim());
          resolve(result.success === true);
        } catch {
          resolve(false);
        }
      } else {
        resolve(false);
      }
    });

    child.on('error', () => {
      resolve(false);
    });

    // Timeout after 30 seconds
    setTimeout(() => {
      child.kill();
      resolve(false);
    }, 30000);
  });
}

// ============================================================================
// Main
// ============================================================================

async function main() {
  const args = process.argv.slice(2);

  if (args.length < 3) {
    console.error('Usage: node background-learning-extractor.mjs <transcript_path> <session_id> <project_dir>');
    process.exit(1);
  }

  const [transcriptPath, sessionId, projectDir] = args;

  const result: ExtractionResult = {
    timestamp: new Date().toISOString(),
    session_id: sessionId,
    learnings: [],
    error: null,
  };

  try {
    // Extract thinking blocks from transcript
    const thinkingBlocks = extractThinkingBlocks(transcriptPath);

    if (thinkingBlocks.length === 0) {
      result.error = 'No thinking blocks found in transcript';
    } else {
      // Extract learnings from all thinking blocks
      const allLearnings: Learning[] = [];
      for (const block of thinkingBlocks) {
        const learnings = classifyAndExtract(block);
        allLearnings.push(...learnings);
      }

      // Deduplicate by content (keep first occurrence)
      const seen = new Set<string>();
      const uniqueLearnings = allLearnings.filter(l => {
        const key = l.content.toLowerCase().trim();
        if (seen.has(key)) return false;
        seen.add(key);
        return true;
      });

      // Limit to top 10 learnings to avoid spam
      const topLearnings = uniqueLearnings.slice(0, 10);

      // Store each learning
      for (const learning of topLearnings) {
        try {
          learning.stored = await storeLearning(learning, sessionId, projectDir);
        } catch (err) {
          learning.error = err instanceof Error ? err.message : String(err);
        }
        result.learnings.push(learning);
      }
    }
  } catch (err) {
    result.error = err instanceof Error ? err.message : String(err);
  }

  // Write results to cache file
  const cacheDir = path.join(projectDir, '.claude', 'cache');
  if (!fs.existsSync(cacheDir)) {
    fs.mkdirSync(cacheDir, { recursive: true });
  }

  const resultFile = path.join(cacheDir, 'last-extraction.json');
  fs.writeFileSync(resultFile, JSON.stringify(result, null, 2));

  // Clean up lock file
  const lockFile = path.join(process.env.HOME || '', '.claude', 'learning-extractor.lock');
  if (fs.existsSync(lockFile)) {
    try {
      fs.unlinkSync(lockFile);
    } catch {
      // Ignore lock cleanup errors
    }
  }

  // Exit with appropriate code
  const storedCount = result.learnings.filter(l => l.stored).length;
  console.log(`Extracted ${result.learnings.length} learnings, stored ${storedCount}`);
  process.exit(result.error ? 1 : 0);
}

main().catch((err) => {
  console.error('Background learning extractor failed:', err);
  process.exit(1);
});
