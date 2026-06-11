# opencode config

Files and dirs managed here are wired into `~/.config/opencode/` by
`programs/opencode.sh`.

## Layout

```
configs/opencode/
  opencode.json                # global config; symlinked. skills.paths pulls in
                               #   this repo's skills/ AND ~/work/opencode/skills
  CLAUDE-TO-OPENCODE.md        # the migration spec (see below)
  skills/                      # converted opencode skills (generated)
    ed3d-<plugin>/<skill>/SKILL.md
  agents/                      # converted opencode agents (generated, flat)
    <agent>.md                 # marker: "# generated-by: migrate-to-opencode"
configs/dependencies/
  skills-sources/              # git submodule (read-only Claude Code source)
configs/agents.md              # shared directives; loaded via opencode.json
```

Generated subtrees are **fully owned** by the migration: every `ed3d-*` dir
under `skills/` and every marker-bearing file under `agents/` is wiped and
regenerated on each run. Don't hand-edit those. Hand-authored personal
skills/agents live in `~/work/opencode/{skills,agents}` (skills picked up via
`skills.paths`; agents symlinked in by `programs/opencode.sh`).

Agents need the symlink treatment because opencode has `skills.paths` but no
agent-paths equivalent — `programs/opencode.sh` aggregates
`configs/opencode/agents` + `~/work/opencode/agents` into
`~/.config/opencode/agents/`.

## Updating skills/agents from upstream

The old `updaters/skills.sh` (awk/sed) converter is retired — it could only
rewrite frontmatter, not port skill bodies to opencode tooling. Conversion is
now agent-driven:

```sh
# 1. Bump the submodule to the upstream commit you want
git submodule update --remote configs/dependencies/skills-sources

# 2. Ask an agent (e.g. opencode itself) to:
#    "Re-run the opencode migration per configs/opencode/CLAUDE-TO-OPENCODE.md"

# 3. Review and commit
git add configs/opencode
git commit
```

`CLAUDE-TO-OPENCODE.md` is the full spec: conversion rules, the
Claude→opencode mapping table, idempotency protocol, and verification gates.
It instructs the agent to re-derive volatile opencode facts (schemas, models,
tool surface) from the live install rather than trusting hardcoded values, so
it stays valid as opencode evolves.

Claude Code output is no longer generated (`configs/claude/{skills,agents}`
were removed; `programs/claude-code.sh` no longer mirrors anything into
`~/.claude/` and cleans up stale symlinks so opencode's external
`~/.claude/skills` scan doesn't double-load).

Restart opencode after committing — skill/agent registration happens once at
startup and is not hot-reloaded.

## Fresh-clone setup

After cloning this dotfiles repo:

```sh
git submodule update --init --recursive   # only needed to re-run the migration
```

The committed `configs/opencode/{skills,agents}` are what opencode actually
consumes, so opencode works without initializing the submodule.
