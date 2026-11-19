#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INSTALLER="$SCRIPT_DIR/../pi.sh"
TEST_ROOT="$(mktemp -d /tmp/opencode/pi-installer-test.XXXXXX)"
trap 'rm -rf "$TEST_ROOT"' EXIT

fail() { printf 'fail: %s\n' "$1" >&2; exit 1; }
assert_equal() { [[ "$1" == "$2" ]] || fail "expected '$2', got '$1'"; }

mkdir -p "$TEST_ROOT/home" "$TEST_ROOT/bin"
ln -s "$(node -p 'process.execPath')" "$TEST_ROOT/bin/node"
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
  'printf '"'"'#!/usr/bin/env node\nif (process.argv[2] === "--echo") console.log(JSON.stringify(process.argv.slice(3))); else if (process.argv[2] === "--child-node") console.log(require("node:child_process").execFileSync("node", ["-p", "42"], {encoding:"utf8"}).trim()); else console.log("%s");\n'"'"' "${5##*@}" >"$4/bin/pi"' \
  'chmod +x "$4/bin/pi"' >"$TEST_ROOT/bin/npm"
chmod +x "$TEST_ROOT/bin/npm"

[[ -f "$INSTALLER" ]] || fail "pi installer is missing"
source "$INSTALLER"

