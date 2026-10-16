#!/bin/bash

# Shared helpers for the OpenCode installers and the cutover and rollback
# scripts. Source this file; do not run it.
#
# opencode_major_for_adapter <adapter-root>  prints 2 when the adapter is the
#   OpenCode 2 shape (opencode.jsonc), else 1. ai-brain is the source of truth
#   for which major a machine runs.
# opencode_install <major> <bin-dir> [version]  installs the pinned binary
#   into <bin-dir>/opencode without touching shell rc files.
# opencode_running_pids  prints pids of opencode processes that are not under
#   the given sandbox prefix (Linux and macOS).

OPENCODE_V1_DEFAULT_VERSION="${OPENCODE_V1_DEFAULT_VERSION:-1.19.3}"
OPENCODE_V2_DEFAULT_VERSION="${OPENCODE_V2_DEFAULT_VERSION:-2.0.31}"

# main's last OpenCode 1 commits before the OpenCode 2 merge; scripts/opencode-rollback.sh pins to them.
OPENCODE_V1_AI_BRAIN_COMMIT=3752e0220586aa8d53e248d9186e1950a4d28cdb
OPENCODE_V1_AI_BRAIN_DISCORD_COMMIT=a2b40cbddec2e0ab692d4ee60356538238713125

opencode_major_for_adapter() {
  local adapter_root="$1"
  if [[ -f "$adapter_root/opencode.jsonc" ]]; then
    printf '2\n'
  else
    printf '1\n'
  fi
}

# The upstream installers hardcode $HOME/.opencode/bin, so run them with a
# scratch HOME and move the binary to the requested directory.
opencode_install() {
  local major="$1"
  local bin_dir="$2"
  local version="${3:-}"
  local url scratch

  case "$major" in
    1) url="https://opencode.ai/install"; version="${version:-$OPENCODE_V1_DEFAULT_VERSION}" ;;
    2) url="https://opencode.ai/v2/install"; version="${version:-$OPENCODE_V2_DEFAULT_VERSION}" ;;
    *) printf 'opencode_install: unknown major %s\n' "$major" >&2; return 1 ;;
  esac

  scratch="$(mktemp -d "${TMPDIR:-/tmp}/opencode-install.XXXXXX")"
  mkdir -p "$bin_dir"
  if ! curl -fsSL "$url" | HOME="$scratch" VERSION="$version" bash -s -- --no-modify-path >/dev/null; then
    rm -rf "$scratch"
    printf 'opencode_install: installer for OpenCode %s %s failed\n' "$major" "$version" >&2
    return 1
  fi
  if [[ ! -x "$scratch/.opencode/bin/opencode" ]]; then
    rm -rf "$scratch"
    printf 'opencode_install: installer produced no binary\n' >&2
    return 1
  fi
  mv -f "$scratch/.opencode/bin/opencode" "$bin_dir/opencode.new"
  mv -f "$bin_dir/opencode.new" "$bin_dir/opencode"
  rm -rf "$scratch"
  "$bin_dir/opencode" --version
}

# Executable path of a pid: /proc on Linux, lsof on macOS, argv[0] as the
# last resort (it may be a bare name when PATH resolved the binary).
opencode_exe_of_pid() {
  local pid="$1"
  local exe=""
  if [[ -e "/proc/$pid/exe" ]]; then
    exe="$(readlink "/proc/$pid/exe" 2>/dev/null || true)"
  elif command -v lsof >/dev/null 2>&1; then
    exe="$(lsof -a -p "$pid" -d txt -Fn 2>/dev/null | sed -n 's/^n//p' | head -n 1)"
  fi
  [[ -z "$exe" ]] && exe="$(ps -o args= -p "$pid" 2>/dev/null | awk '{print $1}')"
  printf '%s\n' "${exe% \(deleted\)}"
}

opencode_running_pids() {
  local exclude_prefix="${1:-}"
  local pid exe
  for pid in $(pgrep -x opencode 2>/dev/null); do
    exe="$(opencode_exe_of_pid "$pid")"
    [[ -n "$exclude_prefix" && "$exe" == "$exclude_prefix"* ]] && continue
    printf '%s %s\n' "$pid" "${exe:-?}"
  done
}
