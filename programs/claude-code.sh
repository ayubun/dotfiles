#!/bin/bash

curl -fsSL https://claude.ai/install.sh | bash

mkdir -p ~/.claude

ln -sF ~/dotfiles/configs/claude/settings.json ~/.claude/settings.json

# claude code is not active, so remove stale skill and agent symlinks
for kind in skills agents; do
  dest="$HOME/.claude/$kind"
  [[ -L "$dest" ]] && rm "$dest"
  [[ -d "$dest" ]] && find "$dest" -mindepth 1 -maxdepth 1 -type l -delete
done

rm -f ~/.claude/CLAUDE.md
ln -s ~/ai-brain/adapters/claude/CLAUDE.md ~/.claude/CLAUDE.md

# nothing reads ~/.claude/AGENTS.md; remove any stale copy
rm -f ~/.claude/AGENTS.md
