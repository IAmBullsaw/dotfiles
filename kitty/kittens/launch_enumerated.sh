#!/usr/bin/env bash
# launch_enumerated.sh <base_title> <cmd...>
#
# Meant to run INSIDE a freshly-spawned kitty tab (as the tab's own
# command), not as a kitty background process. Kitty sets KITTY_LISTEN_ON
# for windows/tabs it spawns itself, so remote control works here even
# though it does NOT work for `launch --type=background`.
#
# Computes the next free enumerated title (base, base 2, base 3, ...),
# sets it on the current tab, then execs into an interactive bash
# running the real command (so ~/.bashrc / work.sh env vars load).

BASE_TITLE="${1:-}"
shift || true

if [ -z "$BASE_TITLE" ] || [ "$#" -eq 0 ]; then
    echo "Usage: launch_enumerated.sh <base_title> <cmd...>" >&2
    exec bash -i
fi

TITLE=$(kitty @ ls 2>/dev/null | python3 -c "
import json, re, sys

base = sys.argv[1]
data = json.load(sys.stdin)

titles = []
for os_win in data:
    for tab in os_win.get('tabs', []):
        titles.append(tab.get('title', ''))

pattern = re.compile(r'^' + re.escape(base) + r'(?: (\d+))?\$')
used = set()
for t in titles:
    m = pattern.match(t)
    if m:
        used.add(int(m.group(1)) if m.group(1) else 1)

n = 1
while n in used:
    n += 1

print(base if n == 1 else f'{base} {n}')
" "$BASE_TITLE" 2>/dev/null)

TITLE="${TITLE:-$BASE_TITLE}"

kitty @ set-tab-title "$TITLE" 2>/dev/null

exec bash -ic 'exec "$@"' bash "$@"
