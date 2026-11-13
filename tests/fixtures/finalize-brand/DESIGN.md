---
name: Pawsley Grooming
description: Warm, precise, local — sunlit orange on cream, deep navy text, calm energy
colors:
  primary: "#f2f2f2"
  on-primary: "#eeeeee"
  surface: oklch(98% 0.01 80)
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
    textColor: "{colors.on-primari}"
    rounded: "{rounded.md}"
  alert-error:
    backgroundColor: "{colors.error}"
    textColor: "{colors.on-error}"
  card:
    backgroundColor: "{colors.primary}"
    textColor: "{colors.on-primary}"
---

# Pawsley Grooming

## Overview
Status: final · brand case: to-create · profile: landing
Creative north star: a neighbourhood groomer you can trust with your dog. Mode per surface: Persuade.

## Colors
Light theme only. Orange `primary` signals the one action (book a slot); navy `on-surface` carries all text on cream `surface`.

## Typography
Plus Jakarta Sans for display and body, self-hosted through next/font; display 700 with tight tracking, body 1rem / 1.5.

## Layout
Max width 72rem, 12-column grid, breakpoints 640 / 1024px, comfortable density.

---

## Elevation & Depth
Flat: tonal layering on `surface`, one soft shadow on the booking card only.

## Shapes
Radius sm 4px (inputs), md 8px (buttons), lg 12px (cards); nested inner radius = outer − gap.

## Components
Button: hover darkens primary 8%, focus-visible 2px navy ring, active scale 0.96, disabled 40% opacity. Inputs share the button radius.

## Colors
Accent notes pasted twice by the generator.

## Do's and Don'ts
- Do: one orange action per screen; real photos of the studio; 4.5:1 text contrast.
- Don't: gradient text, fake testimonials, three-icon-card rows.

## Motion
- Approach: minimal-functional; easing enter ease-out / exit ease-in / move ease-in-out; durations micro 50–100ms, short 150–250ms
- Press: scale(0.96); never `transition: all`; `prefers-reduced-motion` → cross-fade only

## Logo Rules
- Files: pending: no logo yet — mapping plans a wordmark task

## Imagery
- Style: real photos of the studio and its dogs; no stock clichés · alt-text rule: name the dog and the service

## Must-Avoid
- BRIEF §6: gradient text
- Paw-print icon confetti

## Sources
