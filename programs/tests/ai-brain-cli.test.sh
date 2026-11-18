#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HELPER="$SCRIPT_DIR/../../dependencies/ai-brain-cli.bash"
TEST_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/ai-brain-cli-test.XXXXXX")"

trap 'rm -rf "$TEST_ROOT"' EXIT

fail() {
  printf 'fail: %s\n' "$1" >&2
  exit 1
}

assert_equal() {
  [[ "$1" == "$2" ]] || fail "expected '$2', got '$1'"
}

setup_case() {
  case_dir="$(mktemp -d "$TEST_ROOT/case.XXXXXX")"
  home="$case_dir/home"
  repo="$case_dir/repo"
  stubs="$case_dir/stubs"
  cargo_log="$case_dir/cargo.log"
  curl_log="$case_dir/curl.log"
  stamp="$home/.local/state/ai-brain/cli-source.hash"
  failed_stamp="$home/.local/state/ai-brain/cli-source.failed"
  mkdir -p "$home" "$repo/tools/cli/src" "$stubs"
  printf '[workspace]\n' >"$repo/tools/cli/Cargo.toml"
  printf 'fn main() {}\n' >"$repo/tools/cli/src/main.rs"
  : >"$cargo_log"
  : >"$curl_log"
  cat >"$stubs/cargo" <<'STUB'
#!/bin/bash
set -euo pipefail
printf '%s\n' "$*" >>"$CARGO_LOG"
manifest=""
offline=false
while [[ $# -gt 0 ]]; do
  case "$1" in
    --manifest-path) manifest="$2"; shift ;;
    --offline) offline=true ;;
  esac
  shift
done
case "${CARGO_BEHAVIOR:-success}" in
  fail) exit 1 ;;
  online-only) "$offline" && exit 1 ;;
esac
[[ -n "$manifest" ]] || exit 2
mkdir -p "${manifest%/*}/target/release"
printf '#!/bin/sh\nprintf "fixture ai-brain\\n"\n' >"${manifest%/*}/target/release/ai-brain"
chmod +x "${manifest%/*}/target/release/ai-brain"
STUB
  cat >"$stubs/curl" <<'STUB'
#!/bin/bash
set -euo pipefail
printf '%s\n' "$*" >>"$CURL_LOG"
[[ "${RUSTUP_BEHAVIOR:-blocked}" == install ]] || exit 99
cat <<'INSTALL'
set -eu
mkdir -p "$HOME/.cargo/bin"
cp "$CARGO_FIXTURE" "$HOME/.cargo/bin/cargo"
printf 'export PATH="$HOME/.cargo/bin:$PATH"\n' >"$HOME/.cargo/env"
INSTALL
STUB
  # Keep host-wide Nix profiles out of tests that simulate a fresh machine.
  cat >"$case_dir/bash-env" <<'STUB'
