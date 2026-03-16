# ~/.zshrc.d/10-aliases.zsh

alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'

# Modern alternatives (opt-in style)
if command -v eza >/dev/null 2>&1; then
  alias e='eza --group-directories-first'
  alias el='eza -alF --group-directories-first'
fi

if command -v bat >/dev/null 2>&1; then
  alias c='bat --paging=never -p'
fi