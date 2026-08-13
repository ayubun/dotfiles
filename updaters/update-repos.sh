#!/bin/bash

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG="${REPO_UPDATER_CONFIG:-$SCRIPT_DIR/repos.conf}"
STATE_ROOT="${REPO_UPDATER_STATE_ROOT:-$HOME/dotfiles/logs/updater-state}"
LOG_ROOT="${REPO_UPDATER_LOG_ROOT:-$HOME/dotfiles/logs}"
IDLE_SECONDS="${REPO_UPDATER_IDLE_SECONDS:-172800}"
NOW="${REPO_UPDATER_NOW:-$(date +%s)}"
LOCK_DIR="$STATE_ROOT/.lock"

case "$IDLE_SECONDS:$NOW" in
  *[!0-9:]*|:*|*:) printf 'invalid updater time configuration\n' >&2; exit 1 ;;
esac

mkdir -p "$STATE_ROOT" "$LOG_ROOT/repo-updater/events"
if ! mkdir "$LOCK_DIR" 2>/dev/null; then
  lock_pid=""
  [[ -f "$LOCK_DIR/pid" ]] && IFS= read -r lock_pid <"$LOCK_DIR/pid"
  if [[ "$lock_pid" =~ ^[0-9]+$ ]] && kill -0 "$lock_pid" 2>/dev/null; then
    exit 0
  fi
  rm -f "$LOCK_DIR/pid"
  rmdir "$LOCK_DIR" 2>/dev/null || exit 0
  mkdir "$LOCK_DIR" 2>/dev/null || exit 0
fi
printf '%s\n' "$$" >"$LOCK_DIR/pid"
trap 'rm -f "$LOCK_DIR/pid"; rmdir "$LOCK_DIR" 2>/dev/null || true' EXIT

safe_name() {
  printf '%s' "$1" | tr -c 'A-Za-z0-9._-' '_'
}

record_transition() {
  local name="$1"
  local status="$2"
  local detail="$3"
  local transition_file
  local next="$status|$detail"
  local previous=""

  transition_file="$STATE_ROOT/$(safe_name "$name").transition"

  [[ -f "$transition_file" ]] && IFS= read -r previous <"$transition_file"
  TRANSITION_CHANGED=false
  [[ "$previous" == "$next" ]] && return

  printf '%s\n' "$next" >"$transition_file"
  printf '%s %s %s %s\n' "$(date -u '+%Y-%m-%dT%H:%M:%SZ')" "$name" "$status" "$detail" \
    >>"$LOG_ROOT/repo-updater/events/events.log"
  TRANSITION_CHANGED=true
}

blocked() {
  record_transition "$1" "blocked" "$2"
  if $TRANSITION_CHANGED; then
    printf '%s: blocked: %s\n' "$1" "$2" >&2
  fi
}

has_in_progress_operation() {
  local repo="$1"
  local git_dir
  git_dir="$(git -C "$repo" rev-parse --absolute-git-dir 2>/dev/null)" || return 0

  [[ -f "$git_dir/MERGE_HEAD" || -f "$git_dir/CHERRY_PICK_HEAD" || -f "$git_dir/REVERT_HEAD" || -d "$git_dir/rebase-merge" || -d "$git_dir/rebase-apply" ]]
}

working_fingerprint() {
  local repo="$1"
  {
    git -C "$repo" status --porcelain=v1 -z
    git -C "$repo" diff --binary HEAD
    while IFS= read -r -d '' file; do
      printf '%s\0' "$file"
      git -C "$repo" hash-object -- "$file"
    done < <(git -C "$repo" ls-files --others --exclude-standard -z)
  } | git hash-object --stdin
}

read_wait_state() {
  local state_file="$1"
  WAIT_FINGERPRINT=""
  WAIT_LAST_ACTIVITY=""

  [[ -f "$state_file" ]] || return
  while IFS='=' read -r key value; do
    case "$key" in
      fingerprint) WAIT_FINGERPRINT="$value" ;;
      last_activity_at) WAIT_LAST_ACTIVITY="$value" ;;
    esac
  done <"$state_file"
}

write_wait_state() {
  local state_file="$1"
  local fingerprint="$2"
  local last_activity="$3"
  local temp_file="$state_file.tmp.$$"

  {
    printf 'fingerprint=%s\n' "$fingerprint"
    printf 'last_activity_at=%s\n' "$last_activity"
  } >"$temp_file"
  mv "$temp_file" "$state_file"
}

