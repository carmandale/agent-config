# Codex Plan Review: 012-pi-extension-collision

**Model**: gpt-5.3-codex
**Rounds**: 2
**Final Verdict**: APPROVED

---

## Round 1 — VERDICT: REVISE

**Findings (Ordered By Severity)**
1. **High: Plan dropped a must-have requirement from shaping (`R4` skills coverage).**  
   Shaping requires guard coverage for both extensions and skills ([`/tmp/claude-plan-58f8c8d4.md:114`](\/tmp\/claude-plan-58f8c8d4.md:114), [`/tmp/claude-plan-58f8c8d4.md:172`](\/tmp\/claude-plan-58f8c8d4.md:172), [`/tmp/claude-plan-58f8c8d4.md:183`](\/tmp\/claude-plan-58f8c8d4.md:183)), but the plan explicitly cuts C3 and remaps R4 to symlink integrity ([`/tmp/claude-plan-58f8c8d4.md:256`](\/tmp\/claude-plan-58f8c8d4.md:256), [`/tmp/claude-plan-58f8c8d4.md:327`](\/tmp\/claude-plan-58f8c8d4.md:327)).  
   Existing symlink checks in bootstrap only verify link targets, not skill-name collisions ([`/Users/dalecarman/.agent-config/scripts/bootstrap.sh:197`](\/Users\/dalecarman\/.agent-config\/scripts\/bootstrap.sh:197)-[`211`](\/Users\/dalecarman\/.agent-config\/scripts\/bootstrap.sh:211)).  
   **Action:** Restore an explicit skills collision check (or formally revise spec/shaping scope).

2. **High: Durability goal is only “detective,” not “preventive.”**  
   Spec outcome says the fix should survive routine operations ([`/tmp/claude-plan-58f8c8d4.md:59`](\/tmp\/claude-plan-58f8c8d4.md:59)); plan C2 is warning-only with known blind spots ([`/tmp/claude-plan-58f8c8d4.md:293`](\/tmp\/claude-plan-58f8c8d4.md:293)-[`300`](\/tmp\/claude-plan-58f8c8d4.md:300)).  
   **Action:** Add automatic remediation path (or enforced check in setup/install flow), not only warning text.

3. **Medium: Mini scope changed without verifiable evidence.**  
   Selected shape says remove stale copy on laptop + Mini ([`/tmp/claude-plan-58f8c8d4.md:181`](\/tmp\/claude-plan-58f8c8d4.md:181)), but implementation changes this to laptop-only ([`/tmp/claude-plan-58f8c8d4.md:261`](\/tmp\/claude-plan-58f8c8d4.md:261), [`267`](\/tmp\/claude-plan-58f8c8d4.md:267)).  
   Source context only shows laptop extension listing ([`/tmp/claude-plan-58f8c8d4.md:970`](\/tmp\/claude-plan-58f8c8d4.md:970)); no Mini evidence is provided.  
   **Action:** Add explicit Mini verification commands/output or keep Mini remediation in scope.

4. **Medium: Backup-cleanup claim is incorrect as written.**  
   Plan claims all 25 backups are “well past threshold” for `-mtime +7` ([`/tmp/claude-plan-58f8c8d4.md:310`](\/tmp\/claude-plan-58f8c8d4.md:310)), but source listing includes many files dated March 3 ([`/tmp/claude-plan-58f8c8d4.md:977`](\/tmp\/claude-plan-58f8c8d4.md:977)-[`1010`](\/tmp\/claude-plan-58f8c8d4.md:1010)), which are not reliably `>7 days` on March 10.  
   **Action:** Correct expectation (only oldest subset is pruned now) or adjust threshold logic.

5. **Medium: Security concern in cleanup step.**  
   Plan executes local `install.mjs` for removal ([`/tmp/claude-plan-58f8c8d4.md:264`](\/tmp\/claude-plan-58f8c8d4.md:264)); that script is executable code in the target directory ([`/Users/dalecarman/.pi/agent/extensions/pi-messenger/install.mjs:1`](\/Users\/dalecarman\/.pi\/agent\/extensions\/pi-messenger\/install.mjs:1)).  
   **Action:** Add trust note / integrity check, or use controlled directory removal with backup/trash fallback.

6. **Medium: Missing verification steps in plan.**  
   There is no explicit post-change proof step to re-run Pi and confirm collision warnings are gone; no parsing regression cases listed (spaces/scopes/path forms) despite known limits ([`/tmp/claude-plan-58f8c8d4.md:296`](\/tmp\/claude-plan-58f8c8d4.md:296)-[`300`](\/tmp\/claude-plan-58f8c8d4.md:300)).  
   **Action:** Add concrete verification matrix (startup logs + guard output + edge parsing cases).

