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
  'mkdir -p "$4/lib/node_modules/@earendil-works/pi-coding-agent"' \
  'printf '"'"'{"version":"%s"}\n'"'"' "${5##*@}" >"$4/lib/node_modules/@earendil-works/pi-coding-agent/package.json"' \
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
  inode="$(ls -di "$HOME/.local/bin/pi" | awk '{print $1}')"
  log="$(<"$NPM_LOG")"
  install_pi 1.5.2 "$PI_PREFIX_ROOT" "$HOME/.local/bin/pi"
  assert_equal "$(<"$NPM_LOG")" "$log"
  assert_equal "$(readlink "$HOME/.local/bin/pi")" "$target"
  assert_equal "$(ls -di "$HOME/.local/bin/pi" | awk '{print $1}')" "$inode"
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

test_failed_generate_is_not_reported_as_missing() {
  printf '%s\n' '#!/bin/bash' 'exit 7' >"$TEST_ROOT/failing-cli"
  chmod +x "$TEST_ROOT/failing-cli"
  if link_pi "$TEST_ROOT/reconcile" "$TEST_ROOT/failing-cli" 2>"$TEST_ROOT/generate-error"; then
    fail "failed generate returned success"
  fi
  [[ "$(<"$TEST_ROOT/generate-error")" == *"warning: ai-brain generate failed"* ]] || fail "generate failure warning is missing"
  [[ "$(<"$TEST_ROOT/generate-error")" != *"did not run"* ]] || fail "generate failure was reported as skipped"
}

test_version_check_does_not_execute_pi() {
  local log
  log="$(<"$NPM_LOG")"
  printf '%s\n' '#!/bin/bash' 'printf "pi executed\n" >>"$LINK_LOG"' 'exit 1' >"$PI_PREFIX_ROOT/1.5.3/bin/pi"
  : >"$LINK_LOG"
  install_pi 1.5.3 "$PI_PREFIX_ROOT" "$HOME/.local/bin/pi"
  assert_equal "$(<"$LINK_LOG")" ""
  assert_equal "$(<"$NPM_LOG")" "$log"
}

test_replacement_keeps_old_prefix_until_promotion() {
  local prefix="$PI_PREFIX_ROOT/1.5.3"
  printf '{"version":"0.0.0"}\n' >"$prefix/lib/node_modules/@earendil-works/pi-coding-agent/package.json"
  printf 'keep until promotion\n' >"$prefix/old-marker"
  mv() {
    if [[ "$1" == "$prefix.tmp" ]]; then
      [[ -f "$prefix.old/old-marker" ]] || fail "old prefix was deleted before promotion"
    fi
    command mv "$@"
  }
  install_pi 1.5.3 "$PI_PREFIX_ROOT" "$HOME/.local/bin/pi"
  unset -f mv
  [[ ! -e "$prefix.old" && ! -e "$prefix.tmp" ]] || fail "replacement left temporary prefixes"
  assert_equal "$("$HOME/.local/bin/pi" --version)" "1.5.3"
}

test_missing_npm_has_clear_error() {
  command() {
    if [[ "$1" == -v && "$2" == npm ]]; then return 1; fi
    builtin command "$@"
  }
  if install_pi 9.9.9 "$PI_PREFIX_ROOT" "$HOME/.local/bin/pi" 2>"$TEST_ROOT/npm-error"; then
    fail "missing npm returned success"
  fi
  unset -f command
  [[ "$(<"$TEST_ROOT/npm-error")" == *"pi.sh: npm is required"* ]] || fail "missing npm diagnostic is missing"
}

test_first_install_links_versioned_binary
test_second_install_keeps_link_inode
test_pin_change_keeps_old_prefix
test_malformed_pin_is_rejected
test_link_runs_reconciler_before_generate
test_missing_cli_warns_after_reconcile
test_failed_generate_is_not_reported_as_missing
test_version_check_does_not_execute_pi
test_replacement_keeps_old_prefix_until_promotion
test_missing_npm_has_clear_error
printf '10 tests passed\n'
