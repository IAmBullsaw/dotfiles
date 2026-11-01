---
name: regression-protection
description: Detects drift in a mature website by re-measuring against a recorded baseline: density, component variants, charts, duplicate figures, typography scale and the accessibility floor. Use for periodic maintenance reviews, or when asked whether a site has drifted, decayed, regressed or crept back toward clutter.
---

Reviews a mature project for **drift**, not for improvements. The job is
to notice slow decay, not to have new ideas.

## Requires a baseline

Without recorded before-numbers there is nothing to detect drift
*against*. If none exists, record one first — that is the deliverable.

## Density audit

Measure and compare every baseline metric: sections, cards, component
variants, charts, visible rows, answer surfaces, font tokens, page
weight.

**If any number increased, ask: what was removed to make room?**
If nothing was removed, that is the finding. Flag it.

## Also check

- **Legacy components resurrected** — retired variants creeping back.
- **Duplicate answers** — do surfaces that should agree still use the
  same assumptions?
- **Typography drift** — literal sizes reappearing outside the scale.
- **Accessibility floor** — headings, focus, labels, contrast, motion.
- **Mobile** — re-render; don't assume it still holds.
- **Voice** — has copy drifted toward generic? Grep for marketing words;
  confirm the distinctive lines survive.
- **Runtime health** — unfilled placeholders, implausible zeros.

## Distinguish carefully

- **Drift** — slow decay nobody decided on.
- **Violation** — an explicit rule broken.
- **Deliberate exception** — documented, with reasoning. Not a violation.
  Check the docs before crying foul.
- **Requested removal** — content gone because someone asked. Check the
  history before calling it decay.

## Output

**STATUS: Healthy / Minor drift / Needs intervention**, then Healthy,
Drift, Violations, Recommended actions, Explicitly rejected.

If nothing changed since the baseline, say that plainly — verified, not
assumed. A short honest review beats a padded one.

Do not write code unless fixing a regression. Do not propose features.