---

**Adversarial Gate**
7. **3 riskiest assumptions and verification status**
1. *Assumption:* Duplicate loads are truly same tool/command identity collisions.  
   *Verified:* **Yes.** Both copies register `pi_messenger` and `messenger` ([`/Users/dalecarman/.pi/agent/extensions/pi-messenger/index.ts:336`](\/Users\/dalecarman\/.pi\/agent\/extensions\/pi-messenger\/index.ts:336)-[`337`](\/Users\/dalecarman\/.pi\/agent\/extensions\/pi-messenger\/index.ts:337), [`459`](\/Users\/dalecarman\/.pi\/agent\/extensions\/pi-messenger\/index.ts:459); [`.../dev/pi-messenger/index.ts:340`](\/Users\/dalecarman\/Groove Jones Dropbox\/Dale Carman\/Projects\/dev\/pi-messenger\/index.ts:340)-[`341`](\/Users\/dalecarman\/Groove Jones Dropbox\/Dale Carman\/Projects\/dev\/pi-messenger\/index.ts:341), [`464`](\/Users\/dalecarman\/Groove Jones Dropbox\/Dale Carman\/Projects\/dev\/pi-messenger\/index.ts:464)).

2. *Assumption:* Mini has no collision, so laptop-only remediation is enough.  
   *Verified:* **No (not directly verifiable from provided source context).** Plan asserts this ([`/tmp/claude-plan-58f8c8d4.md:267`](\/tmp\/claude-plan-58f8c8d4.md:267)) but the attached context only includes laptop directory state ([`/tmp/claude-plan-58f8c8d4.md:970`](\/tmp\/claude-plan-58f8c8d4.md:970)).

3. *Assumption:* `find ... -mtime +7 -delete` meaningfully clears the reported 25 stale backups now.  
   *Verified:* **No (disproven by timestamps in context).** Many backups are from March 3 ([`/tmp/claude-plan-58f8c8d4.md:977`](\/tmp\/claude-plan-58f8c8d4.md:977)-[`1010`](\/tmp\/claude-plan-58f8c8d4.md:1010)), so the plan’s “all well past threshold” statement ([`/tmp/claude-plan-58f8c8d4.md:310`](\/tmp\/claude-plan-58f8c8d4.md:310)) is not reliable.

8. **Likely first objection from a skeptical senior engineer**  
   “This is a partial warning-based patch that claims structural prevention, but it dropped skills coverage and doesn’t harden recurrence paths.”

9. **What this plan does NOT address for production-level robustness**  
1. Automated prevention/remediation in setup paths (not just warning output).  
2. Cross-machine evidence (Mini) in acceptance criteria.  
3. Regression tests for parser edge cases and discovery-path variants.  
4. Explicit rollback/safety procedure for destructive cleanup actions.

10. **Scope differences between spec and plan**  
1. **Dropped:** skills collision guard from selected shape C (C3 removed).  
2. **Dropped/narrowed:** laptop+Mini cleanup became laptop-only.  
3. **Expanded:** added bootstrap false-positive symlink correction (good addition, but different from original shaping intent).  
4. **Reframed:** R4 is treated as symlink integrity, not collision detection.

VERDICT: REVISE

---

## Round 2 — VERDICT: APPROVED

