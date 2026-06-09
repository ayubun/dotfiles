#!/bin/bash

curl -fsSL https://claude.ai/install.sh | bash

mkdir -p ~/.claude

ln -sF ~/dotfiles/configs/claude/settings.json ~/.claude/settings.json

# Skills and agents must live as directories of per-resource symlinks so we
# can merge sources (dotfiles + ~/work/{skills,agents}). Claude Code has no
# multi-path config for either resource type. Real files placed by the user
# are preserved - we only manage our own symlinks. Later sources win on
# collision against earlier sources, but any user-placed real file always
# wins over both.
for kind in skills agents; do
  dest="$HOME/.claude/$kind"
  [[ -L "$dest" ]] && rm "$dest"
  mkdir -p "$dest"
  find "$dest" -mindepth 1 -maxdepth 1 -type l -delete
  shopt -s nullglob
  for src in "$HOME/dotfiles/configs/claude/$kind" "$HOME/work/$kind"; do
    [[ -d "$src" ]] || continue
    for entry in "$src"/*; do
      name="$(basename "$entry")"
      if [[ -e "$dest/$name" && ! -L "$dest/$name" ]]; then
        continue
      fi
      ln -sfn "$entry" "$dest/$name"
    done
  done
  shopt -u nullglob
done

# Global directive files. CLAUDE.md slot is owned by dotfiles; AGENTS.md slot
# is owned by ~/work/AGENTS.md so work-specific guidance loads globally
# without needing to be in the public dotfiles repo. Claude Code reads both
# files when present.
rm -f ~/.claude/CLAUDE.md
ln -s ~/dotfiles/configs/agents.md ~/.claude/CLAUDE.md

rm -f ~/.claude/AGENTS.md
if [ -f ~/work/AGENTS.md ]; then
  ln -s ~/work/AGENTS.md ~/.claude/AGENTS.md
fi