source() {
  case "$1" in
    "$HOME"/*) builtin source "$@" ;;
    *) return 0 ;;
  esac
}
STUB
  chmod +x "$stubs/cargo" "$stubs/curl"
  cargo_behavior=success
  rustup_behavior=blocked
  os_type=darwin24
}

run_helper() {
  env -i HOME="$home" AI_BRAIN_REPO="$repo" PATH="$stubs:/usr/bin:/bin" \
    AI_BRAIN_CLI_OSTYPE="$os_type" BASH_ENV="$case_dir/bash-env" \
    CARGO_LOG="$cargo_log" CURL_LOG="$curl_log" CARGO_BEHAVIOR="$cargo_behavior" \
    RUSTUP_BEHAVIOR="$rustup_behavior" CARGO_FIXTURE="$case_dir/cargo-fixture" \
    /bin/bash "$HELPER" "$@"
}

cargo_calls() {
  local count
  count="$(wc -l <"$cargo_log")"
  printf '%s\n' "$((count))"
}

test_first_build_installs_binary_and_stamp() {
  setup_case
  run_helper build
  assert_equal "$(cargo_calls)" 1
  [[ -x "$home/.local/bin/ai-brain" ]] || fail "binary was not installed"
  assert_equal "$("$home/.local/bin/ai-brain")" "fixture ai-brain"
  [[ -s "$stamp" ]] || fail "source stamp was not written"
}

test_unchanged_source_skips_build() {
  setup_case
  run_helper build
  run_helper build
  assert_equal "$(cargo_calls)" 1
}

test_source_change_rebuilds() {
  setup_case
  run_helper build
  printf 'fn main() { println!("changed"); }\n' >"$repo/tools/cli/src/main.rs"
  run_helper build
  assert_equal "$(cargo_calls)" 2
}

test_target_dir_changes_do_not_rebuild() {
  setup_case
  run_helper build
  printf 'build artifact\n' >"$repo/tools/cli/target/new-artifact"
  run_helper build
  assert_equal "$(cargo_calls)" 1
}

test_missing_binary_rebuilds() {
  setup_case
  run_helper build
  rm "$home/.local/bin/ai-brain"
  run_helper build
  assert_equal "$(cargo_calls)" 2
}

test_offline_failure_falls_back_to_online_build() {
  setup_case
  cargo_behavior=online-only
  run_helper build
  assert_equal "$(cargo_calls)" 2
  [[ -x "$home/.local/bin/ai-brain" ]] || fail "online fallback did not install the binary"
  local first second
  {
    IFS= read -r first
    IFS= read -r second
  } <"$cargo_log"
  [[ "$first" == *" --offline "* ]] || fail "first build was not offline"
  [[ "$second" != *" --offline "* ]] || fail "fallback build was offline"
}

test_failed_build_keeps_stamp() {
  setup_case
  run_helper build
  local previous
  previous="$(<"$stamp")"
  printf 'changed\n' >>"$repo/tools/cli/src/main.rs"
  cargo_behavior=fail
  if run_helper build >"$case_dir/output" 2>&1; then
    fail "failed cargo build reported success"
  fi
  assert_equal "$(cargo_calls)" 3
  assert_equal "$(<"$stamp")" "$previous"
  assert_equal "$("$home/.local/bin/ai-brain")" "fixture ai-brain"
}

test_unchanged_failed_source_skips_build() {
  setup_case
  cargo_behavior=fail
  if run_helper build >"$case_dir/output" 2>&1; then
    fail "failed cargo build reported success"
  fi
  assert_equal "$(cargo_calls)" 2
  if run_helper build >"$case_dir/output" 2>&1; then
    fail "unchanged failed source reported success"
  fi
  assert_equal "$(cargo_calls)" 2
  [[ -s "$failed_stamp" ]] || fail "failed source stamp was not written"
}

test_source_change_after_failure_rebuilds() {
  setup_case
  cargo_behavior=fail
  if run_helper build >"$case_dir/output" 2>&1; then
    fail "failed cargo build reported success"
  fi
  [[ -s "$failed_stamp" ]] || fail "failed source stamp was not written"
  printf 'changed\n' >>"$repo/tools/cli/src/main.rs"
  cargo_behavior=success
  run_helper build
  assert_equal "$(cargo_calls)" 3
  [[ -x "$home/.local/bin/ai-brain" ]] || fail "changed source did not install the binary"
}

test_old_failed_source_retries_build() {
  setup_case
  cargo_behavior=fail
  if run_helper build >"$case_dir/output" 2>&1; then
    fail "failed cargo build reported success"
  fi
  touch -t 200001010000 "$failed_stamp"
  cargo_behavior=success
  run_helper build
  assert_equal "$(cargo_calls)" 3
  [[ -x "$home/.local/bin/ai-brain" ]] || fail "expired failed source did not install the binary"
  [[ ! -e "$failed_stamp" ]] || fail "successful retry kept the failed source stamp"
}

test_ensure_retries_an_unchanged_failed_source() {
  setup_case
  cargo_behavior=fail
  if run_helper build >"$case_dir/output" 2>&1; then
    fail "failed cargo build reported success"
  fi
  cargo_behavior=success
  run_helper ensure
  assert_equal "$(cargo_calls)" 3
  [[ -x "$home/.local/bin/ai-brain" ]] || fail "ensure did not install the binary after a failed build"
  [[ ! -e "$failed_stamp" ]] || fail "ensure kept the failed source stamp"
}

test_success_removes_failed_stamp() {
  setup_case
  mkdir -p "${failed_stamp%/*}"
  printf 'older failed source\n' >"$failed_stamp"
  run_helper build
  [[ ! -e "$failed_stamp" ]] || fail "successful build kept the failed source stamp"
  [[ -s "$stamp" ]] || fail "successful build did not write the source stamp"
}

test_work_devbox_without_cargo_does_not_install_rustup() {
  setup_case
  mkdir -p "$home/work"
  touch "$home/work/.zshrc_aliases"
  os_type=linux-gnu
  rm "$stubs/cargo"
  if run_helper ensure >"$case_dir/output" 2>&1; then
    fail "work devbox without cargo reported success"
  fi
  [[ ! -s "$curl_log" ]] || fail "work devbox tried to install rustup"
  [[ ! -e "$stamp" ]] || fail "work devbox wrote a build stamp without cargo"
}

test_non_work_machine_without_cargo_installs_rustup() {
  setup_case
  mv "$stubs/cargo" "$case_dir/cargo-fixture"
  rustup_behavior=install
  run_helper ensure
  assert_equal "$(cargo_calls)" 1
  local count
  count="$(wc -l <"$curl_log")"
  assert_equal "$((count))" 1
  [[ -x "$home/.local/bin/ai-brain" ]] || fail "rustup stub did not lead to an installed binary"
}

test_first_build_installs_binary_and_stamp
test_unchanged_source_skips_build
test_source_change_rebuilds
test_target_dir_changes_do_not_rebuild
test_missing_binary_rebuilds
test_offline_failure_falls_back_to_online_build
test_failed_build_keeps_stamp
test_unchanged_failed_source_skips_build
test_source_change_after_failure_rebuilds
test_old_failed_source_retries_build
test_ensure_retries_an_unchanged_failed_source
test_success_removes_failed_stamp
test_work_devbox_without_cargo_does_not_install_rustup
test_non_work_machine_without_cargo_installs_rustup

printf 'ok: 14 tests passed\n'
