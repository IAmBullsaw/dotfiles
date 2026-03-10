###########
# Aliases #
###########


# Add own scripts to path
PATH="$PATH:/home/$USER/bin/"

# Add zoxide to path
PATH="$PATH:/home/$USER/Code/zoxide/"


# Jump to special folders
alias ccd="cd ~/Code"
alias groot='cd $(git rev-parse --show-toplevel)'


# Programs or apps
alias readme='grip -b README.md'


# Searching
alias ll="ls -laF"
alias ls='ls --color=auto --group-directories-first'
alias lsd='ls -d */ .*/'
alias l='ls -l'
alias fhere="find . -iname"


# Sourecing
alias language='setxkbmap -layout se'


# Git
git config --global alias.go checkout
alias ga='git add'
alias gb='git branch'
alias gd='git diff'
alias gg="git grep"
alias gh='git log --pretty=tformat:"%h %ad | %s%d [%an]" --graph --date=short'
alias gk='gitk --all'
alias gl="git log --pretty='oneline'"
alias gs='git status'
alias rebase='git stash && git checkout master && git pull --rebase && git checkout - && git rebase master && git stash apply'

# alias gbv='git merge-base origin/dev HEAD | tr -d "\n" | xargs -0 -I ancestor git log --oneline ancestor..HEAD'
alias cdgt='cd \$MY_GIT_T'
alias gas='alias|grep '
alias gba='for k in `git branch | sed s/^..//`; do echo -e `git log -1 --pretty=format:"%Cgreen%ci %Cblue%cr%Creset" $k --`\\t"$k";done | sort'
alias gbv='git branch -vv'
alias gca="git amend-protected"
alias gclean='cd \$MY_GIT_TOP && git submodule foreach --recursive "git clean -xdf" && git clean -xdf -e .ccache -e .flex_dbg -e remap_catalog\\*.xml -e .baseline && c'
alias gfp='git fetch -p'
alias gsb='git log --oneline | grep -E "DAILYBUILD|(Import.+CXP)" | head -n 1'
alias gsf='git show --pretty="format:" --name-only'
alias gss='cd \$MY_GIT_TOP && git submodule status && c'
alias gsu='cd \$MY_GIT_TOP && git submodule update && c'

# Compiling
alias g++14='g++ -std=c++14 -Wall -Werror -Wextra -Wpedantic -Wconversion -Wcast-align -Wunused -Wshadow -Wold-style-cast -Wpointer-arith -Wno-missing-braces'


# Make
alias mk='make -j16 -l32'
alias mkc='mk realclean'
alias mkt='mk test'
alias make-list='make -pRr all | grep -v "#" | grep -E "^.PHONY" | tr " " "\n" | grep -v ".PHONY"'

# Conversion
alias d2h="printf '%x\n'"


# Other
alias cd..="cd .."
alias clear="clear && clear"
alias hg='history | grep'
alias constants='cat ~/.bash_constants'
alias grep='grep --color=auto'
alias aocurl='python3 ~/Scripts/aocurl.py'

#########################################
# add-alias generated aliases follows ...
# Sort them whenever you're looking at this file!



