#!/usr/bin/env bash
set -euo pipefail

mode="${1:-cpu}"
runtime_dir="${XDG_RUNTIME_DIR:-/tmp}"
state_dir="${runtime_dir}/waybar-system-info"
mkdir -p "$state_dir"

pid_file="${state_dir}/${mode}.pid"

trim() {
  printf '%s' "$1" | sed 's/^[[:space:]]*//; s/[[:space:]]*$//'
}

cursor_position() {
  local out x y

  if command -v hyprctl >/dev/null 2>&1; then
    out="$(hyprctl cursorpos -j 2>/dev/null || true)"
    if [[ -n "$out" ]]; then
      x="$(printf '%s\n' "$out" | sed -n 's/.*"x"[[:space:]]*:[[:space:]]*\([0-9.]\+\).*/\1/p' | head -n1)"
      y="$(printf '%s\n' "$out" | sed -n 's/.*"y"[[:space:]]*:[[:space:]]*\([0-9.]\+\).*/\1/p' | head -n1)"
      if [[ -n "$x" && -n "$y" ]]; then
        printf '%s %s\n' "${x%.*}" "${y%.*}"
        return 0
      fi
    fi
  fi

  printf '0 0\n'
}

kill_popup() {
  if [[ -f "$pid_file" ]]; then
    local pid
    pid="$(cat "$pid_file" 2>/dev/null || true)"
    if [[ "$pid" =~ ^[0-9]+$ ]] && kill -0 "$pid" >/dev/null 2>&1; then
      kill "$pid" >/dev/null 2>&1 || true
      wait "$pid" 2>/dev/null || true
    fi
    rm -f "$pid_file"
  fi
}

popup_running() {
  [[ -f "$pid_file" ]] || return 1
  local pid
  pid="$(cat "$pid_file" 2>/dev/null || true)"
  [[ "$pid" =~ ^[0-9]+$ ]] || return 1
  kill -0 "$pid" >/dev/null 2>&1
}

cpu_payload() {
  local first second
  first="$(mktemp)"
  second="$(mktemp)"
  trap 'rm -f "$first" "$second"' RETURN

  grep '^cpu' /proc/stat > "$first"
  sleep 0.15
  grep '^cpu' /proc/stat > "$second"

  local load1 load5 load15
  read -r load1 load5 load15 _ < /proc/loadavg

  awk -v load1="$load1" -v load5="$load5" -v load15="$load15" '
  function total_sum(    i, t) {
    t = 0
    for (i = 2; i <= NF; i++) t += $i
    return t
  }

  FNR == NR {
    prev_total[$1] = total_sum()
    prev_idle[$1] = $5 + $6
    next
  }

  {
    name = $1
    curr_total = total_sum()
    curr_idle = $5 + $6
    d_total = curr_total - prev_total[name]
    d_idle = curr_idle - prev_idle[name]
    usage[name] = (d_total > 0) ? ((d_total - d_idle) * 100 / d_total) : 0
  }

  END {
    total = usage["cpu"]
    printf("Total %.1f%%  |  Load %s %s %s\n", total, load1, load5, load15)

    for (row = 0; row < 4; row++) {
      line = ""
      for (col = 0; col < 8; col++) {
        idx = row * 8 + col
        name = "cpu" idx
        cell = sprintf("c%02d %4.1f%%", idx, usage[name])
        if (col == 0) {
          line = cell
        } else {
          line = line "   " cell
        }
      }
      print line
    }
  }
  ' "$first" "$second"
}

gpu_payload() {
  if ! command -v nvidia-smi >/dev/null 2>&1; then
    printf 'NVIDIA GPU unavailable\nnvidia-smi not found\n\n'
    return 0
  fi

  local line name util temp mem_used mem_total
  line="$(
    nvidia-smi \
      --query-gpu=name,utilization.gpu,temperature.gpu,memory.used,memory.total \
      --format=csv,noheader,nounits 2>/dev/null | head -n1
  )"

  case "${line:-}" in
    ""|Failed\ to*|No\ devices\ were\ found*)
      printf 'NVIDIA GPU unavailable\nNo live data\n\n'
      return 0
      ;;
  esac

  IFS=',' read -r name util temp mem_used mem_total <<EOF
$line
EOF

  name="$(trim "${name:-NVIDIA}")"
  util="$(trim "${util:-0}")"
  temp="$(trim "${temp:---}")"
  mem_used="$(trim "${mem_used:-0}")"
  mem_total="$(trim "${mem_total:-0}")"

  printf '%s\n' "$name"
  printf 'Util %s%%  |  Temp %s°C\n' "$util" "$temp"
  printf 'VRAM %s / %s MiB\n' "$mem_used" "$mem_total"
}

