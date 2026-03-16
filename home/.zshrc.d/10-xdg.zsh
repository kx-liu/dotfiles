: "${XDG_CACHE_HOME:=$HOME/.cache}"
: "${XDG_STATE_HOME:=$HOME/.local/state}"

typeset -g ZSH_CACHE_DIR="$XDG_CACHE_HOME/zsh"
typeset -g ZSH_STATE_DIR="$XDG_STATE_HOME/zsh"

mkdir -p "$ZSH_CACHE_DIR" "$ZSH_CACHE_DIR/zcompcache" "$ZSH_STATE_DIR" "$HOME/.zshrc.d"
