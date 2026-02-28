# Research 002: Tooling Options for Low-Maintenance Parity

## Decision Context

Goal: maximize reliability and reproducibility while minimizing ongoing maintenance effort so development focus remains on Vision Pro visual work.

## Options Reviewed

1. Keep current custom flow only (`install.sh`, `install-all.sh`, parity tool).
2. Hybrid: current flow + `chezmoi` + `brew bundle` + `mise` lockfile.
3. `yadm`-based dotfiles management.
4. `GNU Stow`-based symlink management.
5. Full `nix-darwin` + `home-manager` replacement.
6. `ansible-pull` host provisioning approach.

## Comparison Summary

| Option | Reliability | Maintenance Overhead | Migration Risk | Notes |
|---|---|---:|---:|---|
| Current only | Medium | Medium-High | Low | Already works, but still custom-heavy and drift-prone outside managed surfaces. |
| Hybrid (recommended) | High | Low-Medium | Low-Medium | Preserves current source-of-truth while standardizing package/runtime/config management. |
| yadm | Medium-High | Medium | Medium | Useful alternates/hooks/encryption, but less opinionated for end-to-end parity pipeline. |
| GNU Stow | Medium | Medium | Medium | Great simple symlink manager, but too minimal for full bootstrap/version policy needs. |
| nix-darwin + home-manager | Very High | Medium-High | High | Best reproducibility, but higher cognitive/migration cost. |
| ansible-pull | High | Medium-High | Medium-High | Strong at fleet scale; likely overkill for laptop + mini at current scope. |

## Recommendation

Adopt the **Hybrid** path as default:

1. Keep `~/.agent-config` as canonical content plane.
2. Add `chezmoi` for external machine-level config surfaces.
3. Add `brew bundle` for package baseline enforcement.
4. Add `mise` lockfile for runtime/tool version pinning.
5. Keep `agent-config-parity` as drift and validation gate.

Escalate to full Nix only if hybrid fails to meet success metrics after pilot.

## Primary Sources

- Chezmoi: quick start, verify, doctor, scripts, concepts, password-manager support
  - https://www.chezmoi.io/quick-start/
  - https://www.chezmoi.io/reference/commands/verify/
  - https://www.chezmoi.io/reference/commands/doctor/
  - https://www.chezmoi.io/user-guide/use-scripts-to-perform-actions/
  - https://www.chezmoi.io/reference/concepts/
- Homebrew Bundle
  - https://docs.brew.sh/Brew-Bundle-and-Brewfile
- Mise lock/version management
  - https://mise.jdx.dev/dev-tools/mise-lock.html
  - https://mise.jdx.dev/cli/install.html
- Home Manager + nix-darwin
  - https://home-manager.dev/
  - https://github.com/nix-community/home-manager
  - https://nix-darwin.github.io/nix-darwin/manual/
- Nix core docs
  - https://nix.dev/manual/nix/2.28/
- yadm
  - https://yadm.io/docs/alternates
  - https://yadm.io/docs/bootstrap
  - https://yadm.io/docs/hooks
  - https://yadm.io/docs/encryption
- GNU Stow
  - https://www.gnu.org/software/stow/manual/stow.html
- Ansible
  - https://docs.ansible.com/projects/ansible-core/devel/playbook_guide/playbooks_intro.html
  - https://docs.ansible.com/projects/ansible-core/devel/cli/ansible-pull.html
