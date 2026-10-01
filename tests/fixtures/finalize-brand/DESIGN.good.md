---
name: Pawsley Grooming
description: Warm, precise, local — sunlit orange on cream, deep navy text, calm energy
colors:
  primary: "#C2410C"
  on-primary: "#FFFFFF"
  surface: "#FFF8F1"
  on-surface: "#1E293B"
  error: "#B91C1C"
  on-error: "#FFFFFF"
typography:
  display:
    fontFamily: "Plus Jakarta Sans, system-ui, sans-serif"
    fontWeight: 700
    fontSize: 3rem
    letterSpacing: -0.02em
  body:
    fontFamily: "Plus Jakarta Sans, system-ui, sans-serif"
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
  alert-error:
    backgroundColor: "{colors.error}"
    textColor: "{colors.on-error}"
  page:
    backgroundColor: "{colors.surface}"
    textColor: "{colors.on-surface}"
---

# Pawsley Grooming

## Overview
Status: final · brand case: to-create · profile: landing
Creative north star: a neighbourhood groomer you can trust with your dog. Mode per surface: Persuade.

## Colors
Light theme only. Orange `primary` signals the one action (book a slot); navy `on-surface` carries all text on cream `surface`. Red `error` marks failed bookings and field errors (`derived`: the palette has no red).

## Typography
Plus Jakarta Sans for display and body, self-hosted through next/font; display 700 with tight tracking, body 1rem / 1.5.

## Layout
Max width 72rem, 12-column grid, breakpoints 640 / 1024px, comfortable density.

## Elevation & Depth
Flat: tonal layering on `surface`, one soft shadow on the booking card only.

## Shapes
Radius sm 4px (inputs), md 8px (buttons), lg 12px (cards); nested inner radius = outer − gap.

## Components
Button: hover darkens primary 8%, focus-visible 2px navy ring, active scale 0.96, disabled 40% opacity. Inputs share the button radius.

## Do's and Don'ts
- Do: one orange action per screen; real photos of the studio; 4.5:1 text contrast.
- Don't: gradient text, fake testimonials, three-icon-card rows.
- No token or mark copied from a reference site.

## Motion
- Approach: minimal-functional; easing enter ease-out / exit ease-in / move ease-in-out; durations micro 50–100ms, short 150–250ms
- Press: scale(0.96); never `transition: all`; `prefers-reduced-motion` → cross-fade only

## Voice
- Adjectives: warm, precise, local · register: informal · locales: one
- Do say / don't say: "your dog", "book a slot", "see you Saturday" / "fur baby", "revolutionary", "world-class"

## Logo Rules
- Files: pending: no logo yet — mapping plans a wordmark task

## Imagery
- Style: real photos of the studio and its dogs; no stock clichés · alt-text rule: name the dog and the service

## Must-Avoid
- BRIEF §6: gradient text, fake testimonials, three-icon-card rows
- Paw-print icon confetti

## Sources
- generated: ui-ux-pro-max 2.13.0 --design-system "warm precise local dog grooming landing" · candidate B chosen
- font: Plus Jakarta Sans · licence: OFL
- schema: google-labs-code/design.md spec, linted with @google/design.md 0.4.0

Next: /v2p mapping
