# Standards: landing

Loaded after `core.md` and `web.md`. Section-by-section checks live in `../landing-10-sections.md`.

## Conversion & Lead Generation (CRO)
- [ ] **Lead Magnet Implementation:** Clear "Value Exchange" (e.g., Free Guide $\rightarrow$ Email).
- [ ] **CRO Tooling:** Setup Heatmaps (Hotjar/Microsoft Clarity) to analyze user behavior.
- [ ] **Thank You Page Optimization:** Lead the user to the "Next Step" after conversion.
- [ ] **Referral Loop:** "Refer a friend" mechanics integrated into the flow.

## Components & Content
- [ ] Testimonials section (with dynamic social proof)
- [ ] Contact form implementation
- [ ] Social media integration buttons
- [ ] Share button integration

## Not "made by AI"
- [ ] **Anti-"made-by-AI" pass:** no gradient headline text; no default three-icon-card row; no fake testimonials; no "it's not X, it's Y" copy; no emoji in headings; no badge/pill above the H1; no lorem ipsum; hierarchy by size and weight, not gradient or colour alone; no fade-in on every section. Evidence: reviewer note per trait, or a `grep` of the copy for the pattern (`grep -P '<h[1-6][^>]*>[^<]*\p{Emoji}'` → 0; `grep -riE 'lorem|ipsum'` → 0). Source: owner's taste rule (unverified; no framework).

## Polish — optional, do last
Each item applies only when its condition holds; otherwise mark it N/A with the reason.
- [ ] Smooth scroll animations
- [ ] Hero section animations
- [ ] Section transitions
- [ ] **Custom Cursor implementation** for branded experience — only if the brand guide asks for it.
- [ ] **Urgency/Scarcity Triggers:** Strategic use of social proof or limited offers — only true, dated claims; fake ones are removed.
- [ ] WhatsApp/Chat floating button — local business or sales-led only.
- [ ] Back-to-top button — only if the page is longer than 3 screens.

***
Copyright © 2026 Rafael Arciniegas. Licensed under the MIT License.
