---
name: repo-visual-report
description: "Generate a single self-contained, shareable HTML report that visually documents a repo, config tree, or system (architecture, topology, data flow) using Mermaid diagrams, inline SVG, and tables. Mermaid is vendored inline so the file works offline, over email, or on a locked-down network with no CDN access. Use when: \"$visual-report\", \"make a visual overview of this repo\", \"show me this setup with diagrams\", \"visualize this config/architecture\", \"make an HTML report of this codebase\", \"turn this into a visual doc I can share\", user points at an unfamiliar repo/config tree and wants a shareable visual summary (not a code-flow walkthrough for onboarding). Not for: code-flow/onboarding diagrams for a feature inside a codebase you already work in (use walkthrough), interactive clickable node-detail diagrams (use walkthrough), single-file explanations (just explain inline)."
---

# Repo Visual Report

Produce one self-contained HTML file that lets someone understand an unfamiliar repo, config tree, or system at a glance: what it is, how its pieces connect, and what stands out. Built for **sharing outside the dev environment** (email, USB, air-gapped machine, a coworker on a locked-down network) — so the whole file, including Mermaid, must work with zero network access when opened cold.

This differs from the `walkthrough` skill: `walkthrough` builds an interactive, clickable diagram for onboarding onto *code you already work in*, writes next to the project it describes, and has no cross-report search or feedback loop. This skill builds a static, scannable *report* for exploring a *repo or system someone just handed you* — mixing Mermaid diagrams, hand-drawn inline SVG, tables, and verbatim quotes from the source material, always written into one shared folder so reports accumulate and stay searchable together.

**Output location is fixed: `~/reports/`.** Every report this skill generates goes there, flat, no subdirectories. This is what makes the cross-report fuzzy search in Step 3b possible — the search manifest is built by scanning that one folder.

**Server dependency (optional, for search/feedback only):** `~/Code/scripts/report-server.py` serves `~/reports/` and provides `GET /index.json` (search manifest) and `POST /feedback` (per-section edit requests → detached `kiro-cli --no-interactive` call). The generated HTML itself never requires this server — Mermaid, layout, and content all work from a bare `file://` open. Only the search box and the feedback form need it running:
```bash
~/Code/scripts/report-server.py                 # http://localhost:8000, serves ~/reports/
~/Code/scripts/report-server.py --port 8080     # custom port
```
Offer to start it after generating a report; don't launch it unprompted since it's a persistent background process (flag per the usual guardrail for anything long-running).

## Workflow
<procedure>

### Step 1: Explore before drawing anything

Read real files. Never invent topology, file names, or config values.

- Use `read`/`glob`/`grep` directly for a small-to-medium target (a single repo, under ~200 files to skim).
- For a large target, delegate exploration to subagents in parallel (one per subsystem/directory), each returning a structured summary: what it is, key config values, how it connects to other parts. Same rationale as `walkthrough` step 2: keeps main context free for HTML generation.
- Prioritize: README/docs first, then config/module entry points, then anything that looks hand-maintained (TODO files, journal-style notes, scripts) — these produce the most interesting "notes from the field" sections.
- Note concrete facts to visualize: real file names, real field values, real relationships (not generic placeholders). If a value is genuinely unknown, mark it as such in the output rather than guessing.

### Step 2: Pick the diagram set

Choose 3-6 sections based on what the target actually contains. Do not force all of these if the repo doesn't have the corresponding concept:

| What's present | Diagram |
|---|---|
| Multiple hosts/services/components | Mermaid `graph` topology, colored by role |
| Layered config/module composition | Mermaid `graph TD` showing inheritance/composition |
| Network, trust, or auth relationships | Mermaid `graph` with solid edges for data flow, dotted for trust/auth |
| Peer-to-peer or many-to-many relationships (sync, pub/sub) | Mermaid `graph` bipartite (peers on one side, resources on the other) |
| A process with no clean graph shape (e.g. secrets flow, pipeline stages) | Hand-written inline `<svg>` with boxes + arrows — more control than Mermaid for linear flows |
| Any enumerable feature matrix (hosts × features, services × flags) | Plain HTML `<table>`, not a diagram |
| Pinned dependencies/versions | Card grid or table |
| Honest rough edges (TODOs, known issues, operational tricks) | A "notes from the field" section with verbatim quotes in `<blockquote>`/`.quote` styling |

