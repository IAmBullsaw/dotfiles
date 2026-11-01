---
name: mobile-verification
description: Verifies responsive web layout by rendering real viewports in a headless browser and inspecting the rendered output, never by reading CSS. Use when asked whether a page works on mobile or small screens, after changing layout, grids or breakpoints, and before shipping web UI.
---

**CSS review does not find mobile bugs.** Two production bugs on this
project were invisible to code review and obvious on first render.

## Check for tooling before giving up

`firefox`, `chromium`, `google-chrome`, `playwright`, `wkhtmltoimage`.
Headless Firefox is usually present and sufficient:

```
firefox --headless -profile /tmp/ff --window-size=375,3300 \
        --screenshot=/tmp/shot.png https://example.com
```

Then **open the image**. Notes: screenshots capture from the top and
ignore `#anchors`, so use a tall viewport to reach lower sections; use a
separate `-profile` per run or captures silently fail.

If genuinely no tooling exists: **do not claim mobile is fixed.** Produce
a manual checklist and say plainly that it is unverified.

## Viewports

375 (small phone) · 390 (common phone) · 768 (tablet) · 1440 (desktop)

## Inspect

- **Tables** — scroll inside their container, not clipped. `overflow:
  hidden` silently truncates rather than scrolling.
- **Multi-column rows** — a 4-column grid crushes below ~480px. Names
  ellipsing to `Goo…` are indistinguishable from each other.
- **Disclosures** — open without clipping.
- **Fixed elements** — do they cover content or the heading?
- **Controls** — ~44px touch targets.
- **Wrapping and spacing** — awkward breaks, cramped stacks.
- **Both themes**, not just light.

## The trap worth naming

A media query can be perfectly correct and target a class nothing uses.
Nothing is wrong with the CSS in isolation; it simply never applies.
**Confirm the selector matches rendered markup**, not just that the rule
exists.

## Also look for what only rendering reveals

Placeholders left unfilled (`—`) mean JS threw. Values that are
implausibly `0` mean load-order bugs. Both look fine in source.
