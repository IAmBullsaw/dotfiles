#/bin/bash
SPACEMACS=~/.spacemacs
EMACS=~/.emacs.d/init.el

printf "Choose your editor:\n\n"
read -n 1 -p "Emacs, Spacemacs or none? (e/s/*): " answer
printf "\n"
if [ "$answer" == "s" ]; then
    printf "[.spacemacs] "
    if [ ! -f $SPACEMACS ]; then
        printf "linking. "
        ln -s "`pwd`/.spacemacs" $SPACEMACS
    else
        read -n 1 -p "Want to remove old config? (y/n):" answer
        if [ "$answer" == y ]; then
            rm $SPACEMACS
            printf "linking. "
            ln -s "`pwd`/.spacemacs" $SPACEMACS
        fi
    fi
elif [ "$answer" == "e" ]; then
    printf "[.emacs] "
    if [ ! -f $EMACS ]; then
        printf "linking. "
        ln -s "`pwd`/init.el" $EMACS
    else
        printf "OK\n"
    fi
else
    printf "No editor chosen.\n"
fi
