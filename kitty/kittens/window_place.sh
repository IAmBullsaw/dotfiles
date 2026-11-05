#!/usr/bin/env bash
# Move and snap the active OS window (EWMH / wmctrl).
#
# Usage:
#   window_place.sh <snap>              full fullscreen left right top bottom
#                                       tl tr bl br center
#   window_place.sh move <dir> [step]   dir = left right up down, step defaults to 50
#
# Geometry is computed from _NET_WORKAREA, so panels/docks are respected.
# Window decorations are compensated via _NET_FRAME_EXTENTS when present.
#
# Deliberately no set -e: a partial failure must not leave the window
# un-maximized but never repositioned.

if ! WMCTRL=$(command -v wmctrl); then
    echo "window_place.sh: wmctrl not found on PATH" >&2
    exit 1
fi

STEP_DEFAULT=50

# --- active window ----------------------------------------------------------
WID=$(xprop -root _NET_ACTIVE_WINDOW | awk '{print $NF}')
if [ -z "$WID" ] || [ "$WID" = "0x0" ]; then
    echo "window_place.sh: no active window" >&2
    exit 1
fi

# Current client geometry (absolute position, client width/height).
read -r X Y W H < <(xwininfo -id "$WID" | awk '
  /Absolute upper-left X:/ {x=$NF}
  /Absolute upper-left Y:/ {y=$NF}
  /^  Width:/  {w=$NF}
  /^  Height:/ {h=$NF}
  END {print x, y, w, h}')

# --- frame extents (0 0 0 0 when decorations are hidden) --------------------
FL=0 FR=0 FT=0 FB=0
fe_raw=$(xprop -id "$WID" _NET_FRAME_EXTENTS 2>/dev/null)
case "$fe_raw" in
    *"= "*)
        read -ra fe < <(printf '%s' "$fe_raw" | sed 's/.*= //' | tr -d ',')
        FL=${fe[0]:-0} FR=${fe[1]:-0} FT=${fe[2]:-0} FB=${fe[3]:-0}
        ;;
esac

# --- work area for the current desktop --------------------------------------
read -ra wa < <(xprop -root _NET_WORKAREA | sed 's/.*= //' | tr -d ',')
desktop=$(xprop -root _NET_CURRENT_DESKTOP 2>/dev/null | awk '{print $NF}')
case "$desktop" in
    ''|*[!0-9]*) desktop=0 ;;
esac
off=$((desktop * 4))
if [ -z "${wa[off]:-}" ]; then
    off=0
fi
WAX=${wa[off]:-0}
WAY=${wa[$((off + 1))]:-0}
WAW=${wa[$((off + 2))]:-0}
WAH=${wa[$((off + 3))]:-0}

if [ "$WAW" -le 0 ] || [ "$WAH" -le 0 ]; then
    # Fall back to full screen geometry if _NET_WORKAREA is unusable.
    read -ra dg < <(xprop -root _NET_DESKTOP_GEOMETRY | sed 's/.*= //' | tr -d ',')
    WAX=0 WAY=0 WAW=${dg[0]:-1920} WAH=${dg[1]:-1080}
fi

# Half sizes. The complementary half uses (total - half) so odd sizes still
# tile without a one pixel gap.
HALF_W=$((WAW / 2))
HALF_H=$((WAH / 2))
REST_W=$((WAW - HALF_W))
REST_H=$((WAH - HALF_H))

# --- helpers ----------------------------------------------------------------

# wmctrl -e is silently ignored while a window is maximized or fullscreen.
unpin() {
    "$WMCTRL" -r :ACTIVE: -b remove,maximized_vert,maximized_horz
    "$WMCTRL" -r :ACTIVE: -b remove,fullscreen
}

# set_outer X Y OUTER_W OUTER_H
# Takes the desired on-screen footprint and converts it to the client size
# wmctrl expects by subtracting the decoration thickness.
set_outer() {
    local x=$1 y=$2 ow=$3 oh=$4
    local cw=$((ow - FL - FR))
    local ch=$((oh - FT - FB))
    [ "$cw" -lt 1 ] && cw=1
    [ "$ch" -lt 1 ] && ch=1
    unpin
    "$WMCTRL" -r :ACTIVE: -e "0,$x,$y,$cw,$ch"
}

usage() {
    sed -n '2,12p' "$0" >&2
    exit 1
}

