"""
Kitty kitten: move to neighboring window, falling back to next/prev tab
when at the leftmost (alt+h) or rightmost (alt+l) edge.
"""

from kittens.tui.handler import result_handler


def main(args: list[str]) -> str:
    return ""


@result_handler(no_ui=True)
def handle_result(
    args: list[str], answer: str, target_window_id: int, boss: object
) -> None:
    direction = args[1] if len(args) > 1 else "right"
    tab = boss.active_tab
    if tab is None:
        return

    before = boss.active_window
    tab.neighboring_window(direction)
    after = boss.active_window

    if before is after:
        # No neighbor — at the edge, switch tab then go to the opposite edge
        if direction == "right":
            boss.next_tab()
            new_tab = boss.active_tab
            if new_tab:
                # Move to leftmost window by going left until we can't
                for _ in range(50):
                    w = boss.active_window
                    new_tab.neighboring_window("left")
                    if boss.active_window is w:
                        break
        elif direction == "left":
            boss.previous_tab()
            new_tab = boss.active_tab
            if new_tab:
                # Move to rightmost window by going right until we can't
                for _ in range(50):
                    w = boss.active_window
                    new_tab.neighboring_window("right")
                    if boss.active_window is w:
                        break
