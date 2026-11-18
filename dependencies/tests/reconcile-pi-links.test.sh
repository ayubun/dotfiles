#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RECONCILER="$SCRIPT_DIR/../reconcile-pi-links.bash"
TEST_ROOT="$(mktemp -d /tmp/opencode/pi-links-test.XXXXXX)"
trap 'rm -rf "$TEST_ROOT"' EXIT

fail() { printf 'fail: %s\n' "$1" >&2; exit 1; }
assert_equal() { [[ "$1" == "$2" ]] || fail "expected '$2', got '$1'"; }

setup() {
  export HOME="$TEST_ROOT/$1/home"
  export PI_CODING_AGENT_DIR="$TEST_ROOT/$1/agent"
  export AI_BRAIN_PI_ADAPTER_ROOT="$HOME/ai-brain/adapters/pi"
  mkdir -p "$AI_BRAIN_PI_ADAPTER_ROOT/extensions"
  printf '{}\n' >"$AI_BRAIN_PI_ADAPTER_ROOT/settings.json"
  printf '{}\n' >"$AI_BRAIN_PI_ADAPTER_ROOT/models.json"
  printf 'export default () => {}\n' >"$AI_BRAIN_PI_ADAPTER_ROOT/extensions/old.ts"
  printf 'export default () => {}\n' >"$AI_BRAIN_PI_ADAPTER_ROOT/extensions/keep.ts"
}

run_reconciler() {
  bash "$RECONCILER"
}

snapshot() {
  find "$PI_CODING_AGENT_DIR" -printf '%p %l %i\n' | sort
}

test_first_run_links_adapter_files() {
  setup first
  run_reconciler
  local name
  for name in settings.json models.json extensions/old.ts extensions/keep.ts; do
    assert_equal "$(readlink "$PI_CODING_AGENT_DIR/$name")" "$AI_BRAIN_PI_ADAPTER_ROOT/$name"
  done
  [[ -d "$PI_CODING_AGENT_DIR/extensions" && ! -L "$PI_CODING_AGENT_DIR/extensions" ]] || fail "extensions is not a real directory"
  assert_equal "$(find "$PI_CODING_AGENT_DIR" -mindepth 1 -maxdepth 1 | wc -l | tr -d ' ')" "3"
}

test_second_run_keeps_inodes_and_targets() {
  setup repeated
  run_reconciler
  local before
  before="$(snapshot)"
  run_reconciler
  assert_equal "$(snapshot)" "$before"
}

test_machine_overrides_and_foreign_extensions_stay() {
  setup overrides
  mkdir -p "$PI_CODING_AGENT_DIR/extensions"
  printf 'local settings\n' >"$PI_CODING_AGENT_DIR/settings.json"
  printf 'local extension\n' >"$PI_CODING_AGENT_DIR/extensions/local.ts"
  ln -s "$TEST_ROOT/foreign.ts" "$PI_CODING_AGENT_DIR/extensions/foreign.ts"
  printf 'local keep override\n' >"$PI_CODING_AGENT_DIR/extensions/keep.ts"
  run_reconciler
  assert_equal "$(<"$PI_CODING_AGENT_DIR/settings.json")" "local settings"
  assert_equal "$(<"$PI_CODING_AGENT_DIR/extensions/local.ts")" "local extension"
  assert_equal "$(<"$PI_CODING_AGENT_DIR/extensions/keep.ts")" "local keep override"
  assert_equal "$(readlink "$PI_CODING_AGENT_DIR/extensions/foreign.ts")" "$TEST_ROOT/foreign.ts"
}

test_removed_extension_is_pruned_without_touching_other_resources() {
  setup pruning
  run_reconciler
  mkdir -p "$PI_CODING_AGENT_DIR/extensions/subagent"
  printf '{}\n' >"$PI_CODING_AGENT_DIR/extensions/subagent/config.json"
  ln -s "$HOME/ai-brain/old.json" "$PI_CODING_AGENT_DIR/extensions/old.json"
  local name
  for name in skills agents AGENTS.md sessions auth.json models-store.json; do
    ln -s "$HOME/ai-brain/$name" "$PI_CODING_AGENT_DIR/$name"
  done
  rm "$AI_BRAIN_PI_ADAPTER_ROOT/extensions/old.ts"
  run_reconciler
  [[ ! -L "$PI_CODING_AGENT_DIR/extensions/old.ts" ]] || fail "stale extension link remains"
  [[ -L "$PI_CODING_AGENT_DIR/extensions/keep.ts" ]] || fail "wanted extension was pruned"
  [[ -L "$PI_CODING_AGENT_DIR/extensions/old.json" ]] || fail "non-TypeScript link was pruned"
  [[ -f "$PI_CODING_AGENT_DIR/extensions/subagent/config.json" ]] || fail "subagent config was removed"
  for name in skills agents AGENTS.md sessions auth.json models-store.json; do
    assert_equal "$(readlink "$PI_CODING_AGENT_DIR/$name")" "$HOME/ai-brain/$name"
  done
}

test_missing_extensions_directory_prunes_nothing() {
  setup missing_extensions
  run_reconciler
  mv "$AI_BRAIN_PI_ADAPTER_ROOT/extensions" "$AI_BRAIN_PI_ADAPTER_ROOT/extensions-away"
  local before
  before="$(snapshot)"
  run_reconciler
  assert_equal "$(snapshot)" "$before"
}

test_uninstalled_machine_creates_nothing() {
  setup uninstalled
  unset PI_CODING_AGENT_DIR
  run_reconciler
  [[ ! -e "$HOME/.pi" ]] || fail "uninstalled machine got a pi directory"
}

test_missing_adapter_creates_nothing() {
  setup missing_adapter
  export AI_BRAIN_PI_ADAPTER_ROOT="$TEST_ROOT/absent"
  run_reconciler
  [[ ! -e "$PI_CODING_AGENT_DIR" ]] || fail "missing adapter created an agent directory"
}

[[ -f "$RECONCILER" ]] || fail "pi reconciler is missing"
test_first_run_links_adapter_files
test_second_run_keeps_inodes_and_targets
test_machine_overrides_and_foreign_extensions_stay
test_removed_extension_is_pruned_without_touching_other_resources
test_missing_extensions_directory_prunes_nothing
test_uninstalled_machine_creates_nothing
test_missing_adapter_creates_nothing
printf '7 tests passed\n'
