#!/bin/zsh

set -euo pipefail

[[ -n "${OPENAI_API_KEY:-}" ]] || exit 0

codex="$HOME/.local/bin/codex"
auth="${CODEX_HOME:-$HOME/.codex}/auth.json"
if [[ ! -x "$codex" ]]; then
  print -u2 "codex is not installed at $codex"
  exit 1
fi

[[ -f "$auth" ]] && chmod 600 "$auth"
if [[ -f "$auth" ]] && command -v jq >/dev/null &&
  [[ "$(jq -r '.OPENAI_API_KEY // ""' "$auth" 2>/dev/null)" == "$OPENAI_API_KEY" ]]; then
  exit 0
fi

# stdin keeps the key out of process arguments; stdout is dropped so nothing echoes into install logs
if ! print -r -- "$OPENAI_API_KEY" | "$codex" login --with-api-key >/dev/null; then
  print -u2 'failed to log codex in with OPENAI_API_KEY'
  exit 1
fi
[[ -f "$auth" ]] && chmod 600 "$auth"
exit 0