**Findings (Round 2)**
1. No blocking findings. All 6 prior findings are substantively addressed in the revised plan.
2. Finding 1 (R4 skills coverage): addressed by explicit two-vector skills guard in C3 ([/tmp/claude-plan-58f8c8d4.md:174](/tmp/claude-plan-58f8c8d4.md:174), [/tmp/claude-plan-58f8c8d4.md:178](/tmp/claude-plan-58f8c8d4.md:178), [/tmp/claude-plan-58f8c8d4.md:183](/tmp/claude-plan-58f8c8d4.md:183)).
3. Finding 2 (detective-only): addressed by preventive `install.sh` warning (C6) ([/tmp/claude-plan-58f8c8d4.md:208](/tmp/claude-plan-58f8c8d4.md:208), [/tmp/claude-plan-58f8c8d4.md:220](/tmp/claude-plan-58f8c8d4.md:220)).
4. Finding 3 (Mini evidence): addressed with explicit SSH check evidence ([/tmp/claude-plan-58f8c8d4.md:146](/tmp/claude-plan-58f8c8d4.md:146)).
5. Finding 4 (backup age math): corrected to `-mtime +5` with date math rationale ([/tmp/claude-plan-58f8c8d4.md:203](/tmp/claude-plan-58f8c8d4.md:203), [/tmp/claude-plan-58f8c8d4.md:206](/tmp/claude-plan-58f8c8d4.md:206)).
6. Finding 5 (security): switched from executing `install.mjs --remove` to `trash`/`mv ~/.Trash` ([/tmp/claude-plan-58f8c8d4.md:138](/tmp/claude-plan-58f8c8d4.md:138), [/tmp/claude-plan-58f8c8d4.md:144](/tmp/claude-plan-58f8c8d4.md:144)).
7. Finding 6 (verification): explicit 7-check matrix present ([/tmp/claude-plan-58f8c8d4.md:222](/tmp/claude-plan-58f8c8d4.md:222), [/tmp/claude-plan-58f8c8d4.md:233](/tmp/claude-plan-58f8c8d4.md:233)).

7. **Three riskiest assumptions + source verification**
1. Assumption: Pi should not use `~/.pi/agent/skills` symlink; it causes duplicate discovery.  
Verified: **Yes**. `install.sh` explicitly says not to create it ([install.sh:98](/Users/dalecarman/.agent-config/install.sh:98), [install.sh:183](/Users/dalecarman/.agent-config/install.sh:183)); current bootstrap check still incorrectly expects it ([bootstrap.sh:201](/Users/dalecarman/.agent-config/scripts/bootstrap.sh:201)).
2. Assumption: Current collision is from dual loading (settings package + extension dir).  
Verified: **Yes**. `settings.json` includes local `pi-messenger` package path ([settings.json:18](/Users/dalecarman/.pi/agent/settings.json:18), [settings.json:21](/Users/dalecarman/.pi/agent/settings.json:21)); installed extension copy exists with `pi-messenger` package metadata ([package.json:2](/Users/dalecarman/.pi/agent/extensions/pi-messenger/package.json:2), [package.json:3](/Users/dalecarman/.pi/agent/extensions/pi-messenger/package.json:3)).
3. Assumption: Basename matching of package entries is sufficient for durable collision detection.  
Verified: **Partially / not fully**. Plan documents this as a heuristic with known gaps ([/tmp/claude-plan-58f8c8d4.md:79](/tmp/claude-plan-58f8c8d4.md:79), [/tmp/claude-plan-58f8c8d4.md:85](/tmp/claude-plan-58f8c8d4.md:85), [/tmp/claude-plan-58f8c8d4.md:90](/tmp/claude-plan-58f8c8d4.md:90)); live settings include `npm:` specifiers where resolution details remain implementation-sensitive ([settings.json:19](/Users/dalecarman/.pi/agent/settings.json:19), [settings.json:20](/Users/dalecarman/.pi/agent/settings.json:20)).

8. **Likely first skeptical senior objection**  
“Why are we duplicating collision logic in both `bootstrap.sh` and `install.sh` (and even calling one ‘simplified’)? That can drift and create inconsistent warnings.”  
Evidence in plan: separate full check vs simplified install-time check ([/tmp/claude-plan-58f8c8d4.md:126](/tmp/claude-plan-58f8c8d4.md:126), [/tmp/claude-plan-58f8c8d4.md:133](/tmp/claude-plan-58f8c8d4.md:133)).

9. **What this plan does not address for production-hardening**
1. No automated regression test script in-repo for parser/guard behavior (only manual matrix).
2. No shared parser/helper to prevent drift between `bootstrap.sh` and `install.sh`.
3. No CI/pre-commit enforcement; checks depend on humans running scripts.
4. Mini evidence is command-level, not yet a repeatable artifact captured in repo logs.

10. **Scope differences vs spec**
1. Scope expands beyond spec R0-R3 into R4/R5 (skills-specific coverage + maintenance ergonomics) in the plan ([spec.md:60](/Users/dalecarman/.agent-config/specs/012-pi-extension-collision/spec.md:60), [/tmp/claude-plan-58f8c8d4.md:129](/tmp/claude-plan-58f8c8d4.md:129)).
2. Plan adds cleanup work (backup deletion) and false-positive symlink remediation, which are valuable but beyond the strict collision fix.
3. Plan adds preventive `install.sh` warning path, which is an intentional durability expansion over minimum spec wording.

**VERDICT: APPROVED**

