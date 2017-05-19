#/bin/bash
SPACEMACS=~/.spacemacs
EMACS=~/.emacs.d/init.el

printf "Choose your editor:\n\n"
read -n 1 -p "Emacs, Spacemacs or none? (e/s/*): " answer
printf "\n"
if [ "$answer" == "s" ]; then
    PRE=.spacemacs
    if [ ! -f $SPACEMACS ]; then
        printf "[$PRE] linking.\n"
        ln -s "`pwd`/.spacemacs" $SPACEMACS
    else
        read -n 1 -p "[$PRE] Want to remove old config? (y/n):" answer
        printf "\n"
        if [ "$answer" == y ]; then
            rm $SPACEMACS
            printf "[$PRE] removed config\n"
            printf "[$PRE] linking. \n"
            ln -s "`pwd`/.spacemacs" $SPACEMACS
        fi
    fi
    printf "[$PRE] done\n"
elif [ "$answer" == "e" ]; then
    PRE=init.el
    if [ ! -f $EMACS ]; then
        printf "[$PRE] linking.\n"
        ln -s "`pwd`/init.el" $EMACS
    else
        read -n 1 -p "[$PRE] Want to remove old config? (y/n):" answer
        printf "\n"
        if [ "$answer" == y ]; then
            rm $EMACS
            printf "[$PRE] removed config\n"
            printf "[$PRE] linking. \n"
            ln -s "`pwd`/init.el" $EMACS
        fi
    fi
    printf "[$PRE] done\n"
else
    printf "No editor chosen.\n"
fi
