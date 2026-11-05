#!/usr/bin/env bash
# detach_window.sh <tab_number>
# Move the focused kitty window to the given tab (1-based).
# If the tab doesn't exist, move to a new tab instead.

TAB_NUM="${1:-}"
if [ -z "$TAB_NUM" ]; then
    echo "Usage: detach_window.sh <tab_number>" >&2
    exit 1
fi

# Count current tabs via kitty remote control.
TAB_COUNT=$(kitty @ ls 2>/dev/null | python3 -c "
import json, sys
data = json.load(sys.stdin)
print(sum(len(os_win.get('tabs', [])) for os_win in data))
" 2>/dev/null)

# Fall back to 1 if we can't determine the count.
TAB_COUNT="${TAB_COUNT:-1}"

# Convert 1-based input to 0-based index.
INDEX=$(( TAB_NUM - 1 ))

if [ "$INDEX" -lt "$TAB_COUNT" ]; then
    kitty @ detach-window --target-tab "index:${INDEX}"
else
    kitty @ detach-window --target-tab new
fi
