# hgg - History Grep G
# simple script to search in bash_history_master
# bash_history_master is simply one huge file containing the history from all open terminals
# add the following to your bash.rc
#
# update_master_history() {
#    history -a ~/.bash_history_master
# }
#
# PROMPT_COMMAND=update_master_history
#
#
# if ripgrep is on the system, use it
# if fzf is on the system, use it

master_file="/home/${USER}/.bash_history_master"


ripgrep=$( command -v rg )
if [[ -z "$ripgrep" ]]; then
    stool=grep;
else
    stool=$ripgrep;
fi


function list_files() {
    fuzzyfilefinder=$( command -v fzf );
    if [[ -z "${fuzzyfilefinder}" ]]; then
        head ${master_file};
    else
        cat ${master_file} | ${fuzzyfilefinder};
    fi
}

function grep_history() {
    flags="-h"

    if [[ "$1" =~ ^[a-z]+$ ]]; then
        flags+="i"
    fi

    $stool "${flags}" "${1}" "${master_file}"
}

function hgg() {
    if [ -z "$1" ]; then
        list_files;
    else
        grep_history "$1" ;
    fi
}

hgg "$1";
