---
name: chat-to-html
description: "Generate a single self-contained, shareable HTML file rendering a chat/agent conversation as a classic bubble-style chat UI (subtle, mellow colors, centered column), for sharing a conversation outside the chat app. Use when: \"$chat-to-html\", \"turn this chat into an HTML\", \"make this conversation shareable\", \"export this chat as html\", \"share this conversation\", \"make a readable version of this chat\", user wants to share a conversation transcript with someone who doesn't have access to the chat app. Not for: visual reports of a repo/codebase/config (use repo-visual-report), code-flow onboarding diagrams (use walkthrough), saving a session to resume later (use /chat save)."
---

# Chat to HTML

Produce one self-contained HTML file rendering a conversation as a classic chat bubble UI: centered column, subtle/mellow bubble colors (not loud chat-app brights), markdown-aware message rendering, code block support, timestamps. Built for sharing a conversation with someone who has no access to the chat app itself — open with a double-click, no server, no login.

Shares infrastructure with `repo-visual-report`: same output folder (`~/reports/`), same vendoring discipline (every dependency inlined, zero network access needed to render), same shared toolbar for cross-report search. Differs in one deliberate way: chat exports do **not** get the per-section feedback form from `report-header.html` — editing a historical chat message via feedback isn't a coherent action the way "revise this section of a report" is. Search, yes; feedback, no.

**Output location is fixed: `~/reports/`.** Same shared folder as `repo-visual-report`, so chat exports show up in cross-report search alongside visual reports.

## Workflow
<procedure>

### Step 1: Get the transcript as JSON

Use `/transcript --json <path>` to export the current conversation (or ask the user which session, if not the current one — `/chat --resume-picker` / `--list-sessions` lists others). This gives a JSON array of `{role, content}` objects, already separated into turns. Do not hand-parse chat logs from `~/.kiro/sessions/` directly; the slash command is the documented, stable interface.

If the user wants a conversation that isn't the current session, tell them to run `/transcript --json <path>` from within that session (or resume it first with `/chat --resume-picker`), since this command only operates on the active conversation.

### Step 2: Vendor a markdown renderer

