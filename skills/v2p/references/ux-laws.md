# UX laws as checks

Source: general UX literature (Laws of UX); not derived from the project's extraction files.

When to run: `landing` always; any UI at the review phase, against staging. Each law is a check plus how to measure it.

## Fitts
- Primary CTA hit area at least 44×44 CSS px.
- Mobile sticky CTA sits in the bottom third of the viewport.
- A destructive control is at least 8 px from the primary one and styled unlike it.
- Measure: Playwright `boundingBox()`; axe rule `target-size`.

## Hick
- At most 1 primary CTA per viewport.
- At most 7 top-level navigation items.
- At most 4 pricing plans.
- One question per step on mobile forms.
- Measure: element counts.

## Jakob
- Logo top-left, linking home.
- Login/account top-right.
- Search at the top.
- Conventional form patterns.
- No custom cursor unless the brand demands it.
- Measure: DOM position assertions.

## Miller
- Lists chunked to 7 or fewer (features 3–6, steps 5 or fewer).
- Card and phone inputs grouped.
- Measure: child counts.

## Parkinson
- Every form field maps to a BRIEF requirement or is removed.
- Multi-step forms show progress.
- `autocomplete` on every eligible input.
- Measure: field list vs requirements; eligible `input:not([autocomplete])` → 0.

## Proximity
- Label-to-input gap smaller than field-to-field gap (8 px or less vs 16 px or more).
- A plan and its CTA share one container.
- Spacing follows one scale (multiples of 4 px); section padding is larger than the gap between elements inside the section. Source: Material Design spacing https://m3.material.io/foundations/layout/understanding-layout/spacing (unverified).
- Measure: computed margins; computed margin/padding values → 0 off-scale; section padding > intra-section gap.

## Von Restorff
- Exactly one primary-styled element per viewport.
- Alerts and destructive actions use a distinct style.
- Measure: primary-style count per viewport == 1.

***
Copyright © 2026 Rafael Arciniegas. Licensed under the MIT License.
