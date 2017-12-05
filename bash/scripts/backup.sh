#!/bin/bash
# backup.sh is a simple script that uses
# cp file file.bak
# as a quick backup for smaller tasks ...
function usage() {
    echo "usage: $0 filename [.name]"
}

function help() {
    echo "Help for backup.sh"
    echo ""
    echo "DESCRIPTION
                  This is a simple script used for quick backups of a file."
    echo "USAGE
                  `usage`"
    echo ""
    echo "OPTIONS
                  -o Overwrite file.
                  -h Print this 'help'.
                  -v Increases the verbosity of the process."
    echo ""
}

VERBOSE=0
function .log () {
    local LEVEL=${1}
    shift
    if [ ${VERBOSE} -ge ${LEVEL} ]; then
        echo "$@"
    fi
}

while getopts 'ohv' flag; do
    case "${flag}" in
        o) OVERWRITE=true ;;
        h) HELP=true ;;
        v) ((VERBOSE=VERBOSE+1)) ;;
        *) { error "Unexpected option $(flag)"; exit -1; } ;;
    esac
done

shift "$((OPTIND - 1))"

.log 10 "I AM SO HORRIBLY VERBOSE NOW"
.log 10 "CHECKING IF YOU ENTERED A FILE"
if [ ! "$1" ]; then
    .log 10 "YOU DIDN'T DO IT"
    .log 10 "PRINTING THE USAGE FOR YOU"
    usage;
    .log 10 "PRINTED THE USAGE FOR YOU"
    .log 10 "EXITING WITH -1 AS STATUS CODE"
    exit -1;
fi
.log 10 "YOU ENTERED SOMETHING AT LEAST"

.log 10 "CHECKING IF YOU NEEDED HELP"
if [ $HELP ]; then
    .log 10 "YOU NEEDED HELP"
    .log 10 "PRINTING THE HELP FOR YOU"
   help;
   .log 10 "PRINTED THE HELP FOR YOU"
   .log 10 "EXITING WITH 0 AS STATUS CODE"
   exit 0;
fi
.log 10 "YOU DIDN'T NEED HELP"

.log 10 "CHECKING IF $1 IS INDEED A FILE"
if [ -e "$1" ]; then
    .log 10 "CREATING ABSOLUTE PATH NAME"
    SRCPATH="`pwd`/`basename $1`"
    .log 10 "CREATED ABSOLUTE PATH NAME $SRCPATH"
    .log 10 "CHECKING IF YOU WANTED ANOTHER ENDING THAN .bak"
    [ "$2" ] && BAK="$2" || BAK=".bak"
    .log 10 "COOL, IT'S $BAK-TIME"
    if [ -e "$SRCPATH$BAK" ]; then
        if [ $OVERWRITE ]; then
            .log 10 "USING CP COMMAND TO COPY $SRCPATH TO $SRCPATH$BAK AND OVERWRITE THE FILE"
            cp "$SRCPATH" "$SRCPATH$BAK"
            FINALPATH="$SRCPATH$BAK"
            .log 10 "I THINK I DID IT."
        else
            .log 10 "$SRCPATH$BAK ALREADY EXISTS"
            VERSION=1
            .log 10 "TRYING $SRCPATH$BAK.$VERSION"
            while [ -e "$SRCPATH$BAK.$VERSION" ]
            do
                ((VERSION=VERSION+1));
                .log 10 "TRYING $SRCPATH$BAK.$VERSION"
            done
            .log 10 "$SRCPATH$BAK.$VERSION IS AVAILABLE"
            .log 10 "USING CP COMMAND TO COPY $SRCPATH TO $SRCPATH$BAK.$VERSION"
            cp "$SRCPATH" "$SRCPATH$BAK.$VERSION"
            FINALPATH="$SRCPATH$BAK.$VERSION"
            .log 10 "I THINK I DID IT."
        fi
    else
        .log 10 "USING CP COMMAND TO COPY $SRCPATH TO $SRCPATH$BAK"
        cp "$SRCPATH" "$SRCPATH$BAK"
        FINALPATH="$SRCPATH$BAK"
        .log 10 "I THINK I DID IT."
    fi
else
    .log 10 "IT WASN'T A FILE"
    .log 10 "TELLING YOU IT'S NOT A VALID FILE"
    echo "'$1' is not a valid file."
    .log 10 "TOLD YOU IT'S NOT A VALID FILE"
    .log 10 "TELLING YOU HOW TO USE THIS SCRIPT"
    usage;
    .log 10 "TOLD YOU HOW TO USE THIS SCRIPT"
    .log 10 "EXITING WITH -1 AS STATUS CODE"
    exit -1;
fi
.log 1 "copied file to '`basename $FINALPATH`'"
.log 2 "full path: $FINALPATH"
.log 10 "THANK YOU FOR USING THIS SCRIPT"
.log 10 "TELL YOUR FRIENDS"
exit 0;
