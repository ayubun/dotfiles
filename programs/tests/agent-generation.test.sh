#!/bin/bash

set -euo pipefail

repo="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
root="$(mktemp -d "${TMPDIR:-/tmp}/agent-generation-test.XXXXXX")"
trap 'rm -rf "$root"' EXIT

fail() {
  printf 'fail: %s\n' "$1" >&2
  exit 1
}

setup_case() {
  home="$(mktemp -d "$root/home.XXXXXX")"
  mkdir -p "$home/dotfiles/dependencies" "$home/ai-brain/.git" "$home/ai-brain-discord/.git" "$home/.local/bin" "$home/stubs"
  log="$home/calls"
  : >"$log"
  printf '#!/bin/bash\nprintf "build\\n" >>"$CALLS"\n' >"$home/dotfiles/dependencies/ai-brain-cli.bash"
  printf '#!/bin/bash\nprintf "reconcile\\n" >>"$CALLS"\n' >"$home/dotfiles/dependencies/reconcile-opencode-links.bash"
  cp "$repo/dependencies/opencode-install.bash" "$home/dotfiles/dependencies/opencode-install.bash"
  mkdir -p "$home/ai-brain/adapters/opencode"
  printf '{}\n' >"$home/ai-brain/adapters/opencode/opencode.jsonc"
}

install_cli_stub() {
  printf '#!/bin/bash\nprintf "%%s %%s\\n" "${RUN_AS:-direct}" "$*" >>"$CALLS"\n' >"$home/.local/bin/ai-brain"
  chmod +x "$home/.local/bin/ai-brain"
}

run_program() {
  env -i HOME="$home" USER=fixture ORIGINAL_USER=fixture TEST_UID="${test_uid:-0}" CALLS="$log" \
    PATH="$home/stubs:/usr/bin:/bin" /bin/bash -c "$program"
}

prepare_opencode_program() {
  setup_case
  install_cli_stub
  printf 'opencode_latest_v2_version() { echo 2.3.0; }\nopencode_version_lt() { return 1; }\nopencode_installed_version() { echo 2.3.0; }\n' \
    >>"$home/dotfiles/dependencies/opencode-install.bash"
  printf '#!/bin/bash\nif [[ "$1" == chown ]]; then exit 0; fi\n[[ "$1" == -u && "$2" == fixture && "$3" == -H ]] || exit 99\nshift 3\nRUN_AS=fixture "$@"\n' >"$home/stubs/sudo"
  for command in curl zsh; do
    printf '#!/bin/bash\nexit 0\n' >"$home/stubs/$command"
    chmod +x "$home/stubs/$command"
  done
  printf '#!/bin/bash\nexit 0\n' >"$home/.local/bin/ocx"
  chmod +x "$home/stubs/sudo" "$home/.local/bin/ocx"
  program="$(<"$repo/programs/opencode.sh")"
  program="${program//\$UID/\$TEST_UID}"
}

test_opencode_generates_as_the_original_user() {
  prepare_opencode_program
  run_program
  [[ "$(<"$log")" == "$(printf 'reconcile\nfixture generate')" ]] || fail "opencode did not generate as the original user"
}

prepare_ai_brain_program() {
  setup_case
  printf '#!/bin/bash\nexit 0\n' >"$home/stubs/git"
  chmod +x "$home/stubs/git"
  program="$(<"$repo/programs/ai-brain.sh")"
  program="${program//\$UID/\$TEST_UID}"
}

test_install_skips_generation_without_a_binary() {
  prepare_ai_brain_program
  test_uid=1000 run_program >"$home/output" 2>&1
  [[ "$(<"$home/output")" != *"No such file"* ]] || fail "installer invoked a missing binary"
  [[ "$(<"$home/output")" != *"failed to run ai-brain generate"* ]] || fail "installer attempted generation without a binary"
  [[ "$(<"$home/output")" == "warning: the ai-brain cli is not installed; skipping the secrets sync and agent generation" ]] || fail "installer warning omitted a skipped operation"
}

