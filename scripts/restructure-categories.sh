#!/usr/bin/env bash
#
# V4: Taxonomy Restructure — migrate skills from origin-based to functional categories
#
# Usage:
#   ./scripts/restructure-categories.sh --dry-run   # Preview changes
#   ./scripts/restructure-categories.sh              # Execute migration
#
set -euo pipefail

cd "$(git rev-parse --show-toplevel)"

DRY=false
[[ "${1:-}" == "--dry-run" ]] && DRY=true

# Counters
MOVED=0
SKIPPED=0
ERRORS=0

log()  { echo "  $*"; }
info() { echo "→ $*"; }
warn() { echo "⚠ $*"; }
err()  { echo "✗ $*" >&2; ERRORS=$((ERRORS + 1)); }

do_mkdir() {
  if $DRY; then
    log "[dry-run] mkdir -p $1"
  else
    mkdir -p "$1"
  fi
}

do_git_mv() {
  local src="$1" dst="$2"
  if [[ ! -e "$src" ]]; then
    warn "Source missing, skip: $src"
    SKIPPED=$((SKIPPED + 1))
    return
  fi
  if [[ -e "$dst" ]]; then
    warn "Destination exists, skip: $src → $dst"
    SKIPPED=$((SKIPPED + 1))
    return
  fi
  if $DRY; then
    log "[dry-run] git mv $src $dst"
  else
    git mv "$src" "$dst"
  fi
  MOVED=$((MOVED + 1))
}

do_rm_symlink() {
  local link="$1"
  if [[ ! -L "$link" ]]; then return; fi
  if $DRY; then
    log "[dry-run] rm $link"
  else
    rm "$link"
    git add "$link" 2>/dev/null || true
  fi
}

do_create_symlink() {
  local target="$1" link="$2"
  if $DRY; then
    log "[dry-run] ln -s $target $link"
  else
    ln -s "$target" "$link"
    git add "$link"
  fi
}

# ─────────────────────────────────────────────────────────────
# CLASSIFICATION MAPS
# ─────────────────────────────────────────────────────────────

# cc3/ → tools/
CC3_TOOLS=(
  ast-grep-find braintrust-analyze firecrawl-scrape github-search
  loogle-search morph-apply morph-search nia-docs perplexity-search
  pint-compute qlty-check repoprompt shapely-compute
  tldr-code tldr-deep tldr-overview tldr-router
)

# cc3/ → workflows/
CC3_WORKFLOWS=(
  commit debug debug-hooks describe-pr discovery-interview explore
  fix help implement-plan implement-plan-micro implement-task
  mcp-chaining migrate mot onboard plan-agent premortem recall
  recall-reasoning refactor reference-sdk release remember
  repo-research-analyst research research-agent research-external
  resume-handoff review security skill-upgrader system-overview
  tdd test tour validate-agent workflow-router
)

# cc3/ → meta/
CC3_META=(
  _sandbox agent-context-isolation agent-orchestration agentic-workflow
  async-repl-protocol background-agent-pings braintrust-tracing
  cli-reference complete-skill completion-check compound-learnings
  continuity-ledger environment-triage explicit-identity git-commits
  graceful-degradation hook-developer hooks idempotent-redundancy
  index-at-creation llm-tuning-patterns mcp-scripts modular-code
  no-polling-agents no-task-output observe-before-editing opc-architecture
  parallel-agent-contracts parallel-agents qlty-during-development
  router-first-architecture search-hierarchy search-router search-tools
  skill-developer skill-development slash-commands sub-agents wiring
)

# cc3/ → domain/agentica/
CC3_DOMAIN_AGENTICA=(
  agentica-claude-proxy agentica-infrastructure agentica-prompts
  agentica-sdk agentica-server agentica-spawn
)

# cc3/ → domain/math/
CC3_DOMAIN_MATH=(math math-help math-router math-unified prove)

# personal/ → tools/
PERSONAL_TOOLS=(
  agent-browser apple-mail-search bird brave-search homeassistant
  nano-banana-pro peekaboo sag second-brain slack video-transcript-downloader
)

# personal/ → workflows/
PERSONAL_WORKFLOWS=(app-store-changelog synthesize-ledgers)

# personal/ → domain/ralph/
PERSONAL_DOMAIN_RALPH=(ralph-tui-create-beads ralph-tui-create-json ralph-tui-prd)

# personal/ → meta/
PERSONAL_META=(mission-control self-improving-agent superdesign)

# Uncategorized real dirs → tools/
UNCATEGORIZED_TOOLS=(
  aligner cloudflare-deploy find-skills imagegen interactive-shell
  lint llm-council openai-docs pdf playwright railway rp-cli-investigate
  speech spreadsheet surf transcribe vercel-deploy
)

