#!/bin/bash

# opencode reads config from ~/.config/opencode/ (XDG), not ~/.opencode/.
# Fix ownership in case a previous root-based install left these root-owned.
sudo chown -R "${ORIGINAL_USER:-$USER}" "$HOME/.config/opencode" 2>/dev/null || true

curl -fsSL https://opencode.ai/install | bash

mkdir -p "$HOME/.config/opencode"

# -s: symbolic, -f: force-replace existing target, -n: don't deref symlink
# target dir (so re-running replaces the symlink instead of creating one
# inside it). If the target exists as a real directory, ln fails loud
# rather than silently clobbering user data.
ln -sfn "$HOME/dotfiles/configs/opencode/opencode.json" "$HOME/.config/opencode/opencode.json"
ln -sfn "$HOME/dotfiles/configs/opencode/skills" "$HOME/.config/opencode/skills"
