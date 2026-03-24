#!/bin/bash
# Lunch reminder — called from cron with argument "early" or "final"

# Auto-detect display and dbus from mate-session process
_ENV="/proc/$(pgrep -u "$(whoami)" -x mate-session | head -1)/environ"
export DISPLAY=$(tr '\0' '\n' < "$_ENV" | rg -m1 '^DISPLAY=' | cut -d= -f2-)
export DBUS_SESSION_BUS_ADDRESS=$(tr '\0' '\n' < "$_ENV" | rg -m1 '^DBUS_SESSION_BUS_ADDRESS=' | cut -d= -f2-)

QUOTES=(
  "The impediment to action advances action. What stands in the way becomes the way. — Marcus Aurelius"
  "We suffer more in imagination than in reality. — Seneca"
  "Waste no more time arguing about what a good man should be. Be one. — Marcus Aurelius"
  "It is not that we have a short time to live, but that we waste a good deal of it. — Seneca"
  "Because I said I would."
  "How long are you going to wait before you demand the best for yourself? — Epictetus"
  "First say to yourself what you would be; and then do what you have to do. — Epictetus"
  "The best time to plant a tree was 20 years ago. The second best time is now."
  "You could leave life right now. Let that determine what you do and say and think. — Marcus Aurelius"
  "Discipline equals freedom. — Jocko Willink"
)

case "$1" in
  early)
    QUOTE="${QUOTES[$((RANDOM % ${#QUOTES[@]}))]}"
    notify-send -u normal -t 0 -i dialog-information \
      "🍽️ Lunch soon!" \
      "Start wrapping up.\n\n\"${QUOTE}\""
    ;;
  final)
    notify-send -u critical -t 0 -i dialog-warning \
      "🍽️ Lunch. Now or never." \
      "Step away from the keyboard."
    ;;
esac
