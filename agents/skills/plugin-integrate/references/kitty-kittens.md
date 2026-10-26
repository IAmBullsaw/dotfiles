# Kitty Custom Kittens Reference

How to write custom kittens for kitty terminal. Based on reverse-engineering kitty 0.46.2 internals.

## Architecture

Kitty loads a custom kitten by calling `import_kitten_main_module(config_dir, kitten_path)`, which returns a dict:
- `m['start']` = the `main()` function (runs in overlay or skipped if `no_ui`)
- `m['end']` = the `handle_result()` function (runs in kitty boss process)

Kitty then checks attributes on `m['end']`:
- `.no_ui` (bool) — if True, skip overlay window, go straight to handle_result
- `.type_of_input` (str|None) — what main() returns
- `.has_ready_notification` (bool)
- `.open_url_handler` (callable|None)

And on `m['start']`:
- `.allow_remote_control` (bool)
- `.remote_control_password` (bool)

These attributes are set by the `@result_handler()` decorator from `kittens.tui.handler`.

## Minimal no-UI kitten template

```python
"""One-line description."""

import os
import subprocess

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

    # Your logic here
    w.paste_text("hello")
```

## kitty.conf mapping

```
map ctrl+shift+v kitten kittens/my_kitten.py
```

Relative paths resolve from kitty's config dir (`~/.config/kitty/`).

## Gotchas

### `@result_handler(no_ui=True)` is mandatory for no-overlay kittens
Without it, `main()` runs in a terminal overlay window. The decorator sets `.no_ui = True` on `handle_result`, which kitty checks via `getattr(e, 'no_ui', False)`.

### `sys.executable` is the kitty binary, not python3
Inside `handle_result()`, `sys.executable` resolves to `/home/user/.local/bin/kitty`. Use `"python3"` when spawning subprocesses.

### `main()` must exist even if unused
Kitty expects `m['start']` to exist. Return empty string.

### Relative kitten paths resolve from `~/.config/kitty/`
If your dotfiles are elsewhere, symlink the kittens directory:
```bash
ln -s ~/dotfiles/kitty/kittens ~/.config/kitty/kittens
```

### Clipboard access
Use `xclip -selection clipboard -o` (from PATH). Don't use `kitty.fast_data_types` — undocumented and may not work in all contexts.

## Debugging kittens

### Inspect module loading
```bash
kitty +runpy "
from kittens.runner import import_kitten_main_module
m = import_kitten_main_module('/home/user/.config/kitty', '/path/to/kitten.py')
e = m['end']
print('no_ui:', getattr(e, 'no_ui', 'NOT SET'))
print('type_of_input:', getattr(e, 'type_of_input', 'NOT SET'))
"
```

### Disassemble kitty internals
```bash
kitty +runpy "
from kittens.runner import create_kitten_handler
import dis
dis.dis(create_kitten_handler)
"
```

### Check available modules
```bash
kitty +runpy "from kittens.tui.handler import result_handler; print(dir(result_handler))"
```

## Available boss methods (partial)

- `boss.window_id_map` — dict of window_id -> Window
- `boss.display_visual_bell_in_window(window_id)` — flash the window
- `w.paste_text(text)` — paste text into window (bracketed paste)
- `w.send_text(text)` — send raw text (no bracketed paste)
