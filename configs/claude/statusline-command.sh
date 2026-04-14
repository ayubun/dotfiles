#!/bin/sh
# Claude Code statusLine command

input=$(cat)

model=$(echo "$input" | jq -r '.model.display_name // "unknown"')
cwd=$(echo "$input" | jq -r '.cwd // ""')
used_pct=$(echo "$input" | jq -r '.context_window.used_percentage // empty')
total_tokens=$(echo "$input" | jq -r '.context_window.total_input_tokens // empty')
cost=$(echo "$input" | jq -r '.cost.total_cost_usd // empty')
session_name=$(echo "$input" | jq -r '.session_name // empty')
session_id=$(echo "$input" | jq -r '.session_id // empty')
worktree=$(echo "$input" | jq -r '.workspace.git_worktree // empty')

user=$(whoami)
host=$(hostname -s)
home=$(eval echo ~)

# Shorten cwd: replace $HOME with ~, truncate to 60 chars
short_cwd=$(echo "$cwd" | sed "s|^${home}|~|")
if [ ${#short_cwd} -gt 60 ]; then
  short_cwd="...$(echo "$short_cwd" | tail -c 58)"
fi

# Colors: #ffd7d7 for all main text, light grey for separators/session
C=$(printf '\033[38;2;255;215;215m')
R=$(printf '\033[0m')

# Light grey for separators and session name
G=$(printf '\033[38;2;160;160;160m')
dot="${G}·${R}"

# Git info
git_info=""
if [ -d "$cwd/.git" ] || [ -n "$worktree" ]; then
  branch=$(git -C "$cwd" symbolic-ref --short HEAD 2>/dev/null || git -C "$cwd" rev-parse --short HEAD 2>/dev/null)
  if [ -n "$branch" ]; then
    dirty=$(git -C "$cwd" status --porcelain 2>/dev/null | head -1)
    if [ -n "$dirty" ]; then
      git_info="${branch}*"
    else
      git_info="${branch}"
    fi
  fi
fi

# Build left part: user@host · cwd · git
left="${C}${user}@${host}${R} ${dot} ${C}${short_cwd}${R}"
left_vis="${user}@${host} · ${short_cwd}"
if [ -n "$git_info" ]; then
  left="${left} ${dot} ${C}${git_info}${R}"
  left_vis="${left_vis} · ${git_info}"
fi

# Build right info parts separated by grey ·
info=""
info_vis=""

if [ -n "$cost" ]; then
  cost_fmt=$(awk "BEGIN { printf \"%.2f\", ${cost} }")
  info="${C}\$${cost_fmt}${R}"
  info_vis="\$${cost_fmt}"
fi

if [ -n "$total_tokens" ] && [ -n "$used_pct" ]; then
  if [ "$total_tokens" -ge 1000 ] 2>/dev/null; then
    tok=$(awk "BEGIN { printf \"%.1f\", ${total_tokens} / 1000 }")
    tok_part="${tok}k (${used_pct}%)"
  else
    tok_part="${total_tokens} (${used_pct}%)"
  fi
  if [ -n "$info_vis" ]; then
    info="${info} ${dot} ${C}${tok_part}${R}"
    info_vis="${info_vis} · ${tok_part}"
  else
    info="${C}${tok_part}${R}"
    info_vis="${tok_part}"
  fi
elif [ -n "$used_pct" ]; then
  if [ -n "$info_vis" ]; then
    info="${info} ${dot} ${C}${used_pct}%${R}"
    info_vis="${info_vis} · ${used_pct}%"
  else
    info="${C}${used_pct}%${R}"
    info_vis="${used_pct}%"
  fi
fi

if [ -n "$info_vis" ]; then
  info="${info} ${dot} ${C}${model}${R}"
  info_vis="${info_vis} · ${model}"
else
  info="${C}${model}${R}"
  info_vis="${model}"
fi

# Center part: session name or id
# center_label="${session_name:-$session_id}"
center=""
center_vis=""
if [ -n "$center_label" ]; then
  center="${G}${center_label}${R}"
  center_vis="${center_label}"
fi

# Get terminal width
cols=$(stty size < /dev/tty 2>/dev/null | awk '{print $2}')
if [ -z "$cols" ] || [ "$cols" -lt 1 ] 2>/dev/null; then
  cols=$(tput cols 2>/dev/null)
fi
cols=${cols:-120}
cols=$((cols - 5))

# Calculate padding
left_len=${#left_vis}
center_len=${#center_vis}
right_len=${#info_vis}

if [ -n "$center_vis" ]; then
  center_pos=$(( (cols - center_len) / 2 ))
  left_gap=$((center_pos - left_len))
  right_gap=$((cols - center_pos - center_len - right_len))
  [ "$left_gap" -lt 1 ] && left_gap=1
  [ "$right_gap" -lt 1 ] && right_gap=1
  lpad=$(printf '%*s' "$left_gap" '')
  rpad=$(printf '%*s' "$right_gap" '')
  echo "${left}${lpad}${center}${rpad}${info}"
else
  gap=$((cols - left_len - right_len))
  [ "$gap" -lt 1 ] && gap=1
  padding=$(printf '%*s' "$gap" '')
  echo "${left}${padding}${info}"
fi
