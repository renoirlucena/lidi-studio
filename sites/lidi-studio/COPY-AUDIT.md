# Lidi Studio site — copy audit

Extracted from mockup `mockups/claude-web/lidi-studio-homepage.html` →
`sites/lidi-studio/src/index.html` on 2026-04-29.

All items below need owner review before/after deploy. Inline `<!-- REVIEW -->`
comments mark the same items in the HTML for quick navigation.

## A. Factual claims to verify

| Line | Claim | Action |
|---|---|---|
| 838 | "Twenty years behind the camera." | Confirm exact figure with Lidi |
| 838 | "A lifetime behind the easel." | Confirm phrasing/intent |
| 980 | "Twenty years behind the camera. A lifetime behind the easel." (duplicate in About) | Same as above — keep symmetry |
| 992 | "Untitled (Landscape, Oil on Linen) · Lidi · 2024" | Confirm title + year of the painting in About photo |

## B. Commission deliverables

| Line | Commission | Stated deliverables | Action |
|---|---|---|---|
| 879 | 01 The Hearth (Family) | "fifteen rendered portraits" (90 min, studio/location) | Confirm count + duration |
| 890 | 02 The Becoming (Maternity) | "Twenty-five rendered portraits and five fine art prints" (3 hrs) | Confirm counts + duration |
| 907 | 03 First Light (Newborn) | No explicit count given | Confirm whether to add deliverables |
| 919 | 04 The Mothering (Motherhood) | "Twenty rendered portraits and three fine art prints" | Confirm counts |
| 935 | 05 The Triptych (Flagship) | "Limited four per year" + "twelve months" + "archival portfolio book" | Confirm scope and pricing positioning |

## C. Testimonials

| Line | Item | Action |
|---|---|---|
| 962 | "— S. · The Becoming · Spring MMXXVI" | Real client initial (privacy)? Or placeholder? Confirm full name to use or keep anonymous. |

## D. Empty links (`href="#"`) — placeholder destinations

| Line | Element | Suggested resolution |
|---|---|---|
| 793 | nav logo | OK — scrolls to top of same page |
| 985 | "Read the studio note →" (About) | Until long-form About page exists, consider linking to `mailto:` or removing |
| 1009 | "All entries →" (Journal head) | Will link to Ghost when fixed; today: `#journal` or removal |
| 1015, 1027, 1037 | 3× journal post anchors | Same — Ghost-dependent |
| 1084 | "Work" (footer) | Likely should be `#commissions` (matches nav). Confirm. |
| 1096 | "Press" (footer) | No press page exists. Hide or add real target. |
| 1104 | "@lidi.studio" (footer social) | Need real Instagram/social URL |
| 1106 | "Anchorage AK · JBER" (footer) | Optionally link to Google Maps; confirm JBER reference is intentional |

Already converted to `mailto:` in this pass:
- 4× "Read the commission" CTAs → `mailto:lidi@lidi.studio?subject=Inquiry%20%E2%80%94%20<commission>`
- "Inquire about the Triptych" → same pattern

Already fixed in this pass:
- "Enter the archive →" was `#`, now `#archive` (anchor exists on page)
- `status.lidi.studio` was `href="#"`, now `https://status.lidi.studio`

## E. Newsletter form (non-functional)

Line ~1075. The form has `onsubmit="event.preventDefault();...textContent='Thank you'"` — it shows "Thank you" without storing the email anywhere. **Visitors who subscribe today will not actually be subscribed.**

- Short term: leave as visual placeholder.
- Medium term: wire to Brevo (already on the SMTP roadmap) or Mailchimp.

## F. Footer fine print

| Line | Item | Action |
|---|---|---|
| 1109 | "Privacy · Terms · © MMXXVI Lidi Studio" | Privacy and Terms pages do not exist. Either create them or remove these links until they do. |
| 1111 | "Anchorage · 61°13′N · 149°54′W" | Coordinates correct for Anchorage. Confirm this is intentional brand element vs literal address. |

## G. Photos referenced vs available

- 11 photos referenced in HTML (out of 16 in `assets/photos/`).
- 5 unused photos kept in `public/photos/` for future use:
  `bts-directing.jpg`, `maternity-veil.jpg`, `newborn-dad.jpg`,
  `newborn-hands.jpg`, `newborn-wrap.jpg`.

## H. SEO + meta tags (added in Hour 2)

(see ETAPA 2.1 — meta description/og:description need a final 1-2 sentence
copy decision that does not invent positioning. Currently using neutral
language drawn from existing manifesto copy.)

---

15 inline `<!-- REVIEW -->` markers in `src/index.html`. Find them with:

```
grep -n REVIEW sites/lidi-studio/src/index.html
```
