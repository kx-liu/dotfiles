#!/usr/bin/env bash
set -euo pipefail

notify() {
  command -v notify-send >/dev/null 2>&1 || return 0
  notify-send "Waybar Network" "$1"
}

if command -v nm-connection-editor >/dev/null 2>&1; then
  exec nm-connection-editor
fi

if command -v nmtui >/dev/null 2>&1; then
  for term in ghostty kitty alacritty foot wezterm gnome-terminal xterm; do
    if command -v "$term" >/dev/null 2>&1; then
      exec "$term" -e nmtui
    fi
  done
fi

if command -v gnome-control-center >/dev/null 2>&1; then
  exec gnome-control-center wifi
fi

if command -v plasmawindowed >/dev/null 2>&1 && command -v kcmshell6 >/dev/null 2>&1; then
  exec kcmshell6 kcm_networkmanagement
fi

notify "No network manager UI found (install network-manager-applet / nm-connection-editor)"
