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
#        git submodule update --remote configs/dependencies/skills-sources
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

SOURCE_DIR="${REPO_ROOT}/configs/dependencies/skills-sources"

OPENCODE_DEST="${REPO_ROOT}/configs/opencode/skills"
OPENCODE_AGENTS_DEST="${REPO_ROOT}/configs/opencode/agents"
CLAUDE_DEST="${REPO_ROOT}/configs/claude/skills"
CLAUDE_AGENTS_DEST="${REPO_ROOT}/configs/claude/agents"

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

mkdir -p "$OPENCODE_DEST" "$OPENCODE_AGENTS_DEST" "$CLAUDE_DEST" "$CLAUDE_AGENTS_DEST"

# Idempotency: wipe every managed tree. Non-ed3d dirs are preserved.
find "$OPENCODE_DEST" -mindepth 1 -maxdepth 1 -type d -name 'ed3d-*' -exec rm -rf {} +
find "$OPENCODE_AGENTS_DEST" -mindepth 1 -maxdepth 1 -type f -name '*.md' -exec rm -f {} +
find "$CLAUDE_DEST" -mindepth 1 -maxdepth 1 -type d -exec rm -rf {} +
find "$CLAUDE_AGENTS_DEST" -mindepth 1 -maxdepth 1 -type f -name '*.md' -exec rm -f {} +

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

# --- opencode agent frontmatter filter ----------------------------------------

# Whitelist for agent frontmatter keys.
# Note: 'color' is rewritten separately by the awk filter so it can be
# mapped from Claude Code names to opencode's enum.
AGENT_ALLOWED_KEYS='^(description|model|mode|permission|hidden|steps|options|temperature|top_p)$'

# Map Claude Code color names to opencode theme colors (or strip if no match).
# opencode only accepts hex codes or these enum values:
#   primary, secondary, accent, success, warning, error, info
opencode_color() {
  case "$1" in
    cyan|blue)   echo "info" ;;
    green)       echo "success" ;;
    yellow)      echo "warning" ;;
    red)         echo "error" ;;
    orange)      echo "accent" ;;
    purple|pink) echo "secondary" ;;
    *)           echo "" ;;
  esac
}

# Map Claude Code model shortnames to opencode provider-prefixed model IDs.
# Must use versioned IDs (e.g. claude-opus-4-7) - generic names like
# claude-opus-4 pass schema validation at startup but fail at actual dispatch
# because they don't resolve to a real model on models.dev.
opencode_model() {
  case "$1" in
    opus)   echo "anthropic/claude-opus-4-8" ;;
    sonnet) echo "anthropic/claude-sonnet-4-6" ;;
    haiku)  echo "anthropic/claude-haiku-4-5" ;;
    *)      echo "anthropic/$1" ;;
  esac
}

# awk program for agent frontmatter: keeps whitelisted keys, translates
# model, injects mode: subagent, drops name (filename is the identifier).
AGENT_AWK_FILTER='
BEGIN { in_fm = 0; fm_done = 0; skip = 0; wrote_mode = 0 }
/^---[ \t]*$/ {
  if (!fm_done && !in_fm) {
    in_fm = 1
    print
    next
  }
  if (in_fm) {
    if (!wrote_mode) { print "mode: subagent"; wrote_mode = 1 }
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
    if (key == "tools") { skip = 1; next }
    if (key == "model") {
      val = $0
      sub(/^model[ \t]*:[ \t]*/, "", val)
      sub(/[ \t]+$/, "", val)
      print "model: " model_map[val]
      skip = 1
      next
    }
    if (key == "color") {
      val = $0
      sub(/^color[ \t]*:[ \t]*/, "", val)
      sub(/[ \t]+$/, "", val)
      if (color_map[val] != "") {
        print "color: " color_map[val]
      }
      skip = 1
      next
    }
    if (key == "mode") { print; wrote_mode = 1; skip = 0; next }
    if (key ~ allowed) { skip = 0; print } else { skip = 1 }
    next
  }
  if (!skip) print
  next
}
{ print }
'

# --- opencode renaming helpers -----------------------------------------------

# Rename map for directory / skill / plugin names.
opencode_rename() {
  local name="$1"
  name="${name//extending-claude/extending-opencode}"
  name="${name//writing-claude-md-files/writing-agents-md-files}"
  name="${name//writing-claude-directives/writing-opencode-directives}"
  name="${name//project-claude-librarian/project-opencode-librarian}"
  echo "$name"
}

# Text replacements applied to all opencode output files.
# Order matters: longer/more specific patterns first to avoid partial matches.
opencode_text_replace() {
  sed \
    -e 's/CLAUDE\.md/AGENTS.md/g' \
    -e 's/Claude Code/opencode/g' \
    -e 's/claude code/opencode/g' \
    -e 's/claude-code/opencode/g' \
    -e 's/extending-claude/extending-opencode/g' \
    -e 's/writing-claude-md-files/writing-agents-md-files/g' \
    -e 's/writing-claude-directives/writing-opencode-directives/g' \
    -e 's/project-claude-librarian/project-opencode-librarian/g' \
    -e 's/CLAUDE_MD_TESTING/AGENTS_MD_TESTING/g' \
    -e 's|~/\.claude/skills/|~/.config/opencode/skills/|g'
}

