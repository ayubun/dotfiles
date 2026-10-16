#!/bin/zsh

set -euo pipefail

[[ -n "${OPENAI_API_KEY:-}" || -n "${ANTHROPIC_API_KEY:-}" ]] || exit 0
command -v jq >/dev/null || {
  print -u2 'jq is required to sync opencode auth'
  exit 1
}

opencode="$HOME/.opencode/bin/opencode"
[[ -x "$opencode" ]] || opencode="$(command -v opencode || true)"
version="$("$opencode" --version 2>/dev/null || true)"
version="${${version#opencode }#v}"

# OpenCode 2 keeps credentials in its database, imports the legacy file only once, and prefers them over the environment.
if [[ "$version" == 2.* ]]; then
  # A running service applies the change live; --standalone avoids starting one from cron.
  server=()
  [[ "$("$opencode" service status 2>/dev/null || true)" == http* ]] || server=(--standalone)

  for integration env_name in openai OPENAI_API_KEY anthropic ANTHROPIC_API_KEY; do
    [[ -n "${(P)env_name:-}" ]] || continue
    if ! stored="$("$opencode" auth export "$integration" "${server[@]}" 2>/dev/null)"; then
      print -u2 "failed to list opencode $integration credentials"
      exit 1
    fi
    current="$(print -r -- "$stored" | jq --arg name "$env_name" \
      '[.[] | select(.active and .value.type == "key" and .value.key == env[$name])] | length')"
    [[ "$current" == 0 ]] || continue

    new_id="ai-brain-$integration-$(date +%s)"
    # stdin keeps the key out of process arguments; output is dropped so nothing echoes into logs
    if ! jq -n --arg id "$new_id" --arg integration "$integration" --arg name "$env_name" \
      '[{id: $id, integrationID: $integration, label: "ai-brain API key", value: {type: "key", key: env[$name]}, active: true}]' |
      "$opencode" auth import "${server[@]}" >/dev/null 2>&1 ||
      ! "$opencode" auth switch "$integration" "$new_id" "${server[@]}" </dev/null >/dev/null 2>&1; then
      print -u2 "failed to store the opencode $integration API key"
      exit 1
    fi
    for old_id in ${(f)"$(print -r -- "$stored" | jq -r '.[] | select(.value.type == "key") | .id')"}; do
      "$opencode" auth logout "$integration" "$old_id" "${server[@]}" </dev/null >/dev/null 2>&1 ||
        print -u2 "failed to remove stale opencode $integration credential $old_id"
    done
  done
  exit 0
fi

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
