#!/bin/bash

set -euo pipefail

repo="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
root="$(mktemp -d "${TMPDIR:-/tmp}/claude-code-test.XXXXXX")"
trap 'rm -rf "$root"' EXIT
helper='zsh ${HOME}/dotfiles/dependencies/claude-api-key.zsh'

fail() {
  printf 'fail: %s\n' "$1" >&2
  exit 1
}

setup_case() {
  home="$(mktemp -d "$root/home.XXXXXX")"
  mkdir -p "$home/dotfiles/configs/claude" "$home/dotfiles/dependencies" "$home/.local/bin" "$home/.claude" "$home/stubs"
  cp "$repo/configs/claude/settings.json" "$home/dotfiles/configs/claude/settings.json"
  cp "$repo/dependencies/reconcile-claude-api-key-helper.bash" "$home/dotfiles/dependencies/"
  printf '#!/bin/bash\nexit 0\n' >"$home/stubs/curl"
  printf '#!/bin/bash\n[[ "$*" == "secrets provider-mode claudeAgent" ]] || exit 99\nprintf "%%s\\n" "$STUB_MODE"\n' >"$home/.local/bin/ai-brain"
  chmod +x "$home/stubs/curl" "$home/.local/bin/ai-brain"
  printf "export ANTHROPIC_API_KEY='fixture-not-a-key'\n" >"$home/.zshenv"
  jq -n --arg helper "$helper" '{apiKeyHelper:$helper,theme:"dark"}' >"$home/.claude/settings.json"
}

run_program() {
  local program
  program="$(<"$repo/programs/claude-code.sh")"
  program="${program//\$UID/\$TEST_UID}"
  env -i HOME="$home" TEST_UID=1000 STUB_MODE="$1" PATH="$home/stubs:/usr/bin:/bin" /bin/bash -c "$program" \
    >"$home/output" 2>&1 || fail "claude-code.sh failed: $(<"$home/output")"
}

test_subscription_mode_drops_the_helper_and_merges_the_dotfiles_settings() {
  setup_case
  run_program subscription
  local settings="$home/.claude/settings.json"
  [[ "$(jq -r '.apiKeyHelper // "none"' "$settings")" == none ]] || fail "subscription mode kept the helper"
  [[ "$(jq -r .theme "$settings")" == dark ]] || fail "a local setting was lost"
  [[ "$(jq -r .model "$settings")" == "$(jq -r .model "$repo/configs/claude/settings.json")" ]] ||
    fail "the dotfiles settings were not merged"
}

test_api_key_mode_keeps_the_helper() {
  setup_case
  run_program api-key
  [[ "$(jq -r '.apiKeyHelper // "none"' "$home/.claude/settings.json")" == "$helper" ]] || fail "api-key mode dropped the helper"
}

if [[ $# -gt 0 ]]; then
  "$1"
  exit
fi

test_subscription_mode_drops_the_helper_and_merges_the_dotfiles_settings
test_api_key_mode_keeps_the_helper
printf 'ok: 2 tests passed\n'
