#!/usr/bin/env bash
set -euo pipefail

mode="${1:-cpu}"

show_text_dialog() {
  local title="$1"
  local body="$2"
  local tmp_file
  tmp_file="$(mktemp)"
  printf '%s\n' "$body" > "$tmp_file"

  if command -v yad >/dev/null 2>&1; then
    yad --title="$title" \
      --text-info \
      --fontname="Noto Sans Mono 11" \
      --width=760 \
      --height=480 \
      --filename="$tmp_file" \
      --button=Close:0 >/dev/null 2>&1 || true
    rm -f "$tmp_file"
    return 0
  fi

  if command -v zenity >/dev/null 2>&1; then
    zenity --text-info \
      --title="$title" \
      --width=760 \
      --height=480 \
      --filename="$tmp_file" >/dev/null 2>&1 || true
    rm -f "$tmp_file"
    return 0
  fi

  if command -v kitty >/dev/null 2>&1; then
    kitty --title="$title" sh -lc '
      clear
      cat "$1"
      rm -f "$1"
      printf "\nPress Enter to close..."
      read -r _
    ' sh "$tmp_file" >/dev/null 2>&1 || true
    return 0
  fi

  rm -f "$tmp_file"
}

cpu_details() {
  local first second
  first="$(mktemp)"
  second="$(mktemp)"
  trap 'rm -f "$first" "$second"' RETURN

  grep '^cpu' /proc/stat > "$first"
  sleep 0.2
  grep '^cpu' /proc/stat > "$second"

  local load_avg
  load_avg="$(awk '{printf "Load avg: %s %s %s", $1, $2, $3}' /proc/loadavg)"

  local body
  body="$(
    awk '
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
      order[++count] = name
    }

    END {
      printf("Total: %.1f%%\n", usage["cpu"])

      cells = 0
      line = ""
      for (i = 1; i <= count; i++) {
        name = order[i]
        if (name == "cpu") {
          continue
        }

        core = substr(name, 4) + 1
        cell = sprintf("c%02d %5.1f%%", core, usage[name])

        if (cells % 4 == 0) {
          line = cell
        } else {
          line = line "    " cell
        }

        cells++
        if (cells % 4 == 0) {
          print line
          line = ""
        }
      }

      if (line != "") {
        print line
      }
    }
    ' "$first" "$second"
  )"

  show_text_dialog "CPU" "${load_avg}"$'\n'"${body}"
}

gpu_details() {
  if ! command -v nvidia-smi >/dev/null 2>&1; then
    show_text_dialog "GPU" "nvidia-smi not found"
    return 0
  fi

  local line name util temp mem_used mem_total
  line="$(
    nvidia-smi \
      --query-gpu=name,utilization.gpu,temperature.gpu,memory.used,memory.total \
      --format=csv,noheader,nounits 2>/dev/null | head -n1
  )"

  if [[ -z "${line:-}" ]]; then
    show_text_dialog "GPU" "No NVIDIA GPU data available"
    return 0
  fi

  case "$line" in
    Failed\ to*|No\ devices\ were\ found*)
    show_text_dialog "GPU" "No NVIDIA GPU data available"
    return 0
    ;;
  esac

  IFS=',' read -r name util temp mem_used mem_total <<EOF
$line
EOF

  trim() {
    printf '%s' "$1" | sed 's/^[[:space:]]*//; s/[[:space:]]*$//'
  }

  name="$(trim "${name:-NVIDIA}")"
  util="$(trim "${util:-0}")"
  temp="$(trim "${temp:---}")"
  mem_used="$(trim "${mem_used:-0}")"
  mem_total="$(trim "${mem_total:-0}")"

  show_text_dialog "GPU" "Model: ${name}
Util: ${util}%
Temp: ${temp}°C
VRAM: ${mem_used}/${mem_total} MiB"
}

memory_details() {
  local body
  body="$(
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

      printf("RAM: %s / %s (%.1f%%)\n", fmt_gib(mem_used), fmt_gib(mem_total), mem_pct)
      printf("Available: %s\n", fmt_gib(mem_avail))
      printf("Cached: %s\n", fmt_gib(cached))
      printf("Swap: %s / %s (%.1f%%)", fmt_gib(swap_used), fmt_gib(swap_total), swap_pct)
    }
    ' /proc/meminfo
  )"

  show_text_dialog "Memory" "$body"
}

case "$mode" in
  cpu)
    cpu_details
    ;;
  gpu)
    gpu_details
    ;;
  memory)
    memory_details
    ;;
  *)
    exit 1
    ;;
esac
