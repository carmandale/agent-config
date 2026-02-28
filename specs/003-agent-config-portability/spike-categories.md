---
shaping: true
---

# Spike: Category Taxonomy

## Key Finding

Categories are **purely for human organization**. Agent discovery works via
top-level symlinks (`skills/bird -> personal/bird`). Restructuring categories
has zero risk to agent discovery as long as top-level symlinks are maintained.

This means the category question is: "How does a human browse skills?" — not
"How does an agent find skills?"

## S1-Q1: What natural clusters emerge?

Analyzing all 275 skills by function (what they DO), five clear clusters
emerge:

### Cluster 1: Tools (~60 skills)
Wraps an external CLI, API, or service. You need that tool installed.

Examples: github, supabase, surf, cupertino, bird, brave-search, ghostty,
gcloud, vercel, wrangler, bv, cass, oracle, ralph-tui, playwright, pdf

Includes: current tools/ (30), most of personal/ (bird, homeassistant,
slack, sag, etc.), some uncategorized (cloudflare-deploy, railway, etc.),
some cc3 (firecrawl-scrape, morph-apply, perplexity-search, etc.)

### Cluster 2: Review (~25 skills)
Analyzes code or content and provides assessment/feedback.

Examples: kieran-python-reviewer, kieran-rails-reviewer,
kieran-typescript-reviewer, dhh-rails-reviewer, security-sentinel,
performance-oracle, code-simplicity-reviewer, architecture-strategist,
data-integrity-guardian, lint, schema-drift-detector

Includes: mostly uncategorized (21), some compound (dhh-rails-style,
every-style-editor, andrew-kane-gem-writer)

### Cluster 3: Workflows (~45 skills)
Orchestrates multi-step development processes.

Examples: debug, fix, test, commit, review, research, refactor, deploy,
implement-plan, tdd, onboard, release, resume-handoff, explore

Includes: most cc3 action skills, uncategorized workflows-* (5),
compound brainstorming/git-worktree, some uncategorized (deepen-plan,
feature-video, design-iterator)

### Cluster 4: Meta (~55 skills)
Agent behavior rules, constraints, architecture patterns, and skill system
management. Small focused files that define HOW agents should behave.

Examples: no-polling-agents, agent-context-isolation, hooks, git-commits,
idempotent-redundancy, parallel-agents, observe-before-editing,
skill-developer, recall, remember, braintrust-analyze

Includes: most of the remaining cc3 skills (rules, patterns, architecture
docs), agentica-* (7), search-hierarchy/router/tools, tldr-* (4)

### Cluster 5: Domain (~90 skills, splits into sub-groups)
Technology/framework-specific knowledge.

