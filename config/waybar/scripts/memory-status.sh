#!/usr/bin/env bash
set -euo pipefail

awk '
function fmt_gib(kb) {
  return sprintf("%.1f GiB", kb / 1024 / 1024)
}

/^MemTotal:/     { total = $2 }
/^MemAvailable:/ { available = $2 }
/^Cached:/       { cached = $2 }
/^SwapTotal:/    { swap_total = $2 }
/^SwapFree:/     { swap_free = $2 }

END {
  used = total - available
  pct = (total > 0) ? (used * 100 / total) : 0
  swap_used = swap_total - swap_free
  swap_pct = (swap_total > 0) ? (swap_used * 100 / swap_total) : 0

  tooltip = sprintf("RAM: %s / %s (%.0f%%)\\nAvailable: %s\\nCached: %s\\nSwap: %s / %s (%.0f%%)",
    fmt_gib(used), fmt_gib(total), pct, fmt_gib(available), fmt_gib(cached),
    fmt_gib(swap_used), fmt_gib(swap_total), swap_pct)

  printf("{\"text\":\"RAM %2.0f%%\",\"tooltip\":\"%s\",\"class\":\"memory\"}\n", pct, tooltip)
}
' /proc/meminfo
