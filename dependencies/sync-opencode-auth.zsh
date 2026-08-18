#!/bin/zsh

set -euo pipefail

[[ -n "${OPENAI_API_KEY:-}" || -n "${ANTHROPIC_API_KEY:-}" ]] || exit 0
command -v jq >/dev/null || {
  print -u2 'jq is required to sync opencode auth'
  exit 1
}

auth="$HOME/.local/share/opencode/auth.json"
mkdir -p -m 700 "${auth:h}"
chmod 700 "${auth:h}"
tmp="$(mktemp "${auth}.XXXXXX")"
trap 'rm -f "$tmp"' EXIT

if [[ -f "$auth" ]]; then
  jq empty "$auth" || {
    print -u2 "invalid opencode auth json: $auth"
    exit 1
  }
  jq '
    if (env.OPENAI_API_KEY // "") != "" then
      .openai = {"type":"api","key":env.OPENAI_API_KEY}
    else . end |
    if (env.ANTHROPIC_API_KEY // "") != "" then
      .anthropic = {"type":"api","key":env.ANTHROPIC_API_KEY}
    else . end
  ' "$auth" >"$tmp"
else
  jq -n '
    {} |
    if (env.OPENAI_API_KEY // "") != "" then
      .openai = {"type":"api","key":env.OPENAI_API_KEY}
    else . end |
    if (env.ANTHROPIC_API_KEY // "") != "" then
      .anthropic = {"type":"api","key":env.ANTHROPIC_API_KEY}
    else . end
  ' >"$tmp"
fi

chmod 600 "$tmp"
mv "$tmp" "$auth"
trap - EXIT
