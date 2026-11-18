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
}

install_cli_stub() {
  printf '#!/bin/bash\nprintf "%%s %%s\\n" "${RUN_AS:-direct}" "$*" >>"$CALLS"\n' >"$home/.local/bin/ai-brain"
  chmod +x "$home/.local/bin/ai-brain"
}

run_program() {
  env -i HOME="$home" USER=fixture ORIGINAL_USER=fixture TEST_UID="${test_uid:-0}" CALLS="$log" \
    PATH="$home/stubs:/usr/bin:/bin" /bin/bash -c "$program"
}

test_opencode_generates_as_the_original_user() {
  setup_case
  install_cli_stub
  printf 'opencode_major_for_adapter() { echo 2; }\nopencode_latest_v2_version() { echo 2.3.0; }\nopencode_version_lt() { return 1; }\nopencode_installed_version() { echo 2.3.0; }\n' \
    >"$home/dotfiles/dependencies/opencode-install.bash"
  printf '#!/bin/bash\nif [[ "$1" == chown ]]; then exit 0; fi\n[[ "$1" == -u && "$2" == fixture && "$3" == -H ]] || exit 99\nshift 3\nRUN_AS=fixture "$@"\n' >"$home/stubs/sudo"
  for command in curl zsh; do
    printf '#!/bin/bash\nexit 0\n' >"$home/stubs/$command"
    chmod +x "$home/stubs/$command"
  done
  printf '#!/bin/bash\nexit 0\n' >"$home/.local/bin/ocx"
  chmod +x "$home/stubs/sudo" "$home/.local/bin/ocx"
  program="$(<"$repo/programs/opencode.sh")"
  program="${program//\$UID/\$TEST_UID}"
  run_program
  [[ "$(<"$log")" == "$(printf 'reconcile\nfixture generate')" ]] || fail "opencode did not generate as the original user"
}

test_install_skips_generation_without_a_binary() {
  setup_case
  printf '#!/bin/bash\nexit 0\n' >"$home/stubs/git"
  chmod +x "$home/stubs/git"
  program="$(<"$repo/programs/ai-brain.sh")"
  program="${program//\$UID/\$TEST_UID}"
  test_uid=1000 run_program >"$home/output" 2>&1
  [[ "$(<"$home/output")" != *"No such file"* ]] || fail "installer invoked a missing binary"
  [[ "$(<"$home/output")" != *"failed to run ai-brain generate"* ]] || fail "installer attempted generation without a binary"
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

if [[ $# -gt 0 ]]; then
  "$1"
  exit
fi

test_opencode_generates_as_the_original_user
test_install_skips_generation_without_a_binary
test_post_update_skips_a_missing_binary
test_post_update_keeps_generation_before_secrets
printf 'ok: 4 tests passed\n'