Messages contain markdown (code fences, lists, bold/links). Vendor `marked` (small, ~35KB minified, unlike Mermaid's ~3MB) the same way Mermaid is vendored in `repo-visual-report`:

```bash
curl -sL --max-time 10 -o /tmp/marked.min.js https://cdn.jsdelivr.net/npm/marked@12/marked.min.js
```

Inline it into the output HTML via a small Python script (never read the file into chat context — same anti-pattern warning as the Mermaid step in `repo-visual-report`):

```python
with open(html_path) as f:
    html = f.read()
with open("/tmp/marked.min.js") as f:
    js = f.read()
html = html.replace(
    '<script src="https://cdn.jsdelivr.net/npm/marked@12/marked.min.js"></script>',
    "<script>\n" + js + "\n</script>"
)
with open(html_path, "w") as f:
    f.write(html)
```
Then delete `/tmp/marked.min.js`.

### Step 3: Embed the transcript and build the HTML

Start from `references/chat-template.html`. It already has:
- the bubble CSS (mellow palette, see Constraints), driven entirely by `--xxx` custom properties on `:root` so it's themeable without touching any other rule
- a built-in **theme engine**: a 🎨 toggle button (fixed top-right) opens a small panel with four bundled presets (mellow dark default, warm paper light, forest quiet, slate blue) plus a "Upload theme .json" file picker. Uploaded/selected themes persist via `localStorage` keyed to the file's path, so reopening the exported HTML keeps the reader's chosen theme. This part needs no per-generation work from you — it's already wired into the template and works entirely client-side (no server, no upload destination, just a `FileReader` reading the picked file locally).
- a `<script type="application/json" id="chat-data">` placeholder for the transcript array
- a renderer that reads that JSON, builds one bubble per message, runs each message's content through `marked.parse()`, and appends a timestamp if present

Your job per generation:
1. Read the exported transcript JSON (from Step 1).
2. Paste it verbatim into the `<script type="application/json" id="chat-data">` block, replacing the placeholder `[]`. Do not transform, summarize, or truncate messages — the point is a faithful, complete transcript.
3. Fill in the page `<title>` and header subtitle (e.g. "Conversation — <topic>, <date>") from the actual conversation content.
4. Write the file to `~/reports/<slug>.html` (kebab-case, e.g. `~/reports/chat-nixos-config-review.html`).
5. Paste in the shared toolbar (style + markup + script) from `repo-visual-report`'s `references/report-header.html` — same three-part splice as that skill's Step 3, for cross-report search. **Skip the per-section feedback wiring**: do not add `class="report-section" data-section-title="..."` to the chat bubbles themselves. If you want the chat to be discoverable by title in search, wrap the whole transcript in one container with an `<h2>` using the conversation's title — that's the only searchable anchor needed, not per-message sections.
6. Vendor `marked` per Step 2.

#### Theme JSON format (for users who want to share/reuse a custom theme)

A theme file is a flat JSON object. Keys match the CSS custom property names minus the `--` prefix (the engine accepts the prefix too, so either form works):

```json
{
  "bg": "#101014",
  "bg-soft": "#16161c",
  "border": "#2a2a33",
  "text": "#e8e6ea",
  "muted": "#8a8794",
  "user-bubble": "#2a2030",
  "user-bubble-border": "#3d2d48",
  "user-text": "#e4d8ee",
  "assistant-bubble": "#1a2024",
  "assistant-bubble-border": "#283036",
  "assistant-text": "#d4dadd",
  "accent": "#b08968",
  "font": "Georgia, serif"
}
```
Any subset of keys is valid. Unspecified ones fall back to the page's current theme. Unrecognized keys are silently ignored (not applied, not an error) so a theme file can carry extra metadata (name, author, etc.) without breaking anything. See `references/example-theme.json` for a complete sample. If you're asked to generate a custom theme for someone (e.g. "make me a theme in my company's blue" or "match my dotfiles' Catppuccin palette"), write one of these flat JSON files and tell them to use the Upload button. Don't try to bake a one-off palette into the HTML's `:root` directly, since that defeats the point of the reader being able to swap themes live.

### Step 4: Verify and hand off

```bash
grep -c "<script" out.html   # expect 3: vendored marked, the toolbar script, and the renderer script (or 2 if renderer is merged into the toolbar script's file — count what you actually wrote)
grep -o "cdn.jsdelivr" out.html | wc -l   # expect 0
```

Open it:
```bash
xdg-open ~/reports/<slug>.html   # Linux
open ~/reports/<slug>.html       # macOS
```

Tell the user the file is self-contained (no network access needed) and, if they started `report-server.py`, that it'll also show up in cross-report search.

</procedure>

## Constraints
<constraints>

- **Subtle and mellow, not a chat-app clone.** No bright blue/green iMessage-style bubbles. Use desaturated, low-contrast tones distinguishing user vs assistant (e.g. a muted warm neutral for user, a muted cool neutral for assistant) against a soft background — see the palette in `references/chat-template.html`.
- **Faithful transcript, not a summary.** Every message from the export goes in, in order, unmodified. This skill renders, it does not edit or curate content. If the user wants a trimmed/curated version, that's a different request (tell them to ask for a redacted export instead, don't silently truncate).
- **No feedback form on chat bubbles.** This is a read-only artifact of a finished conversation, not a living document to be revised in place.
- **Markdown renders properly**: code fences get syntax-neutral monospace blocks (no need to vendor a highlighter just for this — plain monospace with a subtle background is enough), lists/bold/italic/links render as expected via `marked`.
- **Always write to `~/reports/`.** Same shared folder as `repo-visual-report`.
- **Timestamps**: if the transcript JSON includes timestamps, render them (small, muted, under each bubble). If it doesn't, omit rather than fabricate.
- **Tool calls / tool results**: if a message's content includes tool-use or tool-result blocks (not just plain text), render them as a visually distinct, collapsed-by-default block within that bubble (e.g. a small "🔧 tool call" disclosure), not as if they were normal chat prose. Don't drop them, don't expand them by default (keeps the bubble flow readable).
- **Theming is client-side only.** The 🎨 panel's "upload theme" reads the file locally via `FileReader` and never sends it anywhere — no upload endpoint, no server round-trip. Keep it that way; don't wire theme upload to `report-server.py` or any network call, since that would break the zero-infra sharing guarantee for people who don't have the server running.

</constraints>

## Quality Checklist
<done>

- [ ] Output file is in `~/reports/`
- [ ] Transcript is complete and unmodified (spot-check first/last message matches the real conversation)
- [ ] `marked` is vendored inline (`grep cdn.jsdelivr` returns 0 matches)
- [ ] Bubble colors are subtle/mellow, not bright chat-app defaults
- [ ] Code blocks in messages render as monospace, not as raw markdown fence syntax
- [ ] Shared toolbar (search) is present; per-section feedback form is NOT added to chat bubbles
- [ ] Theme toggle (🎨) is present and functional (presets selectable, upload accepts a flat JSON, persists via localStorage)
- [ ] File structurally verified (`<script>`/`</script>` counts match, ends with `</html>`)
- [ ] Opened in browser (or instructions given)

</done>

## References

- [references/chat-template.html](references/chat-template.html) — bubble CSS, theme engine (presets + JSON upload + persistence), JSON transcript placeholder, renderer script.
- [references/example-theme.json](references/example-theme.json) — sample theme file showing the expected flat key/value shape.
