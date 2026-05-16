#!/usr/bin/env bash
set -euo pipefail

dir="${1:-next}"

order=(1 2 3 4 5 6 7 8 9 {A..Z})

current_name="$(hyprctl activeworkspace -j | jq -r '.name')"

# Use workspace names, not IDs: named workspaces and defaultName rules do not
# always have the simple 1..35 IDs that the visible names imply.
mapfile -t used_names < <(
  hyprctl workspaces -j \
    | jq -r '.[] | select(.name | test("^[1-9A-Z]$")) | .name'
)

(( ${#used_names[@]} == 0 )) && exit 0

is_used() {
  local name="$1"
  local used

  for used in "${used_names[@]}"; do
    [[ "$used" == "$name" ]] && return 0
  done

  return 1
}

sorted_used=()
for name in "${order[@]}"; do
  if is_used "$name"; then
    sorted_used+=("$name")
  fi
done

(( ${#sorted_used[@]} <= 1 )) && exit 0

current_index=-1
for i in "${!sorted_used[@]}"; do
  if [[ "${sorted_used[$i]}" == "$current_name" ]]; then
    current_index="$i"
    break
  fi
done

if (( current_index == -1 )); then
  if [[ "$dir" == "prev" ]]; then
    target="${sorted_used[$((${#sorted_used[@]} - 1))]}"
  else
    target="${sorted_used[0]}"
  fi
else
  if [[ "$dir" == "prev" ]]; then
    if (( current_index == 0 )); then
      target="${sorted_used[$((${#sorted_used[@]} - 1))]}"
    else
      target="${sorted_used[$((current_index - 1))]}"
    fi
  else
    if (( current_index == ${#sorted_used[@]} - 1 )); then
      target="${sorted_used[0]}"
    else
      target="${sorted_used[$((current_index + 1))]}"
    fi
  fi
fi

if [[ "$target" =~ ^[1-9]$ ]]; then
  workspace="${target}"
else
  workspace="name:${target}"
fi

hyprctl dispatch "hl.dsp.focus({ workspace = \"${workspace}\" })" >/dev/null
