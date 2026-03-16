#!/usr/bin/env bash
set -euo pipefail

notify() {
  command -v notify-send >/dev/null 2>&1 || return 0
  notify-send "Waybar Power" "$1"
}

select_action() {
  local choice

  if ! command -v yad >/dev/null 2>&1; then
    notify "Install yad for the session dialog"
    return 1
  fi

  choice="$(
    yad --list \
      --title="Session" \
      --width=520 \
      --height=320 \
      --column=Action \
      --column=Description \
      "lock" "Lock the current session" \
      "logout" "Exit Hyprland" \
      "reboot" "Reboot Fedora" \
      "shutdown" "Power off the machine" \
      "windows" "Reboot into Windows" \
      --button=Cancel:1 2>/dev/null
  )" || return 1

  printf '%s\n' "${choice%%|*}"
}

run_windows_reboot() {
  local win_script="/usr/local/bin/reboot-to-windows"

  [[ -x "$win_script" ]] || {
    notify "Windows reboot script not found: $win_script"
    return 1
  }

  # GUI environment usually needs privilege escalation here.
  if command -v pkexec >/dev/null 2>&1; then
    pkexec "$win_script"
  elif command -v sudo >/dev/null 2>&1; then
    sudo "$win_script"
  else
    notify "Need pkexec or sudo to reboot into Windows"
    return 1
  fi
}

choice="$(select_action || true)"
case "$choice" in
  windows)
    run_windows_reboot
    ;;
  lock)
    loginctl lock-session
    ;;
  logout)
    if command -v hyprctl >/dev/null 2>&1; then
      hyprctl dispatch exit
    else
      notify "hyprctl not found"
      exit 1
    fi
    ;;
  reboot)
    systemctl reboot
    ;;
  shutdown)
    systemctl poweroff
    ;;
  *)
    exit 0
    ;;
esac
