#!/usr/bin/env bash
set -euo pipefail

state_file="/tmp/waybar-cpu.prev"
tmp_file="$(mktemp /tmp/waybar-cpu.curr.XXXXXX)"
trap 'rm -f "$tmp_file"' EXIT

grep '^cpu' /proc/stat > "$tmp_file"

if [ ! -s "$state_file" ]; then
  cp "$tmp_file" "$state_file"
  echo '{"text":"CPU  0%","tooltip":"Collecting CPU usage...","class":"cpu"}'
  exit 0
fi

awk '
function total_sum(    i, t) {
  t = 0
  for (i = 2; i <= NF; i++) t += $i
  return t
}

FNR == NR {
  name = $1
  prev_total[name] = total_sum()
  prev_idle[name] = $5 + $6
  next
}

{
  name = $1
  curr_total = total_sum()
  curr_idle = $5 + $6
  d_total = curr_total - prev_total[name]
  d_idle = curr_idle - prev_idle[name]

  if (d_total > 0) {
    usage[name] = (d_total - d_idle) * 100 / d_total
  } else {
    usage[name] = 0
  }

  order[++count] = name
}

END {
  total = (("cpu" in usage) ? usage["cpu"] : 0)
  tooltip = sprintf("Total: %.0f%%", total)

  for (i = 1; i <= count; i++) {
    name = order[i]
    if (name == "cpu") continue
    tooltip = tooltip sprintf("\n%s: %.0f%%", name, usage[name])
  }

  gsub(/\\/, "\\\\", tooltip)
  gsub(/"/, "\\\"", tooltip)
  gsub(/\n/, "\\n", tooltip)

  printf("{\"text\":\"CPU %2.0f%%\",\"tooltip\":\"%s\",\"class\":\"cpu\"}\n", total, tooltip)
}
' "$state_file" "$tmp_file"

cp "$tmp_file" "$state_file"
