# ~/.zshrc
[[ -o interactive ]] || return
setopt extended_glob

if [[ -o interactive ]]; then
  command -v fastfetch >/dev/null 2>&1 && fastfetch
fi

# --- p10k instant prompt (must be near top) ---
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# --- XDG dirs ---
: ${XDG_CACHE_HOME:="$HOME/.cache"}
: ${XDG_STATE_HOME:="$HOME/.local/state"}
ZSH_CACHE_DIR="$XDG_CACHE_HOME/zsh"
ZSH_STATE_DIR="$XDG_STATE_HOME/zsh"
mkdir -p "$ZSH_CACHE_DIR" "$ZSH_CACHE_DIR/zcompcache" "$ZSH_STATE_DIR" "$HOME/.zshrc.d"

# --- source pre-OMZ snippets (00-49) ---
for rc in "$HOME"/.zshrc.d/[0-4][0-9]-*.zsh(N); do
  source "$rc"
done

# --- Oh My Zsh ---
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="powerlevel10k/powerlevel10k"
DISABLE_AUTO_UPDATE="true"
zstyle ':omz:update' mode disabled 2>/dev/null

export ZSH_COMPDUMP="$ZSH_CACHE_DIR/zcompdump-$ZSH_VERSION"
# 如你有 compaudit 权限警告，取消下一行注释：
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

# --- source post-OMZ snippets (50-99) ---
for rc in "$HOME"/.zshrc.d/[5-9][0-9]-*.zsh(N); do
  source "$rc"
done

# --- p10k config last ---
[[ -f "$HOME/.p10k.zsh" ]] && source "$HOME/.p10k.zsh"
alias dot='git --git-dir=$HOME/.dotfiles --work-tree=$HOME'

. "$HOME/.cargo/env"
export PATH="$HOME/.cargo/bin:$PATH"
export PATH="$HOME/.local/npm-global/bin:$PATH"
