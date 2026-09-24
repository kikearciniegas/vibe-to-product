# Landing page: 10 sections

Loaded for the `landing` profile only. Each section has a purpose and a **Check**: a pass condition and how it is measured.

## Global rules
- Sections may be omitted; record each omission and its reason in BRIEF §10.
- Exactly one primary action page-wide, and it is the BRIEF §3 action.
- One `h2` per section.

## 1. Hero
Purpose: say what the visitor gets and give them the one action.
**Check:** the H1 states the outcome for the BRIEF §2 audience in 12 words or fewer; a single primary CTA equal to the BRIEF §3 action is visible without scrolling at 375×667 and 1440×900 (Playwright: `boundingBox().y + height < viewport.height`); no gradient headline text.

## 2. Social proof
Purpose: show that real people or companies already trust this.
**Check:** at least 3 real, attributable logos or numbers, each traceable to a source file that records its source URL; zero placeholder names (`grep -riE 'lorem|acme|john doe'` → 0); certifications and trust seals count only when real and linked to the issuer's verification page. Source: FTC Endorsement Guides https://www.ftc.gov/business-guidance/resources/ftcs-endorsement-guides-what-people-are-asking (verified: 2026-09).

## 3. Problem
Purpose: name the audience's pain in their own words (BRIEF §2).
**Check:** 3 bullets or fewer; each phrase can be traced to something the audience said or wrote.

## 4. Solution
Purpose: connect the pain to the product.
**Check:** one sentence of the form "we do X so you get Y"; links forward to Features.

## 5. Features
Purpose: show how the solution delivers.
**Check:** 3–6 features, each written as benefit + how; not the default three-icon-card row unless the brand guide asks for it.

## 6. How it works
Purpose: remove the "what happens next" doubt.
**Check:** 3 steps or fewer, each starting with a verb.

## 7. Testimonials
Purpose: let customers make the claim.
**Check:** each testimonial has name + role + company, or a photo; consent is recorded in the repo. None exist → omit the section; never fake one.

## 8. Pricing
Purpose: let the visitor decide without a sales call.
**Check:** plans side by side; price visible without a click; one CTA per plan; refund/return policy linked. Lead-generation pages may omit the section with a reason.

## 9. FAQ
Purpose: answer the objections that stop the action.
**Check:** at least 5 questions taken from real objections; built with `<details>` or an ARIA accordion that works by keyboard alone; shows a "last updated" date.

## 10. Final CTA
Purpose: give the action one last time.
**Check:** repeats the hero CTA text verbatim; a sticky CTA on mobile; submitting lands on a thank-you page that states the next step.

***
Copyright © 2026 Rafael Arciniegas. Licensed under the MIT License.
