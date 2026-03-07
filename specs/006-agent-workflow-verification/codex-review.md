1. **High: R3 (“works across all agents via symlinks”) is not implementation-verifiable in the plan.**  
Evidence: requirement in [claude-plan-fa08dd63.md:22](/tmp/claude-plan-fa08dd63.md:22), acceptance in [claude-plan-fa08dd63.md:41](/tmp/claude-plan-fa08dd63.md:41), but no verification step in plan changes [claude-plan-fa08dd63.md:61](/tmp/claude-plan-fa08dd63.md:61).  
Action: add explicit verification tasks after edits: confirm command visibility via `~/.claude/commands`, `~/.pi/agent/prompts`, `~/.codex/prompts`, `~/.gemini/...` (or verify shared symlink target once + each mountpoint exists).

2. **High: R7 (“agents follow skill protocols as written”) is not addressed or validated.**  
Evidence: requirement in [claude-plan-fa08dd63.md:26](/tmp/claude-plan-fa08dd63.md:26); no corresponding plan item in [claude-plan-fa08dd63.md:61](/tmp/claude-plan-fa08dd63.md:61).  
Action: either (a) add concrete command text updates that enforce/point to skill protocol usage, or (b) explicitly mark R7 as already satisfied with file-level proof and a verification check.

3. **Medium: R4 enforcement is indirect and may remain non-operational.**  
Evidence: requirement in [claude-plan-fa08dd63.md:23](/tmp/claude-plan-fa08dd63.md:23); plan only adds markers to prompt-craft guidance [claude-plan-fa08dd63.md:74](/tmp/claude-plan-fa08dd63.md:74) rather than enforcing `/shape` output contract directly.  
Risk: docs updated but command behavior unchanged.  
Action: add a `/shape` prompt line requiring two distinct named perspectives in `shaping-transcript.md` and a verification check.

4. **Medium: R8 (“individually usable”) could be weakened by `/sweep` wording.**  
Evidence: requirement [claude-plan-fa08dd63.md:27](/tmp/claude-plan-fa08dd63.md:27), suggested text in [claude-plan-fa08dd63.md:68](/tmp/claude-plan-fa08dd63.md:68).  
Risk: users may read `/codex-review -> /implement` as mandatory pipeline.  
Action: phrase as optional guidance (“typical next step”) and preserve direct-use paths.

5. **Low: Security/privacy guidance is missing for richer transcript markers.**  
Evidence: marker expansion in [claude-plan-fa08dd63.md:78](/tmp/claude-plan-fa08dd63.md:78).  
Risk: transcripts may include sensitive prompt/context details if shared externally.  
Action: add a short redaction rule in prompt-craft for secrets/tokens/private paths.

6. **Low: Plan lacks an explicit requirement-to-change trace table.**  
Evidence: requirements listed [claude-plan-fa08dd63.md:16](/tmp/claude-plan-fa08dd63.md:16), but coverage is implicit.  
Action: add a small matrix (`R0..R10 -> change #/verification step`) to prevent accidental misses.

**Alternative (simpler and more robust):**  
Add lightweight frontmatter metadata (`next_commands`, `artifacts`, `terminal`) to each command and have `/help-workflow` render from that metadata. This avoids drift between command docs and discoverability docs over time.

VERDICT: REVISE