#!/bin/bash

###################
# START OF SETTINGS
#
# Which file are we linking?
FILE=.bash_aliases
#
# Which file to link to
DESTINATION=~/.bash_aliases
SRCDIRECTORY=`pwd`
#
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
LOG_LEVELS=([0]="emerg" [1]="alert" [2]="crit" [3]="err" [4]="warning" [5]="notice" [6]="info" [7]="debug")
function .log () {
    local LEVEL=${1}
    shift
    if [ ${VERBOSE} -ge ${LEVEL} ]; then
        echo "-> [${LOG_LEVELS[$LEVEL]}]" "[$FILE]" "$@"
    fi
}

function help() {
    echo "Help for bash/link.sh"
    echo ""
    echo "USAGE
                  `usage`
                  User MUST declare the purpose with flags -i or -u."
    echo ""
    echo "OPTIONS
                  -i If you want to install this .bash_aliases config
                  -u If you want to uninstall this .bash_aliases config
                  -F Use force. Think about it.
                  -h Print this 'help'.
                  -v Increases the verbosity of the process."
    echo ""
}

####################################################################################
# Don't edit past this point unless you are super cool. You're super cool? Go ahead!

function install() {
    if [ ! -f $DESTINATION ]; then
        .log 7 "ln -s $SRCDIRECTORY/$FILE $DESTINATION"
        ln -s "$SRCDIRECTORY/$FILE" $DESTINATION
        .log 5 "linked"
    else
        read -n 1 -p "[$FILE] Want to remove old config? (y/n): " answer
        printf "\n"
        if [ "$answer" == y ]; then
            uninstall;
            .log 7 "ln -s $SRCDIRECTORY/$FILE $DESTINATION"
            ln -s "$SRCDIRECTORY/$FILE" $DESTINATION
            .log 5 "linked"
        fi
    fi
}

function uninstall() {
    .log 7 "rm $DESTINATION"
    rm $DESTINATION
    .log 5 "removed config"
}

function reload() {
    .log 7 ". $DESTINATION"
    . $DESTINATION;
    .log 5 "reloaded"
    .log 6 "You might want to restart or run '. ~/.bashrc' in all active bash instances"
}

##################
# MAIN SCRIPT FLOW

# User must provide arguments
[ $# -gt 0 ] || { usage; exit 0; }

# Get options
while getopts 'hFiuv' flag; do
    case "${flag}" in
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

if [ $INSTALL ] && [ $UNINSTALL ]; then
    echo "User provided both -i and -u."
    usage;
    exit -1;
fi

.log 5 "started"

if [ $INSTALL ]; then
    install;
    reload;
fi

if [ $UNINSTALL ]; then
    uninstall;
fi

.log 5 "finished"