memory_payload() {
  awk '
  function fmt_gib(kb) {
    return sprintf("%.1f GiB", kb / 1024 / 1024)
  }

  /^MemTotal:/      { mem_total = $2 }
  /^MemAvailable:/  { mem_avail = $2 }
  /^Cached:/        { cached = $2 }
  /^SwapTotal:/     { swap_total = $2 }
  /^SwapFree:/      { swap_free = $2 }

  END {
    mem_used = mem_total - mem_avail
    swap_used = swap_total - swap_free
    mem_pct = (mem_total > 0) ? (mem_used * 100 / mem_total) : 0
    swap_pct = (swap_total > 0) ? (swap_used * 100 / swap_total) : 0

    printf("RAM %s / %s (%.1f%%)\n", fmt_gib(mem_used), fmt_gib(mem_total), mem_pct)
    printf("Available %s  |  Cached %s\n", fmt_gib(mem_avail), fmt_gib(cached))
    printf("Swap %s / %s (%.1f%%)\n", fmt_gib(swap_used), fmt_gib(swap_total), swap_pct)
  }
  ' /proc/meminfo
}

payload() {
  case "$mode" in
    cpu)
      cpu_payload
      ;;
    gpu)
      gpu_payload
      ;;
    memory)
      memory_payload
      ;;
    *)
      exit 1
      ;;
  esac
}

popup_title() {
  case "$mode" in
    cpu) printf 'Waybar CPU' ;;
    gpu) printf 'Waybar GPU' ;;
    memory) printf 'Waybar Memory' ;;
  esac
}

popup_width() {
  case "$mode" in
    cpu) printf '920' ;;
    gpu) printf '460' ;;
    memory) printf '520' ;;
  esac
}

popup_height() {
  case "$mode" in
    cpu) printf '190' ;;
    gpu) printf '130' ;;
    memory) printf '130' ;;
  esac
}

popup_position() {
  local width height cx cy posx posy

  width="$(popup_width)"
  height="$(popup_height)"
  read -r cx cy <<EOF
$(cursor_position)
EOF

  posx=$((cx - width / 2))
  posy=$((cy + 18))

  if (( posx < 0 )); then
    posx=0
  fi
  if (( posy < 0 )); then
    posy=0
  fi

  printf '%s %s\n' "$posx" "$posy"
}

launch_popup() {
  command -v yad >/dev/null 2>&1 || exit 0

  local posx posy
  read -r posx posy <<EOF
$(popup_position)
EOF

  case "$mode" in
    cpu)
      (
        while :; do
          payload
          sleep 1
        done
      ) | yad \
        --title="$(popup_title)" \
        --form \
        --fixed \
        --undecorated \
        --skip-taskbar \
        --on-top \
        --close-on-unfocus \
        --no-buttons \
        --align=left \
        --width="$(popup_width)" \
        --height="$(popup_height)" \
        --posx="$posx" \
        --posy="$posy" \
        --columns=1 \
        --margins=12 \
        --fontname="Noto Sans Mono 11" \
        --field="Summary":RO \
        --field="Cores 0-7":RO \
        --field="Cores 8-15":RO \
        --field="Cores 16-23":RO \
        --field="Cores 24-31":RO \
        --cycle-read >/dev/null 2>&1
      ;;
    gpu)
      (
        while :; do
          payload
          sleep 1
        done
      ) | yad \
        --title="$(popup_title)" \
        --form \
        --fixed \
        --undecorated \
        --skip-taskbar \
        --on-top \
        --close-on-unfocus \
        --no-buttons \
        --align=left \
        --width="$(popup_width)" \
        --height="$(popup_height)" \
        --posx="$posx" \
        --posy="$posy" \
        --columns=1 \
        --margins=12 \
        --fontname="Noto Sans Mono 11" \
        --field="GPU":RO \
        --field="Live":RO \
        --field="VRAM":RO \
        --cycle-read >/dev/null 2>&1
      ;;
    memory)
      (
        while :; do
          payload
          sleep 1
        done
      ) | yad \
        --title="$(popup_title)" \
        --form \
        --fixed \
        --undecorated \
        --skip-taskbar \
        --on-top \
        --close-on-unfocus \
        --no-buttons \
        --align=left \
        --width="$(popup_width)" \
        --height="$(popup_height)" \
        --posx="$posx" \
        --posy="$posy" \
        --columns=1 \
        --margins=12 \
        --fontname="Noto Sans Mono 11" \
        --field="RAM":RO \
        --field="Memory":RO \
        --field="Swap":RO \
        --cycle-read >/dev/null 2>&1
      ;;
  esac
}

if popup_running; then
  kill_popup
  exit 0
fi

launch_popup &
popup_pid=$!
printf '%s\n' "$popup_pid" > "$pid_file"
disown "$popup_pid" 2>/dev/null || true
