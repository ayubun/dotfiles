#!/bin/bash

curl -fsSL https://claude.ai/install.sh | bash

mkdir -p ~/.claude

ln -sF ~/dotfiles/configs/claude/settings.json ~/.claude/settings.json

rm -rf ~/.claude/skills
ln -s ~/dotfiles/configs/claude/skills ~/.claude/skills

rm -rf ~/.claude/agents
ln -s ~/dotfiles/configs/claude/agents ~/.claude/agents

rm -f ~/.claude/CLAUDE.md
ln -s ~/dotfiles/configs/agents.md ~/.claude/CLAUDE.md

