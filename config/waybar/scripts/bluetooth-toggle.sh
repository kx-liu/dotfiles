#!/usr/bin/env bash
set -euo pipefail

notify() {
  command -v notify-send >/dev/null 2>&1 || return 0
  notify-send "Waybar Bluetooth" "$1"
}

action="${1:-toggle}"

if [ "$action" = "manage" ]; then
  if command -v blueman-manager >/dev/null 2>&1; then
    exec blueman-manager
  fi
  if command -v blueberry >/dev/null 2>&1; then
    exec blueberry
  fi
  if command -v gnome-control-center >/dev/null 2>&1; then
    exec gnome-control-center bluetooth
  fi
  if command -v kcmshell6 >/dev/null 2>&1; then
    exec kcmshell6 kcm_bluetooth
  fi
  if command -v kcmshell5 >/dev/null 2>&1; then
    exec kcmshell5 kcm_bluetooth
  fi
  notify "No Bluetooth manager found (install blueman)"
  exit 0
fi

# Prevent duplicate toggles from rapid repeated click events.
ts_file="/tmp/waybar-bluetooth-toggle.ts"
now_ms="$(date +%s%3N 2>/dev/null || printf '%s000' "$(date +%s)")"
if [ -f "$ts_file" ]; then
  last_ms="$(cat "$ts_file" 2>/dev/null || printf '0')"
  case "$last_ms" in
    ''|*[!0-9]*) last_ms=0 ;;
  esac
  if [ $((now_ms - last_ms)) -lt 700 ]; then
    exit 0
  fi
fi
printf '%s\n' "$now_ms" > "$ts_file"

if ! command -v rfkill >/dev/null 2>&1; then
  notify "rfkill not found"
  exit 0
fi

if ! rfkill list bluetooth >/dev/null 2>&1; then
  notify "No Bluetooth adapter found via rfkill"
  exit 0
fi

if rfkill list bluetooth | grep -qi "Soft blocked: no"; then
  if rfkill block bluetooth; then
    exit 0
  else
    notify "Failed to block Bluetooth"
  fi
else
  if rfkill unblock bluetooth; then
    exit 0
  else
    notify "Failed to unblock Bluetooth"
  fi
fi
