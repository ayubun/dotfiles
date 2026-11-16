#!/usr/bin/env bash
# Runs the private Claude Code that has the artifacts-only claude.ai login, isolated from the API key setup.
set -euo pipefail
[[ $# -ge 1 ]] || { echo "usage: claude-artifact <prompt> [claude options]" >&2; exit 2; }
root="${CLAUDE_ARTIFACT_HOME:-$HOME/.claude-artifacts}"
[[ -x "$root/cli/bin/claude" ]] || { echo "claude-artifact: run ~/dotfiles/programs/claude-artifact.sh first" >&2; exit 1; }
prompt="$1"
shift
exec env -u ANTHROPIC_API_KEY \
  CLAUDE_CONFIG_DIR="$root" \
  CLAUDE_CODE_ARTIFACT=1 \
  CLAUDE_CODE_ARTIFACT_AUTO_OPEN=0 \
  DISABLE_AUTOUPDATER=1 \
  "$root/cli/bin/claude" -p "$prompt" --allowedTools=Artifact,Read "$@"
