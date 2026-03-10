require config

# ============================================================
#  prompt.sh
# ============================================================

# --- Git branch (single call, no sed fork) -----------------
_git_branch() {
    local b
    b=$(git symbolic-ref --short HEAD 2>/dev/null) \
        || { git rev-parse --git-dir &>/dev/null && b='(detached)'; } \
        || b='-'
    echo "$b"
}

# --- Last ≤3 path components, ~ for $HOME ------------------
_short_pwd() {
    local p="${PWD/#$HOME/\~}"
    local IFS='/'
    local -a parts
    read -ra parts <<< "$p"
    local n=${#parts[@]}
    (( n > 3 )) && echo "${parts[n-3]}/${parts[n-2]}/${parts[n-1]}" || echo "$p"
}

# --- VIM terminal indicator --------------------------------
_vim_indicator() {
    [[ -n "$VIM" ]] && printf '%s' "${_C_RED}+${_C_NC}" || echo '$'
}

# --- Stubs overridden by work.sh ---------------------------
get_hostname() { :; }
sourced_file()  { :; }

# --- PWD-change cache --------------------------------------
# git rev-parse is only called when the directory actually changes.
# _CACHED_GIT_ROOT is set to the repo basename, or "" if not in a repo.
# work.sh reads this variable — no extra git calls needed there.
_CACHED_GIT_ROOT=""
_CACHED_PWD=""

_update_git_root_cache() {
    if [[ "$PWD" != "$_CACHED_PWD" ]]; then
        _CACHED_PWD="$PWD"
        local root
        root=$(git rev-parse --show-toplevel 2>/dev/null)
        _CACHED_GIT_ROOT="${root##*/}"
    fi
}

# --- Prompt builder ----------------------------------------
# Called on every prompt via PROMPT_COMMAND.
# Building PS1 here (rather than inline) means:
#  - All path/git/color logic is readable in one place
#  - Picks up pushd/popd/script-driven cd without a cd alias
_build_prompt() {
    _update_git_root_cache
    local host_part
    host_part="$(get_hostname)$(sourced_file)"

    PS1="${_C_GREEN}[\A]${_C_NC}"
    PS1+="${host_part:+ ${host_part}}"
    PS1+=" ${_C_YELLOW}$(_git_branch)${_C_NC}"
    PS1+=" [$(_short_pwd)]"
    PS1+="$(_vim_indicator) "

    PS2="${_C_GREEN}[\A]${_C_NC} ${_C_YELLOW}>${_C_NC} "
}

# PROMPT_COMMAND is set in work.sh after zoxide init, so the order is correct.
# If work.sh is not present, set a sensible default here.
[[ -z "${PROMPT_COMMAND+x}" ]] && PROMPT_COMMAND="_build_prompt"
