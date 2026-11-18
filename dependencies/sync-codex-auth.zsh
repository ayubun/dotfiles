#!/bin/zsh

set -euo pipefail

[[ -n "${OPENAI_API_KEY:-}" ]] || exit 0

# Subscription mode keeps the `codex login` (ChatGPT) in auth.json; exit 3 means ai-brain does not manage codex.
cli="$HOME/.local/bin/ai-brain"
if [[ -x "$cli" ]]; then
  mode_status=0
  mode="$("$cli" secrets provider-mode codex 2>/dev/null)" || mode_status=$?
  if (( mode_status == 0 )); then
    [[ "$mode" == subscription ]] && exit 0
  elif (( mode_status != 3 )); then
    print -u2 "cannot read the codex mode from ai-brain (exit $mode_status); codex auth is unchanged"
    exit 1
  fi
fi

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
