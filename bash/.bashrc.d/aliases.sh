require config
require functions

# ============================================================
#  aliases.sh
# ============================================================

# --- PATH additions ----------------------------------------
[[ ":$PATH:" != *":$HOME/bin:"* ]] && PATH="${PATH%:}:$HOME/bin"

# --- Navigation --------------------------------------------
alias cd..='cd ..'
alias ccd='cd ~/Code'
alias groot='cd "$(git rev-parse --show-toplevel)"'

# --- Listing -----------------------------------------------
alias ls='ls --color=auto --group-directories-first'
alias l='ls -l'
alias ll='ls -laF'
alias lsd='ls -d */ .*/'

# --- Search ------------------------------------------------
alias fhere='find . -iname'
alias hg='history | grep'
alias grep='grep --color=auto'

# --- Git ---------------------------------------------------
alias ga='git add'
alias gb='git branch'
alias gba='for k in $(git branch | sed s/^..//); do echo -e "$(git log -1 --pretty=format:"%Cgreen%ci %Cblue%cr%Creset" "$k" --)\\t$k"; done | sort'
alias gbv='git branch -vv'
alias gca='git amend-protected'
alias gd='git diff'
alias gfp='git fetch -p'
alias gg='git grep'
alias gh='git log --pretty=tformat:"%h %ad | %s%d [%an]" --graph --date=short'
alias gk='gitk --all'
alias gl='git log --pretty=oneline'
alias gs='git status'
alias gsb='git log --oneline | grep -E "DAILYBUILD|(Import.+CXP)" | head -n 1'
alias gsf='git show --pretty="format:" --name-only'
alias rebase='git stash && git checkout master && git pull --rebase && git checkout - && git rebase master && git stash apply'
alias gas='alias | grep'

# --- Programs ----------------------------------------------
alias readme='grip -b README.md'

# --- Compilation -------------------------------------------
alias g++14='g++ -std=c++14 -Wall -Werror -Wextra -Wpedantic -Wconversion -Wcast-align -Wunused -Wshadow -Wold-style-cast -Wpointer-arith -Wno-missing-braces'

# --- Make --------------------------------------------------
alias mk='make -j16 -l32'
alias mkc='mk realclean'
alias mkt='mk test'
alias make-list='make -pRr all | grep -v "#" | grep -E "^.PHONY" | tr " " "\n" | grep -v ".PHONY"'

# --- Conversion --------------------------------------------
alias d2h="printf '%x\n'"

# --- Shell -----------------------------------------------------------------
alias constants='cat "$BASHRC_D/config.sh"'
alias clear='clear && clear'
alias language='setxkbmap -layout se'

# --- Other -----------------------------------------------------------------
alias aocurl='python3 ~/Scripts/aocurl.py'

# --- add-alias generated aliases -------------------------------------------
# Keep sorted when editing manually.
