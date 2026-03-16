[[ -r "$HOME/.cargo/env" ]] && source "$HOME/.cargo/env"

typeset -U path PATH
path=(
  "$HOME/.cargo/bin"
  "$HOME/.local/npm-global/bin"
  $path
)