# Uncategorized real dirs → review/
UNCATEGORIZED_REVIEW=(
  agent-native-reviewer ankane-readme-writer architecture-strategist
  bug-reproduction-validator code-simplicity-reviewer data-integrity-guardian
  data-migration-expert deployment-verification-agent
  design-implementation-reviewer dhh-rails-reviewer every-style-editor-2
  julik-frontend-races-reviewer kieran-python-reviewer kieran-rails-reviewer
  kieran-typescript-reviewer pattern-recognition-specialist performance-oracle
  pr-comment-resolver schema-drift-detector security-sentinel spec-flow-analyzer
)

# Uncategorized real dirs → workflows/
UNCATEGORIZED_WORKFLOWS=(
  best-practices-researcher deepen-plan design-iterator feature-video
  figma-design-sync framework-docs-researcher git-history-analyzer
  learnings-researcher test-browser visual-explainer
  workflows-brainstorm workflows-compound workflows-plan
  workflows-review workflows-work
)

# Uncategorized real dirs → domain/
UNCATEGORIZED_DOMAIN_GITNEXUS=(
  gitnexus-debugging gitnexus-exploring gitnexus-impact-analysis gitnexus-refactoring
)
UNCATEGORIZED_DOMAIN_NOTION=(
  notion-knowledge-capture notion-meeting-intelligence
  notion-research-documentation notion-spec-to-implementation
)
UNCATEGORIZED_DOMAIN_SWIFT=(swiftui-expert-skill)
UNCATEGORIZED_DOMAIN_OTHER=(remotion-best-practices)

# ─────────────────────────────────────────────────────────────
# PRE-FLIGHT CHECK
# ─────────────────────────────────────────────────────────────

info "Pre-flight: ensuring submodules are initialized"
if [[ -f .gitmodules ]]; then
  if ! git submodule update --init --recursive 2>/dev/null; then
    warn "Submodule init had warnings (non-fatal) — continuing"
  fi
fi

info "Pre-flight: counting skills before migration"
BEFORE_COUNT=$(find skills -name "SKILL.md" -o -name "skill.md" | wc -l | tr -d ' ')
info "Found $BEFORE_COUNT skill files before migration"

# ─────────────────────────────────────────────────────────────
# PHASE 1: Remove all top-level symlinks
# ─────────────────────────────────────────────────────────────

info "Phase 1: Removing all top-level symlinks (will regenerate later)"
SYMLINK_COUNT=0
while IFS= read -r link; do
  do_rm_symlink "$link"
  SYMLINK_COUNT=$((SYMLINK_COUNT + 1))
done < <(find skills -maxdepth 1 -type l)
info "Removed $SYMLINK_COUNT symlinks"

# ─────────────────────────────────────────────────────────────
# PHASE 2: Create new category directories
# ─────────────────────────────────────────────────────────────

info "Phase 2: Creating new category directories"
for dir in \
  skills/review \
  skills/workflows \
  skills/meta \
  skills/domain/agentica \
  skills/domain/compound \
  skills/domain/gitnexus \
  skills/domain/math \
  skills/domain/notion \
  skills/domain/other \
  skills/domain/ralph \
  skills/domain/swift \
; do
  do_mkdir "$dir"
done

# ─────────────────────────────────────────────────────────────
# PHASE 3: Move skills from old categories
# ─────────────────────────────────────────────────────────────

info "Phase 3a: Moving cc3/ skills"

for s in "${CC3_TOOLS[@]}"; do
  do_git_mv "skills/cc3/$s" "skills/tools/$s"
done
for s in "${CC3_WORKFLOWS[@]}"; do
  do_git_mv "skills/cc3/$s" "skills/workflows/$s"
done
for s in "${CC3_META[@]}"; do
  do_git_mv "skills/cc3/$s" "skills/meta/$s"
done
for s in "${CC3_DOMAIN_AGENTICA[@]}"; do
  do_git_mv "skills/cc3/$s" "skills/domain/agentica/$s"
done
for s in "${CC3_DOMAIN_MATH[@]}"; do
  do_git_mv "skills/cc3/$s" "skills/domain/math/$s"
done

info "Phase 3b: Moving personal/ skills"

for s in "${PERSONAL_TOOLS[@]}"; do
  do_git_mv "skills/personal/$s" "skills/tools/$s"
done
for s in "${PERSONAL_WORKFLOWS[@]}"; do
  do_git_mv "skills/personal/$s" "skills/workflows/$s"
