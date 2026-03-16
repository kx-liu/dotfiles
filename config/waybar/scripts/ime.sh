#!/usr/bin/env bash
set -euo pipefail

if ! command -v fcitx5-remote >/dev/null 2>&1; then
  echo '{"text":"IME?","tooltip":"fcitx5-remote not found","class":"ime-off"}'
  exit 0
fi

im="$(fcitx5-remote -n 2>/dev/null || true)"
if [[ -z "$im" ]]; then
  echo '{"text":"IME","tooltip":"fcitx5 not running?","class":"ime-off"}'
  exit 0
fi

low="$(printf "%s" "$im" | tr '[:upper:]' '[:lower:]')"
if [[ "$low" == *"keyboard"* || "$low" == *"english"* || "$low" == *"latin"* ]]; then
  text="en"
  cls="ime-en"
else
  text="中"
  cls="ime-zh"
fi

tooltip="$im"
tooltip="${tooltip//\\/\\\\}"
tooltip="${tooltip//\"/\\\"}"
echo "{\"text\":\"$text\",\"tooltip\":\"$tooltip\",\"class\":\"$cls\"}"