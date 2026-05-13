#!/usr/bin/env bash
set -euo pipefail

dir="${1:-next}"

current_id="$(hyprctl activeworkspace -j | jq -r '.id')"

# 只取当前已经存在的 workspace，并限制在我们的 1..35 范围内。
# 1-9 = 1-9
# 10-35 = A-Z
mapfile -t used_ids < <(
  hyprctl workspaces -j \
    | jq -r '.[] | select(.id >= 1 and .id <= 35) | .id' \
    | sort -n
)

# 如果没有可切换目标，直接退出。
(( ${#used_ids[@]} == 0 )) && exit 0

# 如果只有当前一个 workspace，也不切。
if (( ${#used_ids[@]} == 1 )); then
  exit 0
fi

current_index=-1

for i in "${!used_ids[@]}"; do
  if [[ "${used_ids[$i]}" == "$current_id" ]]; then
    current_index="$i"
    break
  fi
done

# 如果当前 workspace 不在 1..35 里，就跳到已使用列表的第一个/最后一个。
if (( current_index == -1 )); then
  if [[ "$dir" == "prev" ]]; then
    target="${used_ids[-1]}"
  else
    target="${used_ids[0]}"
  fi
else
  if [[ "$dir" == "prev" ]]; then
    if (( current_index == 0 )); then
      target="${used_ids[-1]}"
    else
      target="${used_ids[$((current_index - 1))]}"
    fi
  else
    if (( current_index == ${#used_ids[@]} - 1 )); then
      target="${used_ids[0]}"
    else
      target="${used_ids[$((current_index + 1))]}"
    fi
  fi
fi

hyprctl dispatch workspace "$target" >/dev/null
