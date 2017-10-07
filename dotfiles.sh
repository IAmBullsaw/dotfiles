#!/bin/bash
INSTALL=-i
FORCE=-F
BASHALIASES=0
function usage() {
    echo "usage: $0 $INSTALL [-flags]"
}
[ $# -gt 0 ] || ( usage )

[ "$1" == "$INSTALL" ] && ( [ ! -f "$HOME/.bash_aliases" ] || [ "$2" == "$FORCE" ] ) && ln -s -f "`pwd`/.bash_aliases" "$HOME/.bash_aliases" && BASHALIASES=1 || echo "Couldn't install .bash_aliases. Please remove the existing one or rerun with -F."
[ $BASHALIASES -eq 1 ] && . "$HOME/.bash_aliases" || ( echo "Couldn't make a link to .bash_aliases" )
