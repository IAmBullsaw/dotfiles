#!/usr/bin/env bash
# Pre-input hook: scan user prompt for sensitive data and warn.
# Receives JSON on stdin with {"prompt": "..."} field.
# Exit 0: adds stdout to context (the warning).
# If clean, outputs nothing.

REDACT="$HOME/Code/scripts/redact.py"

prompt=$(python3 -c "import sys,json; print(json.load(sys.stdin).get('prompt',''))")

if [[ -z "$prompt" ]]; then
    exit 0
fi

# Run --check mode: exits 1 if sensitive data found
findings=$(echo "$prompt" | python3 "$REDACT" --check 2>&1)
rc=$?

if [[ $rc -eq 1 ]]; then
    echo "⚠️  SENSITIVE DATA DETECTED in your prompt:"
    echo "$findings" | grep "^  "
    echo ""
    echo "Consider redacting before proceeding. Run: echo '...' | redact"
fi

exit 0
