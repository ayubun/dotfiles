#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INSTALLER="$SCRIPT_DIR/../pi.sh"
TEST_ROOT="$(mktemp -d /tmp/opencode/pi-installer-test.XXXXXX)"
trap 'rm -rf "$TEST_ROOT"' EXIT

fail() { printf 'fail: %s\n' "$1" >&2; exit 1; }
assert_equal() { [[ "$1" == "$2" ]] || fail "expected '$2', got '$1'"; }

mkdir -p "$TEST_ROOT/home" "$TEST_ROOT/bin"
export HOME="$TEST_ROOT/home"
export PI_PREFIX_ROOT="$TEST_ROOT/prefix"
export NPM_LOG="$TEST_ROOT/npm.log"
export LINK_LOG="$TEST_ROOT/link.log"
export PATH="$TEST_ROOT/bin:$PATH"
printf '%s\n' '#!/bin/bash' 'set -euo pipefail' \
  'printf "%s\n" "$*" >>"$NPM_LOG"' \
  '[[ "$1" == install && "$2" == -g && "$3" == --prefix ]]' \
  'mkdir -p "$4/bin"' \
  'printf '"'"'#!/bin/bash\nprintf "%%s\\n" "%s"\n'"'"' "${5##*@}" >"$4/bin/pi"' \
  'chmod +x "$4/bin/pi"' >"$TEST_ROOT/bin/npm"
chmod +x "$TEST_ROOT/bin/npm"

[[ -f "$INSTALLER" ]] || fail "pi installer is missing"
source "$INSTALLER"

test_first_install_links_versioned_binary() {
  install_pi 1.5.2 "$PI_PREFIX_ROOT" "$HOME/.local/bin/pi"
  assert_equal "$(<"$NPM_LOG")" "install -g --prefix $PI_PREFIX_ROOT/1.5.2.tmp @earendil-works/pi-coding-agent@1.5.2"
  assert_equal "$(readlink "$HOME/.local/bin/pi")" "$PI_PREFIX_ROOT/1.5.2/bin/pi"
  assert_equal "$("$HOME/.local/bin/pi" --version)" "1.5.2"
}

test_second_install_keeps_link_inode() {
  local target inode log
  target="$(readlink "$HOME/.local/bin/pi")"
  inode="$(stat -c %i "$HOME/.local/bin/pi")"
  log="$(<"$NPM_LOG")"
  install_pi 1.5.2 "$PI_PREFIX_ROOT" "$HOME/.local/bin/pi"
  assert_equal "$(<"$NPM_LOG")" "$log"
  assert_equal "$(readlink "$HOME/.local/bin/pi")" "$target"
  assert_equal "$(stat -c %i "$HOME/.local/bin/pi")" "$inode"
}

test_pin_change_keeps_old_prefix() {
  local pin="$TEST_ROOT/pi-version"
  printf '1.5.3\n' >"$pin"
  install_pi "$(pi_pinned_version "$pin")" "$PI_PREFIX_ROOT" "$HOME/.local/bin/pi"
  assert_equal "$(readlink "$HOME/.local/bin/pi")" "$PI_PREFIX_ROOT/1.5.3/bin/pi"
  assert_equal "$("$PI_PREFIX_ROOT/1.5.2/bin/pi" --version)" "1.5.2"
  assert_equal "$("$HOME/.local/bin/pi" --version)" "1.5.3"
  assert_equal "$(wc -l <"$NPM_LOG" | tr -d ' ')" "2"
}

test_malformed_pin_is_rejected() {
  printf '../1.5.2\n' >"$TEST_ROOT/bad-pin"
  if pi_pinned_version "$TEST_ROOT/bad-pin" 2>"$TEST_ROOT/pin-error"; then
    fail "malformed pin was accepted"
  fi
  [[ "$(<"$TEST_ROOT/pin-error")" == *"bad pin"* ]] || fail "bad pin diagnostic is missing"
}

test_link_runs_reconciler_before_generate() {
  printf '%s\n' '#!/bin/bash' 'printf "reconcile:%s\n" "$*" >>"$LINK_LOG"' >"$TEST_ROOT/reconcile"
  printf '%s\n' '#!/bin/bash' 'printf "cli:%s\n" "$*" >>"$LINK_LOG"' >"$TEST_ROOT/ai-brain"
  chmod +x "$TEST_ROOT/ai-brain"
  link_pi "$TEST_ROOT/reconcile" "$TEST_ROOT/ai-brain"
  assert_equal "$(<"$LINK_LOG")" $'reconcile:\ncli:generate'
}

test_missing_cli_warns_after_reconcile() {
  : >"$LINK_LOG"
  link_pi "$TEST_ROOT/reconcile" "$TEST_ROOT/missing" 2>"$TEST_ROOT/warning"
  assert_equal "$(<"$LINK_LOG")" "reconcile:"
  [[ "$(<"$TEST_ROOT/warning")" == *"warning: ai-brain generate did not run"* ]] || fail "missing cli warning is missing"
}

test_first_install_links_versioned_binary
test_second_install_keeps_link_inode
test_pin_change_keeps_old_prefix
test_malformed_pin_is_rejected
test_link_runs_reconciler_before_generate
test_missing_cli_warns_after_reconcile
printf '6 tests passed\n'
