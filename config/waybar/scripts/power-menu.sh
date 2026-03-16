#!/usr/bin/env bash
set -euo pipefail

notify() {
  command -v notify-send >/dev/null 2>&1 || return 0
  notify-send "Waybar Power" "$1"
}

select_action() {
  if command -v yad >/dev/null 2>&1; then
    local choice
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
    return 0
  fi

  if command -v zenity >/dev/null 2>&1; then
    local choice
    choice="$(
      zenity --list \
      --title="Session" \
      --width=520 \
      --height=320 \
      --column=Action \
      --column=Description \
      "lock" "Lock the current session" \
      "logout" "Exit Hyprland" \
      "reboot" "Reboot Fedora" \
      "shutdown" "Power off the machine" \
      "windows" "Reboot into Windows" 2>/dev/null
    )" || return 1
    printf '%s\n' "${choice%%|*}"
    return 0
  fi

  if command -v kitty >/dev/null 2>&1; then
    local result_file
    result_file="$(mktemp)"

    kitty --title="Session" sh -lc '
      clear
      cat <<'"'"'EOF'"'"'
Session controls

1. Lock screen
2. Log out of Hyprland
3. Reboot Fedora
4. Shut down
5. Reboot into Windows

Press Enter without a choice to cancel.
EOF
      printf "\nChoose an option [1-5]: "
      read -r choice
      case "$choice" in
        1) printf "lock" > "$1" ;;
        2) printf "logout" > "$1" ;;
        3) printf "reboot" > "$1" ;;
        4) printf "shutdown" > "$1" ;;
        5) printf "windows" > "$1" ;;
      esac
    ' sh "$result_file" >/dev/null 2>&1 || true

    if [[ -f "$result_file" ]]; then
      cat "$result_file"
      rm -f "$result_file"
      return 0
    fi

    rm -f "$result_file"
    return 1
  fi

  notify "Install yad or zenity for session dialogs"
  return 1
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
