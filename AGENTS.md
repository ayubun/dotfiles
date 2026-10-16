# dotfiles

last verified: 2026-10-16

## purpose

this repository owns machine bootstrap, shell setup, harness installation, and updater wiring

## stack

- bash and zsh installers
- platform-specific setup under `programs/mac/` and `programs/ubuntu/`

## execution model

- `install.sh` automatically runs matching scripts under platform `programs/` directories and then `programs/*.sh`
- files under `programs/` are executable installer inventory, not a general script library
- helpers invoked or sourced by installers belong under `dependencies/`
- use a non-`.sh` extension for dependency helpers that must never match installer globs
- `scripts/` holds operator scripts that a human runs by hand; `install.sh` never runs them
- the per-minute cron `updaters/update-repos.sh` fast-forwards the managed repositories
- after any run in which the set of repository heads differs from the last successful reconcile, the cron runs `dependencies/reconcile-opencode-links.bash`
- anything the updater must apply after a pull belongs in that reconciler; keep it idempotent, sudo-free, and offline

## opencode major

- `~/ai-brain/adapters/opencode` decides the OpenCode major: `opencode.jsonc` means OpenCode 2, `opencode.json` means OpenCode 1. `programs/opencode.sh` and `dependencies/reconcile-opencode-links.bash` read that shape and never choose on their own
- `dependencies/opencode-install.bash` is the shared helper (pinned installs into any bin dir, running-process check); it is sourced, never run
- `scripts/opencode-v2-sandbox.sh` installs OpenCode 2 beside OpenCode 1 under `~/opencode-v2-sandbox` with its own XDG roots and an `opencode-v2` wrapper; it changes nothing in the primary install
- every OpenCode 2 install defaults its managed service to port 49374; the sandbox sets 49375 so both can run
- `scripts/opencode-cutover.sh` archives the OpenCode 1 config, data, and state under `~/.local/share/opencode-backups/<stamp>/`, keeps the old binary as `~/.opencode/bin/opencode-<version>`, installs OpenCode 2 to the primary path, and relinks. it refuses while OpenCode 1 processes run and requires the OpenCode 2 adapter on ai-brain main
- `scripts/opencode-cutover-here.sh` is the one-shot for a machine that should run OpenCode 2 before the branches merge: it stops t3, waits for OpenCode 1 processes to exit, checks out `origin/opencode-v2` in the three repositories on a local tracking branch, runs the cutover, waits for the database migration to report `completed`, verifies agents and config, and starts t3 again. run it from a plain shell, never from inside an opencode session
- `scripts/opencode-rollback.sh [stamp]` restores that archive, reinstalls the recorded OpenCode 1 binary, moves the OpenCode 2 directories aside, and pins ai-brain and ai-brain-discord to their pre-2 commits on a local `opencode-v1-rollback` branch, which the updater leaves alone (no upstream). sessions created on OpenCode 2 are not carried back

## verification

- run `bash -n` or `zsh -n` for every changed shell script
- run targeted scripts under `programs/tests/` when the affected installer has coverage
- run `updaters/tests/update-repos.test.sh` when the updater changes

## boundaries

- keep credentials out of this repository; provisioning may consume exported environment variables without printing them
- keep installer changes idempotent because startup provisioning can run them again
