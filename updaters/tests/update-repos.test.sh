#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
UPDATER="$SCRIPT_DIR/../update-repos.sh"
TEST_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/repo-updater-test.XXXXXX")"

trap 'rm -rf "$TEST_ROOT"' EXIT

export GIT_AUTHOR_NAME="repo updater test"
export GIT_AUTHOR_EMAIL="repo-updater@example.com"
export GIT_COMMITTER_NAME="$GIT_AUTHOR_NAME"
export GIT_COMMITTER_EMAIL="$GIT_AUTHOR_EMAIL"

fail() {
  printf 'fail: %s\n' "$1" >&2
  exit 1
}

assert_equal() {
  [[ "$1" == "$2" ]] || fail "expected '$2', got '$1'"
}

assert_contains() {
  grep -q "$2" "$1" || fail "expected $1 to contain $2"
}

new_fixture() {
  local name="$1"
  local root="$TEST_ROOT/$name"

  mkdir -p "$root"
  git init --bare -q "$root/origin.git"
  git clone -q "$root/origin.git" "$root/seed"
  git -C "$root/seed" switch -q -c main
  printf 'base\n' >"$root/seed/file.txt"
  git -C "$root/seed" add file.txt
  git -C "$root/seed" commit -qm "base"
  git -C "$root/seed" push -qu origin main
  git -C "$root/origin.git" symbolic-ref HEAD refs/heads/main
  git clone -q "$root/origin.git" "$root/worker"

  printf 'test|%s\n' "$root/worker" >"$root/repos.conf"
  mkdir -p "$root/state" "$root/logs"
  printf '%s\n' "$root"
}

run_updater() {
  local root="$1"
  local now="$2"

  REPO_UPDATER_CONFIG="$root/repos.conf" \
    REPO_UPDATER_STATE_ROOT="$root/state" \
    REPO_UPDATER_LOG_ROOT="$root/logs" \
    REPO_UPDATER_NOW="$now" \
    REPO_UPDATER_IDLE_SECONDS=10 \
    bash "$UPDATER"
}

test_clean_fast_forward() {
  local root
  root="$(new_fixture clean)"

  printf 'remote\n' >>"$root/seed/file.txt"
  git -C "$root/seed" commit -qam "remote"
  git -C "$root/seed" push -q

  run_updater "$root" 100

  assert_equal "$(git -C "$root/worker" rev-parse HEAD)" "$(git -C "$root/seed" rev-parse HEAD)"
  [[ ! -e "$root/state/test.state" ]] || fail "clean update did not reset state"
}

test_activity_and_recovery() {
  local root
  root="$(new_fixture activity)"

  printf 'sensitive-body-one\n' >>"$root/worker/file.txt"
  run_updater "$root" 100
  assert_contains "$root/state/test.state" "last_activity_at=100"
  [[ -z "$(git -C "$root/worker" stash list)" ]] || fail "fresh work was stashed"

  git -C "$root/worker" add file.txt
  run_updater "$root" 102
  assert_contains "$root/state/test.state" "last_activity_at=102"

  printf 'sensitive-body-two\n' >>"$root/worker/file.txt"
  printf 'untracked-sensitive-body\n' >"$root/worker/untracked.txt"
  run_updater "$root" 105
  assert_contains "$root/state/test.state" "last_activity_at=105"

  printf 'more-untracked-activity\n' >>"$root/worker/untracked.txt"
  run_updater "$root" 108
  assert_contains "$root/state/test.state" "last_activity_at=108"

  run_updater "$root" 119

  [[ -z "$(git -C "$root/worker" status --porcelain)" ]] || fail "expired worktree was not clean"
  [[ -n "$(git -C "$root/worker" for-each-ref --format='%(refname)' refs/ayu-update-backups/)" ]] || fail "recovery ref missing"
  git -C "$root/worker" stash show --include-untracked --name-only 'stash@{0}' | grep -q untracked.txt || fail "untracked file missing from stash"
  [[ ! -e "$root/state/test.state" ]] || fail "successful recovery did not reset state"
  [[ -n "$(find "$root/logs/update-overwrites/test" -type f -name metadata.txt -print)" ]] || fail "recovery metadata missing"
  if grep -R -q "sensitive-body" "$root/logs"; then
    fail "recovery logs contain file contents"
  fi
}

