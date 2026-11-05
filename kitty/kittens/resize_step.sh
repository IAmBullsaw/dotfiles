#!/usr/bin/env bash
# Usage: resize_step.sh <w+|w-|h+|h->  [step]
if ! WMCTRL=$(command -v wmctrl); then
    echo "resize_step.sh: wmctrl not found on PATH" >&2
    exit 1
fi
STEP=${2:-50}
DIR=$1

WID=$(xprop -root _NET_ACTIVE_WINDOW | awk '{print $NF}')
read -r X Y W H < <(xwininfo -id "$WID" | awk '
  /Absolute upper-left X:/ {x=$NF}
  /Absolute upper-left Y:/ {y=$NF}
  /Width:/  {w=$NF}
  /Height:/ {h=$NF}
  END {print x, y, w, h}')

case "$DIR" in
    w+) W=$((W + STEP)) ;;                                    # extend right edge
    w-) W=$((W > STEP ? W - STEP : W)) ;;                    # shrink right edge
    h+) H=$((H + STEP)) ;;                                    # extend bottom edge
    h-) H=$((H > STEP ? H - STEP : H)) ;;                    # shrink bottom edge
    xl+) X=$((X - STEP)); W=$((W + STEP)) ;;                 # extend left edge
    xl-) X=$((X + STEP)); W=$((W > STEP ? W - STEP : W)) ;;  # shrink left edge
    yt+) Y=$((Y - STEP)); H=$((H + STEP)) ;;                 # extend top edge
    yt-) Y=$((Y + STEP)); H=$((H > STEP ? H - STEP : H)) ;;  # shrink top edge
esac

$WMCTRL -r :ACTIVE: -e "0,$X,$Y,$W,$H"
