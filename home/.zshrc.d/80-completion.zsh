# ---- completion + fzf-tab (post-OMZ) ----
ZSH_CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/zsh"

zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'
zstyle ':completion:*' use-cache on
zstyle ':completion:*' cache-path "$ZSH_CACHE_DIR/zcompcache"

# fzf-tab 预览：eza/bat 优先
zstyle ':fzf-tab:complete:*' fzf-preview '
  if [[ -d "$realpath" ]]; then
    if command -v eza >/dev/null 2>&1; then
      eza -1 --color=always -- "$realpath"
    else
      ls -1 --color=always -- "$realpath"
    fi
  else
    if command -v bat >/dev/null 2>&1; then
      bat --paging=never -n --color=always --line-range=:200 -- "$realpath"
    else
      sed -n "1,200p" "$realpath"
    fi
  fi
'
