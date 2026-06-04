# opencode config

Files and dirs managed here are symlinked into `~/.config/opencode/` by
`programs/opencode.sh`.

## Layout

```
configs/opencode/
  opencode.json                            # global config; symlinked
  skills/                                  # converted Claude Code skills; symlinked
    ed3d-<plugin>/<skill>/SKILL.md
  sources/
    ed3d-plugins-hailz/                    # git submodule (read-only)
```

`skills/` is **fully owned** by `updaters/skills.sh`. Do not hand-edit
files under any `ed3d-*` subdir; the next conversion will wipe them. Custom
non-`ed3d-*` skill dirs placed here are preserved.

## Updating skills from upstream

```sh
# 1. Bump the submodule to the upstream commit you want
git submodule update --remote configs/opencode/sources/ed3d-plugins-hailz

# 2. Regenerate (emits both opencode and claude code output)
./updaters/skills.sh

# 3. Review and commit
git add configs/opencode configs/claude
git commit
```

Restart opencode after committing - skill registration happens once at
startup and is not hot-reloaded.

## What the converter does

For each `plugins/<plugin>/skills/<skill>/SKILL.md` in the submodule, the
converter copies the skill directory verbatim and rewrites `SKILL.md` to:

- emit a canonical `name: <folder-name>` (opencode requires `name` to match
  the folder; upstream occasionally drifts and this normalization fixes it)
- drop any frontmatter key that opencode's skill schema does not recognize
  (notably the Claude-Code-only `user-invocable`)
- preserve `description` and any other documented schema keys

Auxiliary files (other `.md`, `.dot`, `.py`, `examples/` etc.) are copied
through unchanged.

## Fresh-clone setup

After cloning this dotfiles repo:

```sh
git submodule update --init --recursive
```

The committed `configs/opencode/skills/` is what opencode actually consumes,
so opencode works correctly even without initializing the submodule. The
submodule is only required when regenerating from a newer upstream commit.