Sub-groups:
- **swift/** (10): swift-concurrency-expert, swiftui-*, xcode-26
- **compound/** (19): vendored set from compound plugin
- **ralph/** (12): code-assist, pdd, eval, creating-hat-collections, etc.
- **notion/** (4): notion-knowledge-capture, notion-meeting-intelligence, etc.
- **gitnexus/** (4): gitnexus-debugging, exploring, impact-analysis, refactoring
- **shaping/** (3): breadboarding, shaping, napkin
- **math/** (7): math-help, math-router, math-unified, pint-compute, etc.
- **other domain** (~30): remotion, openai-docs, dspy-ruby, etc.

## S1-Q2: Do existing categories map to meaningful intent?

| Category | Origin-based or Function-based? | Keep? |
|----------|---------------------------------|-------|
| cc3 | Origin (Claude Code v3 era) | No — 104 skills in one bucket, no decision rule |
| personal | Origin (user-created) | No — bird and homeassistant are tools, not "personal" |
| tools | Function (wraps CLI) | Yes — clear intent, clear decision rule |
| compound | Origin (plugin) | Yes — coherent vendored set, keep as-is per user decision |
| ralph-o | Origin + domain | Rename to ralph/ — coherent domain set |
| swift | Domain | Yes — coherent domain set |
| setup | Origin | No — 0 skills, remove |

## S1-Q3: Decision rule for placement

Given a new skill, ask in order:

1. **Does it wrap a specific external CLI, API, or service?** → `tools/`
2. **Does it analyze/review code or content and provide feedback?** → `review/`
3. **Does it orchestrate a multi-step dev process?** → `workflows/`
4. **Is it specific to a named domain sub-group?** → `domain/<sub>/` (swift/, compound/, ralph/, etc.)
5. **Does it define agent behavior rules or manage the skill system?** → `meta/`

Tiebreaker: prefer the category that describes what the skill DOES over what
it KNOWS.

## S1-Q4: Right number of categories

**Proposed: 5 functional categories + domain sub-groups**

| Category | Decision rule | Approx count |
|----------|---------------|:------------:|
| **tools/** | Wraps external CLI/API/service | ~60 |
| **review/** | Analyzes/reviews code or content | ~25 |
| **workflows/** | Orchestrates multi-step dev processes | ~45 |
| **meta/** | Agent behavior rules, patterns, skill system | ~55 |
| **domain/** | Technology-specific knowledge | ~90 |

domain/ is large but naturally splits into named sub-groups:

| Sub-group | Contents | Count |
|-----------|----------|:-----:|
| domain/swift/ | Apple/Swift platform skills | ~10 |
| domain/compound/ | Vendored compound plugin set | ~19 |
| domain/ralph/ | Ralph orchestrator skills | ~12 |
| domain/notion/ | Notion integration skills | ~4 |
| domain/gitnexus/ | GitNexus code graph skills | ~4 |
| domain/shaping/ | Shaping methodology skills | ~3 |
| domain/math/ | Math/computation skills | ~7 |
| domain/other/ | Remaining domain skills | ~30 |

### Why not fewer categories?

3 categories (tools, workflows, everything-else) would recreate the cc3
problem — "everything-else" becomes a catch-all.

### Why not more?

7+ top-level categories adds ambiguity about where things go. The decision
rule should have at most 5 steps.

## Draft Mapping: 60 Uncategorized Skills

| Skill | Proposed category |
|-------|-------------------|
| agent-native-reviewer | review/ |
| aligner | tools/ |
| ankane-readme-writer | review/ |
| architecture-strategist | review/ |
| best-practices-researcher | workflows/ |
| bug-reproduction-validator | review/ |
| cloudflare-deploy | tools/ |
| code-simplicity-reviewer | review/ |
| data-integrity-guardian | review/ |
| data-migration-expert | review/ |
| deepen-plan | workflows/ |
| deployment-verification-agent | review/ |
| design-implementation-reviewer | review/ |
| design-iterator | workflows/ |
| dhh-rails-reviewer | review/ |
| document-review | review/ |
| every-style-editor-2 | review/ |
| feature-video | workflows/ |
| figma-design-sync | workflows/ |
| framework-docs-researcher | workflows/ |
| git-history-analyzer | workflows/ |
| gitnexus-debugging | domain/gitnexus/ |
| gitnexus-exploring | domain/gitnexus/ |
| gitnexus-impact-analysis | domain/gitnexus/ |
| gitnexus-refactoring | domain/gitnexus/ |
| imagegen | tools/ |
| interactive-shell | tools/ |
| julik-frontend-races-reviewer | review/ |
| kieran-python-reviewer | review/ |
| kieran-rails-reviewer | review/ |
| kieran-typescript-reviewer | review/ |
| learnings-researcher | workflows/ |
| lint | tools/ |
| llm-council | tools/ |
| notion-knowledge-capture | domain/notion/ |
| notion-meeting-intelligence | domain/notion/ |
| notion-research-documentation | domain/notion/ |
| notion-spec-to-implementation | domain/notion/ |
| openai-docs | tools/ |
| orchestrating-swarms | meta/ |
| pattern-recognition-specialist | review/ |
| pdf | tools/ |
| performance-oracle | review/ |
| playwright | tools/ |
| pr-comment-resolver | review/ |
| railway | tools/ |
| rp-cli-investigate | tools/ |
| schema-drift-detector | review/ |
| security-sentinel | review/ |
| spec-flow-analyzer | review/ |
| speech | tools/ |
| spreadsheet | tools/ |
| test-browser | workflows/ |
| transcribe | tools/ |
| vercel-deploy | tools/ |
| visual-explainer | workflows/ |
| workflows-brainstorm | workflows/ |
| workflows-compound | workflows/ |
| workflows-plan | workflows/ |
| workflows-review | workflows/ |
| workflows-work | workflows/ |

## Acceptance

Spike is complete. We can describe:
- 5 proposed categories with a sequential decision rule
- domain/ sub-groups for coherent technology sets
- Draft mapping of all 60 stray skills
- Which existing categories to keep, rename, or dissolve
