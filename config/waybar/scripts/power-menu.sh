#!/usr/bin/env bash
set -euo pipefail

notify() {
  command -v notify-send >/dev/null 2>&1 || return 0
  notify-send "Waybar Power" "$1"
}

compact_error() {
  local msg="${1//$'\n'/ }"
  msg="${msg#"${msg%%[![:space:]]*}"}"
  msg="${msg%"${msg##*[![:space:]]}"}"
  printf '%s\n' "$msg"
}

select_action() {
  local choice

  if ! command -v yad >/dev/null 2>&1; then
    notify "Install yad for the session dialog"
    return 1
  fi

  choice="$(
    yad --list \
      --title="Waybar Session" \
      --width=560 \
      --height=320 \
      --center \
      --on-top \
      --skip-taskbar \
      --undecorated \
      --margins=14 \
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
  local err=""

  [[ -x "$win_script" ]] || {
    notify "Windows reboot script not found: $win_script"
    return 1
  }

  if command -v pkexec >/dev/null 2>&1; then
    err="$(pkexec "$win_script" 2>&1)" && return 0
    err="$(compact_error "$err")"
  fi

  if command -v sudo >/dev/null 2>&1 && sudo -n true >/dev/null 2>&1; then
    err="$(sudo -n "$win_script" 2>&1)" && return 0
    err="$(compact_error "$err")"
  fi

  if [[ -z "$err" ]]; then
    err="Windows reboot failed: authentication was cancelled or no non-interactive sudo path is available"
  fi

  notify "$err"
  return 1
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
