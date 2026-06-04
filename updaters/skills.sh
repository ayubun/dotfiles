#!/usr/bin/env bash
# Convert Claude Code skills from the ed3d-plugins-hailz submodule into:
#   1. opencode format  -> configs/opencode/skills/<plugin>/<skill>/SKILL.md
#   2. claude code copy -> configs/claude/skills/<skill>/SKILL.md  (flat, unmodified)
#
# Idempotent: both destinations are fully owned by this script. Every
# managed subtree is wiped and rewritten from the current submodule state,
# so re-running after an upstream bump always produces the same result.
#
# Typical workflow:
#   1. Bump the submodule to the upstream commit you want:
#        git submodule update --remote configs/opencode/sources/ed3d-plugins-hailz
#      (or cd in and check out a specific ref)
#   2. Regenerate:
#        ./updaters/skills.sh
#   3. Review and commit:
#        git add configs/opencode configs/claude
#        git commit
#
# Flags:
#   --source <path>   override the source repo path (default: the submodule)
#   -h | --help       print this header

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

SOURCE_DIR="${REPO_ROOT}/configs/opencode/sources/ed3d-plugins-hailz"

OPENCODE_DEST="${REPO_ROOT}/configs/opencode/skills"
CLAUDE_DEST="${REPO_ROOT}/configs/claude/skills"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --source)
      SOURCE_DIR="$2"
      shift 2
      ;;
    -h | --help)
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

# --- Prepare destinations ---------------------------------------------------

mkdir -p "$OPENCODE_DEST" "$CLAUDE_DEST"

# Idempotency: wipe every managed tree. Non-ed3d dirs are preserved.
find "$OPENCODE_DEST" -mindepth 1 -maxdepth 1 -type d -name 'ed3d-*' -exec rm -rf {} +
find "$CLAUDE_DEST" -mindepth 1 -maxdepth 1 -type d -exec rm -rf {} +

# --- opencode frontmatter filter --------------------------------------------

# Whitelist for opencode SKILL.md frontmatter keys.
ALLOWED_KEYS='^(name|description|license|compatibility|metadata)$'

# awk program: rewrites frontmatter for opencode (canonical name, strip
# unknown keys); copies markdown body verbatim.
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
  if (match($0, /^[A-Za-z_][A-Za-z0-9_-]*[ \t]*:/)) {
    key = $0
    sub(/[ \t]*:.*/, "", key)
    if (key == "name") { skip = 1; next }
    if (key ~ allowed) { skip = 0; print } else { skip = 1 }
    next
  }
  if (!skip) print
  next
}
{ print }
'

# Extract a one-line frontmatter scalar value (for validation only).
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

# --- Convert -----------------------------------------------------------------

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

    if [[ -z "$fm_desc" ]]; then
      echo "error: ${plugin_name}/${skill_name}/SKILL.md missing 'description'" >&2
      exit 1
    fi
    if [[ -n "$fm_name" && "$fm_name" != "$skill_name" ]]; then
      echo "warn: ${plugin_name}/${skill_name}/SKILL.md: source name '$fm_name' != folder; using folder" >&2
    fi

    # -- opencode: plugin-grouped, rewritten frontmatter --
    oc_dir="$OPENCODE_DEST/$plugin_name/$skill_name"
    mkdir -p "$oc_dir"

    find "$skill_path" -mindepth 1 -maxdepth 1 ! -name 'SKILL.md' \
      -exec cp -R {} "$oc_dir/" \;

    awk -v allowed="$ALLOWED_KEYS" -v folder_name="$skill_name" "$AWK_FILTER" \
      "${skill_path}SKILL.md" > "$oc_dir/SKILL.md"

    # -- claude code: flat, original files verbatim --
    cc_dir="$CLAUDE_DEST/$skill_name"
    cp -R "$skill_path" "$cc_dir"

    count=$((count + 1))
  done
done
shopt -u nullglob

echo "converted $count skills"
echo "  source:  $SOURCE_DIR"
echo "  opencode: $OPENCODE_DEST"
echo "  claude:   $CLAUDE_DEST"
