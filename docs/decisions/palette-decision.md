# ADR-001 · Palette Decision

| | |
|---|---|
| **Status** | LOCKED |
| **Date** | 2026-04-26 |
| **Decided by** | Lidi (operator) — overriding Brand Chief's recommendation after side-by-side testing |
| **Reference brand book** | `/docs/brand-book-v2.2.md` |

---

## Decision

**Direction A — Sargent Luminous** is the official Lidi Studio palette.

| Color | HEX | Role | % |
|---|---|---|---:|
| Champagne Cream | `#F5EBDD` | Primary — dominant background | 60% |
| Soft Mauve | `#D4B5B0` | Secondary — skin-warm accents | 20% |
| Pearl Grey | `#C9C2B8` | Atmospheric — dividers, ambient | 12% |
| Aged Gold | `#B89968` | Signature accent — wordmark *L*, CTAs, seal | 5% |
| Warm Charcoal | `#4A3F38` | Type only — body, headlines | 3% |

---

## Context

The brand had cycled through three palette directions before this decision:

1. **v1.0 (Lidi Lopez Atelier)** — initial branding exploration. Superseded by v2.0 rename.
2. **v2.0 (Carbon Black + Bone + Oxblood)** — tested funereal against the maternal subject. Pregnant Anchorage / JBER women felt asked to perform aesthetic literacy before being allowed in.
3. **v2.1 (Sargent v2.1 — Brand Chief recommendation)** — surgical revision to a light register. Alabaster Glow `#F0E5D0` 60% + Walnut Ink `#2D1F15` 22% + Sargent Umber + Pearl Mist + Aged Brass. Correct diagnosis but the dose still over-corrected toward shadow at 22%.

Rather than commit to v2.1 directly, ten candidate palettes were rendered side-by-side in a decision tool: `/mockups/claude-web/showcase.html`. Each palette was tested with the same Lidi photo, the same tagline ("Painted, not posed."), the same typography stack, in real editorial context.

The ten candidates:
| | Direction | Dominant register |
|---|---|---|
| A | **Sargent Luminous** | Cream + soft mauve |
| B | Vermeer Soft Light | Linen + powder blue |
| C | Modern Atelier | Bone + dusty rose + brass |
| D | Aman Spa | Warm linen + clay pink |
| E | Champagne & Smoke | Iced champagne + smoky mauve |
| F | Tuscan Morning | Sun-bleached + faded terracotta |
| G | Powder Room | Pearl cream + blush + lavender |
| H | Wabi-Sabi | Rice paper + faded sakura |
| I | Coastal Pastel | Sea salt + driftwood |
| J ★ | Sargent v2.1 (Brand Chief recommended) | Alabaster + walnut ink |

---

## Decision rationale

The user chose **A · Sargent Luminous** over the Brand Chief's recommendation **J · Sargent v2.1**. The five reasons recorded:

1. **More luminous primary.** Champagne Cream `#F5EBDD` reads warmer and more luminous than Alabaster Glow `#F0E5D0`. The 5-RGB-point shift toward warm yellow is small but visible in context — it lifts the page from "warm" to "*sunlit*".

2. **Soft Mauve at 20% is the breath the v2.1 lacked.** v2.1 had no skin-warm secondary — only Walnut Ink as deep + Pearl Mist as cool whisper. A maternal brand needs a tone that *harmonizes with skin* in the page itself, not only in the photographs. Soft Mauve `#D4B5B0` carries that breath.

3. **Aged Gold is more vibrant than Aged Brass.** `#B89968` reads as gilded picture frame. `#7A5828` reads as iron-oxide bronze. The difference matters: the brand is about *frames around portraits*, not about industrial brass hardware. Aged Gold lifts the brand from craft-trade to art-house.

4. **Pearl Grey at 12% carries more atmosphere than Pearl Mist at 3%.** v2.1 used the cool tone as a barely-there whisper. Direction A makes it a real participant — Pearl Grey at 12% gives every section its atmospheric distance without competing with the warmth.

5. **Warm Charcoal at 3% (type only) is less institutional than Walnut Ink at 22%.** v2.1's Walnut Ink at 22% still occupied real estate beyond type — ceremonial sections, dark slabs. v2.2 confines deep to *type only*, at *3%*, which is enough for body legibility and zero more. The brand feels inhabited by people, not curated by an institution.

---

## Trade-offs accepted

- **Less dramatic ceremonial register.** v2.2 has no equivalent of v2.1's Walnut Ink full-section dark slabs. The Triptych flagship treatment must achieve gravity through composition and typography, not through full-bleed dark backgrounds. Acceptable — the brand's drama lives in the photographs, not in the chrome.
- **Aged Gold at 3:1 contrast on Champagne is decorative-only.** CTAs that need AA-grade text contrast use Warm Charcoal text with an Aged Gold underline rule, not Aged Gold as link body color. This is a known constraint and is documented in `/docs/brand-book-v2.2.md` §7.4.
- **Warm Charcoal as type-only at 3%** means the brand cannot use deep backgrounds liberally. Footer dark slabs are reserved/sparing.

---

## Consequences

### Immediate
- All future builds reference `/docs/brand-book-v2.2.md` as palette source of truth
- v2.0 and v2.1 brand books retained in `/docs/` as ADRs
- Visual canonical reference: `/mockups/claude-web/lidi-studio-homepage.html` (rendered in Sargent Luminous)
- The Hermès-style integrated wordmark (gold L + charcoal IDI) replaces the previous LIDI/divider/STUDIO stack

### Downstream squads
- **claude-code-mastery** — Astro `/apps/web/` build uses v2.2 tokens
- **design-squad** — component specs ground in `/mockups/claude-web/lidi-studio-homepage.html` + `/lidi-studio-logo-system.html`
- **copy-master · storytelling** — voice, manifesto, commission descriptions all unchanged from v2.0; only palette references update
- **traffic-masters · cybersecurity · AIOX · hormozi-squad** — no impact (palette doesn't touch their scope)

### Print and packaging
- Business cards: 55×85mm Champagne Cream stock, debossed Hermès-style wordmark with Aged Gold L
- Proposal PDF cover: full-bleed Champagne with two-tone wordmark + Aged Gold wax seal
- Triptych portfolio book: linen Champagne cover, debossed Aged Gold wordmark on spine

---

## Reversal criteria

This decision should be revisited if:
- A/B testing on actual lidi.studio traffic shows >25% bounce rate from the homepage with no other obvious cause
- Audience research surfaces consistent "too soft / too feminine" feedback from the JBER military spouse segment
- A campaign or press feature requires a darker editorial register that the current palette cannot accommodate even via the Triptych ceremonial treatment

In any reversal scenario, prefer to add a **ceremonial dark variant** (controlled, sparingly applied) rather than re-replace the dominant register.

---

## References

- Brand book (active): `/docs/brand-book-v2.2.md`
- Brand book (deprecated v2.0): `/docs/brand-book-v2.0.md`
- Brand book (deprecated v2.1): `/docs/brand-book-v2.1.md`
- Visual decision tool: `/mockups/claude-web/showcase.html`
- Canonical homepage render: `/mockups/claude-web/lidi-studio-homepage.html`
- Logo system: `/mockups/claude-web/lidi-studio-logo-system.html`
