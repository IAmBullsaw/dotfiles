---
name: production-readiness
description: Decides whether a website is genuinely shippable, covering runtime health, accessibility, mobile, performance, deploy and broken assumptions. Returns READY or NOT READY with no middle state. Use when asked 'can we ship this', 'is this ready', or for a pre-release, pre-deploy or final QA pass on web UI.
---

Returns exactly one of **READY** or **NOT READY**. No "ready with
caveats" — that is NOT READY with extra words.

## Order

1. **Automated gates** — tests, structural checks (balanced JS, no orphan
   element references, no literal values outside the design tokens).
2. **Runtime** — the section below. Non-negotiable.
3. **Accessibility** — run the accessibility-review skill.
4. **Mobile** — run the mobile-verification skill. Unverified mobile is a
   blocker, not a caveat.
5. **Performance** — page weight, JS size, images, animation cost.
   Avoid optimisation theatre: a small page with no images and no
   dependencies has nothing to optimise. Say so and move on.
6. **Broken assumptions** — the highest-value category, below.
7. **Deploy** — CI green, live page returns 200, correct content live.
8. **Docs** — is the reasoning recoverable in six months?

## Runtime verification — rendering is not running

The other gates all inspect a *description* of the page: its source, its
markup, a picture of it. None of them observe it working.

A page whose script throws on line 1 passes every one of them. Braces
balance. Element ids resolve. It screenshots perfectly, because the HTML
and CSS never needed the JS to render. Every listener registered after
the throw simply does not exist, and the controls are painted buttons.

**Unverified runtime is a blocker, not a caveat.** Load the page in a
real browser and assert:

- **Console clean** — no uncaught error, no unhandled rejection. One
  exception is a total failure of everything after it, not a warning.
- **Every control changes observable state when clicked.** Read a value,
  click, read again, compare. A control that renders proves nothing.
  Check the *effect* (computed style, attribute, text), not that the
  handler ran.
- **Every chart drew something.** An empty `<svg>` is a chart that gave
  up silently.
- **`scrollWidth <= clientWidth`, at the narrowest viewport you support.**
  Layout defects too small to see are still defects, and this one is a
  number. Run it at more than one width: 6px of overflow here passed at
  1440 and failed at 375.
- **Nothing depends on load order that isn't guaranteed.** A value read
  before its producer runs reads as `undefined` and formats as `0`.

Register the error listener **before** the page's own script. One
attached afterwards never sees the exception that killed it, and will
report a clean console on a dead page.

Automate it and keep it in the repo, so the gate outlives the review that
invented it: a script in the repo, run as a release gate. Any new
interactive control gets added to its assertions in the same change — a
control nothing asserts is a control that can quietly die.

**Prove the check fails.** Run it against a commit known to be broken.
A runtime check that has only ever passed is not evidence of anything.

## Hunt broken assumptions

Cheap checks that repeatedly find real defects:

- **Are two "same" numbers computed the same way?** Surfaces that should
  agree and quietly don't.
- **Are chart series actually independent?** If B and C are constant
  multiples of A, normalising each to its own max draws one curve three
  times.
- **Does a unit conversion silently assert something?** Converting a
  future figure at today's rate asserts that rate never changes.
- **Does a fallback path work?** Simulate the outage; don't assume.
- **Do stated assumptions match the code?** Constants drift from their
  documentation.

## Reporting

- **Fixed** / **Not fixed** / **Remaining decisions**
- Before → after metrics
- Blockers must be *exact* and say who can clear them. "Mobile untested,
  no browser available, needs a human on a real device" is useful.
  "Mobile could be better" is not.

State which findings were verified and which inferred. A NOT READY with
two precise blockers is more useful than a READY that quietly assumed.
