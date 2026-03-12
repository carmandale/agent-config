#!/usr/bin/env bash
#==============================================================================
# collision-check.sh - Detect Pi extension and skill collisions
#
# Sourced by both bootstrap.sh (detective) and install.sh (preventive).
# Single source of truth — no duplicated logic.
#
# Exports:
#   get_pi_package_names  - Parse settings.json packages → basenames
#   check_extension_collisions - Package names vs extensions/ dirs
#   check_skill_collisions     - Two vectors: package skills vs agent-config,
#                                direct copies in ~/.pi/agent/skills/
#
# Coverage limits (known blind spots):
#   - Catches: package whose basename matches an extensions/ dir name
#   - Does NOT catch: legacy extensions/ dirs that later get a packages entry
#     under a different name (e.g., extension "foo" + package "bar" that
#     registers the same tool)
#   - Does NOT catch: scoped npm packages where the installed dir name
#     differs from the package basename (e.g., npm:@scope/name installs
#     as "name" but dir might be "@scope-name")
#   - These are known blind spots; the guard is a regression catcher,
#     not comprehensive deduplication.
#==============================================================================

# Callers must define: log_ok, log_warn, log_err, log_info, DRIFT
# (bootstrap.sh and install.sh both define these before sourcing)

PI_SETTINGS="$HOME/.pi/agent/settings.json"
PI_EXTENSIONS="$HOME/.pi/agent/extensions"
PI_SKILLS="$HOME/.pi/agent/skills"
AGENT_CONFIG_SKILLS="${AGENT_CONFIG_SKILLS:-$HOME/.agent-config/skills}"

#==============================================================================
# get_pi_package_names - Parse settings.json packages array → one basename/line
#
# Input formats handled:
#   npm:name           → name
#   npm:name@version   → name
#   npm:@scope/name    → name
#   npm:@scope/name@v  → name
#   /absolute/path     → basename
#   ../../relative     → basename
#==============================================================================
get_pi_package_names() {
  if [[ ! -f "$PI_SETTINGS" ]]; then
    return 1
  fi

  if command -v python3 &>/dev/null; then
    python3 -c "
import json, os, re

with open(os.path.expanduser('$PI_SETTINGS')) as f:
    data = json.load(f)

for pkg in data.get('packages', []):
    if pkg.startswith('npm:'):
        # Strip 'npm:' prefix
        name = pkg[4:]
        # Strip version suffix (@x.y.z or @latest etc.)
        # But preserve @scope — only strip trailing @version
        if name.startswith('@'):
            # Scoped: @scope/name or @scope/name@version
            parts = name.split('/', 1)
            if len(parts) == 2:
                sub = parts[1]
                # Strip version from subpart
                at_idx = sub.find('@')
                if at_idx > 0:
                    sub = sub[:at_idx]
                print(sub)
            else:
                print(name.lstrip('@'))
        else:
            # Unscoped: name or name@version
            at_idx = name.find('@')
            if at_idx > 0:
                name = name[:at_idx]
            print(name)
    else:
        # Local path (absolute or relative)
        print(os.path.basename(os.path.normpath(pkg)))
" 2>/dev/null
  else
    # Fallback: grep/sed heuristic (reduced accuracy)
    log_warn "python3 not found — using grep/sed fallback for settings.json parsing"
    grep -o '"[^"]*"' "$PI_SETTINGS" \
      | tr -d '"' \
      | grep -E '^(npm:|/)' \
      | sed -E '
        s|^npm:@[^/]+/||;
        s|^npm:||;
        s|@[^@]*$||;
        s|.*/||;
      '
  fi
}