test_first_install_links_versioned_binary() {
  install_pi 1.5.2 "$PI_PREFIX_ROOT" "$HOME/.local/bin/pi"
  assert_equal "$(<"$NPM_LOG")" "install -g --prefix $PI_PREFIX_ROOT/1.5.2.tmp @earendil-works/pi-coding-agent@1.5.2"
  assert_equal "$(readlink "$HOME/.local/bin/pi")" "$PI_PREFIX_ROOT/1.5.2/bin/pi-launcher"
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
  assert_equal "$(readlink "$HOME/.local/bin/pi")" "$PI_PREFIX_ROOT/1.5.3/bin/pi-launcher"
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
      [[ -x "$prefix.tmp/bin/pi-launcher" ]] || fail "launcher was not staged before promotion"
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

test_launcher_uses_node_without_shell_initialization() {
  local minimal="$TEST_ROOT/minimal-bin"
  mkdir -p "$minimal"
  PATH="$minimal" "$HOME/.local/bin/pi" --version >"$TEST_ROOT/launcher-output"
  assert_equal "$(<"$TEST_ROOT/launcher-output")" "1.5.3"
}

test_launcher_preserves_arguments() {
  assert_equal "$("$HOME/.local/bin/pi" --echo "space arg" "'quoted'" '$literal')" \
    '["space arg","'"'quoted'"'","$literal"]'
}

test_launcher_makes_node_available_to_children() {
  PATH="$TEST_ROOT/minimal-bin" "$HOME/.local/bin/pi" --child-node >"$TEST_ROOT/child-output"
  assert_equal "$(<"$TEST_ROOT/child-output")" "42"
}

test_launcher_preserves_existing_node_path_priority() (
  mkdir -p "$TEST_ROOT/other-node"
  printf '#!/bin/bash\nprintf "other-node\\n"\n' >"$TEST_ROOT/other-node/node"
  chmod +x "$TEST_ROOT/other-node/node"
  assert_equal "$(PATH="$TEST_ROOT/other-node" "$HOME/.local/bin/pi" --child-node)" "other-node"
)

test_launcher_does_not_add_an_empty_path_entry() (
  printf '#!/bin/bash\nprintf "%%s\\n" "$PATH"\n' >"$TEST_ROOT/path-probe"
  chmod +x "$TEST_ROOT/path-probe"
  write_pi_launcher "$TEST_ROOT/path-launcher" "$TEST_ROOT/path-probe" /bin/bash
  assert_equal "$(PATH="" "$TEST_ROOT/path-launcher")" /bin
)

test_launcher_falls_back_when_pinned_node_is_removed() (
  mkdir -p "$TEST_ROOT/removable-node"
  ln -s "$TEST_ROOT/bin/node" "$TEST_ROOT/removable-node/node"
  PATH="$TEST_ROOT/removable-node:$PATH" install_pi 1.5.3 "$PI_PREFIX_ROOT" "$HOME/.local/bin/pi"
  rm "$TEST_ROOT/removable-node/node"
  assert_equal "$("$HOME/.local/bin/pi" --version)" "1.5.3"
  local result=0
  PATH="" "$HOME/.local/bin/pi" 2>"$TEST_ROOT/missing-pinned-error" || result=$?
  assert_equal "$result" 127
  assert_equal "$(<"$TEST_ROOT/missing-pinned-error")" \
    "pi: pinned node $TEST_ROOT/removable-node/node is missing; rerun ~/dotfiles/programs/pi.sh"
  install_pi 1.5.3 "$PI_PREFIX_ROOT" "$HOME/.local/bin/pi"
)

test_existing_install_does_not_require_npm() (
  command() {
    if [[ "$1" == -v && "$2" == npm ]]; then return 1; fi
    builtin command "$@"
  }
  source() { fail "nvm was sourced despite node being on PATH"; }
  install_pi 1.5.3 "$PI_PREFIX_ROOT" "$HOME/.local/bin/pi"
)

test_refresh_repairs_an_existing_launcher_without_installing() (
  local log
  log="$(<"$NPM_LOG")"
  printf '#!/bin/bash\nexit 99\n' >"$PI_PREFIX_ROOT/1.5.3/bin/pi-launcher"
  /bin/bash "$INSTALLER" --refresh-launcher
  assert_equal "$("$HOME/.local/bin/pi" --version)" "1.5.3"
  assert_equal "$(<"$NPM_LOG")" "$log"
)

test_refresh_skips_an_absent_pi_installation() (
  export HOME="$TEST_ROOT/empty-home"
  /bin/bash "$INSTALLER" --refresh-launcher
  [[ ! -e "$HOME/.local/bin/pi" ]] || fail "refresh installed pi"
)

test_refresh_keeps_pinned_node_despite_a_different_nvm_default() (
  local minimal="$TEST_ROOT/refresh-bin" tool
  mkdir -p "$minimal" "$HOME/.nvm/bin"
  for tool in dirname readlink cmp chmod mv ln; do
    ln -s "$(command -v "$tool")" "$minimal/$tool"
  done
  printf '#!/bin/bash\nprintf "node B\\n"\n' >"$HOME/.nvm/bin/node"
  chmod +x "$HOME/.nvm/bin/node"
  printf '%s\n' 'nvm() { export PATH="$NVM_DIR/bin:$PATH"; }' >"$HOME/.nvm/nvm.sh"
  PATH="$minimal" /bin/bash "$INSTALLER" --refresh-launcher
  assert_equal "$(PATH="$minimal" "$HOME/.local/bin/pi" --version)" "1.5.3"
  assert_equal "$(<"$PI_PREFIX_ROOT/1.5.3/bin/.pi-node")" "$TEST_ROOT/bin/node"
  rm -rf "$HOME/.nvm"
)

test_refresh_without_any_node_warns_and_keeps_the_launcher() (
  local minimal="$TEST_ROOT/no-node-bin" tool before
  mkdir -p "$minimal"
  for tool in dirname readlink; do
    ln -s "$(command -v "$tool")" "$minimal/$tool"
  done
  rm -f "$PI_PREFIX_ROOT/1.5.3/bin/.pi-node"
  before="$(<"$PI_PREFIX_ROOT/1.5.3/bin/pi-launcher")"
  if ! PATH="$minimal" /bin/bash "$INSTALLER" --refresh-launcher 2>"$TEST_ROOT/refresh-warning"; then
    fail "refresh without node failed"
  fi
  [[ "$(<"$TEST_ROOT/refresh-warning")" == *"warning: pi launcher refresh skipped"* ]] || fail "refresh warning is missing"
  [[ "$(<"$TEST_ROOT/refresh-warning")" != *"install pi"* ]] || fail "refresh printed an install diagnostic"
  assert_equal "$(<"$PI_PREFIX_ROOT/1.5.3/bin/pi-launcher")" "$before"
)

test_refresh_recovers_missing_or_stale_node_sidecar() (
  local pinned
  for pinned in "" "$TEST_ROOT/missing-node"; do
    rm -f "$PI_PREFIX_ROOT/1.5.3/bin/.pi-node"
    if [[ -n "$pinned" ]]; then
      printf '%s\n' "$pinned" >"$PI_PREFIX_ROOT/1.5.3/bin/.pi-node"
    fi
    /bin/bash "$INSTALLER" --refresh-launcher
    assert_equal "$(<"$PI_PREFIX_ROOT/1.5.3/bin/.pi-node")" "$TEST_ROOT/bin/node"
    assert_equal "$("$HOME/.local/bin/pi" --version)" "1.5.3"
  done
)

test_existing_node_does_not_source_nvm() (
  source() { fail "nvm was sourced despite node and npm being on PATH"; }
  install_pi 1.5.3 "$PI_PREFIX_ROOT" "$HOME/.local/bin/pi"
)

test_missing_node_has_clear_error() (
  command() {
    if [[ "$1" == -v && "$2" == node ]]; then return 1; fi
    builtin command "$@"
  }
  if install_pi 9.9.9 "$PI_PREFIX_ROOT" "$HOME/.local/bin/pi" 2>"$TEST_ROOT/node-error"; then
    fail "missing node returned success"
  fi
  [[ "$(<"$TEST_ROOT/node-error")" == *"pi.sh: node is required"* ]] || fail "missing node diagnostic is missing"
)

test_install_loads_nvm_when_node_is_not_on_path() (
  local minimal="$TEST_ROOT/minimal-bin" tool
  mkdir -p "$HOME/.nvm/bin" "$minimal"
  ln -s "$(command -v node)" "$HOME/.nvm/bin/node"
  cp "$TEST_ROOT/bin/npm" "$HOME/.nvm/bin/npm"
  for tool in dirname mkdir rm mv ln readlink chmod cmp; do
    ln -sf "$(command -v "$tool")" "$minimal/$tool"
  done
  printf '%s\n' \
    ': "${NVM_TEST_UNSET}"' \
    'nvm() {' \
    '  [[ "$*" == "use default" ]] || return 1' \
    '  export PATH="$NVM_DIR/bin:$PATH"' \
    '}' >"$HOME/.nvm/nvm.sh"
  unset NVM_TEST_UNSET
  export PATH="$minimal"
  /bin/bash -c 'source "$1"; install_pi 1.5.4 "$2" "$3"' \
    bash "$INSTALLER" "$PI_PREFIX_ROOT" "$HOME/.local/bin/pi"
  "$HOME/.local/bin/pi" --version >"$TEST_ROOT/nvm-output"
  assert_equal "$(<"$TEST_ROOT/nvm-output")" "1.5.4"
)

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
test_launcher_uses_node_without_shell_initialization
test_launcher_preserves_arguments
test_launcher_makes_node_available_to_children
test_launcher_preserves_existing_node_path_priority
test_launcher_does_not_add_an_empty_path_entry
test_launcher_falls_back_when_pinned_node_is_removed
test_existing_install_does_not_require_npm
test_refresh_repairs_an_existing_launcher_without_installing
test_refresh_skips_an_absent_pi_installation
test_refresh_keeps_pinned_node_despite_a_different_nvm_default
test_refresh_without_any_node_warns_and_keeps_the_launcher
test_refresh_recovers_missing_or_stale_node_sidecar
test_existing_node_does_not_source_nvm
test_missing_node_has_clear_error
test_install_loads_nvm_when_node_is_not_on_path
printf '25 tests passed\n'
