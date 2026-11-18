#!/bin/bash

# Installs OpenCode 2 beside the OpenCode 1 install, with its own XDG roots,
# so both can run on one machine. Nothing under ~/.opencode, ~/.config/opencode,
# or ~/.local/share/opencode changes. Idempotent; rerun to upgrade the pin.
#
#   OPENCODE_V2_SANDBOX      prefix (default ~/opencode-v2-sandbox)
#   OPENCODE_V2_VERSION      binary version (default from dependencies/opencode-install.bash)
#   AI_BRAIN_ADAPTER_ROOT    adapter to link (default: the sandbox's ai-brain
#                            worktree when present, else ~/ai-brain)
#   OPENCODE_V2_SANDBOX_PORT managed service port (default 49375; the primary
#                            install uses 49374)
#
# Afterwards `opencode-v2` on PATH runs the sandboxed install.

set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../dependencies/opencode-install.bash
source "$script_dir/../dependencies/opencode-install.bash"

sandbox="${OPENCODE_V2_SANDBOX:-$HOME/opencode-v2-sandbox}"
version="${OPENCODE_V2_VERSION:-$OPENCODE_V2_DEFAULT_VERSION}"
if [[ -z "${AI_BRAIN_ADAPTER_ROOT:-}" ]]; then
  if [[ -d "$sandbox/ai-brain/adapters/opencode" ]]; then
    AI_BRAIN_ADAPTER_ROOT="$sandbox/ai-brain/adapters/opencode"
  else
    AI_BRAIN_ADAPTER_ROOT="$HOME/ai-brain/adapters/opencode"
  fi
fi
export AI_BRAIN_ADAPTER_ROOT

if [[ "$(opencode_major_for_adapter "$AI_BRAIN_ADAPTER_ROOT")" != 2 ]]; then
  printf 'adapter %s is not the OpenCode 2 shape (no opencode.jsonc)\n' "$AI_BRAIN_ADAPTER_ROOT" >&2
  exit 1
fi

mkdir -p "$sandbox"/{bin,config/opencode,data/opencode,state,cache}

if [[ "$("$sandbox/bin/opencode" --version 2>/dev/null || true)" != *"$version"* ]]; then
  opencode_install 2 "$sandbox/bin" "$version"
fi

# The wrapper owns the XDG roots of the sandbox install.
cat >"$sandbox/bin/opencode-v2.new" <<'EOF'
#!/usr/bin/env bash
set -uo pipefail

sandbox="${OPENCODE_V2_SANDBOX:-$HOME/opencode-v2-sandbox}"
export XDG_CONFIG_HOME="$sandbox/config"
export XDG_DATA_HOME="$sandbox/data"
export XDG_STATE_HOME="$sandbox/state"
export XDG_CACHE_HOME="$sandbox/cache"

exec "$sandbox/bin/opencode" "$@"
EOF
chmod 755 "$sandbox/bin/opencode-v2.new"
mv -f "$sandbox/bin/opencode-v2.new" "$sandbox/bin/opencode-v2"
mkdir -p "$HOME/.local/bin"
ln -sfn "$sandbox/bin/opencode-v2" "$HOME/.local/bin/opencode-v2"

# OpenCode 2 imports credentials from <data>/opencode/auth.json on first start.
if [[ -f "$HOME/.local/share/opencode/auth.json" && ! -e "$sandbox/data/opencode/auth.json" ]]; then
  cp -p "$HOME/.local/share/opencode/auth.json" "$sandbox/data/opencode/auth.json"
fi

OPENCODE_CONFIG_ROOT="$sandbox/config/opencode" bash "$script_dir/../dependencies/reconcile-opencode-links.bash"

# Every OpenCode 2 install defaults its managed service to port 49374, so the
# sandbox service takes another port to coexist with a primary OpenCode 2.
if [[ ! -f "$sandbox/config/opencode/service.json" ]]; then
  "$sandbox/bin/opencode-v2" service set port "${OPENCODE_V2_SANDBOX_PORT:-49375}" >/dev/null
fi

printf 'opencode-v2 -> %s (%s), adapter %s\n' "$sandbox/bin/opencode" "$("$sandbox/bin/opencode" --version)" "$AI_BRAIN_ADAPTER_ROOT"
