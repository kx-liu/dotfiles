# ---- functions (post-OMZ) ----
# yazi：退出时自动 cd 到最后目录
function y() {
  local tmp="$(mktemp -t yazi-cwd.XXXXXX)" cwd
  command yazi "$@" --cwd-file="$tmp"
  IFS= read -r cwd < "$tmp"
  [[ -n "$cwd" && "$cwd" != "$PWD" && -d "$cwd" ]] && builtin cd -- "$cwd"
  rm -f -- "$tmp"
}
