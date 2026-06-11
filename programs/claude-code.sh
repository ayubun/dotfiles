#!/bin/bash

curl -fsSL https://claude.ai/install.sh | bash

mkdir -p ~/.claude

ln -sF ~/dotfiles/configs/claude/settings.json ~/.claude/settings.json

# RETIRED: skills/agents are no longer mirrored into ~/.claude/. The canonical
# skill/agent trees are opencode-format (configs/opencode/* + ~/work/opencode/*,
# see configs/opencode/CLAUDE-TO-OPENCODE.md). Claude Code is not
# actively used; if it's ever revived, regenerate Claude-format copies from
# configs/dependencies/skills-sources rather than re-linking here. We still
# clean up any stale symlinks so opencode's external ~/.claude/skills scan
# doesn't double-load them.
for kind in skills agents; do
  dest="$HOME/.claude/$kind"
  [[ -L "$dest" ]] && rm "$dest"
  [[ -d "$dest" ]] && find "$dest" -mindepth 1 -maxdepth 1 -type l -delete
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