test_ahead_branch_blocks() {
  local root before
  root="$(new_fixture ahead)"
  printf 'local\n' >>"$root/worker/file.txt"
  git -C "$root/worker" commit -qam "local"
  before="$(git -C "$root/worker" rev-parse HEAD)"

  run_updater "$root" 100

  assert_equal "$(git -C "$root/worker" rev-parse HEAD)" "$before"
  [[ -z "$(git -C "$root/worker" stash list)" ]] || fail "ahead branch was stashed"
}

test_diverged_branch_blocks() {
  local root before
  root="$(new_fixture diverged)"
  printf 'local\n' >"$root/worker/local.txt"
  git -C "$root/worker" add local.txt
  git -C "$root/worker" commit -qm "local"
  before="$(git -C "$root/worker" rev-parse HEAD)"

  printf 'remote\n' >"$root/seed/remote.txt"
  git -C "$root/seed" add remote.txt
  git -C "$root/seed" commit -qm "remote"
  git -C "$root/seed" push -q

  run_updater "$root" 100

  assert_equal "$(git -C "$root/worker" rev-parse HEAD)" "$before"
}

test_detached_head_blocks() {
  local root before
  root="$(new_fixture detached)"
  git -C "$root/worker" checkout -q --detach
  before="$(git -C "$root/worker" rev-parse HEAD)"

  run_updater "$root" 100

  assert_equal "$(git -C "$root/worker" rev-parse HEAD)" "$before"
}

test_conflicted_merge_blocks() {
  local root before
  root="$(new_fixture conflicted)"

  printf 'local\n' >"$root/worker/file.txt"
  git -C "$root/worker" commit -qam "local"
  printf 'remote\n' >"$root/seed/file.txt"
  git -C "$root/seed" commit -qam "remote"
  git -C "$root/seed" push -q
  git -C "$root/worker" fetch -q
  if git -C "$root/worker" merge origin/main >/dev/null 2>&1; then
    fail "conflict fixture merged cleanly"
  fi
  before="$(git -C "$root/worker" rev-parse HEAD)"

  run_updater "$root" 100

  assert_equal "$(git -C "$root/worker" rev-parse HEAD)" "$before"
  [[ -f "$(git -C "$root/worker" rev-parse --absolute-git-dir)/MERGE_HEAD" ]] || fail "updater changed merge state"
}

test_stale_lock_recovers() {
  local root
  root="$(new_fixture stale-lock)"
  mkdir "$root/state/.lock"
  printf '99999999\n' >"$root/state/.lock/pid"

  run_updater "$root" 100

  [[ ! -e "$root/state/.lock" ]] || fail "stale lock was not removed"
}

test_optional_missing_repo_is_ignored() {
  local root="$TEST_ROOT/optional"
  mkdir -p "$root/state" "$root/logs" "$root/not-a-repo"
  {
    printf 'missing|%s|optional\n' "$root/missing"
    printf 'directory|%s|optional\n' "$root/not-a-repo"
  } >"$root/repos.conf"
  touch "$root/state/missing.state" "$root/state/missing.transition"
  touch "$root/state/directory.state" "$root/state/directory.transition"

  run_updater "$root" 100

  [[ ! -e "$root/state/missing.state" ]] || fail "optional missing repo retained stale state"
  [[ ! -e "$root/state/missing.transition" ]] || fail "optional missing repo was recorded as blocked"
  [[ ! -e "$root/state/directory.state" ]] || fail "optional non-repository retained stale state"
  [[ ! -e "$root/state/directory.transition" ]] || fail "optional non-repository was recorded as blocked"
}

test_clean_fast_forward
test_activity_and_recovery
test_ahead_branch_blocks
test_diverged_branch_blocks
test_detached_head_blocks
test_conflicted_merge_blocks
test_stale_lock_recovers
test_optional_missing_repo_is_ignored

printf 'ok\n'
