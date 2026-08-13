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
ln -s ~/ai-brain/AGENTS.md ~/.claude/CLAUDE.md

rm -f ~/.claude/AGENTS.md
if [ -f ~/ai-brain-discord/AGENTS.md ]; then
  ln -s ~/ai-brain-discord/AGENTS.md ~/.claude/AGENTS.md
fi
