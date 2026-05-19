#!/usr/bin/env bash
# Safe paste: get clipboard, redact, send to active kitty window.
# Requires: allow_remote_control socket-only + listen_on in kitty.conf

REDACT="$HOME/Code/scripts/redact.py"

raw=$(xclip -selection clipboard -o 2>/dev/null)
if [[ -z "$raw" ]]; then
    exit 0
fi

redacted=$(python3 "$REDACT" <<< "$raw" 2>/dev/null)

if [[ -n "$redacted" ]]; then
    kitty @ send-text -- "$redacted"
fi
