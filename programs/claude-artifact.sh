#!/bin/bash

# a private claude code with its own claude.ai login publishes claude artifacts, which api key sessions cannot do
if [[ $UID -eq 0 && -n "${ORIGINAL_USER:-}" && "$ORIGINAL_USER" != "root" ]]; then
  exec sudo -u "$ORIGINAL_USER" -H bash "$0" "$@"
fi

root="$HOME/.claude-artifacts"
cli="$root/cli/bin/claude"

mkdir -p "$root/cli" "$HOME/.local/bin"
chmod 700 "$root"

if ! command -v npm >/dev/null; then
  echo "claude-artifact: npm not found; skipping the private claude code install" >&2
else
  latest="$(npm view @anthropic-ai/claude-code version 2>/dev/null)"
  current="$("$cli" --version 2>/dev/null | cut -d' ' -f1)"
  if [[ -n "$latest" && "$latest" != "$current" ]]; then
    npm install -g --prefix "$root/cli" "@anthropic-ai/claude-code@$latest" || exit 1
  fi
fi

ln -sfn "$HOME/dotfiles/dependencies/claude-artifact.bash" "$HOME/.local/bin/claude-artifact"

if ! env -u ANTHROPIC_API_KEY CLAUDE_CONFIG_DIR="$root" "$cli" auth status 2>/dev/null | grep -q '"authMethod": "claude.ai"'; then
  echo "claude-artifact: not logged in; run: env -u ANTHROPIC_API_KEY CLAUDE_CONFIG_DIR=$root $cli auth login --claudeai"
fi

exit 0
