#!/bin/bash

set -euo pipefail

repo="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
root="$(mktemp -d "${TMPDIR:-/tmp}/claude-helper-test.XXXXXX")"
trap 'rm -rf "$root"' EXIT
helper='zsh ${HOME}/dotfiles/dependencies/claude-api-key.zsh'
passed=0

fail() {
  printf 'fail: %s\n' "$1" >&2
  exit 1
}

setup_case() {
  home="$(mktemp -d "$root/home.XXXXXX")"
  mkdir -p "$home/.local/bin" "$home/.claude"
  settings="$home/.claude/settings.json"
  # The stub prints the mode in STUB_MODE and exits with STUB_EXIT, like `ai-brain secrets provider-mode`.
  cat >"$home/.local/bin/ai-brain" <<'STUB'
#!/bin/bash
[[ "$*" == "secrets provider-mode claudeAgent" ]] || exit 99
[[ "${STUB_EXIT:-0}" == 0 ]] && printf '%s\n' "$STUB_MODE"
exit "${STUB_EXIT:-0}"
STUB
  chmod +x "$home/.local/bin/ai-brain"
  printf "export ANTHROPIC_API_KEY='fixture-not-a-key'\n" >"$home/.zshenv"
}

run_reconcile() {
  env -i HOME="$home" PATH=/usr/bin:/bin STUB_MODE="${1:-api-key}" STUB_EXIT="${2:-0}" /bin/bash \
    "$repo/dependencies/reconcile-claude-api-key-helper.bash" >"$home/output" 2>&1
}

helper_value() {
  jq -r '.apiKeyHelper // "none"' "$settings"
}

file_mode() {
  stat -c %a "$1" 2>/dev/null || stat -f %Lp "$1"
}

file_identity() {
  stat -c '%i %Y' "$1" 2>/dev/null || stat -f '%i %m' "$1"
}

pass() {
  passed=$((passed + 1))
}

test_api_key_mode_adds_the_helper_and_keeps_other_settings() {
  setup_case
  printf '{"model":"opus","env":{"A":"b"}}\n' >"$settings"
  chmod 640 "$settings"
  run_reconcile api-key || fail "api-key reconcile failed: $(<"$home/output")"
  [[ "$(helper_value)" == "$helper" ]] || fail "api-key mode did not add the helper"
  [[ "$(jq -c 'del(.apiKeyHelper)' "$settings")" == '{"model":"opus","env":{"A":"b"}}' ]] || fail "other settings changed"
  [[ "$(file_mode "$settings")" == 640 ]] || fail "the file mode changed"
  [[ ! -s "$home/output" ]] || fail "api-key reconcile printed output"
  pass
}

test_subscription_mode_removes_only_the_dotfiles_helper() {
  setup_case
  jq -n --arg helper "$helper" '{model:"opus",apiKeyHelper:$helper}' >"$settings"
  run_reconcile subscription || fail "subscription reconcile failed"
  [[ "$(jq -c . "$settings")" == '{"model":"opus"}' ]] || fail "subscription mode kept the helper or lost a setting"
  pass
}

test_subscription_mode_keeps_a_custom_helper_and_warns() {
  setup_case
  printf '{"apiKeyHelper":"custom-helper"}\n' >"$settings"
  run_reconcile subscription || fail "subscription reconcile with a custom helper failed"
  [[ "$(helper_value)" == custom-helper ]] || fail "subscription mode removed a custom helper"
  grep -q 'custom apiKeyHelper' "$home/output" || fail "subscription mode did not warn about the custom helper"
  pass
}

test_api_key_mode_keeps_a_custom_helper() {
  setup_case
  printf '{"apiKeyHelper":"custom-helper"}\n' >"$settings"
  run_reconcile api-key || fail "api-key reconcile with a custom helper failed"
  [[ "$(helper_value)" == custom-helper ]] || fail "api-key mode replaced a custom helper"
  pass
}

test_api_key_mode_without_a_key_removes_the_helper() {
  setup_case
  rm "$home/.zshenv"
  jq -n --arg helper "$helper" '{apiKeyHelper:$helper}' >"$settings"
  run_reconcile api-key || fail "reconcile without a key failed"
  [[ "$(helper_value)" == none ]] || fail "the helper stayed without a key"
  pass
}

test_an_unreadable_mode_leaves_the_file_unchanged() {
  setup_case
  jq -n --arg helper "$helper" '{apiKeyHelper:$helper}' >"$settings"
  local before
  before="$(<"$settings")"
  if run_reconcile subscription 1; then
    fail "reconcile accepted a failed provider-mode"
  fi
  [[ "$(<"$settings")" == "$before" ]] || fail "a failed provider-mode changed the settings"
  grep -q 'unchanged' "$home/output" || fail "a failed provider-mode was not reported"
  pass
}

test_an_unmanaged_instance_keeps_the_api_key_behavior() {
  setup_case
  printf '{}\n' >"$settings"
  run_reconcile '' 2 || fail "reconcile for an unmanaged instance failed"
  [[ "$(helper_value)" == "$helper" ]] || fail "an unmanaged claudeAgent did not keep the helper"
  pass
}

test_a_missing_cli_keeps_the_api_key_behavior() {
  setup_case
  rm "$home/.local/bin/ai-brain"
  run_reconcile || fail "reconcile without the cli failed"
  [[ "$(helper_value)" == "$helper" ]] || fail "reconcile without the cli did not add the helper"
  [[ "$(file_mode "$settings")" == 600 ]] || fail "a new settings file is not private"
  pass
}

test_subscription_mode_creates_no_settings_file() {
  setup_case
  run_reconcile subscription || fail "subscription reconcile without settings failed"
  [[ ! -e "$settings" ]] || fail "subscription mode created a settings file"
  pass
}

test_an_unchanged_file_is_not_rewritten() {
  setup_case
  jq -n --arg helper "$helper" '{apiKeyHelper:$helper}' >"$settings"
  local before
  before="$(file_identity "$settings")"
  sleep 1
  run_reconcile api-key || fail "an unchanged reconcile failed"
  [[ "$(file_identity "$settings")" == "$before" ]] || fail "an unchanged file was rewritten"
  pass
}

test_a_machine_without_claude_code_is_left_alone() {
  setup_case
  rmdir "$home/.claude"
  run_reconcile api-key || fail "reconcile without ~/.claude failed"
  [[ ! -e "$home/.claude" ]] || fail "reconcile created ~/.claude"
  pass
}

test_invalid_json_is_reported_and_kept() {
  setup_case
  printf 'not json\n' >"$settings"
  if run_reconcile subscription; then
    fail "reconcile accepted invalid settings"
  fi
  [[ "$(<"$settings")" == "not json" ]] || fail "invalid settings were replaced"
  pass
}

if [[ $# -gt 0 ]]; then
  "$1"
  exit
fi

test_api_key_mode_adds_the_helper_and_keeps_other_settings
test_subscription_mode_removes_only_the_dotfiles_helper
test_subscription_mode_keeps_a_custom_helper_and_warns
test_api_key_mode_keeps_a_custom_helper
test_api_key_mode_without_a_key_removes_the_helper
test_an_unreadable_mode_leaves_the_file_unchanged
test_an_unmanaged_instance_keeps_the_api_key_behavior
test_a_missing_cli_keeps_the_api_key_behavior
test_subscription_mode_creates_no_settings_file
test_an_unchanged_file_is_not_rewritten
test_a_machine_without_claude_code_is_left_alone
test_invalid_json_is_reported_and_kept
printf 'ok: %s tests passed\n' "$passed"
