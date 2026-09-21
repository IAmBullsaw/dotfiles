require config

# ============================================================
#  functions.sh
# ============================================================

# --- Recompile .bashrc.d -----------------------------------
# Force a fresh compile and reload the current shell.
bashrc-compile() {
    local compiled="$BASHRC_D/compiled"
    echo "Removing $compiled and reloading..."
    rm -f "$compiled"
    # Re-source .bashrc which will detect missing compiled and rebuild
    # shellcheck source=/dev/null
    source "$HOME/.bashrc"
    _bashrc_notify_kitty
}

# --- Push current env to already-running kitty instances ---
# New tabs in an already-running kitty process inherit ITS environment,
# not a fresh shell's. `kitty @ env` updates what future tabs of a
# running instance will see, without needing to restart kitty.
# Source of vars: everything work.sh itself exports, discovered by running
# it in a near-clean subshell and diffing env before/after (not grepping
# the source, which misses dynamic exports like _load_netrc_token). This
# deliberately excludes shell-session noise (PWD, SHLVL, PS1, etc.) since
# those are never set by work.sh in the first place.
# Removals: kitty @ env VARNAME (no "=") unsets a var for future windows
# (verified live, not just from --help). We track PREVIOUSLY PUSHED VAR
# NAMES ONLY (never values) in .kitty-env-vars, so deleting an export from
# work.sh gets cleaned up in kitty too, instead of lingering until kitty
# restarts. No secret values are ever written to disk.
# See ~/.kiro/learnings.md "Tooling" for why this is needed.
_bashrc_notify_kitty() {
    if ! command -v kitty >/dev/null 2>&1; then
        return 0
    fi

    local sockets=()
    local sock
    for sock in /tmp/kitty-*; do
        [[ -S "$sock" ]] || continue
        sockets+=("$sock")
    done

    if [[ ${#sockets[@]} -eq 0 ]]; then
        echo "no kitty available"
        return 0
    fi

    local work_sh="$HOME/.config/work/work.sh"
    if [[ ! -f "$work_sh" ]]; then
        return 0
    fi

    local before after
    before=$(env -i HOME="$HOME" PATH="$PATH" USER="$USER" bash -c 'env' 2>/dev/null | sort)
    after=$(env -i HOME="$HOME" PATH="$PATH" USER="$USER" bash -c "source '$work_sh' >/dev/null 2>&1; env" 2>/dev/null | sort)

    local -a env_args=()
    while IFS= read -r line; do
        [[ -n "$line" ]] && env_args+=("$line")
    done < <(comm -13 <(printf '%s\n' "$before") <(printf '%s\n' "$after"))

    # Names-only, for the removal diff and the next snapshot. Never write
    # env_args (which contains values) to disk.
    local -a names_now=()
    local pair
    for pair in "${env_args[@]}"; do
        names_now+=("${pair%%=*}")
    done

    local snapshot="$BASHRC_D/.kitty-env-vars"
    local -a names_before=()
    if [[ -f "$snapshot" ]]; then
        while IFS= read -r line; do
            [[ -n "$line" ]] && names_before+=("$line")
        done < "$snapshot"
    fi

    local -a removed=()
    while IFS= read -r line; do
        [[ -n "$line" ]] && removed+=("$line")
    done < <(comm -23 <(printf '%s\n' "${names_before[@]}" | sort) <(printf '%s\n' "${names_now[@]}" | sort))

    printf '%s\n' "${names_now[@]}" > "$snapshot"

    if [[ ${#env_args[@]} -eq 0 && ${#removed[@]} -eq 0 ]]; then
        return 0
    fi

    local told=0
    for sock in "${sockets[@]}"; do
        local ok=1
        if [[ ${#env_args[@]} -gt 0 ]]; then
            kitty @ --to="unix:$sock" env "${env_args[@]}" >/dev/null 2>&1 || ok=0
        fi
        if [[ ${#removed[@]} -gt 0 ]]; then
            kitty @ --to="unix:$sock" env "${removed[@]}" >/dev/null 2>&1 || ok=0
        fi
        [[ "$ok" -eq 1 ]] && told=$(( told + 1 ))
    done

    local suffix=""
    if [[ ${#env_args[@]} -gt 0 && ${#removed[@]} -gt 0 ]]; then
        suffix=" (${#env_args[@]} added, ${#removed[@]} removed)"
    elif [[ ${#env_args[@]} -gt 0 ]]; then
        suffix=" (${#env_args[@]} added)"
    elif [[ ${#removed[@]} -gt 0 ]]; then
        suffix=" (${#removed[@]} removed)"
    fi

    if [[ "$told" -eq 1 ]]; then
        echo "told kitty${suffix}"
    elif [[ "$told" -gt 1 ]]; then
        echo "told $told kittens${suffix}"
    else
        echo "no kitty available"
    fi
}

# --- Most-used commands ------------------------------------
most-frequent() {
    history \
        | awk '{CMD[$2]++; count++} END {for (a in CMD) print CMD[a], CMD[a]/count*100"%", a}' \
        | grep -v './' \
        | sort -nr \
        | head -n 10 \
        | nl \
        | column -t
}

# --- Add alias and reload -----------------------------------
add-alias() {
    local name="$1"
    if [[ -z "$name" ]]; then
        echo "Usage: add-alias <name> <command...>" >&2
        return 1
    fi
    shift
    if [[ $# -eq 0 ]]; then
        echo "add-alias: no command provided for '$name'" >&2
        return 1
    fi
    echo -e "\nalias ${name}='$*'" >> "$BASHRC_D/aliases.sh"
    # Invalidate compiled so next shell (and this one via bashrc-compile) picks it up
    bashrc-compile
}

# --- Symlink ~/Code/scripts/* into ~/.local/bin (no extension) --
relink-scripts() {
    local src="$HOME/Code/scripts"
    local dst="$HOME/.local/bin"
    [[ -d "$src" ]] || { echo "relink-scripts: $src not found" >&2; return 1; }
    mkdir -p "$dst"
    local file link
    for file in "$src"/*; do
        [[ -f "$file" ]] || continue
        link="$dst/${file##*/}"
        link="${link%%.*}"
        if [[ ! -e "$link" ]]; then
            ln -s "$file" "$link" && echo "Linked: $link → $file"
        fi
    done
}

# --- Safe git commit (refuse master/main) ------------------
gc() {
    local branch
    branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null) || return 1
    if [[ "$branch" == "master" || "$branch" == "main" ]]; then
        echo "gc: refusing to commit directly to '$branch'" >&2
        echo "    Use: git checkout -b <branch-name>" >&2
        return 1
    fi
    git commit "$@"
}

# --- Open repo logbook (one dir above repo root) -----------
llb() {
    git rev-parse --is-inside-work-tree &>/dev/null \
        || { echo "llb: not inside a git repository" >&2; return 1; }
    logbook -t "$(git rev-parse --show-toplevel)_logbook.md" "$@"
}

# --- Directory bookmarks -----------------------------------
# bm            → list all bookmarks
# bm <name>     → jump to bookmark
# bm -s <name>  → save current dir as bookmark
# bm -d <name>  → delete bookmark
bm() {
    [[ -f "$BOOKMARK_FILE" ]] || touch "$BOOKMARK_FILE"
    case "${1-}" in
        -s) [[ -z "$2" ]] && { echo "bm -s: name required" >&2; return 1; }
            echo "${2}=${PWD}" >> "$BOOKMARK_FILE"
            echo "Saved: $2 → $PWD" ;;
        -d) [[ -z "$2" ]] && { echo "bm -d: name required" >&2; return 1; }
            sed -i "/^${2}=/d" "$BOOKMARK_FILE"
            echo "Deleted: $2" ;;
        '')
            [[ -s "$BOOKMARK_FILE" ]] && cat "$BOOKMARK_FILE" || echo "(no bookmarks)" ;;
        *)  local target
            target=$(grep "^${1}=" "$BOOKMARK_FILE" 2>/dev/null | cut -d= -f2-)
            [[ -n "$target" ]] && cd "$target" || { echo "bm: no bookmark '$1'" >&2; return 1; } ;;
    esac
}

# --- NVM lazy loader ---------------------------------------
# Avoids the ~400ms startup penalty of sourcing nvm.sh eagerly.
if [[ -s "$NVM_DIR/nvm.sh" ]]; then
    _nvm_load() {
        unset -f nvm node npm npx yarn _nvm_load
        # shellcheck source=/dev/null
        source "$NVM_DIR/nvm.sh"
    }
    nvm()  { _nvm_load; nvm  "$@"; }
    node() { _nvm_load; node "$@"; }
    npm()  { _nvm_load; npm  "$@"; }
    npx()  { _nvm_load; npx  "$@"; }
    yarn() { _nvm_load; yarn "$@"; }
fi
