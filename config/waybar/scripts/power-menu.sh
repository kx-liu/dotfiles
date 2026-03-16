#!/usr/bin/env bash
set -euo pipefail

notify() {
  command -v notify-send >/dev/null 2>&1 || return 0
  notify-send "Waybar Power" "$1"
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

menu() {
  choices="$(cat <<'EOF'
󰍹  Windows
󰌾  Lock
󰍃  Logout
󰜉  Reboot
󰐥  Shutdown
EOF
)"

  # Approximate placement under the top-right power button.
  xoffset="-18"
  yoffset="42"

  if command -v wofi >/dev/null 2>&1; then
    printf "%s\n" "$choices" | wofi \
      --dmenu \
      --prompt "Session" \
      --lines 5 \
      --width 260 \
      --hide-scroll \
      --location top_right \
      --xoffset "$xoffset" \
      --yoffset "$yoffset"
  elif command -v fuzzel >/dev/null 2>&1; then
    printf "%s\n" "$choices" | fuzzel --dmenu --prompt "Session> "
  elif command -v rofi >/dev/null 2>&1; then
    printf "%s\n" "$choices" | rofi -dmenu -i -p "Session" -lines 5
  else
    notify "No menu app found (install wofi, fuzzel, or rofi)"
    return 1
  fi
}

choice="$(menu || true)"
case "$choice" in
  "󰍹  Windows"|"Windows"|"windows")
    run_windows_reboot
    ;;
  "󰌾  Lock"|"Lock"|"lock")
    loginctl lock-session
    ;;
  "󰍃  Logout"|"Logout"|"logout")
    if command -v hyprctl >/dev/null 2>&1; then
      hyprctl dispatch exit
    else
      notify "hyprctl not found"
      exit 1
    fi
    ;;
  "󰜉  Reboot"|"Reboot"|"reboot")
    systemctl reboot
    ;;
  "󰐥  Shutdown"|"Shutdown"|"shutdown")
    systemctl poweroff
    ;;
  *)
    exit 0
    ;;
esac
