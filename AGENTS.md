# dotfiles

last verified: 2026-08-17

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

## verification

- run `bash -n` or `zsh -n` for every changed shell script
- run targeted scripts under `programs/tests/` when the affected installer has coverage

## boundaries

- keep credentials out of this repository; provisioning may consume exported environment variables without printing them
- keep installer changes idempotent because startup provisioning can run them again
