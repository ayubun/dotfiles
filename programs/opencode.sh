#!/bin/bash

# opencode reads config from ~/.config/opencode/ (XDG), not ~/.opencode/.
# Fix ownership in case a previous root-based install left these root-owned.
sudo chown -R "${ORIGINAL_USER:-$USER}" "$HOME/.config/opencode" 2>/dev/null || true

curl -fsSL https://opencode.ai/install | bash
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

# ai-brain owns the active config, instructions, and skill paths
rm -f "$HOME/.config/opencode/opencode.json"
ln -s "$HOME/ai-brain/adapters/opencode/opencode.json" "$HOME/.config/opencode/opencode.json"

# standard global paths remain available for per-machine additions

"$HOME/.local/bin/ocx" init --global --quiet

# agents, plugins, and lib symlinks are owned by the reconciler so the repo
# updater can rerun it after every fast-forward
bash "$HOME/dotfiles/dependencies/reconcile-opencode-links.bash"
