#!/usr/bin/env bash
set -euo pipefail

notify() {
  command -v notify-send >/dev/null 2>&1 || return 0
  notify-send "Waybar Audio" "$1"
}

action="${1:-toggle}"

case "$action" in
  toggle)
    if ! command -v pactl >/dev/null 2>&1; then
      notify "pactl not found"
      exit 0
    fi
    pactl set-sink-mute @DEFAULT_SINK@ toggle
    ;;
  settings)
    if command -v pavucontrol >/dev/null 2>&1; then
      exec pavucontrol
    fi
    if command -v pwvucontrol >/dev/null 2>&1; then
      exec pwvucontrol
    fi
    notify "No mixer UI found (install pavucontrol or pwvucontrol)"
    ;;
  *)
    exit 1
    ;;
esac
