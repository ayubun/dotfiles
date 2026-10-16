#!/bin/bash

# opencode reads config from ~/.config/opencode/ (XDG), not ~/.opencode/.
# Fix ownership in case a previous root-based install left these root-owned.
sudo chown -R "${ORIGINAL_USER:-$USER}" "$HOME/.config/opencode" 2>/dev/null || true

# ai-brain decides the major: an adapter with opencode.jsonc is OpenCode 2.
# scripts/opencode-cutover.sh and scripts/opencode-rollback.sh move a machine
# between the two; this installer only keeps the installed major in place.
source "$HOME/dotfiles/dependencies/opencode-install.bash"
major="$(opencode_major_for_adapter "$HOME/ai-brain/adapters/opencode")"
if [[ "$major" == 2 ]]; then
  if [[ "$("$HOME/.opencode/bin/opencode" --version 2>/dev/null || true)" != *"$OPENCODE_V2_DEFAULT_VERSION"* ]]; then
    opencode_install 2 "$HOME/.opencode/bin"
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

mkdir -p "$HOME/.config/opencode"

# ai-brain no longer symlinks these; remove dangling links left by earlier installs
for stale in "$HOME/.config/opencode/AGENTS.md" "$HOME/.config/opencode/skills"; do
  [[ -L "$stale" && ! -e "$stale" ]] && rm -f "$stale"
done

# standard global paths remain available for per-machine additions

"$HOME/.local/bin/ocx" init --global --quiet

# the reconciler owns the config, agents, plugins, and lib symlinks so the
# repo updater can rerun it after every fast-forward
bash "$HOME/dotfiles/dependencies/reconcile-opencode-links.bash"
