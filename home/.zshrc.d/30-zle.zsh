# ---- ZLE / keybindings / paste fix (pre-OMZ) ----
bindkey -e

autoload -Uz up-line-or-beginning-search down-line-or-beginning-search
zle -N up-line-or-beginning-search
zle -N down-line-or-beginning-search
bindkey '^[[A' up-line-or-beginning-search
bindkey '^[[B' down-line-or-beginning-search

# bracketed paste：避免插件逐字触发导致粘贴很慢
autoload -Uz bracketed-paste-magic
zle -N bracketed-paste bracketed-paste-magic
zstyle ':bracketed-paste-magic' active-widgets '.self-*'

# 可选：关闭“粘贴高亮”观感
zle_highlight+=(paste:none)