done
for s in "${PERSONAL_DOMAIN_RALPH[@]}"; do
  do_git_mv "skills/personal/$s" "skills/domain/ralph/$s"
done
for s in "${PERSONAL_META[@]}"; do
  do_git_mv "skills/personal/$s" "skills/meta/$s"
done

info "Phase 3c: Moving ralph-o/ → domain/ralph/"

for s in $(ls skills/ralph-o/ 2>/dev/null); do
  [[ -d "skills/ralph-o/$s" ]] && do_git_mv "skills/ralph-o/$s" "skills/domain/ralph/$s"
done

info "Phase 3d: Moving compound/ → domain/compound/"

# Move the whole compound dir contents into domain/compound/
for s in $(ls skills/compound/ 2>/dev/null); do
  [[ -d "skills/compound/$s" ]] && do_git_mv "skills/compound/$s" "skills/domain/compound/$s"
done

info "Phase 3e: Moving swift/ → domain/swift/"

for s in $(ls skills/swift/ 2>/dev/null); do
  [[ -d "skills/swift/$s" ]] && do_git_mv "skills/swift/$s" "skills/domain/swift/$s"
done

# ─────────────────────────────────────────────────────────────
# PHASE 4: Move uncategorized real dirs
# ─────────────────────────────────────────────────────────────

info "Phase 4: Moving uncategorized real dirs"

for s in "${UNCATEGORIZED_TOOLS[@]}"; do
  do_git_mv "skills/$s" "skills/tools/$s"
done
for s in "${UNCATEGORIZED_REVIEW[@]}"; do
  do_git_mv "skills/$s" "skills/review/$s"
done
for s in "${UNCATEGORIZED_WORKFLOWS[@]}"; do
  do_git_mv "skills/$s" "skills/workflows/$s"
done
for s in "${UNCATEGORIZED_DOMAIN_GITNEXUS[@]}"; do
  do_git_mv "skills/$s" "skills/domain/gitnexus/$s"
done
for s in "${UNCATEGORIZED_DOMAIN_NOTION[@]}"; do
  do_git_mv "skills/$s" "skills/domain/notion/$s"
done
for s in "${UNCATEGORIZED_DOMAIN_SWIFT[@]}"; do
  do_git_mv "skills/$s" "skills/domain/swift/$s"
done
for s in "${UNCATEGORIZED_DOMAIN_OTHER[@]}"; do
  do_git_mv "skills/$s" "skills/domain/other/$s"
done

# ─────────────────────────────────────────────────────────────
# PHASE 5: Clean up empty old category dirs
# ─────────────────────────────────────────────────────────────

info "Phase 5: Cleaning up empty old category directories"

for old_dir in skills/cc3 skills/personal skills/ralph-o skills/compound skills/swift; do
  if [[ -d "$old_dir" ]]; then
    remaining=$(find "$old_dir" -mindepth 1 -not -name '.gitkeep' 2>/dev/null | head -1)
    if [[ -z "$remaining" ]]; then
      if $DRY; then
        log "[dry-run] rmdir $old_dir"
      else
        rm -rf "$old_dir"
        git add "$old_dir" 2>/dev/null || true
      fi
      log "Removed empty: $old_dir"
    else
      warn "Not empty, keeping: $old_dir"
      if ! $DRY; then
        find "$old_dir" -mindepth 1 -maxdepth 1 | head -5
      fi
    fi
  fi
done

# ─────────────────────────────────────────────────────────────
# PHASE 6: Regenerate discovery symlinks
# ─────────────────────────────────────────────────────────────

info "Phase 6: Regenerating top-level discovery symlinks"

SYMLINKS_CREATED=0
SYMLINK_COLLISIONS=0

# Track which names have been claimed
declare -A CLAIMED

# Process categories in priority order (highest priority last, so they win)
# Priority: domain/ < meta/ < workflows/ < review/ < tools/
CATEGORY_ORDER=(
  "domain/other"
  "domain/math"
  "domain/agentica"
  "domain/gitnexus"
  "domain/notion"
  "domain/ralph"
  "domain/compound"
  "domain/swift"
  "meta"
  "workflows"
  "review"
  "tools"
)

