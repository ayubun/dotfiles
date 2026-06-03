#!/usr/bin/env bash
# Convert Claude Code skills from the ed3d-plugins-hailz submodule into
# opencode-compatible skill directories under configs/opencode/skills/.
#
# Idempotent: the destination is fully owned by this script. Every plugin
# subtree it manages is wiped and rewritten from the current submodule
# state, so re-running after an upstream bump always produces the same
# result as a fresh checkout.
#
# Typical workflow:
#   1. Bump the submodule to the upstream commit you want:
#        git submodule update --remote configs/opencode/sources/ed3d-plugins-hailz
#      (or cd in and check out a specific ref)
#   2. Regenerate:
#        ./updaters/opencode-skills.sh
#   3. Review and commit both the submodule bump and the regenerated skills:
#        git add .gitmodules configs/opencode
#        git commit
#
# Flags:
#   --source <path>   override the source repo path (default: the submodule)
#   --dest   <path>   override the destination dir (default: configs/opencode/skills)
#   -h | --help       print this header

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

SOURCE_DIR="${REPO_ROOT}/configs/opencode/sources/ed3d-plugins-hailz"
DEST_DIR="${REPO_ROOT}/configs/opencode/skills"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --source)
      SOURCE_DIR="$2"
      shift 2
      ;;
    --dest)
      DEST_DIR="$2"
      shift 2
      ;;
    -h | --help)
      # Print the leading comment block as usage.
      awk 'NR>1 && /^#/ {sub(/^# ?/,""); print; next} NR>1 {exit}' "${BASH_SOURCE[0]}"
      exit 0
      ;;
    *)
      echo "error: unknown arg: $1" >&2
      exit 2
      ;;
  esac
done

if [[ ! -d "$SOURCE_DIR/plugins" ]]; then
  echo "error: source does not look like ed3d-plugins-hailz (no plugins/ dir): $SOURCE_DIR" >&2
  echo "       hint: run 'git submodule update --init --recursive'" >&2
  exit 1
fi

mkdir -p "$DEST_DIR"

# Idempotency: wipe every plugin tree we previously emitted. Leave anything
# else in the directory alone (README, .gitkeep, manually-added skills).
# All emitted plugin dirs are prefixed "ed3d-".
find "$DEST_DIR" -mindepth 1 -maxdepth 1 -type d -name 'ed3d-*' -exec rm -rf {} +

# Frontmatter whitelist. Anything not in this set is dropped from the
# rewritten SKILL.md (notably the Claude-Code-only "user-invocable" key).
# Keep this list aligned with opencode's documented skill schema:
#   https://opencode.ai/config.json
ALLOWED_KEYS='^(name|description|license|compatibility|metadata)$'

# awk program that:
#   - copies markdown body verbatim
#   - in frontmatter:
#       * emits a canonical "name: <folder-name>" right after the opening
#         "---" (opencode requires name to match the folder, and upstream
#         occasionally drifts; we normalize unconditionally)
#       * drops any source "name:" line
#       * keeps whitelisted keys and their continuation lines
#       * drops everything else (notably the Claude-Code "user-invocable")
AWK_FILTER='
BEGIN { in_fm = 0; fm_done = 0; skip = 0 }
/^---[ \t]*$/ {
  if (!fm_done && !in_fm) {
    in_fm = 1
    print
    print "name: " folder_name
    next
  }
  if (in_fm) {
    in_fm = 0; fm_done = 1; skip = 0
    print
    next
  }
}
in_fm {
  # A new key starts at column 0 and matches "key:".
  if (match($0, /^[A-Za-z_][A-Za-z0-9_-]*[ \t]*:/)) {
    key = $0
    sub(/[ \t]*:.*/, "", key)
    if (key == "name") { skip = 1; next }
    if (key ~ allowed) { skip = 0; print } else { skip = 1 }
    next
  }
  # Continuation line (indented or blank): inherit current skip state.
  if (!skip) print
  next
}
{ print }
'

# Extract a one-line frontmatter scalar value. Used for validation, not for
# rewriting (rewriting is done by the awk filter above).
extract_value() {
  awk -v key="$2" '
    BEGIN { in_fm = 0 }
    /^---[ \t]*$/ {
      if (!in_fm) { in_fm = 1; next }
      exit
    }
    in_fm && $0 ~ ("^" key "[ \t]*:") {
      sub("^" key "[ \t]*:[ \t]*", "")
      sub(/[ \t]+$/, "")
      print
      exit
    }
  ' "$1"
}

count=0
shopt -s nullglob
for plugin_path in "$SOURCE_DIR"/plugins/*/; do
  plugin_name="$(basename "$plugin_path")"
  [[ -d "${plugin_path}skills" ]] || continue
  for skill_path in "${plugin_path}skills"/*/; do
    [[ -f "${skill_path}SKILL.md" ]] || continue
    skill_name="$(basename "$skill_path")"

    fm_name="$(extract_value "${skill_path}SKILL.md" name)"
    fm_desc="$(extract_value "${skill_path}SKILL.md" description)"

    # description is the only hard requirement (opencode silently drops
    # skills without it). name is normalized to folder regardless of source.
    if [[ -z "$fm_desc" ]]; then
      echo "error: ${plugin_name}/${skill_name}/SKILL.md missing 'description'" >&2
      exit 1
    fi
    if [[ -n "$fm_name" && "$fm_name" != "$skill_name" ]]; then
      echo "warn: ${plugin_name}/${skill_name}/SKILL.md: source name '$fm_name' != folder; using folder" >&2
    fi

    out_dir="$DEST_DIR/$plugin_name/$skill_name"
    mkdir -p "$out_dir"

    # Copy every auxiliary file verbatim (subdirs included).
    find "$skill_path" -mindepth 1 -maxdepth 1 ! -name 'SKILL.md' \
      -exec cp -R {} "$out_dir/" \;

    # Rewrite SKILL.md with the frontmatter filter.
    awk -v allowed="$ALLOWED_KEYS" -v folder_name="$skill_name" "$AWK_FILTER" \
      "${skill_path}SKILL.md" > "$out_dir/SKILL.md"

    count=$((count + 1))
  done
done
shopt -u nullglob

echo "converted $count skills"
echo "  source: $SOURCE_DIR"
echo "  dest:   $DEST_DIR"