#==============================================================================
# check_extension_collisions - Compare package names vs extensions/ dirs
#==============================================================================
check_extension_collisions() {
  if [[ ! -f "$PI_SETTINGS" ]]; then
    log_info "Skipping extension collision check (no $PI_SETTINGS)"
    return
  fi

  if [[ ! -d "$PI_EXTENSIONS" ]]; then
    log_info "Skipping extension collision check (no $PI_EXTENSIONS)"
    return
  fi

  local pkg_names
  pkg_names=$(get_pi_package_names 2>/dev/null) || {
    log_info "Skipping extension collision check (cannot parse settings.json)"
    return
  }

  local collision_count=0

  # List extension directories (not bare .ts files)
  for ext_dir in "$PI_EXTENSIONS"/*/; do
    [[ -d "$ext_dir" ]] || continue
    local ext_name
    ext_name=$(basename "$ext_dir")

    # Check if this extension dir name matches any package basename
    if echo "$pkg_names" | grep -qx "$ext_name"; then
      collision_count=$((collision_count + 1))

      # Try to get versions for context
      local ext_version="unknown"
      if [[ -f "$ext_dir/package.json" ]] && command -v python3 &>/dev/null; then
        ext_version=$(python3 -c "
import json
with open('$ext_dir/package.json') as f:
    print(json.load(f).get('version', 'unknown'))
" 2>/dev/null || echo "unknown")
      fi

      # Find the matching package entry for its path
      local pkg_path
      pkg_path=$(python3 -c "
import json, os
with open(os.path.expanduser('$PI_SETTINGS')) as f:
    data = json.load(f)
for pkg in data.get('packages', []):
    name = pkg
    if pkg.startswith('npm:'):
        name = pkg[4:]
        if '@' in name and not name.startswith('@'):
            name = name[:name.index('@')]
        elif name.startswith('@'):
            parts = name.split('/', 1)
            if len(parts) == 2:
                sub = parts[1]
                at_idx = sub.find('@')
                if at_idx > 0:
                    sub = sub[:at_idx]
                name = sub
    else:
        name = os.path.basename(os.path.normpath(pkg))
    if name == '$ext_name':
        print(pkg)
        break
" 2>/dev/null || echo "?")

      log_err "COLLISION: $ext_name in both extensions/ and settings.json packages"
      log_err "    extensions/: $ext_dir (v$ext_version)"
      log_err "    packages:    $pkg_path"
      log_err "    Fix: trash $ext_dir"
      DRIFT=$((DRIFT + 1))
    fi
  done

  if [[ $collision_count -eq 0 ]]; then
    log_ok "No extension collisions ($(echo "$pkg_names" | wc -l | tr -d ' ') packages checked)"
  fi
}

#==============================================================================
# check_skill_collisions - Two vectors
#
# Vector 1: Package-declared skills vs agent-config skills
#   For each local package path, read package.json → pi.skills → list skill
#   subdirs → compare names against $AGENT_CONFIG_SKILLS
#
# Vector 2: Direct copies in ~/.pi/agent/skills/ (the spec 005 pattern)
#   If ~/.pi/agent/skills/ is a real directory (not a symlink), report any
#   non-symlink directory entries as potential collisions — something was
#   directly copied in rather than managed via agent-config.
#==============================================================================
check_skill_collisions() {
  local collision_count=0

  # --- Vector 1: Package-declared skills vs agent-config ---
  if [[ -f "$PI_SETTINGS" ]] && command -v python3 &>/dev/null; then
    # Get local package paths (not npm: entries — those are resolved by Pi)
    local local_pkgs
    local_pkgs=$(python3 -c "
import json, os
with open(os.path.expanduser('$PI_SETTINGS')) as f:
    data = json.load(f)
for pkg in data.get('packages', []):
    if not pkg.startswith('npm:'):
        # Resolve relative paths from home dir
        path = os.path.expanduser(pkg)
        if not os.path.isabs(path):
            path = os.path.abspath(path)
        print(path)
" 2>/dev/null)

    while IFS= read -r pkg_path; do
      [[ -z "$pkg_path" ]] && continue
      [[ -f "$pkg_path/package.json" ]] || continue

      # Read pi.skills from package.json
      local skills_dirs
      skills_dirs=$(python3 -c "
import json, os
with open('$pkg_path/package.json') as f:
    data = json.load(f)
pi = data.get('pi', {})
for skill_rel in pi.get('skills', []):
    skill_abs = os.path.join('$pkg_path', skill_rel)
    if os.path.isdir(skill_abs):
        for entry in os.listdir(skill_abs):
            entry_path = os.path.join(skill_abs, entry)
            if os.path.isdir(entry_path):
                print(entry)
" 2>/dev/null)

      local pkg_name
      pkg_name=$(basename "$pkg_path")

      while IFS= read -r skill_name; do
        [[ -z "$skill_name" ]] && continue
        # Check against agent-config skills (recursive — category dirs at any depth)
        if find "$AGENT_CONFIG_SKILLS" -name "$skill_name" -type d -print -quit 2>/dev/null | grep -q .; then
          collision_count=$((collision_count + 1))
          log_err "SKILL COLLISION: '$skill_name' declared by package '$pkg_name' AND exists in agent-config"
          log_err "    package: $pkg_path/skills/*/$skill_name"
          log_err "    agent-config: $(find "$AGENT_CONFIG_SKILLS" -name "$skill_name" -type d -print -quit)"
          DRIFT=$((DRIFT + 1))
        fi
      done <<< "$skills_dirs"
    done <<< "$local_pkgs"
  fi

  # --- Vector 2: Direct copies in ~/.pi/agent/skills/ ---
  if [[ -d "$PI_SKILLS" ]] && [[ ! -L "$PI_SKILLS" ]]; then
    # It's a real directory (not a symlink) — check for non-symlink entries
    local direct_copies=0
    for entry in "$PI_SKILLS"/*/; do
      [[ -d "$entry" ]] || continue
      if [[ ! -L "${entry%/}" ]]; then
        # This is a real directory, not a symlink — it was directly copied in
        direct_copies=$((direct_copies + 1))
        collision_count=$((collision_count + 1))
        local entry_name
        entry_name=$(basename "$entry")
        log_warn "POTENTIAL COLLISION: '$entry_name' is a direct copy in ~/.pi/agent/skills/"
        log_warn "    path: $entry"
        log_warn "    This may duplicate a skill already managed via ~/.agents/skills/"
        log_warn "    Fix: trash ${entry%/}"
        DRIFT=$((DRIFT + 1))
      fi
    done
  fi

  # --- Vector 3: Loopback symlinks in ~/.pi/agent/skills/ pointing into agent-config ---
  # These create a redundant second discovery path for the same skill,
  # causing cross-source collision (e.g., testflight — spec 005).
  if [[ -d "$PI_SKILLS" ]]; then
    for entry in "$PI_SKILLS"/*/; do
      [[ -L "${entry%/}" ]] || continue
      local resolved
      resolved=$(cd "${entry%/}" && pwd -P 2>/dev/null) || continue
      if [[ "$resolved" == */.agent-config/skills/* ]]; then
        collision_count=$((collision_count + 1))
        log_warn "LOOPBACK: '$(basename "$entry")' in ~/.pi/agent/skills/ points into agent-config"
        log_warn "    symlink: ${entry%/}"
        log_warn "    resolves to: $resolved"
        log_warn "    Fix: trash ${entry%/}"
        DRIFT=$((DRIFT + 1))
      fi
    done
  fi

  # --- Vector 4: Broad cross-source collision check ---
  # Any entry in ~/.pi/agent/skills/ (symlink or dir) whose basename matches
  # an agent-config skill name at any depth. Catches manual symlinks, package
  # installs, and direct copies that Vector 1 and 2 miss.
  if [[ -d "$PI_SKILLS" ]]; then
    for entry in "$PI_SKILLS"/*/; do
      [[ -d "$entry" ]] || continue
      local entry_name
      entry_name=$(basename "$entry")
      # Skip loopbacks (already caught by Vector 3)
      if [[ -L "${entry%/}" ]]; then
        local resolved
        resolved=$(cd "${entry%/}" && pwd -P 2>/dev/null) || continue
        [[ "$resolved" == */.agent-config/skills/* ]] && continue
      fi
      # Check if this name exists anywhere in agent-config skills
      if find "$AGENT_CONFIG_SKILLS" -name "$entry_name" -type d -print -quit 2>/dev/null | grep -q .; then
        collision_count=$((collision_count + 1))
        log_err "CROSS-SOURCE COLLISION: '$entry_name' exists in both ~/.pi/agent/skills/ and agent-config"
        log_err "    pi-skills: ${entry%/}"
        log_err "    agent-config: $(find "$AGENT_CONFIG_SKILLS" -name "$entry_name" -type d -print -quit)"
        log_err "    Fix: rename one of them to avoid name conflict"
        DRIFT=$((DRIFT + 1))
      fi
    done
  fi

  if [[ $collision_count -eq 0 ]]; then
    log_ok "No skill collisions"
  fi
}
