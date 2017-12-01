#!/bin/bash

###################
# START OF SETTINGS
#
# Array of files.
declare -A FILES
FILE=VScode
#
# Which files to link to
DESTDIRECTORY=~/.config/Code/User
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
LOG_LEVELS=([0]="..emerg" [1]="..alert" [2]="...crit" [3]="....err" [4]="warning" [5]=".notice" [6]="...info" [7]="..debug")
function .log () {
    local LEVEL=${1}
    shift
    if [ ${VERBOSE} -ge ${LEVEL} ]; then
        echo "-> [${LOG_LEVELS[$LEVEL]}]" "[$FILE]" "$@"
    fi
}

function help() {
    echo "Help for VScode/link.sh"
    echo ""
    echo "USAGE
                  `usage`
                  User MUST declare the purpose with flags -i or -u."
    echo ""
    echo "OPTIONS
                  -i If you want to install
                  -u If you want to uninstall
                  -s If you want settings.json
                  -k If you want keybindings.json
                  -a If you want all.
                  -F Use force. Think about it.
                  -h Print this 'help'.
                  -v Increases the verbosity of the process."
    echo ""
}

####################################################################################
# Don't edit past this point unless you are super cool. You're super cool? Go ahead!

function install() {

    for i in "${FILES[@]}"
    do
        FILE="$i"
        if [ ! -e "$DESTDIRECTORY/$FILE" ]; then
            .log 7 "ln -s $SRCDIRECTORY/$FILE $DESTDIRECTORY/$FILE"
            ln -s "$SRCDIRECTORY/$FILE" "$DESTDIRECTORY/$FILE"
            .log 5 "linked"
        else
            read -n 1 -p "-> [${LOG_LEVELS[1]}] [$FILE] Want to remove old config (y/n): " answer
            printf "\n"
            if [ "$answer" == y ]; then
                uninstallFile "$FILE";
                .log 7 "ln -s $SRCDIRECTORY/$FILE $DESTDIRECTORY/$FILE"
                ln -s "$SRCDIRECTORY/$FILE" "$DESTDIRECTORY/$FILE"
                .log 5 "linked"
            fi
        fi
    done
}

function uninstallFile() {
    .log 7 "rm $DESTDIRECTORY/$1"
    rm "$DESTDIRECTORY/$1"
    .log 5 "removed"
}

function uninstall() {
    for i in "${FILES[@]}"
    do
        FILE="$i"
        uninstallFile "$FILE";
    done
}

##################
# MAIN SCRIPT FLOW

# User must provide arguments
[ $# -gt 0 ] || { usage; exit 0; }

# Get options
while getopts 'skahFiuv' flag; do
    case "${flag}" in
        s) FILES[0]="settings.json" ;;
        k) FILES[1]="keybindings.json" ;;
        a) { FILES[0]="settings.json"; FILES[1]="keybindings.json"; } ;;
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
    error "User provided both -i and -u."
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

FILE="VScode"
.log 5 "finished"