# --- dispatch ---------------------------------------------------------------
ACTION=${1:-}

case "$ACTION" in
    full)       set_outer "$WAX" "$WAY" "$WAW" "$WAH" ;;
    maximize)
        "$WMCTRL" -r :ACTIVE: -b remove,fullscreen
        "$WMCTRL" -r :ACTIVE: -b toggle,maximized_vert,maximized_horz
        ;;
    fullscreen) "$WMCTRL" -r :ACTIVE: -b toggle,fullscreen ;;

    # Toggle fullscreen, saving geometry before entering and restoring on exit.
    # State file: /tmp/wp_fs_save_<WID>
    fullscreen-toggle)
        SAVE_FILE="/tmp/wp_fs_save_${WID}"
        # Check current fullscreen state.
        fs_state=$(xprop -id "$WID" _NET_WM_STATE 2>/dev/null)
        if echo "$fs_state" | grep -q '_NET_WM_STATE_FULLSCREEN'; then
            # Currently fullscreen: restore saved geometry if available.
            "$WMCTRL" -r :ACTIVE: -b remove,fullscreen
            if [ -f "$SAVE_FILE" ]; then
                read -r sx sy sow soh < "$SAVE_FILE"
                rm -f "$SAVE_FILE"
                sleep 0.05  # let the WM apply the un-fullscreen
                set_outer "$sx" "$sy" "$sow" "$soh"
            fi
        else
            # Not fullscreen: save current outer geometry, then go fullscreen.
            ow=$((W + FL + FR))
            oh=$((H + FT + FB))
            printf '%s %s %s %s\n' "$X" "$Y" "$ow" "$oh" > "$SAVE_FILE"
            "$WMCTRL" -r :ACTIVE: -b add,fullscreen
        fi
        ;;

    left)   set_outer "$WAX"                  "$WAY"                  "$HALF_W" "$WAH" ;;
    right)  set_outer "$((WAX + HALF_W))"     "$WAY"                  "$REST_W" "$WAH" ;;
    top)    set_outer "$WAX"                  "$WAY"                  "$WAW"    "$HALF_H" ;;
    bottom) set_outer "$WAX"                  "$((WAY + HALF_H))"     "$WAW"    "$REST_H" ;;

    tl)     set_outer "$WAX"                  "$WAY"                  "$HALF_W" "$HALF_H" ;;
    tr)     set_outer "$((WAX + HALF_W))"     "$WAY"                  "$REST_W" "$HALF_H" ;;
    bl)     set_outer "$WAX"                  "$((WAY + HALF_H))"     "$HALF_W" "$REST_H" ;;
    br)     set_outer "$((WAX + HALF_W))"     "$((WAY + HALF_H))"     "$REST_W" "$REST_H" ;;

    center)
        ow=$((W + FL + FR))
        oh=$((H + FT + FB))
        set_outer "$((WAX + (WAW - ow) / 2))" "$((WAY + (WAH - oh) / 2))" "$ow" "$oh"
        ;;

    move)
        DIR=${2:-}
        STEP=${3:-$STEP_DEFAULT}
        ow=$((W + FL + FR))
        oh=$((H + FT + FB))

        case "$DIR" in
            left)  X=$((X - STEP)) ;;
            right) X=$((X + STEP)) ;;
            up)    Y=$((Y - STEP)) ;;
            down)  Y=$((Y + STEP)) ;;
            *)     usage ;;
        esac

        # Keep the window inside the work area. When the window is larger than
        # the work area the max collapses onto the min, pinning it to the edge.
        min_x=$WAX
        max_x=$((WAX + WAW - ow))
        min_y=$WAY
        max_y=$((WAY + WAH - oh))
        [ "$max_x" -lt "$min_x" ] && max_x=$min_x
        [ "$max_y" -lt "$min_y" ] && max_y=$min_y
        [ "$X" -lt "$min_x" ] && X=$min_x
        [ "$X" -gt "$max_x" ] && X=$max_x
        [ "$Y" -lt "$min_y" ] && Y=$min_y
        [ "$Y" -gt "$max_y" ] && Y=$max_y

        set_outer "$X" "$Y" "$ow" "$oh"
        ;;

    ''|-h|--help) usage ;;
    *)
        echo "window_place.sh: unknown action '$ACTION'" >&2
        usage
        ;;
esac
