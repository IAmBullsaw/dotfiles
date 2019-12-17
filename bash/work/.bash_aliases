###########
# Aliases #
###########

# Add ~/bin
PATH="$PATH:/home/$USER/bin/"


# Jump to special folders


# Programs or apps
alias demacs='emacs --debug-init'


# Searching
alias ll="ls -laF"
alias ls='ls --color=auto --group-directories-first'
alias ld='ls -d */ .*/'
alias l='ls -l'
alias fhere="find . -iname"


# Sourcing


# Git
alias gg="git grep"
alias gca="git commit --amend"
alias gbv='git branch -vv'
alias gl="git log --pretty='oneline'"
alias gc='git commit'
alias rebase='git stash && git checkout master && git pull --rebase && git checkout - && git rebase master && git stash apply'
alias gba='for k in `git branch | sed s/^..//`; do echo -e `git log -1 --pretty=format:"%Cgreen%ci %Cblue%cr%Creset" $k --`\\t"$k";done | sort'


# Compiling
alias g++14='g++ -std=c++14 -Wall -Werror -Wextra -Wpedantic -Wconversion -Wcast-align -Wunused -Wshadow -Wold-style-cast -Wpointer-arith -Wno-missing-braces'


# Make
alias make='make -j16 -l32'
alias make-list='make -pRr all | grep -v "#" | grep -E "^.PHONY" | tr " " "\n" | grep -v ".PHONY"'
alias mk='make -j16 -l32'
alias mkc='mk realclean'


# Conversion
alias d2h="printf '%x\n'"


# Other
alias clear="clear && clear"
alias hg='history | grep'
alias constants='cat ~/.bash_constants'
alias grep='grep --color=auto'


#########################################
# add-alias generated aliases follows ...
# Sort them whenever you're looking at this file!