recover_dirty_tree() {
  local name="$1"
  local repo="$2"
  local state_file="$3"
  local upstream="$4"
  local behind="$5"
  local timestamp stash_oid ref_name log_dir changed_paths

  timestamp="$(date -u '+%Y%m%dT%H%M%SZ')"
  changed_paths="$(git -C "$repo" status --short)"

  if ! git -C "$repo" stash push --include-untracked --message "auto-shelved by repo updater at $timestamp" --quiet; then
    blocked "$name" "failed to stash expired work"
    return
  fi

  stash_oid="$(git -C "$repo" rev-parse 'stash@{0}' 2>/dev/null)" || {
    blocked "$name" "stash completed without a recoverable object"
    return
  }
  ref_name="refs/ayu-update-backups/${timestamp}-${stash_oid:0:12}"
  if ! git -C "$repo" update-ref "$ref_name" "$stash_oid"; then
    blocked "$name" "failed to anchor recovery ref"
    return
  fi

  log_dir="$LOG_ROOT/update-overwrites/$(safe_name "$name")/$timestamp"
  mkdir -p "$log_dir"
  {
    printf 'repository=%s\n' "$repo"
    printf 'branch=%s\n' "$(git -C "$repo" symbolic-ref --short HEAD)"
    printf 'upstream=%s\n' "$upstream"
    printf 'stash=%s\n' "$stash_oid"
    printf 'recovery_ref=%s\n' "$ref_name"
    printf 'restore=git -C %q stash apply %q\n' "$repo" "$stash_oid"
  } >"$log_dir/metadata.txt"
  printf '%s\n' "$changed_paths" >"$log_dir/changed-paths.txt"

  if [[ "$behind" -gt 0 ]] && ! git -C "$repo" merge --ff-only --quiet "$upstream"; then
    blocked "$name" "work was preserved but fast-forward failed"
    return
  fi

  rm -f "$state_file"
  record_transition "$name" "shelved" "$ref_name"
}

update_repo() {
  local name="$1"
  local repo="$2"
  local state_file branch upstream counts ahead behind fingerprint elapsed

  repo="${repo/#\~/$HOME}"
  state_file="$STATE_ROOT/$(safe_name "$name").state"

  [[ -d "$repo" ]] || {
    blocked "$name" "repository path does not exist"
    return
  }
  git -C "$repo" rev-parse --git-dir >/dev/null 2>&1 || {
    blocked "$name" "path is not a git repository"
    return
  }
  has_in_progress_operation "$repo" && {
    blocked "$name" "git operation is in progress"
    return
  }
  [[ -z "$(git -C "$repo" diff --name-only --diff-filter=U)" ]] || {
    blocked "$name" "repository has unmerged files"
    return
  }

  branch="$(git -C "$repo" symbolic-ref --quiet --short HEAD 2>/dev/null)" || {
    blocked "$name" "head is detached"
    return
  }
  upstream="$(git -C "$repo" rev-parse --abbrev-ref --symbolic-full-name '@{u}' 2>/dev/null)" || {
    blocked "$name" "branch has no upstream"
    return
  }
  git -C "$repo" fetch --quiet || {
    blocked "$name" "fetch failed"
    return
  }

  counts="$(git -C "$repo" rev-list --left-right --count HEAD..."$upstream")" || {
    blocked "$name" "could not compare branch with upstream"
    return
  }
  read -r ahead behind <<<"$counts"
  [[ "$ahead" -eq 0 ]] || {
    blocked "$name" "branch has local commits or diverged"
    return
  }

  if [[ -z "$(git -C "$repo" status --porcelain)" ]]; then
    if [[ "$behind" -gt 0 ]] && ! git -C "$repo" merge --ff-only --quiet "$upstream"; then
      blocked "$name" "fast-forward failed"
      return
    fi
    rm -f "$state_file"
    record_transition "$name" "clean" "$branch"
    return
  fi

  fingerprint="$(working_fingerprint "$repo")" || {
    blocked "$name" "failed to fingerprint local activity"
    return
  }
  read_wait_state "$state_file"
  [[ "$WAIT_LAST_ACTIVITY" =~ ^[0-9]+$ ]] || WAIT_LAST_ACTIVITY=""
  if [[ "$WAIT_FINGERPRINT" != "$fingerprint" || -z "$WAIT_LAST_ACTIVITY" ]]; then
    write_wait_state "$state_file" "$fingerprint" "$NOW"
    record_transition "$name" "waiting" "local activity"
    return
  fi

  elapsed=$((NOW - WAIT_LAST_ACTIVITY))
  if [[ "$elapsed" -lt "$IDLE_SECONDS" ]]; then
    record_transition "$name" "waiting" "local activity"
    return
  fi

  recover_dirty_tree "$name" "$repo" "$state_file" "$upstream" "$behind"
}

[[ -f "$CONFIG" ]] || {
  printf 'repo updater config not found: %s\n' "$CONFIG" >&2
  exit 1
}

while IFS='|' read -r name repo mode; do
  [[ -n "$name" && "${name:0:1}" != "#" ]] || continue
  expanded_repo="${repo/#\~/$HOME}"
  if [[ "$mode" == "optional" ]] && ! git -C "$expanded_repo" rev-parse --git-dir >/dev/null 2>&1; then
    continue
  fi
  update_repo "$name" "$repo"
done <"$CONFIG"
