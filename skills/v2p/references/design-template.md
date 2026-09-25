# DESIGN template

Copy the block below into `.v2p/DESIGN.draft.md` (brand Step 3) and replace every `<…>`. The format is Google's DESIGN.md (`google-labs-code/design.md`): YAML frontmatter with the normative tokens, then prose sections. Later phases check against it: mapping plans the tokens task from the frontmatter, execute takes tokens from it (never invents them), review compares the running page with it.

Rules:
- Frontmatter is normative; the prose explains it. Two-space indentation, one key per line, no flow style (`{…}` maps, `[…]` lists).
- Required tokens: `name`, `description`; `colors.primary`, `colors.on-primary`, `colors.surface`, `colors.on-surface`; `typography.display.fontFamily`, `typography.body.fontFamily`; `rounded.md`; `spacing.md`; `components.button-primary` with `backgroundColor: "{colors.primary}"` and `textColor: "{colors.on-primary}"`; `components.page` with `backgroundColor: "{colors.surface}"` and `textColor: "{colors.on-surface}"` (those two pairs are what the linter measures for 4.5:1 contrast).
- Every `colors.*` value is a quoted 6-digit hex (`"#RRGGBB"`; unquoted, `#` starts a YAML comment). Dimensions are plain values (`3rem`, `16px`): the linter rejects `clamp()` as a dimension (measured 2026-09-25); put the fluid scale in the Typography prose.
- The eight canonical sections, in this order, each exactly once: Overview, Colors, Typography, Layout, Elevation & Depth, Shapes, Components, Do's and Don'ts. Then the v2p sections, in this order, each exactly once: Motion (optional), Voice, Logo Rules, Imagery, Must-Avoid, Sources.
- `## Must-Avoid` first bullet is literally `- BRIEF §6: <the BRIEF's Must-avoid text, verbatim>` (`none` when the BRIEF has none).
- `## Sources` bullets use only the kinds shown in the block; one `font:` line per face with its licence. A local guide carries its sha256.
- `## Do's and Don'ts` keeps the line "No token or mark copied from a reference site." Reference sites give mood and structure only.
- No routed skill draws a vector logo: Logo Rules transcribe the guide or record a decision (`pending: …` plans a wordmark task).
- The frontmatter fence is the only `---` allowed (the one exception to v2p's `***` rule). Last line: `Next: /v2p mapping`.

````
---
name: <project name>
description: <one line: mood, material, energy — or "PLACEHOLDER — neutral tokens until <guide> arrives">
colors:
  primary: "#RRGGBB"
  on-primary: "#RRGGBB"
  surface: "#RRGGBB"
  on-surface: "#RRGGBB"
  <more descriptive slugs; every value a quoted 6-digit hex>
typography:
  display:
    fontFamily: "<face>, <fallback>"
    fontWeight: 700
    fontSize: 3rem
    letterSpacing: -0.02em
  body:
    fontFamily: "<face>, <fallback>"
    fontSize: 1rem
    lineHeight: 1.5
rounded:
  sm: 4px
  md: 8px
  lg: 12px
spacing:
  sm: 8px
  md: 16px
  lg: 24px
components:
  button-primary:
    backgroundColor: "{colors.primary}"
    textColor: "{colors.on-primary}"
    rounded: "{rounded.md}"
  page:
    backgroundColor: "{colors.surface}"
    textColor: "{colors.on-surface}"
---

# <project name>

## Overview
Status: <final | placeholder> · brand case: <existing | to-create | none> · profile: <BRIEF §1> <· scavenge: skipped>
Creative north star: <one sentence>. Mode per surface: <Persuade/Operate/Read/Experience per BRIEF §1 profile>.

## Colors
<strategy and roles; light/dark decision; which token signals action; `derived` where a value was converted (Pantone/CMYK) or filled in>

## Typography
<faces, roles, loading (next/font/google unless a Sources licence line says otherwise; self-hosted), fluid scale, rationale>

## Layout
<max width, grid, breakpoints, density>

## Elevation & Depth
<shadow or tonal layering; "flat" is a valid answer>

## Shapes
<radius hierarchy; nested inner radius = outer − gap>

## Components
<button/input/card/nav states: hover, focus-visible, active, disabled>

## Do's and Don'ts
- Do: <3–5 checkable rules>
- Don't: <3–5 anti-patterns; include the BRIEF §6 must-avoid items again in plain words>
- No token or mark copied from a reference site.

## Motion
- Approach: <minimal-functional | intentional | expressive>; easing enter ease-out / exit ease-in / move ease-in-out; durations micro 50–100ms, short 150–250ms, medium 250–400ms
- Press: scale(0.96); never `transition: all`; `prefers-reduced-motion` → cross-fade only
- Springs (native-app or gesture UI): damping 1.0 / response 0.3–0.4 by default; bounce only after a flick

## Voice
- Adjectives: <BRIEF §6 adjectives> · register: <tú/usted, formal/informal> · locales: <BRIEF §6>
- Do say / don't say: <3 each>

## Logo Rules
- Files: <public/logo.svg …> · clear space: <n × mark height> · min size: <px> · on dark: <variant> · never: <stretch, recolor, effects>

## Imagery
- Style: <real photos of …; no stock clichés> · treatment: <…> · alt-text rule: <…>

## Must-Avoid
- BRIEF §6: <verbatim from BRIEF §6 Must-avoid, or "none">
- <brand-specific additions>

## Sources
- guide: <relative path> · sha256: <64 hex>
- guide: <url>
- reference: <url> · <what was taken: mood/structure only>
- generated: ui-ux-pro-max 2.13.0 --design-system "<query>" · candidate <A|B|C> chosen
- kit: <org UI kit name/url>
- font: <face> · licence: <OFL | Fontshare | commercial>
- placeholder: brand guide pending (<name>)
- schema: google-labs-code/design.md spec, linted with @google/design.md 0.4.0

Next: /v2p mapping
````

***
Copyright © 2026 Rafael Arciniegas. Licensed under the MIT License.