test_post_update_skips_a_missing_binary() {
  setup_case
  cp "$repo/dependencies/post-update.bash" "$home/dotfiles/dependencies/post-update.bash"
  if env -i HOME="$home" CALLS="$log" PATH=/usr/bin:/bin /bin/bash \
    "$home/dotfiles/dependencies/post-update.bash" >"$home/output" 2>&1; then
    fail "post-update accepted a missing binary"
  fi
  [[ ! -s "$home/output" ]] || fail "post-update invoked a missing binary"
  [[ "$(<"$log")" == "$(printf 'build\nreconcile')" ]] || fail "post-update skipped prerequisites"
}

test_post_update_keeps_generation_before_secrets() {
  setup_case
  install_cli_stub
  cp "$repo/dependencies/post-update.bash" "$home/dotfiles/dependencies/post-update.bash"
  env -i HOME="$home" CALLS="$log" PATH=/usr/bin:/bin /bin/bash "$home/dotfiles/dependencies/post-update.bash"
  [[ "$(<"$log")" == "$(printf 'build\nreconcile\ndirect generate\ndirect secrets sync')" ]] || fail "post-update changed step order"
}

use_opencode_one_adapter() {
  rm "$home/ai-brain/adapters/opencode/opencode.jsonc"
  printf '{}\n' >"$home/ai-brain/adapters/opencode/opencode.json"
}

test_opencode_one_install_skips_generation() {
  prepare_opencode_program
  use_opencode_one_adapter
  run_program >"$home/output" 2>&1
  [[ ! -s "$home/output" ]] || fail "opencode 1 install did not skip silently"
  [[ "$(<"$log")" == reconcile ]] || fail "opencode 1 install generated agents"
}

test_ai_brain_install_skips_generation_for_opencode_one() {
  prepare_ai_brain_program
  install_cli_stub
  use_opencode_one_adapter
  test_uid=1000 run_program >"$home/output" 2>&1
  [[ ! -s "$home/output" ]] || fail "ai-brain install did not skip silently"
  [[ "$(<"$log")" == "$(printf 'build\ndirect secrets sync')" ]] || fail "ai-brain install generated opencode 1 agents"
}

test_post_update_skips_generation_for_opencode_one() {
  setup_case
  install_cli_stub
  use_opencode_one_adapter
  cp "$repo/dependencies/post-update.bash" "$home/dotfiles/dependencies/post-update.bash"
  env -i HOME="$home" CALLS="$log" PATH=/usr/bin:/bin /bin/bash \
    "$home/dotfiles/dependencies/post-update.bash" >"$home/output" 2>&1
  [[ ! -s "$home/output" ]] || fail "opencode 1 post-update did not skip silently"
  [[ "$(<"$log")" == "$(printf 'build\nreconcile\ndirect secrets sync')" ]] || fail "post-update generated opencode 1 agents"
}

prepare_migration_script() {
  setup_case
  mkdir -p "$home/dotfiles/scripts" "$home/.opencode/bin" "$home/.config/opencode"
  cp "$repo/scripts/$1" "$home/dotfiles/scripts/$1"
  cat >>"$home/dotfiles/dependencies/opencode-install.bash" <<'STUB'
opencode_running_pids() { :; }
opencode_install() {
  mkdir -p "$2"
  printf '#!/bin/bash\nprintf "opencode v2.3.0\\n"\n' >"$2/opencode"
  chmod +x "$2/opencode"
}
STUB
  printf '#!/bin/bash\nprintf "%%s:%%s:%%s\\n" "$*" "${AI_BRAIN_ROOT:-$HOME/ai-brain}" "${OPENCODE_CONFIG_ROOT:-$HOME/.config/opencode}" >>"$CALLS"\n' \
    >"$home/.local/bin/ai-brain"
  chmod +x "$home/.local/bin/ai-brain"
}

