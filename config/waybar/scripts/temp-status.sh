#!/usr/bin/env bash
set -euo pipefail

critical_c=80
mode="${1:-cpu}"

emit_json() {
  text="$1"
  tooltip="$2"
  class="$3"
  tooltip="${tooltip//\\/\\\\}"
  tooltip="${tooltip//\"/\\\"}"
  tooltip="${tooltip//$'\n'/\\n}"
  printf '{"text":"%s","tooltip":"%s","class":"%s"}\n' "$text" "$tooltip" "$class"
}

read_hwmon_temp_c() {
  name="$1"
  label_pat="${2:-}"
  for d in /sys/class/hwmon/hwmon*; do
    [ -f "$d/name" ] || continue
    [ "$(cat "$d/name" 2>/dev/null)" = "$name" ] || continue

    for in_f in "$d"/temp*_input; do
      [ -f "$in_f" ] || continue
      base="${in_f%_input}"
      if [ -n "$label_pat" ] && [ -f "${base}_label" ]; then
        label="$(cat "${base}_label" 2>/dev/null || true)"
        case "$label" in
          *"$label_pat"*) ;;
          *) continue ;;
        esac
      fi
      raw="$(cat "$in_f" 2>/dev/null || true)"
      case "$raw" in
        ''|*[!0-9]*) continue ;;
      esac
      awk -v r="$raw" 'BEGIN { printf "%.0f", r/1000 }'
      return 0
    done
  done
  return 1
}

emit_cpu() {
  source_name=""
  temp_c=""

  if temp_c="$(read_hwmon_temp_c k10temp Tctl)"; then
    source_name="CPU (k10temp/Tctl)"
  elif temp_c="$(read_hwmon_temp_c k10temp)"; then
    source_name="CPU (k10temp)"
  fi

  if [ -z "$temp_c" ]; then
    emit_json "CPU  --" "No supported CPU temperature sensor found" "temp-off"
    return 0
  fi

  class="temperature"
  crit="$(awk -v t="$temp_c" -v c="$critical_c" 'BEGIN { if (t >= c) print 1; else print 0 }')"
  if [ "$crit" = "1" ]; then
    class="critical"
  fi

  emit_json "CPU  ${temp_c}°C" "${source_name}: ${temp_c}°C" "$class"
}

emit_gpu() {
  if ! command -v nvidia-smi >/dev/null 2>&1; then
    emit_json "GPU  --" "NVIDIA GPU temperature unavailable (nvidia-smi not found)" "temp-off"
    return 0
  fi

  line="$(
    nvidia-smi \
      --query-gpu=name,temperature.gpu \
      --format=csv,noheader,nounits 2>/dev/null | head -n1 || true
  )"
  if [ -z "${line:-}" ]; then
    emit_json "GPU  --" "NVIDIA GPU temperature unavailable" "temp-off"
    return 0
  fi
  case "$line" in
    Failed\ to*|No\ devices\ were\ found*|NVIDIA-SMI\ has\ failed*)
      emit_json "GPU  --" "NVIDIA GPU temperature unavailable" "temp-off"
      return 0
      ;;
  esac

  IFS=',' read -r name temp_c <<EOF
$line
EOF

  trim() {
    printf '%s' "$1" | sed 's/^[[:space:]]*//; s/[[:space:]]*$//'
  }

  name="$(trim "${name:-NVIDIA}")"
  temp_c="$(trim "${temp_c:---}")"
  case "$temp_c" in ''|*[!0-9.]*) temp_c='--' ;; esac

  if [ "$temp_c" = "--" ]; then
    emit_json "GPU  --" "NVIDIA: ${name}" "temp-off"
    return 0
  fi

  class="temperature"
  crit="$(awk -v t="$temp_c" -v c="$critical_c" 'BEGIN { if (t >= c) print 1; else print 0 }')"
  if [ "$crit" = "1" ]; then
    class="critical"
  fi

  emit_json "GPU  ${temp_c}°C" "NVIDIA: ${name}\nTemp: ${temp_c}°C" "$class"
}

case "$mode" in
  cpu) emit_cpu ;;
  gpu) emit_gpu ;;
  *)
    emit_json "TEMP --" "Unknown mode: $mode" "temp-off"
    ;;
esac
