export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="powerlevel10k/powerlevel10k"
DISABLE_AUTO_UPDATE="true"
zstyle ':omz:update' mode disabled 2>/dev/null

export ZSH_COMPDUMP="$ZSH_CACHE_DIR/zcompdump-$ZSH_VERSION"
# Uncomment if compaudit permissions become noisy on this machine.
# ZSH_DISABLE_COMPFIX="true"

plugins=(
  git
  sudo
  z
  zsh-autosuggestions
  fzf-tab
  fast-syntax-highlighting
)

source "$ZSH/oh-my-zsh.sh"
