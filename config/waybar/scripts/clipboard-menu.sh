#!/usr/bin/env bash
set -euo pipefail

if ! command -v cliphist >/dev/null 2>&1 || ! command -v wl-copy >/dev/null 2>&1; then
  exit 0
fi

menu() {
  if command -v wofi >/dev/null 2>&1; then
    wofi --dmenu --prompt "Clipboard"
  else
    rofi -dmenu -p "Clipboard"
  fi
}

sel="$(cliphist list | menu || true)"
[[ -z "${sel}" ]] && exit 0
printf "%s" "$sel" | cliphist decode | wl-copy