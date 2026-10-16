#!/bin/bash

# Everything the repo updater applies after a pull. Each step must stay offline and sudo-free.

set -uo pipefail

dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
status=0

bash "$dir/reconcile-opencode-links.bash" || status=1
bash "$dir/ai-brain-secrets.bash" sync || status=1

exit "$status"
