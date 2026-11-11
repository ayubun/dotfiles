#!/bin/bash
# Records memory pressure and OOM evidence under the persistent home disk, one file set per boot.
set -u

OUT_DIR="${MEMWATCH_DIR:?}"
INTERVAL="${MEMWATCH_INTERVAL:-10}"
KEEP_DAYS="${MEMWATCH_KEEP_DAYS:-30}"
MAX_MB="${MEMWATCH_MAX_MB:-300}"

mkdir -p "$OUT_DIR"
BOOT_ID=$(tr -d '-' < /proc/sys/kernel/random/boot_id)
STAMP="$(date -u -d "@$(($(date +%s) - $(cut -d. -f1 /proc/uptime)))" +%Y%m%dT%H%M%SZ)-${BOOT_ID:0:8}"
SAMPLES="$OUT_DIR/$STAMP.samples.log"
JOURNAL="$OUT_DIR/$STAMP.journal.log"
SNAPSHOTS="$OUT_DIR/$STAMP.snapshots.log"

prune() {
  find "$OUT_DIR" -maxdepth 1 -name '*.log' ! -name "$STAMP.*" -exec gzip -q {} \;
  find "$OUT_DIR" -maxdepth 1 -name '*.log.gz' -mtime +"$KEEP_DAYS" -delete
  while (($(du -sm "$OUT_DIR" | cut -f1) > MAX_MB)); do
    oldest=$(ls -1tr "$OUT_DIR"/*.gz 2>/dev/null | head -1)
    [[ -n $oldest ]] || break
    rm -f "$oldest"
  done
}
prune

# Kernel messages (OOM killer, hung tasks), systemd unit results, and the coder agent survive the root disk reset this way.
backlog=all
[[ -s $JOURNAL ]] && backlog=0
journalctl -b -f -n "$backlog" -o short-iso-precise _TRANSPORT=kernel + _PID=1 + _SYSTEMD_UNIT=coder-agent.service >> "$JOURNAL" 2>&1 &
journal_pid=$!
trap 'kill $journal_pid 2>/dev/null' EXIT

total_kb=$(awk '/^MemTotal:/ {print $2}' /proc/meminfo)
last_snapshot=0
tick=0

top_cgroups() {
  # Anonymous memory only, because memory.current also counts reclaimable page cache.
  for f in /sys/fs/cgroup/system.slice/*/memory.stat /sys/fs/cgroup/user.slice/user-*.slice/user@*.service/*/*/memory.stat /sys/fs/cgroup/user.slice/user-*.slice/user@*.service/app.slice/app-t3code.slice/*/*/memory.stat /sys/fs/cgroup/user.slice/user-*.slice/session-*.scope/memory.stat; do
    [[ -r $f ]] && awk -v n="${f#/sys/fs/cgroup/}" '$1 == "anon" {print $2, n}' "$f"
  done | sort -rn | head -"$1" | awk '{sub(/\/memory.stat$/, "", $2); n=split($2, p, "/"); printf "%s=%.1fG ", p[n], $1/1073741824}'
}

while sleep "$INTERVAL"; do
  read -r avail_kb swap_total swap_free < <(awk '/^MemAvailable:/ {a=$2} /^SwapTotal:/ {t=$2} /^SwapFree:/ {f=$2} END {print a, t, f}' /proc/meminfo)
  swap_used_kb=$((swap_total - swap_free))
  read -r some10 full10 < <(awk -F'[ =]' '/^some/ {s=$3} /^full/ {f=$3} END {print s, f}' /proc/pressure/memory)
  procs=$(ps -eo rss=,pid=,comm= --sort=-rss)
  top=$(head -6 <<< "$procs" | awk '{printf "%s(%s)=%.1fG ", $3, $2, $1/1048576}')
  by_name=$(awk '{s[$3]+=$1; c[$3]++} END {for (n in s) printf "%d %s %d\n", s[n], n, c[n]}' <<< "$procs" | sort -rn | head -5 | awk '{printf "%sx%d=%.1fG ", $2, $3, $1/1048576}')
  line="$(date -u +%FT%TZ) avail=$(awk "BEGIN {printf \"%.1f\", $avail_kb/1048576}")G swap=$(awk "BEGIN {printf \"%.1f\", $swap_used_kb/1048576}")G psi_some10=$some10 psi_full10=$full10 | top: $top| by_name: $by_name"
  ((tick % 6 == 0)) && line+="| cgroups: $(top_cgroups 6)"
  echo "$line" >> "$SAMPLES"
  tick=$((tick + 1))

  now=$(date +%s)
  if ((avail_kb * 100 < total_kb * 15 || swap_used_kb > 2097152)) || awk "BEGIN {exit !($full10 > 5)}"; then
    if ((now - last_snapshot >= 60)); then
      last_snapshot=$now
      {
        echo "===== $(date -u +%FT%TZ) avail_kb=$avail_kb swap_used_kb=$swap_used_kb psi_full10=$full10"
        cat /proc/pressure/memory
        grep -E '^(MemTotal|MemFree|MemAvailable|Buffers|Cached|SwapTotal|SwapFree|Shmem|Slab|SUnreclaim|AnonPages|Dirty):' /proc/meminfo
        echo "--- cgroups"
        top_cgroups 15 | tr ' ' '\n'
        echo "--- processes"
        ps -eo pid,ppid,user,rss,etimes,args --sort=-rss | head -40 | cut -c1-300
      } >> "$SNAPSHOTS"
      sync -f "$SNAPSHOTS"
    fi
  fi
  ((tick % 360 == 0)) && prune
done
