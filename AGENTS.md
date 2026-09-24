# dotfiles

last verified: 2026-09-24

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
- the per-minute cron `updaters/update-repos.sh` fast-forwards the managed repositories
- after any run in which the set of repository heads differs from the last successful reconcile, the cron runs `dependencies/reconcile-opencode-links.bash`
- anything the updater must apply after a pull belongs in that reconciler; keep it idempotent, sudo-free, and offline

## verification

- run `bash -n` or `zsh -n` for every changed shell script
- run targeted scripts under `programs/tests/` when the affected installer has coverage
- run `updaters/tests/update-repos.test.sh` when the updater changes

## boundaries

- keep credentials out of this repository; provisioning may consume exported environment variables without printing them
- keep installer changes idempotent because startup provisioning can run them again
