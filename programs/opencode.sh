#!/bin/bash

# opencode reads config from ~/.config/opencode/ (XDG), not ~/.opencode/.
# Fix ownership in case a previous root-based install left these root-owned.
sudo chown -R "${ORIGINAL_USER:-$USER}" "$HOME/.config/opencode" 2>/dev/null || true

curl -fsSL https://opencode.ai/install | bash

mkdir -p "$HOME/.config/opencode"

# Destructively replace any existing entry (file, symlink, or real
# directory) with our dotfiles-managed symlink. The dotfiles are the
# source of truth on machines where this script runs - anything sitting
# at these paths is overwritten.
rm -rf "$HOME/.config/opencode/opencode.json"
ln -s "$HOME/dotfiles/configs/opencode/opencode.json" "$HOME/.config/opencode/opencode.json"

rm -rf "$HOME/.config/opencode/skills"
ln -s "$HOME/dotfiles/configs/opencode/skills" "$HOME/.config/opencode/skills"
