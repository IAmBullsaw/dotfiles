require config
require functions

# ============================================================
#  aliases.sh
# ============================================================

# --- PATH additions ----------------------------------------
[[ ":$PATH:" != *":$HOME/.local/bin:"* ]] && PATH="${PATH%:}:$HOME/.local/bin"

# --- Navigation --------------------------------------------
alias cd..='cd ..'
alias ccd='cd ~/Code'
alias groot='cd "$(git rev-parse --show-toplevel)"'

# --- Listing -----------------------------------------------
alias ls='ls --color=auto --group-directories-first'
alias l='ls -l'
alias la='ls -A'
alias ll='ls -laF'
alias lsd='ls -d */ .*/'

# --- Search ------------------------------------------------
alias fhere='find . -iname'
alias hg='history | grep'
alias grep='grep --color=auto'
alias fgrep='fgrep --color=auto'
alias egrep='egrep --color=auto'

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
alias g++17='g++ -std=c++17 -Wall -Werror -Wextra -Wpedantic -Wconversion -Wcast-align -Wunused -Wshadow -Wold-style-cast -Wpointer-arith -Wno-missing-braces'
alias g++20='g++ -std=c++2a -Wall -Werror -Wextra -Wpedantic -Wconversion -Wcast-align -Wunused -Wshadow -Wold-style-cast -Wpointer-arith -Wno-missing-braces'

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
alias zj="zellij attach -c"

# --- Homelab ---------------------------------------------------------------
alias mount-rpi5='sshfs -v dietpi@192.168.88.9:/home/dietpi /home/bullen/projects/homelab/rpi5'
alias unmount-rpi5='fusermount -u /home/bullen/projects/homelab/rpi5'

# --- Other -----------------------------------------------------------------
alias aocurl='python3 ~/Code/scripts/aocurl.py'

# --- add-alias generated aliases -------------------------------------------
# Keep sorted when editing manually.
