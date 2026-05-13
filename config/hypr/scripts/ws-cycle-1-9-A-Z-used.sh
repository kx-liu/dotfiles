#!/usr/bin/env bash
set -euo pipefail

dir="${1:-next}"

# 你想要的顺序：1-9, A-Z
order=(1 2 3 4 5 6 7 8 9 {A..Z})

current_name="$(hyprctl activeworkspace -j | jq -r '.name')"

# 当前已经存在/被使用的 workspace 名字。
# 排除 special:*，只保留单字符 1-9 或 A-Z。
mapfile -t used_names < <(
  hyprctl workspaces -j \
    | jq -r '.[] | select(.name | test("^[1-9A-Z]$")) | .name'
)

# 没有可切换对象，直接退出
(( ${#used_names[@]} == 0 )) && exit 0

# 做一个 used set
is_used() {
  local x="$1"
  local u
  for u in "${used_names[@]}"; do
    [[ "$u" == "$x" ]] && return 0
  done
  return 1
}

# 按 order 重建“已使用 workspace”的有序列表
sorted_used=()
for name in "${order[@]}"; do
  if is_used "$name"; then
    sorted_used+=("$name")
  fi
done

# 只有一个已使用 workspace，就不切
(( ${#sorted_used[@]} <= 1 )) && exit 0

current_index=-1
for i in "${!sorted_used[@]}"; do
  if [[ "${sorted_used[$i]}" == "$current_name" ]]; then
    current_index="$i"
    break
  fi
done

# 当前 workspace 如果不在 1-9/A-Z 里，比如 special:keepass，
# next 跳到第一个，prev 跳到最后一个。
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

hyprctl dispatch workspace "name:${target}" >/dev/null