test_cutover_generates_agents_after_reconciling() {
  prepare_migration_script opencode-cutover.sh
  printf '#!/bin/bash\nprintf "opencode v1.19.3\\n"\n' >"$home/.opencode/bin/opencode"
  chmod +x "$home/.opencode/bin/opencode"
  env -i HOME="$home" CALLS="$log" PATH=/usr/bin:/bin /bin/bash \
    "$home/dotfiles/scripts/opencode-cutover.sh" >"$home/output" 2>&1
  [[ "$(<"$log")" == "$(printf 'reconcile\ngenerate:%s/ai-brain:%s/.config/opencode' "$home" "$home")" ]] || fail "cutover did not generate primary agents"
}

test_sandbox_generates_agents_from_its_adapter_into_its_config() {
  prepare_migration_script opencode-v2-sandbox.sh
  mkdir -p "$home/opencode-v2-sandbox/ai-brain/adapters/opencode"
  printf '{}\n' >"$home/opencode-v2-sandbox/ai-brain/adapters/opencode/opencode.jsonc"
  env -i HOME="$home" CALLS="$log" PATH=/usr/bin:/bin /bin/bash \
    "$home/dotfiles/scripts/opencode-v2-sandbox.sh" >"$home/output" 2>&1
  [[ "$(<"$log")" == "$(printf 'reconcile\ngenerate:%s/opencode-v2-sandbox/ai-brain:%s/opencode-v2-sandbox/config/opencode' "$home" "$home")" ]] || fail "sandbox did not generate agents with isolated roots"
}

make_generate_fail() {
  printf '#!/bin/bash\nprintf "%%s\\n" "$*" >>"$CALLS"\nexit 1\n' >"$home/.local/bin/ai-brain"
  chmod +x "$home/.local/bin/ai-brain"
}

test_cutover_finishes_with_a_warning_when_generate_fails() {
  prepare_migration_script opencode-cutover.sh
  make_generate_fail
  printf '#!/bin/bash\nprintf "opencode v1.19.3\\n"\n' >"$home/.opencode/bin/opencode"
  chmod +x "$home/.opencode/bin/opencode"
  env -i HOME="$home" CALLS="$log" PATH=/usr/bin:/bin /bin/bash \
    "$home/dotfiles/scripts/opencode-cutover.sh" >"$home/output" 2>&1 || fail "cutover exited after a failed generate"
  grep -q 'warning: ai-brain generate did not run' "$home/output" || fail "cutover did not warn about generate"
  grep -q '^rollback: ' "$home/output" || fail "cutover did not print the rollback line"
}

test_sandbox_finishes_with_a_warning_when_generate_fails() {
  prepare_migration_script opencode-v2-sandbox.sh
  make_generate_fail
  mkdir -p "$home/opencode-v2-sandbox/ai-brain/adapters/opencode"
  printf '{}\n' >"$home/opencode-v2-sandbox/ai-brain/adapters/opencode/opencode.jsonc"
  env -i HOME="$home" CALLS="$log" PATH=/usr/bin:/bin /bin/bash \
    "$home/dotfiles/scripts/opencode-v2-sandbox.sh" >"$home/output" 2>&1 || fail "sandbox exited after a failed generate"
  grep -q 'warning: ai-brain generate did not run' "$home/output" || fail "sandbox did not warn about generate"
  grep -q '^opencode-v2 -> ' "$home/output" || fail "sandbox did not print its summary"
}

if [[ $# -gt 0 ]]; then
  "$1"
  exit
fi

test_opencode_generates_as_the_original_user
test_install_skips_generation_without_a_binary
test_post_update_skips_a_missing_binary
test_post_update_keeps_generation_before_secrets
test_opencode_one_install_skips_generation
test_ai_brain_install_skips_generation_for_opencode_one
test_post_update_skips_generation_for_opencode_one
test_cutover_generates_agents_after_reconciling
test_sandbox_generates_agents_from_its_adapter_into_its_config
test_cutover_finishes_with_a_warning_when_generate_fails
test_sandbox_finishes_with_a_warning_when_generate_fails
printf 'ok: 11 tests passed\n'
