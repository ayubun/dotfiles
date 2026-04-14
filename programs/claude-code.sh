#!/bin/bash

curl -fsSL https://claude.ai/install.sh | bash

mkdir -p ~/.claude

ln -sF ~/dotfiles/configs/claude/settings.json ~/.claude/settings.json

