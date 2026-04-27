#!/usr/bin/env bash
set -euo pipefail

direction="${1:-down}"
runtime_base="${XDG_RUNTIME_DIR:-/tmp}"
state_dir="${runtime_base}/waybar-network-speed"
if ! mkdir -p "$state_dir" 2>/dev/null; then
  state_dir="/tmp/waybar-network-speed"
  mkdir -p "$state_dir"
fi

active_iface() {
  local route iface

  route="$(ip route show default 2>/dev/null | head -n1 || true)"
  iface="$(printf '%s\n' "$route" | sed -n 's/.* dev \([^ ]*\).*/\1/p')"
  if [[ -n "$iface" && -d "/sys/class/net/$iface" ]]; then
    printf '%s\n' "$iface"
    return 0
  fi

  for path in /sys/class/net/*; do
    iface="${path##*/}"
    [[ "$iface" == "lo" ]] && continue
    [[ -f "$path/operstate" ]] || continue
    [[ "$(cat "$path/operstate" 2>/dev/null || true)" == "up" ]] || continue
    printf '%s\n' "$iface"
    return 0
  done

  return 1
}

format_rate() {
  awk -v bps="$1" 'BEGIN {
    if (bps < 1024) {
      printf "%.0fB/s", bps
    } else if (bps < 1024 * 1024) {
      printf "%.0fK/s", bps / 1024
    } else if (bps < 1024 * 1024 * 1024) {
      printf "%.1fM/s", bps / 1024 / 1024
    } else {
      printf "%.1fG/s", bps / 1024 / 1024 / 1024
    }
  }'
}

json_escape() {
  local value="$1"
  value="${value//\\/\\\\}"
  value="${value//\"/\\\"}"
  value="${value//$'\n'/\\n}"
  printf '%s' "$value"
}

emit() {
  local text="$1"
  local tooltip="$2"
  local class="$3"
  printf '{"text":"%s","tooltip":"%s","class":"%s"}\n' \
    "$(json_escape "$text")" \
    "$(json_escape "$tooltip")" \
    "$class"
}

case "$direction" in
  down|up) ;;
  *) direction="down" ;;
esac

if ! iface="$(active_iface)"; then
  if [[ "$direction" == "down" ]]; then
    emit "D --" "No active network interface" "net-down-off"
  else
    emit "U --" "No active network interface" "net-up-off"
  fi
  exit 0
fi

rx_file="/sys/class/net/${iface}/statistics/rx_bytes"
tx_file="/sys/class/net/${iface}/statistics/tx_bytes"
[[ -r "$rx_file" && -r "$tx_file" ]] || {
  if [[ "$direction" == "down" ]]; then
    emit "D --" "Network statistics unavailable for ${iface}" "net-off"
  else
    emit "U --" "Network statistics unavailable for ${iface}" "net-off"
  fi
  exit 0
}

now="$(date +%s)"
rx="$(cat "$rx_file")"
tx="$(cat "$tx_file")"
state_file="${state_dir}/${iface}.state"
if ! touch "$state_file" 2>/dev/null; then
  state_dir="/tmp/waybar-network-speed"
  mkdir -p "$state_dir"
  state_file="${state_dir}/${iface}.state"
fi

prev_ts="$now"
prev_rx="$rx"
prev_tx="$tx"
rx_rate=0
tx_rate=0
have_state=0
if [[ -f "$state_file" ]]; then
  if read -r prev_ts prev_rx prev_tx rx_rate tx_rate < "$state_file"; then
    have_state=1
  fi
fi

if (( have_state == 0 )); then
  printf '%s %s %s %s %s\n' "$now" "$rx" "$tx" "$rx_rate" "$tx_rate" > "$state_file"
elif (( now > prev_ts )); then
  elapsed=$((now - prev_ts))
  if (( elapsed < 1 )); then
    elapsed=1
  fi

  rx_rate=$(((rx - prev_rx) / elapsed))
  tx_rate=$(((tx - prev_tx) / elapsed))
  if (( rx_rate < 0 )); then rx_rate=0; fi
  if (( tx_rate < 0 )); then tx_rate=0; fi

  printf '%s %s %s %s %s\n' "$now" "$rx" "$tx" "$rx_rate" "$tx_rate" > "$state_file"
fi

down_text="D $(format_rate "$rx_rate")"
up_text="U $(format_rate "$tx_rate")"
tooltip="${iface}\nDownload: $(format_rate "$rx_rate")\nUpload: $(format_rate "$tx_rate")"

if [[ "$direction" == "down" ]]; then
  emit "$down_text" "$tooltip" "net-down"
else
  emit "$up_text" "$tooltip" "net-up"
fi
