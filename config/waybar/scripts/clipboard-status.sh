#!/usr/bin/env bash
set -euo pipefail

if ! command -v cliphist >/dev/null 2>&1; then
  echo '{"text":"📋","tooltip":"cliphist not installed","class":"clipboard-off"}'
  exit 0
fi

count="$(cliphist list | wc -l | tr -d ' ')"
echo "{\"text\":\"📋 ${count}\",\"tooltip\":\"Clipboard entries: ${count}\",\"class\":\"clipboard\"}"