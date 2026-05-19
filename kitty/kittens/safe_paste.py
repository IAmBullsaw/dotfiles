"""
Kitty kitten: paste clipboard through redact.py before typing.
No overlay. Uses xclip for clipboard access.
"""

import os
import subprocess
import sys

from kittens.tui.handler import result_handler


def main(args: list[str]) -> str:
    return ""


@result_handler(no_ui=True)
def handle_result(
    args: list[str], answer: str, target_window_id: int, boss: object
) -> None:
    w = boss.window_id_map.get(target_window_id)
    if w is None:
        return

    # Get clipboard via xclip
    cp = subprocess.run(
        ["xclip", "-selection", "clipboard", "-o"],
        capture_output=True,
        text=True,
        timeout=5,
    )
    raw = cp.stdout
    if not raw:
        return

    # Redact
    redact = os.path.expanduser("~/Code/scripts/redact.py")
    result = subprocess.run(
        ["python3", redact],
        input=raw,
        capture_output=True,
        text=True,
        timeout=5,
    )

    text = result.stdout if result.stdout else raw
    w.paste_text(text)