Keep each diagram scoped to one concern. Don't cram topology + trust + data flow into a single Mermaid graph — split into separate panels with their own heading.

### Step 3: Write the HTML

Write the output to `~/reports/<slug>.html` (kebab-case slug describing the target, e.g. `~/reports/nix-config-overview.html`). Create the folder if it doesn't exist yet (`mkdir -p ~/reports`). Never write report HTML anywhere else.

Dark theme by default (match the target's aesthetic only if the user asks for light). Structure:

1. `<body>` opens with the shared toolbar markup from `references/report-header.html` (search bar + collapse hint) — paste it as the very first thing inside `<body>`, before your own `<header>`.
2. `<header>` — title, one-paragraph summary, badges for key tech/tools detected
3. Every `<section>` you'd normally write gets two additions so it plugs into search and feedback:
   - `class="report-section" data-section-title="Human-readable section title"` on the `<section>` tag itself
   - nothing else — the shared script injects the feedback toggle button and hidden input automatically for any element matching `.report-section`
4. Each section still follows the pattern from Step 2: lead paragraph, diagram/table panel, legend/caption if needed
5. A closing "notes" or "rough edges" section quoting real TODOs/journal entries verbatim — also wrapped in `class="report-section"` so it's searchable/annotatable like any other section
6. `<footer>` — note that it was generated from a read-only walkthrough, no files modified
7. Right before `</body>`, paste the shared toolbar `<script>` block from `references/report-header.html`

Use `references/template.html` as the structural starting point — it already has the toolbar wired in correctly, plus the Mermaid/SVG/table examples from Step 2.

**Mermaid dark theme init** (always use this unless the user wants light mode):
```js
mermaid.initialize({
  startOnLoad: true,
  theme: "dark",
  themeVariables: {
    darkMode: true,
    background: "#161923",
    primaryColor: "#1c2030",
    primaryTextColor: "#e3e6f0",
    primaryBorderColor: "#7dd3fc",
    lineColor: "#8b92ab",
    secondaryColor: "#1c2030",
    tertiaryColor: "#1c2030",
    fontFamily: "Segoe UI, Inter, system-ui, sans-serif"
  },
  flowchart: { curve: "basis", htmlLabels: true }
});
```
This must be a *separate* `<script>` block from the toolbar script and from the vendored Mermaid library script (Step 4) — three script tags total, in this order: vendored Mermaid library, your mermaid.initialize() call, the toolbar script. Order doesn't matter between the init call and the toolbar script, but the vendored library must load before either.

### Step 3b: Cross-report search and per-section feedback — how it works

This is wired entirely by the `report-header.html` snippet you pasted in Step 3; you don't write any of this logic yourself, but should understand what it depends on so you don't break it:

- **Search** fetches `GET /index.json` from whatever server is serving the file. That endpoint doesn't exist on a bare `file://` open — it's served by `~/Code/scripts/report-server.py`, which scans `~/reports/*.html` for `<title>` and `<h2>` text on every request. This means: **use real, descriptive `<h2>` text for every section** (not generic labels like "Section 1") since that's exactly what becomes searchable.
- **Per-section feedback** POSTs `{file, section, text}` to `/feedback` on the same server. The server queues the job and launches `kiro-cli --no-interactive` detached to edit that one section of that one file. You don't need to do anything for this to work beyond the `class="report-section" data-section-title="..."` markup — the toggle button, hidden input, and submit handler are all injected by the shared script.
- Both features **fail gracefully without the server running**: search shows "needs report-server.py running", feedback shows "failed: ... (is report-server.py running?)" inline instead of throwing. Don't add your own error handling around this — it's already handled in the shared snippet.
- Tell the user, after generating a report, that the search/feedback features need the server: `~/Code/scripts/report-server.py` (default `http://localhost:8000`). Don't start it yourself unless asked — it's a long-running background process and starting one unprompted is the kind of thing to flag, not just do.

### Step 4: Vendor Mermaid inline — mandatory, not optional

**A `<script src="https://cdn...">` tag makes the file fail silently offline or on a locked-down network.** This is the whole point of the skill — do not skip this step.

```bash
curl -sL --max-time 10 -o /tmp/mermaid.min.js https://cdn.jsdelivr.net/npm/mermaid@10/dist/mermaid.min.js
```

Then replace the CDN `<script src="...">` tag with the file's contents inlined between `<script>` and `</script>` tags. Do this with a small Python script (not by reading the 3MB file into the chat context — read tools will dump the whole minified blob into context otherwise):

```python
with open(html_path) as f:
    html = f.read()
with open("/tmp/mermaid.min.js") as f:
    js = f.read()
cdn_tag = '<script src="https://cdn.jsdelivr.net/npm/mermaid@10/dist/mermaid.min.js"></script>'
html = html.replace(cdn_tag, "<script>\n" + js + "\n</script>")
with open(html_path, "w") as f:
    f.write(html)
```

Run this via `shell`, then delete `/tmp/mermaid.min.js`. Verify afterward:
```bash
grep -c "<script" out.html   # expect 3: vendored mermaid lib, your mermaid.initialize() call, the toolbar script
grep -o "cdn.jsdelivr" out.html | wc -l   # expect 0
```

If `curl` has no network access in the current environment either, tell the user the file will need CDN access to render Mermaid, and ask whether to proceed without vendoring or if they can fetch the library another way.

### Step 5: Open and hand off

```bash
xdg-open ~/reports/<slug>.html   # Linux
open ~/reports/<slug>.html       # macOS
```

Tell the user:
- the file size (vendoring adds ~3MB)
- it needs zero network access to render the diagrams
- search and feedback additionally need `~/Code/scripts/report-server.py` running (`http://localhost:8000` by default) — offer to start it, don't start it unasked, since it's a persistent background process

</procedure>

## Constraints
<constraints>

- **Never fabricate.** Every diagram node, table row, and quoted TODO must trace back to a real file you read. If a detail wasn't observed, mark it "not shown" / "unknown" rather than guessing — call this out explicitly in the final summary (see the appSTkit precedent: flag unverified matrix cells instead of inventing values).
- **No per-diagram click-to-drill-down / node-detail JS.** That pattern belongs to `walkthrough`. This skill's diagrams themselves stay read-only; the only interactive elements are the shared toolbar (search) and per-section feedback form from `report-header.html` — don't add bespoke interactivity beyond those two.
- Pick dark theme by default; only use light/match-brand theming if explicitly requested.
- Use real relative paths and field names in labels, not generic placeholders, unless the source material is itself generic.
- Prefer hand-drawn inline SVG over forcing Mermaid for anything that isn't naturally graph-shaped (e.g. a linear pipeline with branching decrypt/encrypt steps reads better as boxes+arrows SVG than a mermaid flowchart).
- Keep the output a single `.html` file per report. Do not split into separate CSS/JS files — the point is one artifact that travels as one file. (The shared `report-server.py` is a separate, optional, long-lived process — not part of the report artifact itself.)
- Always write to `~/reports/`. Never write a report HTML to the project directory or anywhere else.

</constraints>

## Quality Checklist
<done>

- [ ] Output file is in `~/reports/`, nowhere else
- [ ] Every Mermaid/SVG diagram and table traces to real files/config you actually read
- [ ] Mermaid is vendored inline (`grep cdn.jsdelivr` returns 0 matches)
- [ ] `report-header.html`'s style/markup/script are all three present (toolbar div right after `<body>`, style in `<head>`, script right before `</body>`)
- [ ] Every top-level `<section>` has `class="report-section" data-section-title="..."` with a real, descriptive title (this is what populates search)
- [ ] File renders standalone — tested or at minimum structurally verified (`<script>`/`</script>` counts match, file ends with `</html>`)
- [ ] At least one section quotes real rough-edge content (TODOs, known issues, journal notes) verbatim, not paraphrased into something generic
- [ ] Any uncertain/unverified detail is explicitly flagged in the response, not silently guessed
- [ ] User was told search/feedback need `report-server.py` running, and offered (not forced) to start it
- [ ] Opened in browser (or instructions given) at the end

</done>

## References

- [references/template.html](references/template.html) — starting-point HTML/CSS skeleton (toolbar wired in, dark panel cards, Mermaid init block, SVG/table examples) extracted from the first real use of this skill (a NixOS/home-manager config walkthrough).
- [references/report-header.html](references/report-header.html) — the shared collapsible-toolbar + cross-report fuzzy search + per-section feedback snippet. Paste its three parts (style/markup/script) into every report as described in Step 3.
