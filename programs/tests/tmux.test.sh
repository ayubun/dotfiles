#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INSTALLER="$SCRIPT_DIR/../tmux.sh"
TEST_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/tmux-installer-test.XXXXXX")"

trap 'rm -rf "$TEST_ROOT"' EXIT

fail() {
  printf 'fail: %s\n' "$1" >&2
  exit 1
}

assert_equal() {
  [[ "$1" == "$2" ]] || fail "expected '$2', got '$1'"
}

write_tmux_binary() {
  local path="$1"
  local version="$2"

  printf '#!/bin/sh\nprintf "tmux %s\\n"\n' "$version" >"$path"
  chmod +x "$path"
}

test_versioned_install_preserves_rollback_binary() {
  local build_dir="$TEST_ROOT/build"
  local install_dir="$TEST_ROOT/install"
  local current_binary="$TEST_ROOT/tmux-current"

  mkdir -p "$build_dir" "$install_dir"
  write_tmux_binary "$build_dir/tmux" "3.7b"
  write_tmux_binary "$current_binary" "3.5a"

  grep -q '^install_tmux_binary()' "$INSTALLER" || fail "installer has no testable install function"
  # shellcheck source=programs/tmux.sh
  source "$INSTALLER"
  install_tmux_binary "$build_dir/tmux" "$install_dir" "3.7b" "$current_binary"

  [[ -L "$install_dir/tmux" ]] || fail "tmux entry point is not a symlink"
  assert_equal "$(readlink "$install_dir/tmux")" "tmux-3.7b"
  assert_equal "$("$install_dir/tmux" -V)" "tmux 3.7b"
  assert_equal "$("$install_dir/tmux-3.5a" -V)" "tmux 3.5a"
}

test_existing_versioned_binary_restores_entry_point() {
  local build_dir="$TEST_ROOT/restore-build"
  local install_dir="$TEST_ROOT/restore-install"

  mkdir -p "$build_dir" "$install_dir"
  write_tmux_binary "$build_dir/tmux" "3.7b"
  write_tmux_binary "$install_dir/tmux-3.5a" "3.5a"

  install_tmux_binary "$build_dir/tmux" "$install_dir" "3.7b" "$install_dir/tmux-3.5a"

  assert_equal "$(readlink "$install_dir/tmux")" "tmux-3.7b"
  assert_equal "$("$install_dir/tmux-3.5a" -V)" "tmux 3.5a"
}

test_rerun_repoints_entry_point() {
  local build_dir="$TEST_ROOT/rerun-build"
  local install_dir="$TEST_ROOT/rerun-install"
  local current_binary="$TEST_ROOT/rerun-current"

  mkdir -p "$build_dir" "$install_dir"
  write_tmux_binary "$current_binary" "3.5a"
  write_tmux_binary "$build_dir/tmux" "3.7b"
  install_tmux_binary "$build_dir/tmux" "$install_dir" "3.7b" "$current_binary"

  write_tmux_binary "$build_dir/tmux" "3.6b"
  install_tmux_binary "$build_dir/tmux" "$install_dir" "3.6b" "$install_dir/tmux-3.7b"

  assert_equal "$(readlink "$install_dir/tmux")" "tmux-3.6b"
  assert_equal "$("$install_dir/tmux-3.5a" -V)" "tmux 3.5a"
  assert_equal "$("$install_dir/tmux-3.7b" -V)" "tmux 3.7b"
}

test_invalid_version_is_rejected() {
  local build_dir="$TEST_ROOT/invalid-build"
  local install_dir="$TEST_ROOT/invalid-install"

  mkdir -p "$build_dir" "$install_dir"
  write_tmux_binary "$build_dir/tmux" "3.7b"

  if install_tmux_binary "$build_dir/tmux" "$install_dir" "../3.7b" 2>/dev/null; then
    fail "invalid tmux version was accepted"
  fi
}

test_versioned_install_preserves_rollback_binary
test_existing_versioned_binary_restores_entry_point
test_rerun_repoints_entry_point
test_invalid_version_is_rejected

printf 'ok\n'
