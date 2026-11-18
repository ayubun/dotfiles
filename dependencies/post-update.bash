#!/bin/bash

# Everything the repo updater applies after a pull. Each step must stay sudo-free, and offline except the cli rebuild's crate fetch.

set -uo pipefail

dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$dir/opencode-install.bash"
status=0

bash "$dir/ai-brain-cli.bash" build || status=1
bash "$dir/reconcile-opencode-links.bash" || status=1
bash "$dir/reconcile-pi-links.bash" || status=1
if [[ -x "$HOME/.local/bin/ai-brain" ]]; then
  if [[ "$(opencode_major_for_adapter "$HOME/ai-brain/adapters/opencode")" == 2 ]]; then
    "$HOME/.local/bin/ai-brain" generate || status=1
    if grep -q 'adapters/opencode/generated/skills' "$HOME/ai-brain/adapters/opencode/opencode.jsonc" &&
      [[ ! -d "$HOME/ai-brain/adapters/opencode/generated/skills" ]]; then
      printf 'post-update: generated skills are missing; opencode has no skills until ai-brain generate succeeds\n' >&2
      status=1
    fi
  fi
  "$HOME/.local/bin/ai-brain" secrets sync || status=1
else
  status=1
fi

exit "$status"
