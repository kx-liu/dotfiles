# ~/.zshrc
[[ -o interactive ]] || return
setopt extended_glob

typeset -g ZSHRC_D="$HOME/.zshrc.d"

# Optional early TTY output must happen before the instant prompt preamble.
if [[ "$TERM" == "xterm-kitty" ]] \
  && command -v fastfetch >/dev/null 2>&1 \
  && [[ -z "$SSH_CONNECTION" && -z "$TMUX" && -z "$FASTFETCH_SHOWN" ]]; then
  export FASTFETCH_SHOWN=1
  fastfetch
fi

# --- p10k instant prompt (must be near top) ---
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# Source numbered startup fragments in order.
for rc in "$ZSHRC_D"/[0-9][0-9]-*.zsh(N); do
  source "$rc"
done
