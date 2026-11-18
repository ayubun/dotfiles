#!/bin/bash

as_user=()
if [[ $UID -eq 0 && -n "${ORIGINAL_USER:-}" && "$ORIGINAL_USER" != "root" ]]; then
  as_user=(sudo -u "$ORIGINAL_USER" -H)
fi

# opencode reads config from ~/.config/opencode/ (XDG), not ~/.opencode/.
# Fix ownership in case a previous root-based install left these root-owned.
sudo chown -R "${ORIGINAL_USER:-$USER}" "$HOME/.config/opencode" 2>/dev/null || true

# ai-brain decides the major: an adapter with opencode.jsonc is OpenCode 2.
# scripts/opencode-cutover.sh and scripts/opencode-rollback.sh move a machine
# between the two; this installer only keeps the installed major in place.
source "$HOME/dotfiles/dependencies/opencode-install.bash"
major="$(opencode_major_for_adapter "$HOME/ai-brain/adapters/opencode")"
if [[ "$major" == 2 ]]; then
  # Follow latest, never go below the floor, and never downgrade a newer install (for example a T3 upgrade).
  target="$(opencode_latest_v2_version || true)"
  if [[ -z "$target" ]] || opencode_version_lt "$target" "$OPENCODE_V2_DEFAULT_VERSION"; then
    target="$OPENCODE_V2_DEFAULT_VERSION"
  fi
  installed="$(opencode_installed_version "$HOME/.opencode/bin/opencode" || true)"
  if [[ -z "$installed" ]] || opencode_version_lt "$installed" "$target"; then
    opencode_install 2 "$HOME/.opencode/bin" "$target"
  fi
else
  curl -fsSL https://opencode.ai/install | bash
fi
curl -fsSL https://ocx.kdco.dev/install.sh | sh

if [[ $UID -eq 0 && -n "${ORIGINAL_USER:-}" && "$ORIGINAL_USER" != "root" ]]; then
  sudo -u "$ORIGINAL_USER" -H zsh -lc 'zsh "$HOME/dotfiles/dependencies/sync-opencode-auth.zsh"'
else
  zsh -lc 'zsh "$HOME/dotfiles/dependencies/sync-opencode-auth.zsh"'
fi

${as_user[@]+"${as_user[@]}"} mkdir -p "$HOME/.config/opencode"

# ai-brain no longer symlinks these; remove dangling links left by earlier installs
for stale in "$HOME/.config/opencode/AGENTS.md" "$HOME/.config/opencode/skills"; do
  [[ -L "$stale" && ! -e "$stale" ]] && rm -f "$stale"
done

# standard global paths remain available for per-machine additions

"$HOME/.local/bin/ocx" init --global --quiet

# the reconciler owns the config, plugins, and lib symlinks; ai-brain generate owns the agent links
bash "$HOME/dotfiles/dependencies/reconcile-opencode-links.bash"
# a root install creates the reconciled links as root, and generate runs as the original user
if [[ ${#as_user[@]} -gt 0 ]]; then
  sudo chown -R "$ORIGINAL_USER" "$HOME/.config/opencode" 2>/dev/null || true
fi
if [[ "$major" == 2 ]]; then
  [[ -x "$HOME/.local/bin/ai-brain" ]] && ${as_user[@]+"${as_user[@]}"} "$HOME/.local/bin/ai-brain" generate || printf 'warning: ai-brain generate did not run; agents and skills are generated on the next update\n' >&2
fi
