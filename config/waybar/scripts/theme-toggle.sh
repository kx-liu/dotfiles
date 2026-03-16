#!/usr/bin/env bash
set -euo pipefail

config_dir="${HOME}/.config/waybar"
state_file="${config_dir}/.theme-mode"
active_theme_file="${config_dir}/waybar-theme.css"
transparent_file="${config_dir}/waybar-theme-transparent.css"
solid_file="${config_dir}/waybar-theme-solid.css"

mode="${1:-status}"

read_mode() {
  if [ -f "$state_file" ]; then
    m="$(cat "$state_file" 2>/dev/null || true)"
    case "$m" in
      transparent|solid) printf '%s\n' "$m"; return 0 ;;
    esac
  fi
  printf 'transparent\n'
}

write_mode() {
  printf '%s\n' "$1" > "$state_file"
}

apply_mode() {
  m="$1"
  case "$m" in
    transparent) cp "$transparent_file" "$active_theme_file" ;;
    solid) cp "$solid_file" "$active_theme_file" ;;
    *) return 1 ;;
  esac
}

reload_waybar() {
  if command -v systemctl >/dev/null 2>&1; then
    if systemctl --user is-active --quiet waybar.service 2>/dev/null; then
      systemctl --user restart waybar.service && return 0
    fi
  fi

  pkill -x waybar >/dev/null 2>&1 || true
  nohup waybar >/dev/null 2>&1 &
}

emit_status() {
  m="$1"
  if [ "$m" = "solid" ]; then
    text="◼"
    tooltip="Waybar theme: solid background"
    class="theme-solid"
  else
    text="◌"
    tooltip="Waybar theme: transparent background"
    class="theme-transparent"
  fi
  printf '{"text":"%s","tooltip":"%s","class":"%s"}\n' "$text" "$tooltip" "$class"
}

case "$mode" in
  status)
    emit_status "$(read_mode)"
    ;;
  toggle)
    current="$(read_mode)"
    if [ "$current" = "solid" ]; then
      next="transparent"
    else
      next="solid"
    fi
    apply_mode "$next"
    write_mode "$next"
    reload_waybar
    ;;
  set-transparent)
    apply_mode transparent
    write_mode transparent
    ;;
  set-solid)
    apply_mode solid
    write_mode solid
    ;;
  *)
    exit 1
    ;;
esac
