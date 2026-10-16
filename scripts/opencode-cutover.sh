#!/bin/bash

# Moves the primary OpenCode install from 1 to 2 with a restorable backup.
# Run it by hand after ~/ai-brain main carries the OpenCode 2 adapter and after
# every OpenCode 1 process has exited. scripts/opencode-rollback.sh undoes it.
#
# Steps:
#   1. refuse while an OpenCode 1 process runs (sandbox processes are ignored)
#   2. archive ~/.config/opencode, ~/.local/share/opencode, ~/.local/state/opencode
#      and record the OpenCode 1 version plus the pre-2 commits of ai-brain and
#      ai-brain-discord under ~/.local/share/opencode-backups/<stamp>/
#   3. keep the OpenCode 1 binary as ~/.opencode/bin/opencode-<version>
#   4. install OpenCode 2 to ~/.opencode/bin/opencode
#   5. move the OpenCode 1-only files out of ~/.config/opencode and relink the
#      adapter; the first OpenCode 2 start migrates the database in place
#
#   OPENCODE_V2_VERSION   binary version (default from dependencies/opencode-install.bash)
#   --force               proceed although opencode processes are running

set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../dependencies/opencode-install.bash
source "$script_dir/../dependencies/opencode-install.bash"

force=false
[[ "${1:-}" == "--force" ]] && force=true

adapter_root="$HOME/ai-brain/adapters/opencode"
config_root="$HOME/.config/opencode"
data_root="$HOME/.local/share/opencode"
state_root="$HOME/.local/state/opencode"
bin_dir="$HOME/.opencode/bin"
sandbox="${OPENCODE_V2_SANDBOX:-$HOME/opencode-v2-sandbox}"
version="${OPENCODE_V2_VERSION:-$OPENCODE_V2_DEFAULT_VERSION}"

if [[ "$(opencode_major_for_adapter "$adapter_root")" != 2 ]]; then
  printf '%s has no opencode.jsonc; merge the OpenCode 2 adapter into ai-brain main first\n' "$adapter_root" >&2
  exit 1
fi

running="$(opencode_running_pids "$sandbox/")"
if [[ -n "$running" && "$force" != true ]]; then
  printf 'opencode processes are still running; quit them or pass --force:\n%s\n' "$running" >&2
  exit 1
fi

current_version="$("$bin_dir/opencode" --version 2>/dev/null | sed 's/^opencode //; s/^v//' || true)"
if [[ "$current_version" == 2.* ]]; then
  printf 'the primary install is already OpenCode %s\n' "$current_version" >&2
  exit 1
fi

# The commit before the adapter switched shape is what a rollback checks out.
pre_v2_commit() {
  local repo="$1"
  local path="$2"
  local switch
  switch="$(git -C "$repo" log -1 --format=%H -- "$path" 2>/dev/null || true)"
  [[ -n "$switch" ]] || return 0
  git -C "$repo" rev-parse --verify --quiet "$switch^" || true
}

stamp="$(date -u +%Y%m%dT%H%M%SZ)"
backup_root="$HOME/.local/share/opencode-backups/$stamp"
mkdir -p "$backup_root"

printf 'archiving OpenCode 1 state to %s\n' "$backup_root"
# worktrees under the config root are real git checkouts and stay in place.
archive_members=()
[[ -d "$config_root" ]] && archive_members+=(.config/opencode)
[[ -d "$data_root" ]] && archive_members+=(.local/share/opencode)
[[ -d "$state_root" ]] && archive_members+=(.local/state/opencode)
tar -czf "$backup_root/opencode-v1-state.tar.gz" -C "$HOME" \
  --exclude='.config/opencode/worktrees' \
  --exclude='.config/opencode/node_modules' \
  "${archive_members[@]}"
{
  printf 'opencode_v1_version=%s\n' "${current_version:-unknown}"
  printf 'ai_brain_pre_v2_commit=%s\n' "$(pre_v2_commit "$HOME/ai-brain" adapters/opencode/opencode.json)"
  printf 'ai_brain_discord_pre_v2_commit=%s\n' "$(pre_v2_commit "$HOME/ai-brain-discord" agents)"
  printf 'cutover_at=%s\n' "$stamp"
} >"$backup_root/manifest"
cat "$backup_root/manifest"

if [[ -n "$current_version" && -x "$bin_dir/opencode" ]]; then
  cp -p "$bin_dir/opencode" "$bin_dir/opencode-$current_version"
  printf 'kept OpenCode 1 binary as %s\n' "$bin_dir/opencode-$current_version"
fi

opencode_install 2 "$bin_dir" "$version"

# OpenCode 1 resolved @opencode-ai/plugin from these; OpenCode 2 has no use for them.
mkdir -p "$backup_root/config-v1-only"
for name in opencode.json package.json package-lock.json bun.lock node_modules; do
  [[ -e "$config_root/$name" || -L "$config_root/$name" ]] || continue
  mv "$config_root/$name" "$backup_root/config-v1-only/$name"
done

bash "$script_dir/../dependencies/reconcile-opencode-links.bash"

cat <<EOF

cutover done: $("$bin_dir/opencode" --version)
next:
  opencode debug agents | jq '[.[] | select(.model.providerID=="tier")] | length'   # must print 0
  opencode debug config | jq -r '.[0].path'                                           # the opencode.jsonc link
  restart t3 (restarting-t3 skill) so it picks up the new binary
rollback: bash ~/dotfiles/scripts/opencode-rollback.sh $stamp
EOF
