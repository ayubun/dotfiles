#!/bin/bash

# Restores the OpenCode 1 install from a scripts/opencode-cutover.sh backup.
# Sessions created on OpenCode 2 after the cutover are not carried back; the
# OpenCode 2 directories are kept beside the restored ones for reference.
#
#   opencode-rollback.sh [stamp] [--force]
#     stamp     backup under ~/.local/share/opencode-backups (default: newest)
#     --force   proceed although opencode processes are running
#
# ai-brain and ai-brain-discord are pinned to their pre-2 commits on a local
# branch without upstream, which the repo updater leaves alone. Delete those
# branches and check out main again when the machine returns to OpenCode 2.

set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../dependencies/opencode-install.bash
source "$script_dir/../dependencies/opencode-install.bash"

stamp=""
force=false
for arg in "$@"; do
  case "$arg" in
    --force) force=true ;;
    *) stamp="$arg" ;;
  esac
done
if [[ -n "${OPENCODE_PID:-}" && "$force" != true ]]; then
  printf 'run this from a plain shell, not from inside an opencode session\n' >&2
  exit 1
fi

backups_root="$HOME/.local/share/opencode-backups"
if [[ -z "$stamp" ]]; then
  # Stamps sort lexically by time, so the last glob match is the newest backup.
  for candidate in "$backups_root"/*/; do
    [[ -d "$candidate" ]] && stamp="$(basename "$candidate")"
  done
fi
backup_root="$backups_root/$stamp"
archive="$backup_root/opencode-v1-state.tar"
[[ -f "$archive" ]] || archive="$archive.gz"
if [[ -z "$stamp" || ! -f "$backup_root/manifest" || ! -f "$archive" ]]; then
  printf 'no usable backup under %s\n' "$backups_root" >&2
  exit 1
fi

# shellcheck disable=SC1090
source "$backup_root/manifest"
config_root="$HOME/.config/opencode"
data_root="$HOME/.local/share/opencode"
state_root="$HOME/.local/state/opencode"
bin_dir="$HOME/.opencode/bin"
sandbox="${OPENCODE_V2_SANDBOX:-$HOME/opencode-v2-sandbox}"

running="$(opencode_running_pids "$sandbox/")"
if [[ -n "$running" && "$force" != true ]]; then
  printf 'opencode processes are still running; quit them or pass --force:\n%s\n' "$running" >&2
  exit 1
fi
"$bin_dir/opencode" service stop >/dev/null 2>&1 || true

pin_repo() {
  local repo="$1"
  local commit="$2"
  [[ -d "$repo/.git" && -n "$commit" ]] || return 0
  if [[ -n "$(git -C "$repo" status --porcelain)" ]]; then
    printf '%s has local changes; pin it to %s by hand\n' "$repo" "$commit" >&2
    return 0
  fi
  git -C "$repo" checkout --quiet -B opencode-v1-rollback "$commit"
  printf 'pinned %s to %s on branch opencode-v1-rollback\n' "$repo" "$commit"
}
pin_repo "$HOME/ai-brain" "${ai_brain_pre_v2_commit:-}"
pin_repo "$HOME/ai-brain-discord" "${ai_brain_discord_pre_v2_commit:-}"

aside_stamp="$(date -u +%Y%m%dT%H%M%SZ)"
for dir in "$config_root" "$data_root" "$state_root"; do
  [[ -e "$dir" ]] || continue
  if [[ "$dir" == "$config_root" && -d "$config_root/worktrees" ]]; then
    # Worktrees were excluded from the archive; keep them where they are.
    mkdir -p "$config_root.v2-$aside_stamp"
    for entry in "$config_root"/* "$config_root"/.[!.]*; do
      [[ -e "$entry" || -L "$entry" ]] || continue
      [[ "$(basename "$entry")" == worktrees ]] && continue
      mv "$entry" "$config_root.v2-$aside_stamp/"
    done
  else
    mv "$dir" "$dir.v2-$aside_stamp"
  fi
done
mkdir -p "$config_root" "$data_root" "$state_root"
tar -xf "$archive" -C "$HOME"
for name in "$backup_root"/config-v1-only/*; do
  [[ -e "$name" || -L "$name" ]] || continue
  cp -a "$name" "$config_root/$(basename "$name")"
done

v1_version="${opencode_v1_version:-$OPENCODE_V1_DEFAULT_VERSION}"
if [[ -x "$bin_dir/opencode-$v1_version" ]]; then
  cp -p "$bin_dir/opencode-$v1_version" "$bin_dir/opencode.new"
  mv -f "$bin_dir/opencode.new" "$bin_dir/opencode"
  "$bin_dir/opencode" --version
else
  opencode_install 1 "$bin_dir" "$v1_version"
fi

bash "$script_dir/../dependencies/reconcile-opencode-links.bash"

cat <<EOF

rollback done: $("$bin_dir/opencode" --version)
OpenCode 2 state kept at: $config_root.v2-$aside_stamp, $data_root.v2-$aside_stamp, $state_root.v2-$aside_stamp
restart t3 (restarting-t3 skill) so it picks up the restored binary
EOF
