#!/usr/bin/env bash
set -euo pipefail

runtime_base="${XDG_RUNTIME_DIR:-/tmp}"
state_dir="${runtime_base}/waybar-idle-mode"
if ! mkdir -p "$state_dir" 2>/dev/null; then
  runtime_base="/tmp"
  state_dir="${runtime_base}/waybar-idle-mode"
  mkdir -p "$state_dir"
fi

state_file="${state_dir}/state"
hibernate_pid_file="${state_dir}/hibernate_timer.pid"
inhibit_pid_file="${state_dir}/inhibit.pid"
hypridle_flag_file="${state_dir}/hypridle_stopped_by_waybar"

cmd="${1:-status}"

notify() {
  command -v notify-send >/dev/null 2>&1 || return 0
  notify-send "Waybar Idle Mode" "$1"
}

read_state() {
  if [ -f "$state_file" ]; then
    s="$(cat "$state_file" 2>/dev/null || true)"
    case "$s" in
      awake|sleep) printf '%s\n' "$s"; return 0 ;;
    esac
  fi
  printf 'sleep\n'
}

write_state() {
  printf '%s\n' "$1" > "$state_file"
}

kill_pidfile() {
  f="$1"
  [ -f "$f" ] || return 0
  pid="$(cat "$f" 2>/dev/null || true)"
  case "$pid" in
    ''|*[!0-9]*) rm -f "$f"; return 0 ;;
  esac
  if kill -0 "$pid" >/dev/null 2>&1; then
    kill "$pid" >/dev/null 2>&1 || true
  fi
  rm -f "$f"
}

maybe_stop_hypridle() {
  command -v systemctl >/dev/null 2>&1 || return 0
  if systemctl --user is-active --quiet hypridle.service 2>/dev/null; then
    if systemctl --user stop hypridle.service >/dev/null 2>&1; then
      printf '1\n' > "$hypridle_flag_file"
    fi
  fi
}

maybe_restore_hypridle() {
  [ -f "$hypridle_flag_file" ] || return 0
  command -v systemctl >/dev/null 2>&1 || return 0
  systemctl --user start hypridle.service >/dev/null 2>&1 || true
  rm -f "$hypridle_flag_file"
}

start_inhibitor() {
  kill_pidfile "$inhibit_pid_file"
  command -v systemd-inhibit >/dev/null 2>&1 || return 0

  nohup systemd-inhibit \
    --what=idle:sleep:shutdown \
    --mode=block \
    --why="Waybar AWAKE mode" \
    sh -c 'trap "exit 0" TERM INT; while :; do sleep 3600; done' \
    >/dev/null 2>&1 &
  printf '%s\n' "$!" > "$inhibit_pid_file"
}

schedule_hibernate_timer() {
  kill_pidfile "$hibernate_pid_file"
  nohup "$0" __hibernate_timer >/dev/null 2>&1 &
  printf '%s\n' "$!" > "$hibernate_pid_file"
}

emit_status() {
  state="$(read_state)"
  if [ "$state" = "awake" ]; then
    printf '{"text":"AWAKE","tooltip":"AWAKE: block idle/sleep/shutdown; stop hypridle if managed","class":"mode-awake"}\n'
  else
    printf '{"text":"SLEEP","tooltip":"SLEEP: 10s grace, then auto-hibernate after 60s total unless switched back","class":"mode-sleep"}\n'
  fi
}

do_awake() {
  write_state awake
  kill_pidfile "$hibernate_pid_file"
  start_inhibitor
  maybe_stop_hypridle
  notify "AWAKE enabled: idle/sleep/shutdown inhibited; hypridle stopped if managed"
}

do_sleep() {
  write_state sleep
  kill_pidfile "$inhibit_pid_file"
  maybe_restore_hypridle
  schedule_hibernate_timer
  notify "SLEEP enabled: 10s grace; auto-hibernate after 60s if no action"
}

hibernate_timer() {
  sleep 10
  [ "$(read_state)" = "sleep" ] || exit 0
  notify "SLEEP confirmed. Hibernating in 50s unless switched to AWAKE."

  sleep 50
  [ "$(read_state)" = "sleep" ] || exit 0

  if command -v systemctl >/dev/null 2>&1; then
    if ! systemctl hibernate; then
      notify "Hibernate failed (check logind/polkit support)"
    fi
  else
    notify "systemctl not found; cannot hibernate"
  fi
}

case "$cmd" in
  status)
    emit_status
    ;;
  toggle)
    if [ "$(read_state)" = "awake" ]; then
      do_sleep
    else
      do_awake
    fi
    ;;
  awake)
    do_awake
    ;;
  sleep)
    do_sleep
    ;;
  __hibernate_timer)
    hibernate_timer
    ;;
  *)
    exit 1
    ;;
esac
