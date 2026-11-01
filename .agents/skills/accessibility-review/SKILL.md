---
name: accessibility-review
description: Checks a web page for semantic heading structure, form and control labels, keyboard focus styling, reduced-motion support and WCAG colour contrast — computing contrast ratios rather than eyeballing them. Use before shipping web UI, or when asked about accessibility, a11y, WCAG, screen readers, contrast or keyboard navigation.
---

Check the real markup and compute the real ratios. **An accessibility
claim without a measurement is a guess.**

## Structure

- Real `<h1>`/`<h2>`, never heading-shaped `<div>`s. Zero headings means
  a screen reader gets no document outline at all — this is the single
  most common and most damaging failure.
- Landmarks: `<main>`, `<header>`, `<nav>`, `<section>`.
- `lang` must match the *prose*, not the author's nationality. English
  copy under `lang="sv"` gets read with Swedish phonetics.

## Controls

- Every input/slider needs a programmatic label. An adjacent `<span>` is
  not a label.
- `:focus-visible` on everything interactive. Zero focus styling means a
  keyboard user cannot see where they are.
- Prefer native `<details>`/`<summary>`, `<button>` — they are keyboard
  accessible for free.
- Decorative glyphs in buttons need `aria-hidden`.

## Charts

Each needs `role="img"` and an `aria-label`. Then ask the harder
question: **is the underlying data available as text anywhere?** If a
chart is the only way to reach a number, the page is unusable without
sight. Labels are a floor, not a fix.

## Contrast — compute it

```
python3 -c "
def lum(h):
    h=h.lstrip('#');r,g,b=[int(h[i:i+2],16)/255 for i in (0,2,4)]
    f=lambda c: c/12.92 if c<=0.03928 else ((c+0.055)/1.055)**2.4
    return .2126*f(r)+.7152*f(g)+.0722*f(b)
def ratio(a,b):
    la,lb=lum(a),lum(b);return (max(la,lb)+.05)/(min(la,lb)+.05)
print(round(ratio('#54756a','#f8f6f1'),2))"
```

AA is 4.5:1 for body text. **Check every theme.** Muted "faint" tokens
are the usual failure and are usually used on exactly the small text that
most needs contrast.

## Motion

`prefers-reduced-motion: reduce` must disable transitions and animations.

## Report honestly

State what was **verified** vs **inferred**. Structure and labels can be
read from markup; how it *sounds* in a screen reader, real keyboard
navigation and 200% zoom cannot. Name those as untested rather than
implying coverage.
