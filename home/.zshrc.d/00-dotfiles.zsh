typeset -g DOTFILES_GIT_DIR=""

if [[ -d "$HOME/.dotfiles/.git" ]]; then
  DOTFILES_GIT_DIR="$HOME/.dotfiles/.git"
elif [[ -f "$HOME/.dotfiles/HEAD" ]]; then
  DOTFILES_GIT_DIR="$HOME/.dotfiles"
fi

if [[ -n "$DOTFILES_GIT_DIR" ]]; then
  dot() {
    git --git-dir="$DOTFILES_GIT_DIR" --work-tree="$HOME" "$@"
  }

  dot config --local status.showUntrackedFiles no >/dev/null 2>&1 || true
fi
