#!/usr/bin/env bash
set -euo pipefail

notify() {
  command -v notify-send >/dev/null 2>&1 || return 0
  notify-send "Waybar Launcher" "$1"
}

if command -v wofi >/dev/null 2>&1; then
  exec wofi --show drun
fi

if command -v rofi >/dev/null 2>&1; then
  exec rofi -show drun
fi

if command -v fuzzel >/dev/null 2>&1; then
  exec fuzzel
fi

if command -v bemenu-run >/dev/null 2>&1; then
  exec bemenu-run
fi

if command -v walker >/dev/null 2>&1; then
  exec walker
fi

notify "No app launcher found (install wofi or rofi)"
