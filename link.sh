#/bin/bash
SPACEMACS=~/.spacemacs
printf "[.spacemacs] "
if [ ! -f $SPACEMACS ]; then
    printf "linking. "
    ln -s "`pwd`/.spacemacs" ~/.spacemacs
    printf "OK\n"
else
    printf "OK\n"
fi
