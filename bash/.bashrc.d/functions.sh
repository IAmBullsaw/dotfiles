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
