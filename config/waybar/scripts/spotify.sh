#!/usr/bin/env bash
set -euo pipefail

action="${1:-status}"
refresh_signal="8"

notify() {
  command -v notify-send >/dev/null 2>&1 || return 0
  notify-send "Waybar Spotify" "$1"
}

launch_spotify() {
  if command -v spotify >/dev/null 2>&1; then
    nohup spotify >/dev/null 2>&1 &
    (
      sleep 2
      refresh_waybar
    ) >/dev/null 2>&1 &
    return 0
  fi

  if command -v flatpak >/dev/null 2>&1 && flatpak info com.spotify.Client >/dev/null 2>&1; then
    nohup flatpak run com.spotify.Client >/dev/null 2>&1 &
    (
      sleep 2
      refresh_waybar
    ) >/dev/null 2>&1 &
    return 0
  fi

  notify "Spotify is not installed"
  return 1
}

emit_json() {
  local text="$1"
  local tooltip="$2"
  local class="$3"

  tooltip="${tooltip//\\/\\\\}"
  tooltip="${tooltip//\"/\\\"}"
  tooltip="${tooltip//$'\n'/\\n}"

  printf '{"text":"%s","tooltip":"%s","class":"%s"}\n' "$text" "$tooltip" "$class"
}

refresh_waybar() {
  pkill "-RTMIN+${refresh_signal}" -x waybar >/dev/null 2>&1 || true
}

status_json() {
  if ! command -v playerctl >/dev/null 2>&1; then
    emit_json "" "playerctl not installed" "spotify-offline"
    return 0
  fi

  local status
  if ! status="$(playerctl --player=spotify status 2>/dev/null)"; then
    emit_json "" "Spotify not running\nLeft click to launch" "spotify-offline"
    return 0
  fi

  local artist title state_icon class text
  artist="$(playerctl --player=spotify metadata artist 2>/dev/null || true)"
  title="$(playerctl --player=spotify metadata title 2>/dev/null || true)"

  case "$status" in
    Playing)
      state_icon=""
      class="spotify-playing"
      ;;
    Paused)
      state_icon=""
      class="spotify-paused"
      ;;
    *)
      state_icon=""
      class="spotify-offline"
      ;;
  esac

  if [[ -n "$artist" && -n "$title" ]]; then
    text=" ${state_icon} ${artist} - ${title}"
  elif [[ -n "$title" ]]; then
    text=" ${state_icon} ${title}"
  else
    text=" ${state_icon} Spotify"
  fi

  emit_json "$text" "Spotify: ${status}
Left click: play/pause
Middle click: next
Right click: previous" "$class"
}

case "$action" in
  status)
    status_json
    ;;
  toggle)
    if command -v playerctl >/dev/null 2>&1 && playerctl --player=spotify status >/dev/null 2>&1; then
      playerctl --player=spotify play-pause
      (
        sleep 0.15
        refresh_waybar
      ) >/dev/null 2>&1 &
    else
      launch_spotify
    fi
    ;;
  next)
    if command -v playerctl >/dev/null 2>&1 && playerctl --player=spotify status >/dev/null 2>&1; then
      playerctl --player=spotify next
      (
        sleep 0.15
        refresh_waybar
      ) >/dev/null 2>&1 &
    else
      launch_spotify
    fi
    ;;
  previous)
    if command -v playerctl >/dev/null 2>&1 && playerctl --player=spotify status >/dev/null 2>&1; then
      playerctl --player=spotify previous
      (
        sleep 0.15
        refresh_waybar
      ) >/dev/null 2>&1 &
    else
      launch_spotify
    fi
    ;;
  *)
    exit 1
    ;;
esac
