#!/usr/bin/env bash
# stop hook: ring the kitty bell in THIS window when the assistant finishes
# a turn, so an unfocused tab visually flags (and auto-clears on focus) via
# kitty's native bell_on_tab indicator - no tab-title mutation, see
# the earlier job-bell script for why that approach was abandoned.
#
# ATTEMPT 1 (superseded): tried printing \a directly to /dev/tty. Verified
# broken - a kiro-cli-chat hook subprocess has no controlling terminal
# (`tty` reports "not a tty", /dev/tty open fails with ENXIO). Writing to
# stdout doesn't work either: per hooks.md, a stop hook's stdout is never
# surfaced to the user.
#
# ATTEMPT 2 (this version, verified working): kitty sets KITTY_WINDOW_ID and
# KITTY_LISTEN_ON in every window's environment, and a hook subprocess
# inherits its parent session's env - so both are available here even
# though there's no tty. Use `kitty @ send-text --match id:$KITTY_WINDOW_ID`
# against THIS window's own socket. That is a remote-control call, not a
# direct tty write, so it works regardless of whether the hook subprocess
# has a controlling terminal.
#
# Reads (and ignores) the stop hook's JSON payload on stdin. Always exits 0
# so a missing kitty/env var never surfaces a warning or blocks the turn -
# a bell that doesn't fire is not worth interrupting the session over.
set -u

# Drain stdin (the hook_event_name/cwd/assistant_response payload) - unused.
cat >/dev/null 2>&1 || true

if [ -n "${KITTY_LISTEN_ON:-}" ] && [ -n "${KITTY_WINDOW_ID:-}" ]; then
    kitty @ --to "$KITTY_LISTEN_ON" send-text --match "id:$KITTY_WINDOW_ID" $'\a' \
        >/dev/null 2>&1 || true
fi

exit 0
