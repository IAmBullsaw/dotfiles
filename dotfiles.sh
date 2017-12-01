#!/bin/bash

###################
# START OF SETTINGS
#
SRCDIR=`pwd`
# Read about the different levels at https://en.wikipedia.org/wiki/Syslog#Severity_level
# Verbosity should start at 5
VERBOSE=5
#
# END OF SETTINGS
#################

function usage() {
    echo "usage: $0 -i or -u [-flags]"
}

declare -A LOG_LEVELS
LOG_LEVELS=([0]="..emerg" [1]="..alert" [2]="...crit" [3]="....err" [4]="warning" [5]=".notice" [6]="...info" [7]="..debug")
function .log () {
    local LEVEL=${1}
    shift
    if [ ${VERBOSE} -ge ${LEVEL} ]; then
        echo "-> [${LOG_LEVELS[$LEVEL]}]" "[$0]" "$@"
    fi
}

function help() {
    echo "Help for dotfiles.sh"
    echo ""
    echo "USAGE
                  `usage`
                  User MUST declare the purpose with flags -i or -u."
    echo ""
    echo "OPTIONS
                  -i If you want to install the listed configs.
                  -u If you want to uninstall the listed configs.
                  -a For ALL configs.
                  -A For ALL configs and ALL extra.
                  -e For init.el
                  -s For spacemacs config.
                  -S For spacemacs config AND spacemacs desktop icon.
                  -b For .bash_aliases
                  -F Use force. Think about it.
                  -h Print this 'help'.
                  -v Increases the verbosity of the process."
    echo ""
}

####################################################################################
# Don't edit past this point unless you are super cool. You're super cool? Go ahead!

function install() {
    .log 0 "Not implemented"
}

##################
# MAIN SCRIPT FLOW

# User must provide arguments
[ $# -gt 0 ] || { usage; exit 0; }

# Get options
while getopts 'bsSeaAhFiuv' flag; do
    case "${flag}" in
        a) ALL=true ;;
        A) { ALL=true; ALLEXTRA=true; } ;;
        e) EMACS=true ;;
        s) SPACEMACS=true ;;
        S) { SPACEMACS=true; SPACEEXTRA=true; } ;;
        b) BASHALIASES=true ;;
        i) INSTALL=true ;;
        u) UNINSTALL=true ;;
        F) FORCE=true ;;
        h) HELP=true ;;
        v) ((VERBOSE=VERBOSE+1)) ;;
        *) { error "Unexpected option $(flag)"; exit -1; } ;;
    esac
done

if [ $HELP ]; then
    help;
    exit 0;
fi

.log 0 "Not implemented"
.log 0 "Use folder scripts instead"
exit -1;

if [ $INSTALL ] && [ $UNINSTALL ]; then
    echo "User provided both -i and -u."
    usage;
    exit -1;
fi

.log 5 "started"

if [ $INSTALL ]; then
    install;
fi

if [ $UNINSTALL ]; then
    uninstall;
fi

.log 5 "finished"
