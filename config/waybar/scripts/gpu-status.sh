#!/usr/bin/env bash
set -euo pipefail

emit_json() {
  text="$1"
  tooltip="$2"
  class="$3"
  tooltip="${tooltip//\\/\\\\}"
  tooltip="${tooltip//\"/\\\"}"
  tooltip="${tooltip//$'\n'/\\n}"
  printf '{"text":"%s","tooltip":"%s","class":"%s"}\n' "$text" "$tooltip" "$class"
}

emit_nvidia() {
  command -v nvidia-smi >/dev/null 2>&1 || return 1

  line="$(
    nvidia-smi \
      --query-gpu=name,utilization.gpu,temperature.gpu,memory.used,memory.total \
      --format=csv,noheader,nounits 2>/dev/null | head -n1 || true
  )"
  [ -n "${line:-}" ] || return 1
  case "$line" in
    Failed\ to*|No\ devices\ were\ found*|NVIDIA-SMI\ has\ failed*)
      return 1
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

  case "$util" in ''|*[!0-9]*) util=0 ;; esac
  case "$temp" in ''|*[!0-9]*) temp='--' ;; esac
  case "$mem_used" in ''|*[!0-9]*) mem_used=0 ;; esac
  case "$mem_total" in ''|*[!0-9]*) mem_total=0 ;; esac

  tooltip="NVIDIA: ${name}"
  tooltip="${tooltip}"$'\n'"Util: ${util}%"
  if [ "$temp" != "--" ]; then
    tooltip="${tooltip}"$'\n'"Temp: ${temp}°C"
  fi
  if [ "$mem_total" -gt 0 ] 2>/dev/null; then
    tooltip="${tooltip}"$'\n'"VRAM: ${mem_used}/${mem_total} MiB"
  fi

  emit_json "GPU ${util}%" "$tooltip" "gpu"
  return 0
}

if emit_nvidia; then
  exit 0
fi

emit_json "GPU --" "NVIDIA GPU data unavailable (nvidia-smi not found or no NVIDIA GPU visible)" "gpu-off"
