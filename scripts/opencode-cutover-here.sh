#!/bin/bash

# One-shot OpenCode 2 cutover for this machine while the OpenCode 2 work still
# lives on a branch. Run it from a plain shell (not inside opencode) after
# quitting every opencode TUI:
#
#   bash ~/dotfiles/scripts/opencode-cutover-here.sh
#
# What it does:
#   1. stops t3code.service when present (it owns an `opencode serve`)
#   2. waits up to 60 s for the remaining OpenCode 1 processes to exit; aborts
#      and restarts t3 when some remain, so a stray TUI is never killed
#   3. checks out origin/<branch> in ~/ai-brain, ~/ai-brain-discord, and
#      ~/dotfiles on a local tracking branch; the repo updater keeps it current
#   4. runs scripts/opencode-cutover.sh (archive, keep the old binary, install
#      OpenCode 2, relink)
#   5. starts an OpenCode 2 server once so the database migration runs and
#      finishes, then verifies agents, config, and tier pins
#   6. starts t3code.service again
#
#   OPENCODE_V2_BRANCH   branch to track (default opencode-v2)
#
# Undo: bash ~/dotfiles/scripts/opencode-rollback.sh (it pins ai-brain and
# ai-brain-discord to their last OpenCode 1 commits; dotfiles main handles both).

set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../dependencies/opencode-install.bash
source "$script_dir/../dependencies/opencode-install.bash"

branch="${OPENCODE_V2_BRANCH:-opencode-v2}"
sandbox="${OPENCODE_V2_SANDBOX:-$HOME/opencode-v2-sandbox}"
local_branch="$branch-$(hostname -s)"
repos=("$HOME/ai-brain" "$HOME/ai-brain-discord" "$HOME/dotfiles")

if [[ -n "${OPENCODE_PID:-}" ]]; then
  printf 'run this from a plain shell, not from inside an opencode session\n' >&2
  exit 1
fi

has_t3() { systemctl --user cat t3code.service >/dev/null 2>&1; }
t3_was_active=false
if has_t3 && systemctl --user is-active --quiet t3code.service; then
  t3_was_active=true
fi

for repo in "${repos[@]}"; do
  [[ -d "$repo/.git" ]] || continue
  if [[ -n "$(git -C "$repo" status --porcelain)" ]]; then
    printf '%s has local changes; commit or stash them first\n' "$repo" >&2
    exit 1
  fi
  git -C "$repo" fetch -q origin
  git -C "$repo" rev-parse --verify --quiet "origin/$branch" >/dev/null || {
    printf '%s has no origin/%s\n' "$repo" "$branch" >&2
    exit 1
  }
done

if $t3_was_active; then
  printf 'stopping t3code.service\n'
  systemctl --user stop t3code.service
fi

printf 'waiting for OpenCode 1 processes to exit'
for _ in $(seq 1 30); do
  running="$(opencode_running_pids "$sandbox/")"
  [[ -z "$running" ]] && break
  printf '.'
  sleep 2
done
printf '\n'
if [[ -n "$running" ]]; then
  printf 'these opencode processes are still running; quit them and rerun:\n%s\n' "$running" >&2
  $t3_was_active && systemctl --user start t3code.service
  exit 1
fi

for repo in "${repos[@]}"; do
  [[ -d "$repo/.git" ]] || continue
  git -C "$repo" checkout -q -B "$local_branch" --track "origin/$branch"
  printf '%s -> %s (%s)\n' "$repo" "$local_branch" "$(git -C "$repo" log -1 --format=%h)"
done

# The adapter now has its OpenCode 2 shape, so the installer helper selects major 2.
bash "$script_dir/opencode-cutover.sh"

# A server start runs the v1 -> v2 database migration; wait for `completed`.
printf 'migrating the session database'
"$HOME/.opencode/bin/opencode" service start >/dev/null 2>&1 || true
for _ in $(seq 1 120); do
  # Any client call starts the service when it is not running.
  "$HOME/.opencode/bin/opencode" debug config >/dev/null 2>&1 || true
  phase="$(python3 - <<'EOF' 2>/dev/null || true
import sqlite3, os, json
db = os.path.expanduser("~/.local/share/opencode/opencode.db")
c = sqlite3.connect(f"file:{db}?mode=ro", uri=True)
row = c.execute("select value from kv where key='migration.v1-v2'").fetchone()
print(json.loads(row[0]).get("phase") if row else "")
EOF
)"
  [[ "$phase" == "completed" ]] && break
  printf '.'
  sleep 5
done
printf '\n'
if [[ "$phase" != "completed" ]]; then
  printf 'migration has not reported completed yet (phase: %s); it resumes on the next server start\n' "${phase:-unknown}" >&2
fi

# The agent list is empty for the first seconds after the service starts, and a
# large list can truncate when piped, so write to a file and retry.
agents_file="$(mktemp)"
for _ in $(seq 1 15); do
  "$HOME/.opencode/bin/opencode" debug agents >"$agents_file" 2>/dev/null || true
  agent_count="$(jq 'length' "$agents_file" 2>/dev/null || echo 0)"
  [[ "${agent_count:-0}" -gt 0 ]] && break
  sleep 3
done
tier_refs="$(jq '[.[] | select(.model.providerID=="tier")] | length' "$agents_file" 2>/dev/null || echo '?')"
rm -f "$agents_file"
config_path="$("$HOME/.opencode/bin/opencode" debug config 2>/dev/null | jq -r '.[0].path' || echo '?')"
"$HOME/.opencode/bin/opencode" service stop >/dev/null 2>&1 || true

if $t3_was_active; then
  printf 'starting t3code.service\n'
  systemctl --user start t3code.service
fi

cat <<EOF

verification:
  version      $("$HOME/.opencode/bin/opencode" --version)
  config       $config_path
  agents       $agent_count
  tier refs    $tier_refs (must be 0)
  migration    ${phase:-unknown}
EOF
[[ "$tier_refs" == 0 && "$config_path" == *opencode.jsonc ]] || {
  printf 'verification failed; see scripts/opencode-rollback.sh\n' >&2
  exit 1
}
