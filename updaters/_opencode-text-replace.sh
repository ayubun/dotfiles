#!/usr/bin/env bash
# In-place text replacement helper for opencode skill conversion.
# Called by updaters/skills.sh via find -exec on auxiliary files.
# Applies the same replacements as opencode_text_replace().
set -euo pipefail
for f in "$@"; do
  sed -i '' \
    -e 's/CLAUDE\.md/AGENTS.md/g' \
    -e 's/Claude Code/opencode/g' \
    -e 's/claude code/opencode/g' \
    -e 's/claude-code/opencode/g' \
    -e 's/extending-claude/extending-opencode/g' \
    -e 's/writing-claude-md-files/writing-agents-md-files/g' \
    -e 's/writing-claude-directives/writing-opencode-directives/g' \
    -e 's/project-claude-librarian/project-opencode-librarian/g' \
    -e 's/CLAUDE_MD_TESTING/AGENTS_MD_TESTING/g' \
    -e 's|~/\.claude/skills/|~/.config/opencode/skills/|g' \
    "$f"
done
