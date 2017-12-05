#!/bin/bash

###################
# START OF SETTINGS
#
# Which file are we linking?
FILE=.spacemacs
DESKTOPFILE=spacemacs.desktop
#
# Which file to link to
DESTINATION=~/.spacemacs
APPLICATIONS=~/.local/share/applications
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
    echo "Help for spacemacs/link.sh"
    echo ""
    echo "USAGE
                  `usage`
                  User MUST declare the purpose with flags -i or -u."
    echo ""
    echo "OPTIONS
                  -d If you want a spacemacs desktop icon
                  -i If you want to install this .spacemacs config
                  -u If you want to uninstall this .spacemacs config
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

function installDesktopIcon() {
    NAME=`whoami`
    if [ $DESKTOPICON ]; then
        .log 7 "replacing Icon=path in desktop"
        sed -i "/Icon=/c\Icon=/home/$NAME/.emacs.d/core/banners/img/spacemacs.png" "$SRCDIRECTORY/desktop/$DESKTOPFILE"
        if [ ! -f "$APPLICATIONS/$DESKTOPFILE" ]; then
            .log 7 "ln -s $SRCDIRECTORY/desktop/$DESKTOPFILE $APPLICATIONS/$DESKTOPFILE"
            ln -s "$SRCDIRECTORY/desktop/$DESKTOPFILE" "$APPLICATIONS/$DESKTOPFILE"
            .log 5 "linked"
        else
            read -n 1 -p "[$FILE] Want to remove old desktop config? (y/n): " answer
            printf "\n"
            if [ "$answer" == y ]; then
                uninstallDesktopIcon;
                .log 7 "ln -s $SRCDIRECTORY/desktop/$DESKTOPFILE $APPLICATIONS/$DESKTOPFILE"
                ln -s "$SRCDIRECTORY/desktop/$DESKTOPFILE" "$APPLICATIONS/$DESKTOPFILE"
                .log 5 "linked"
            fi
        fi
    fi
}

function uninstallDesktopIcon() {
    .log 7 "rm $APPLICATIONS/$DESKTOPFILE"
    rm "$APPLICATIONS/$DESKTOPFILE"
    .log 5 "removed config"
}

##################
# MAIN SCRIPT FLOW

# User must provide arguments
[ $# -gt 0 ] || { usage; exit 0; }

# Get options
while getopts 'dhFiuv' flag; do
    case "${flag}" in
        d) DESKTOPICON=true ;;
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
fi

if [ $UNINSTALL ]; then
    uninstall;
fi

if [ $DESKTOPICON ]; then
    installDesktopIcon;
fi

.log 5 "finished"
