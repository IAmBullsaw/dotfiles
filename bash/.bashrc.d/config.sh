# === config.sh =============================================
#  Environment setup: variables, exports, shopt, and
#  one-time shell init (lesspipe, dircolors, completion).
#  Everything else does: require config
# ===========================================================

# Location of this config dir (available to all modules)
export BASHRC_D="$HOME/.bashrc.d"

# --- Shell options -----------------------------------------
shopt -s checkwinsize   # re-wrap lines after terminal resize
shopt -s histappend     # append to history, never overwrite
shopt -s globstar       # enable ** glob patterns
shopt -s cmdhist        # save multi-line commands as one entry

# --- Core environment --------------------------------------
export PAGER=less
export EDITOR=nvim

# --- History -----------------------------------------------
export HISTSIZE=-1
export HISTFILESIZE=-1
export HISTCONTROL=ignoreboth:erasedups
export HISTTIMEFORMAT="%F %T  "
export HISTFILE="$HOME/.bash_history"

# --- Colors ------------------------------------------------
#  Used by prompt.sh and any module that needs ANSI colors.
#  NOT exported — no reason to leak escape codes into subprocesses.
_C_NC='\[\e[0m\]'
_C_GREEN='\[\e[0;32m\]'
_C_YELLOW='\[\e[1;33m\]'
_C_RED='\[\e[0;31m\]'
_C_CYAN='\[\e[0;36m\]'

#  Raw (non-PS1-escaped) versions for use in echo/printf contexts
_R_NC='\e[0m'
_R_RED='\e[0;31m'
_R_GREEN='\e[0;32m'
_R_YELLOW='\e[0;33m'
_R_BLUE='\e[0;34m'
_R_PURPLE='\e[0;35m'
_R_CYAN='\e[0;36m'

# --- Paths -------------------------------------------------
export NVM_DIR="$HOME/.nvm"
BOOKMARK_FILE="$HOME/.bash_bookmarks"

# --- Terminal setup ----------------------------------------
[ -x /usr/bin/lesspipe ] && eval "$(SHELL=/bin/sh lesspipe)"

if [ -x /usr/bin/dircolors ]; then
    test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
fi

# --- Bash completion ----------------------------------------
if ! shopt -oq posix; then
    if [ -f /usr/share/bash-completion/bash_completion ]; then
        . /usr/share/bash-completion/bash_completion
    elif [ -f /etc/bash_completion ]; then
        . /etc/bash_completion
    fi
fi

# --- Repos that require environment sourcing before use.
# Shows a red NaN in prompt if env is not sourced.
# Overridden in work.sh
WATCHED_REPOS=(
  "null"
  "next"
)
