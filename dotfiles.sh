#!/bin/bash

function usage() {
    echo "usage: $0 [-i | -u] [-flags]"
}
[ $# -gt 0 ] || ( usage )

VERBOSE=5

declare -A LOG_LEVELS
# https://en.wikipedia.org/wiki/Syslog#Severity_level
LOG_LEVELS=([0]="emerg" [1]="alert" [2]="crit" [3]="err" [4]="warning" [5]="notice" [6]="info" [7]="debug")
function .log () {
    local LEVEL=${1}
    shift
    if [ ${VERBOSE} -ge ${LEVEL} ]; then
        echo "-> [${LOG_LEVELS[$LEVEL]}]" "$@"
    fi
}

while getopts 'bFiuv' flag; do
    case "${flag}" in
        b) BASHALIASES=true ;;
        i) INSTALL=true ;;
        u) UNINSTALL=true ;;
        F) FORCE=true ;;
        v) ((VERBOSE=VERBOSE+1)) ;;
        *) { error "Unexpected option $(flag)"; exit -1; } ;;
    esac
done

if [ $UNINSTALL ] && [ $INSTALL ]; then
    usage;
    exit 0;
fi;

function installBashAliases() {
    .log 6 "Installing .bash_Aliases"
    ( [ ! -f "$HOME/.bash_aliases" ] || [ $FORCE ] ) && ln -s -f "`pwd`/.bash_aliases" "$HOME/.bash_aliases" && BASHALIASES=true || .log 4 "Couldn't install .bash_aliases. Please remove the existing one or rerun with -F."
    [ $BASHALIASES ] && . "$HOME/.bash_aliases" || ( .log 4 "Couldn't make a link to .bash_aliases" )
}

function uninstallBashAliases() {
    echo "no"
}

if [ $VERBOSE -gt 10 ]; then
    echo "There's no easter eggs here.";
    exit 0;
fi

if [ $INSTALL ]; then
    if [ $BASHALIASES ]; then
        installBashAliases;
    fi
fi
if [ $UNINSTALL ] && [ ! $INSTALL ]; then
    echo "HELLO";
fi
