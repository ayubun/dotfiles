#!/bin/bash

set -euo pipefail

repo="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
root="$(mktemp -d "${TMPDIR:-/tmp}/codex-auth-test.XXXXXX")"
trap 'rm -rf "$root"' EXIT
passed=0

fail() {
  printf 'fail: %s\n' "$1" >&2
  exit 1
}

setup_case() {
  home="$(mktemp -d "$root/home.XXXXXX")"
  mkdir -p "$home/.local/bin" "$home/.codex"
  auth="$home/.codex/auth.json"
  # The fake codex records each login and stores the key it reads from stdin.
  cat >"$home/.local/bin/codex" <<'STUB'
#!/bin/bash
[[ "$*" == "login --with-api-key" ]] || exit 99
printf 'login\n' >>"$HOME/codex-calls"
jq -n --arg key "$(cat)" '{OPENAI_API_KEY:$key}' >"$HOME/.codex/auth.json"
STUB
  # The stub prints STUB_MODE and exits with STUB_EXIT, like `ai-brain secrets provider-mode codex`.
  cat >"$home/.local/bin/ai-brain" <<'STUB'
#!/bin/bash
[[ "$*" == "secrets provider-mode codex" ]] || exit 99
[[ "${STUB_EXIT:-0}" == 0 ]] && printf '%s\n' "$STUB_MODE"
exit "${STUB_EXIT:-0}"
STUB
  chmod +x "$home/.local/bin/codex" "$home/.local/bin/ai-brain"
  printf '{"tokens":{"fixture":"chatgpt-login"}}\n' >"$auth"
}

run_sync() {
  env -i HOME="$home" PATH=/usr/bin:/bin OPENAI_API_KEY=fixture-not-a-key STUB_MODE="${1:-api-key}" STUB_EXIT="${2:-0}" \
    zsh "$repo/dependencies/sync-codex-auth.zsh" >"$home/output" 2>&1
}

logins() {
  [[ -f "$home/codex-calls" ]] && wc -l <"$home/codex-calls" | tr -d ' ' || printf '0'
}

pass() {
  passed=$((passed + 1))
}

test_api_key_mode_logs_codex_in_with_the_key() {
  setup_case
  run_sync api-key || fail "api-key sync failed: $(<"$home/output")"
  [[ "$(logins)" == 1 ]] || fail "api-key mode did not log codex in"
  [[ "$(jq -r .OPENAI_API_KEY "$auth")" == fixture-not-a-key ]] || fail "api-key mode did not store the key"
  pass
}

test_subscription_mode_keeps_the_chatgpt_login() {
  setup_case
  run_sync subscription || fail "subscription sync failed: $(<"$home/output")"
  [[ "$(logins)" == 0 ]] || fail "subscription mode ran codex login"
  [[ "$(jq -c . "$auth")" == '{"tokens":{"fixture":"chatgpt-login"}}' ]] || fail "subscription mode changed auth.json"
  pass
}

test_an_unmanaged_instance_keeps_the_api_key_behavior() {
  setup_case
  run_sync '' 3 || fail "sync for an unmanaged codex failed"
  [[ "$(logins)" == 1 ]] || fail "an unmanaged codex was not logged in"
  pass
}

test_a_missing_cli_keeps_the_api_key_behavior() {
  setup_case
  rm "$home/.local/bin/ai-brain"
  run_sync || fail "sync without the cli failed"
  [[ "$(logins)" == 1 ]] || fail "sync without the cli did not log codex in"
  pass
}

test_a_failed_mode_lookup_keeps_auth_json_and_warns() {
  for status in 1 2; do
    setup_case
    if run_sync '' "$status"; then
      fail "sync accepted provider-mode exit $status"
    fi
    [[ "$(logins)" == 0 ]] || fail "provider-mode exit $status still ran codex login"
    [[ "$(jq -c . "$auth")" == '{"tokens":{"fixture":"chatgpt-login"}}' ]] || fail "provider-mode exit $status changed auth.json"
    grep -q 'unchanged' "$home/output" || fail "provider-mode exit $status was not reported"
  done
  pass
}

if [[ $# -gt 0 ]]; then
  "$1"
  exit
fi

test_api_key_mode_logs_codex_in_with_the_key
test_subscription_mode_keeps_the_chatgpt_login
test_an_unmanaged_instance_keeps_the_api_key_behavior
test_a_missing_cli_keeps_the_api_key_behavior
test_a_failed_mode_lookup_keeps_auth_json_and_warns
printf 'ok: %s tests passed\n' "$passed"
