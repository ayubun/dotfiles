#!/bin/bash

# opencode reads config from ~/.config/opencode/ (XDG), not ~/.opencode/.
# Fix ownership in case a previous root-based install left these root-owned.
sudo chown -R "${ORIGINAL_USER:-$USER}" "$HOME/.config/opencode" 2>/dev/null || true

curl -fsSL https://opencode.ai/install | bash

mkdir -p "$HOME/.config/opencode"

# Single-file config: this drives skill paths, instructions, etc., so opencode
# can pull from both dotfiles and ~/work without any further symlinks.
rm -rf "$HOME/.config/opencode/opencode.json"
ln -s "$HOME/dotfiles/configs/opencode/opencode.json" "$HOME/.config/opencode/opencode.json"

# Skills and AGENTS.md are pulled in via opencode.json (skills.paths and
# instructions). The standard locations ~/.config/opencode/skills and
# ~/.config/opencode/AGENTS.md are NOT touched - opencode auto-discovers
# them too, so any per-machine ad-hoc skills or directives placed there
# merge naturally with the dotfiles and ~/work sources.

# Agents have no multi-path config in opencode, so we build a real directory
# and symlink each agent into it from dotfiles + ~/work/agents (if present).
# Real files placed by the user are preserved - this script only manages its
# own symlinks. Later sources win on collision against earlier sources, but
# any user-placed real file always wins over both.
dest="$HOME/.config/opencode/agents"
[[ -L "$dest" ]] && rm "$dest"
mkdir -p "$dest"
find "$dest" -mindepth 1 -maxdepth 1 -type l -delete
shopt -s nullglob
for src in "$HOME/dotfiles/configs/opencode/agents" "$HOME/work/opencode/agents"; do
  [[ -d "$src" ]] || continue
  for f in "$src"/*.md; do
    name="$(basename "$f")"
    if [[ -e "$dest/$name" && ! -L "$dest/$name" ]]; then
      continue
    fi
    ln -sfn "$f" "$dest/$name"
  done
done
shopt -u nullglob
