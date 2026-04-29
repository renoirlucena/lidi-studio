# Lidi Studio — Brand Book v2.1 *(deprecated, historical record)*

> ## ⚠ DEPRECATED
>
> This was the **Brand Chief's official recommendation** going into the palette showcase, but lost to **Direction A · Sargent Luminous** when all 10 candidates were rendered side-by-side with real Lidi photos.
>
> v2.1 was a *correct diagnosis with the wrong dose* — it identified that v2.0 was funereal and pushed toward warmth, but Walnut Ink at 22% still carried more shadow than the maternity audience needed. v2.2 takes the same direction further into light.
>
> **Do not build against v2.1.** This file exists as an Architecture Decision Record (ADR) and historical reference only.
>
> Active brand book: `/docs/brand-book-v2.2.md`
> Decision rationale: `/docs/decisions/palette-decision.md`

---

## What v2.1 was

A surgical palette revision from v2.0. The diagnosis: v2.0 built a Caravaggio palette for a Sargent subject. The fix: invert the dominance — light wins, shadow serves the light. Five colors, all literal oil-painting pigments.

### Palette *(deprecated — but the framing is preserved into v2.2)*

| Name | HEX | RGB | Pigment | Role | % |
|---|---|---|---|---|---:|
| Alabaster Glow | `#F0E5D0` | 240, 229, 208 | Lead White (Cremnitz) | Primary — warm light register | 60 |
| Walnut Ink | `#2D1F15` | 45, 31, 21 | Walnut Hull Ink | Type / ceremonial dark sections | 22 |
| Sargent Umber | `#705440` | 112, 84, 64 | Raw Umber | Mid neutral · captions · hairlines | 10 |
| Pearl Mist | `#9D9C95` | 157, 156, 149 | Lamp Black + Lead White | Atmospheric whisper | 3 |
| Aged Brass | `#7A5828` | 122, 88, 40 | Yellow Ochre + Burnt Sienna | Signature accent · CTAs · seal | 5 |

Proportion: **60 / 22 / 10 / 5 / 3**.

### What v2.1 changed from v2.0

| Element | v2.0 | v2.1 |
|---|---|---|
| Dominant register | Dark (Carbon Black ~65%) | **Light** (Alabaster Glow ~60%) |
| Primary | Carbon Black `#1A1612` | **Alabaster Glow `#F0E5D0`** |
| Type / deep | Bone (supporting) | **Walnut Ink `#2D1F15`** (ceremonial) |
| Accent | Oxblood `#5A1E1E` | **Aged Brass `#7A5828`** |
| Atmospheric | Slate Frost `#3D434A` | **Pearl Mist `#9D9C95`** |
| Mid neutral | Raw Umber `#6B4F3A` | **Sargent Umber `#705440`** *(slightly warmer)* |
| Logo default | Light on Dark | **Dark on Light** *(canonical default)* |
| Wax seal | Oxblood | **Aged Brass** *(gilded, not bloody)* |

### What did NOT change in v2.1 *(and remains locked through v2.2)*
- Identity, archetype, positioning, voice
- Typography (Cormorant Garamond + Inter + JetBrains Mono)
- Manifesto text
- Studio activation rules
- Commission architecture
- Logo mark structure (LIDI / hairline / STUDIO; L monogram)

### References cited in v2.1
1. Sargent — *Madame X*, *Lady Agnew*, *Carnation, Lily, Lily, Rose*
2. Aesop store interiors
3. Loro Piana / The Row / Khaite brand worlds

---

## Why v2.1 lost to v2.2 (Direction A)

In the 10-palette showcase (`mockups/claude-web/showcase.html`), v2.1 was **Direction J** with the official Brand Chief recommendation badge. **Direction A · Sargent Luminous** won the side-by-side comparison. The user's rationale (recorded in `/docs/decisions/palette-decision.md`):

- **Champagne Cream `#F5EBDD`** sits warmer and more luminous than Alabaster Glow `#F0E5D0`
- **Soft Mauve `#D4B5B0`** at 20% adds a *skin-warm secondary* that v2.1 lacked — gives the palette breath against maternal subjects
- **Aged Gold `#B89968`** is more vibrant, more *gilded-frame*, less iron-oxide than Aged Brass `#7A5828`
- **Pearl Grey `#C9C2B8`** carries more atmosphere at 12% than Pearl Mist did at 3%
- **Warm Charcoal `#4A3F38`** as type-only at 3% reads less institutional than Walnut Ink at 22%; lets the brand feel inhabited by people, not curated by an institution

Both v2.1 and v2.2 share the same diagnosis (light wins, oil-paint heritage, Sargent register). v2.2 simply executes it with more breath and more skin-warmth.

---

## Versioning timeline

| Version | Date | Status | Note |
|---|---|---|---|
| v1.0 | 2026-04-25 | superseded | Initial — Lidi Lopez Atelier |
| v2.0 | 2026-04-26 | deprecated | Carbon Black + Oxblood. Funereal against subject. |
| **v2.1** | **2026-04-26** | **deprecated** | **This document — Sargent v2.1 / Brand Chief recommendation. Lost to Direction A.** |
| **v2.2** | **2026-04-27** | **active** | **Sargent Luminous — official locked palette.** |