# Rename files whose names contain claude-specific terms.
opencode_rename_files() {
  local dir="$1"
  find "$dir" -depth -type f -name '*CLAUDE*' | while read -r f; do
    local base; base="$(basename "$f")"
    local newbase; newbase="${base//CLAUDE_MD/AGENTS_MD}"
    [[ "$base" != "$newbase" ]] && mv "$f" "$(dirname "$f")/$newbase"
  done
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
    # Apply dir name renames (plugin + skill level).
    oc_plugin="$(opencode_rename "$plugin_name")"
    oc_skill="$(opencode_rename "$skill_name")"
    oc_dir="$OPENCODE_DEST/$oc_plugin/$oc_skill"
    mkdir -p "$oc_dir"

    find "$skill_path" -mindepth 1 -maxdepth 1 ! -name 'SKILL.md' \
      -exec cp -R {} "$oc_dir/" \;

    # Rewrite SKILL.md: frontmatter filter + text replacements.
    # folder_name uses the renamed skill name so name: matches the dir.
    awk -v allowed="$ALLOWED_KEYS" -v folder_name="$oc_skill" "$AWK_FILTER" \
      "${skill_path}SKILL.md" | opencode_text_replace > "$oc_dir/SKILL.md"

    # Post-process auxiliary text files with the same replacements.
    find "$oc_dir" -type f ! -name 'SKILL.md' \( -name '*.md' -o -name '*.txt' \) \
      -exec "$SCRIPT_DIR/_opencode-text-replace.sh" {} +

    # Rename auxiliary files (e.g. CLAUDE_MD_TESTING.md -> AGENTS_MD_TESTING.md).
    opencode_rename_files "$oc_dir"

    # -- claude code: flat, original files verbatim --
    cc_dir="$CLAUDE_DEST/$skill_name"
    cp -R "$skill_path" "$cc_dir"

    count=$((count + 1))
  done
done
shopt -u nullglob

# --- Convert agents ----------------------------------------------------------

agent_count=0
shopt -s nullglob
for plugin_path in "$SOURCE_DIR"/plugins/*/; do
  plugin_name="$(basename "$plugin_path")"
  [[ -d "${plugin_path}agents" ]] || continue
  for agent_file in "${plugin_path}agents"/*.md; do
    agent_name="$(basename "$agent_file" .md)"
    [[ "$agent_name" == ".keep" ]] && continue

    fm_desc="$(extract_value "$agent_file" description)"
    fm_model="$(extract_value "$agent_file" model)"

    if [[ -z "$fm_desc" ]]; then
      echo "warn: ${plugin_name}/agents/${agent_name}.md missing 'description'; skipping" >&2
      continue
    fi

    # Rename agent name if it contains "claude".
    oc_agent_name="$(opencode_rename "$agent_name")"

    # Build model map for awk.
    oc_model="$(opencode_model "${fm_model:-sonnet}")"

    # Rewrite frontmatter + body text replacements.
    awk -v allowed="$AGENT_ALLOWED_KEYS" \
        -v "model_map_opus=$(opencode_model opus)" \
        -v "model_map_sonnet=$(opencode_model sonnet)" \
        -v "model_map_haiku=$(opencode_model haiku)" \
        -v "color_cyan=$(opencode_color cyan)" \
        -v "color_blue=$(opencode_color blue)" \
        -v "color_green=$(opencode_color green)" \
        -v "color_yellow=$(opencode_color yellow)" \
        -v "color_red=$(opencode_color red)" \
        -v "color_orange=$(opencode_color orange)" \
        -v "color_purple=$(opencode_color purple)" \
        -v "color_pink=$(opencode_color pink)" \
        "BEGIN {
          model_map[\"opus\"] = model_map_opus
          model_map[\"sonnet\"] = model_map_sonnet
          model_map[\"haiku\"] = model_map_haiku
          color_map[\"cyan\"] = color_cyan
          color_map[\"blue\"] = color_blue
          color_map[\"green\"] = color_green
          color_map[\"yellow\"] = color_yellow
          color_map[\"red\"] = color_red
          color_map[\"orange\"] = color_orange
          color_map[\"purple\"] = color_purple
          color_map[\"pink\"] = color_pink
        }
        $AGENT_AWK_FILTER" "$agent_file" \
      | opencode_text_replace > "$OPENCODE_AGENTS_DEST/${oc_agent_name}.md"

    # -- claude code: original agent verbatim --
    cp "$agent_file" "$CLAUDE_AGENTS_DEST/${agent_name}.md"

    agent_count=$((agent_count + 1))
  done
done
shopt -u nullglob

echo "converted $count skills, $agent_count agents"
echo "  source:  $SOURCE_DIR"
echo "  opencode skills:  $OPENCODE_DEST"
echo "  opencode agents:  $OPENCODE_AGENTS_DEST"
echo "  claude skills:    $CLAUDE_DEST"
echo "  claude agents:    $CLAUDE_AGENTS_DEST"
