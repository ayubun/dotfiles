#!/bin/zsh

# Claude Code apiKeyHelper; hosts such as the t3 service do not inherit the login shell environment
set -euo pipefail

key="${ANTHROPIC_API_KEY:-}"
# fd 3 carries only the key, so login shell startup output cannot corrupt it
[[ -n "$key" ]] || key="$(zsh -lc 'print -r -- "${ANTHROPIC_API_KEY:-}" >&3' 3>&1 >/dev/null 2>/dev/null)"
if [[ -z "$key" || "$key" == *$'\n'* ]]; then
  print -u2 'ANTHROPIC_API_KEY is not set in the environment or a login shell'
  exit 1
fi
print -r -- "$key"