for category in "${CATEGORY_ORDER[@]}"; do
  cat_path="skills/$category"
  [[ -d "$cat_path" ]] || continue

  for skill_dir in "$cat_path"/*/; do
    [[ -d "$skill_dir" ]] || continue
    skill_name=$(basename "$skill_dir")

    # Skip internal dirs
    [[ "$skill_name" == _* ]] && continue

    link="skills/$skill_name"

    if [[ -n "${CLAIMED[$skill_name]:-}" ]]; then
      # Higher priority category claims this name — overwrite
      if $DRY; then
        log "[dry-run] overwrite symlink: $skill_name (${CLAIMED[$skill_name]} → $category/$skill_name)"
      else
        rm -f "$link"
      fi
      SYMLINK_COLLISIONS=$((SYMLINK_COLLISIONS + 1))
    fi

    do_create_symlink "$category/$skill_name" "$link"
    CLAIMED[$skill_name]="$category"
    SYMLINKS_CREATED=$((SYMLINKS_CREATED + 1))
  done
done

# Handle shaping submodule skills (special paths)
# breadboarding, breadboard-reflection, shaping are inside shaping-skills submodule
for sub_skill in breadboarding breadboard-reflection shaping; do
  sub_path="domain/shaping/shaping-skills/$sub_skill"
  if [[ -d "skills/$sub_path" ]]; then
    link="skills/$sub_skill"
    [[ -L "$link" ]] && do_rm_symlink "$link"
    do_create_symlink "$sub_path" "$link"
    CLAIMED[$sub_skill]="domain/shaping"
    SYMLINKS_CREATED=$((SYMLINKS_CREATED + 1))
  fi
done

# napkin is directly in shaping submodule
if [[ -d "skills/domain/shaping/napkin" ]]; then
  link="skills/napkin"
  [[ -L "$link" ]] && do_rm_symlink "$link"
  do_create_symlink "domain/shaping/napkin" "$link"
  CLAIMED[napkin]="domain/shaping"
  SYMLINKS_CREATED=$((SYMLINKS_CREATED + 1))
fi

# tools/last30days submodule
if [[ -d "skills/tools/last30days" ]]; then
  link="skills/last30days"
  [[ -L "$link" ]] && do_rm_symlink "$link"
  do_create_symlink "tools/last30days" "$link"
  CLAIMED[last30days]="tools"
  SYMLINKS_CREATED=$((SYMLINKS_CREATED + 1))
fi

info "Created $SYMLINKS_CREATED symlinks ($SYMLINK_COLLISIONS name collisions resolved by priority)"

# ─────────────────────────────────────────────────────────────
# PHASE 7: Verification
# ─────────────────────────────────────────────────────────────

info "Phase 7: Verification"

if $DRY; then
  info "[dry-run] Skipping verification — no changes were made"
  echo ""
  info "Summary (dry-run):"
  info "  Would move: $MOVED skills"
  info "  Would skip: $SKIPPED skills"
  info "  Would create: $SYMLINKS_CREATED symlinks"
  info "  Errors: $ERRORS"
  exit 0
fi

# Count skills after
AFTER_COUNT=$(find skills -name "SKILL.md" -o -name "skill.md" | wc -l | tr -d ' ')

# Check for broken symlinks
BROKEN=$(find skills -maxdepth 1 -type l ! -exec test -e {} \; -print 2>/dev/null | wc -l | tr -d ' ')

# Check remaining top-level real dirs (should only be category dirs + .system)
NON_CATEGORY_DIRS=$(find skills -maxdepth 1 -type d -not -name skills \
  -not -name tools -not -name review -not -name workflows \
  -not -name meta -not -name domain -not -name '.system' \
  2>/dev/null | wc -l | tr -d ' ')

echo ""
info "═══════════════════════════════════"
info "Migration complete!"
info "═══════════════════════════════════"
info "  Skills before: $BEFORE_COUNT"
info "  Skills after:  $AFTER_COUNT"
info "  Moved:         $MOVED"
info "  Skipped:       $SKIPPED"
info "  Symlinks:      $SYMLINKS_CREATED"
info "  Broken links:  $BROKEN"
info "  Stray dirs:    $NON_CATEGORY_DIRS"
info "  Errors:        $ERRORS"

VERIFY_FAIL=0
if [[ "$BEFORE_COUNT" != "$AFTER_COUNT" ]]; then
  warn "SKILL COUNT CHANGED! Was $BEFORE_COUNT, now $AFTER_COUNT — investigate!"
  VERIFY_FAIL=1
fi
if [[ "$BROKEN" -gt 0 ]]; then
  warn "Broken symlinks found:"
  find skills -maxdepth 1 -type l ! -exec test -e {} \; -print
  VERIFY_FAIL=1
fi
if [[ "$NON_CATEGORY_DIRS" -gt 0 ]]; then
  warn "Stray top-level directories (not categories):"
  find skills -maxdepth 1 -type d -not -name skills \
    -not -name tools -not -name review -not -name workflows \
    -not -name meta -not -name domain -not -name '.system'
  VERIFY_FAIL=1
fi

exit "$VERIFY_FAIL"
