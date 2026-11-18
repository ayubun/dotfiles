#!/bin/bash

# Everything the repo updater applies after a pull. Each step must stay sudo-free, and offline except the cli rebuild's crate fetch.

set -uo pipefail

dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
status=0

bash "$dir/ai-brain-cli.bash" build || status=1
bash "$dir/reconcile-opencode-links.bash" || status=1
"$HOME/.local/bin/ai-brain" generate || status=1
if [[ -x "$HOME/.local/bin/ai-brain" ]]; then
  "$HOME/.local/bin/ai-brain" secrets sync || status=1
else
  status=1
fi

exit "$status"
