# Lidi Studio

> **Painted, not posed.**
>
> Fine art portraiture for the most extraordinary chapter of a woman's life. Composed in light, atmosphere, and time — by a photographer who paints in oil.
>
> Lidi `/LEE-dee/` Studio · Anchorage, Alaska · JBER service area

This repository is the source of truth for the Lidi Studio brand system, web platform, and operational infrastructure.

---

## Status

**Phase: Brand foundation locked. Site implementation pending.**

| Layer | Status |
|---|---|
| Brand system v2.2 (Sargent Luminous) | ✅ locked |
| Visual artifacts (homepage · logo system · palette showcase) | ✅ in `mockups/claude-web/` |
| Platform architecture v1.0 (Hetzner self-hosted) | ✅ specified |
| Public site (`apps/web/` Astro build) | ⏳ pending |
| Infrastructure (`infra/` Docker Compose stack) | ⏳ pending |
| CI/CD (`.github/workflows/`) | ⏳ pending |
| Live at `lidi.studio` | ⏳ pending |

---

## Stack

Single Hetzner **CPX21** VPS in Hillsboro, OR ($13.99/mo · 3 vCPU AMD EPYC · 4 GB RAM · 80 GB NVMe SSD). Zero SaaS subscriptions. *(Server choice rationale: [`docs/decisions/server-decision.md`](docs/decisions/server-decision.md) — ADR-002. Operational fact sheet: [`infra/server-info.md`](infra/server-info.md).)*

| Layer | Tool |
|---|---|
| Frontend | Astro 4.x (hybrid mode) |
| Journal CMS | Ghost 5.x (self-hosted) |
| Booking | Cal.com 3.x (self-hosted) |
| Contracts | DocuSeal 1.x (self-hosted) |
| Internal CRM | NocoDB |
| Analytics | Umami (self-hosted) |
| Monitoring | Uptime Kuma + status.lidi.studio |
| Reverse proxy | Caddy 2 (auto-SSL via Let's Encrypt) |
| Database | PostgreSQL 16 + Redis 7 + SQLite |
| Outbound email | Brevo SMTP (300/day free) |
| Payments | Stripe (transactional only) |
| Backups | Restic + Cloudflare R2 (10 GB free) |
| Edge | Cloudflare Free (DNS · CDN · WAF) |
| CI/CD | GitHub Actions → SSH deploy |

Full RAM budget, routing map, and trade-off rationale: `/docs/platform-architecture-v1.md`.

---

## Brand at a glance

| | |
|---|---|
| **Tagline** | Painted, not posed. |
| **Pronunciation** | /LEE-dee/ |
| **Archetype** | Magician (primary) + Creator (secondary) |
| **Palette (Sargent Luminous)** | Champagne Cream `#F5EBDD` 60% · Soft Mauve `#D4B5B0` 20% · Pearl Grey `#C9C2B8` 12% · Aged Gold `#B89968` 5% · Warm Charcoal `#4A3F38` 3% |
| **Type** | Cormorant Garamond · Italiana · EB Garamond · Inter · JetBrains Mono *(all free Google Fonts)* |
| **Logo** | Hermès-style integrated wordmark — Aged Gold L + Warm Charcoal IDI |
| **Commissions** | The Hearth · The Becoming · First Light · The Mothering · The Triptych |
| **Voice** | reverent · painterly · intentional · atmospheric · confident |

Full specification: `/docs/brand-book-v2.2.md`.

---

## Repository layout

```
lidianelucena/
├── apps/
│   ├── web/              # Astro public site (pending build)
│   └── ghost-theme/      # Custom Ghost theme for /journal (pending)
├── infra/
│   ├── caddy/            # Caddyfile + reverse proxy config
│   └── scripts/          # backup.sh · restore.sh · provisioning
├── docs/
│   ├── brand-book-v2.0.md          # deprecated · historical
│   ├── brand-book-v2.1.md          # deprecated · historical
│   ├── brand-book-v2.2.md          # ★ ACTIVE source of truth
│   ├── platform-architecture-v1.md # ★ ACTIVE
│   ├── decisions/
│   │   └── palette-decision.md     # ADR-001
│   └── screenshots/                # site screenshots (pending)
├── assets/
│   ├── photos/           # 16 photos by Lidi (© all rights reserved)
│   ├── branding/         # logo SVGs (pending)
│   └── pdf/              # brand-guidelines.pdf (pending)
├── mockups/
│   ├── claude-web/       # Refined artifacts from Claude.ai web sessions
│   │   ├── lidi-studio-homepage.html        # Sargent Luminous · 9 sections
│   │   ├── lidi-studio-logo-system.html     # Hermès wordmark · 7 configs
│   │   ├── lidi-studio-logo.html            # Single-mark detail
│   │   └── showcase.html                    # 10-palette decision tool
│   ├── xsquads/          # v2.0 design squad iteration (Carbon Black)
│   └── legacy/           # Pre-brand-system index.html + styles.css
├── .github/
│   ├── workflows/        # CI · deploy (pending)
│   └── ISSUE_TEMPLATE/   # bug · feature templates (pending)
├── .env.example          # Environment variables template
├── .gitignore
├── LICENSE               # MIT for code · all rights reserved on brand + photos
└── README.md             # this file
```

---

## Quick start *(future — once `apps/web/` is built)*

```bash
# Clone
git clone https://github.com/<you>/lidi-studio.git
cd lidi-studio

# Install (pnpm preferred)
pnpm install

# Copy env template
cp .env.example .env
# Fill in real values — never commit .env

# Develop
pnpm dev               # Astro dev server at http://localhost:4321

# Build
pnpm build             # Static + hybrid output to apps/web/dist

# Run full local stack (Postgres + Ghost + Cal.com + DocuSeal + NocoDB + Umami)
docker compose -f infra/docker-compose.dev.yml up -d
```

For now, you can preview the visual artifacts directly:

```bash
# macOS
open mockups/claude-web/lidi-studio-homepage.html
open mockups/claude-web/lidi-studio-logo-system.html
open mockups/claude-web/showcase.html
```

---

## Documentation

Read in this order:

1. **`docs/brand-book-v2.2.md`** — who we are, how we look, how we sound
2. **`docs/platform-architecture-v1.md`** — where everything runs, how it connects
3. **`docs/decisions/palette-decision.md`** — why the palette is what it is
4. **`docs/brand-book-v2.0.md`** + **`v2.1.md`** — what we explored and rejected (institutional memory)

---

## Decision records

Architecture decisions live in `/docs/decisions/`. Each ADR is stamped with date, status, context, decision, consequences, and reversal criteria.

| ADR | Decision | Status |
|---|---|---|
| [001](docs/decisions/palette-decision.md) | Palette: Sargent Luminous | LOCKED |
| [002](docs/decisions/server-decision.md) | Server: adopt existing Hetzner CPX21 (Hillsboro, OR) over planned new CX22 (EU) | LOCKED |

---

## Photography

The 16 photographs in `/assets/photos/` are © Lidiane Lopez. All rights reserved. They are present in this repository as visual reference for the brand system and platform build. They are not licensed for reuse, redistribution, derivative works, or training of machine-learning models.

If you are not Lidi or someone she has authorized to work on this platform, the photographs are not yours to use.

---

## License

- **Code** (Astro app, infra, scripts, docs): MIT — see `LICENSE`
- **Brand identity** (name, wordmark, palette spec, tagline, manifesto, commission descriptions): © Lidi Studio · all rights reserved
- **Photography**: © Lidiane Lopez · all rights reserved

---

## Contact

| | |
|---|---|
| Studio | Lidi Studio · Anchorage, AK |
| Website | [lidi.studio](https://lidi.studio) *(pending)* |
| Instagram | [@lidi.studio](https://instagram.com/lidi.studio) |
| Email | [lidi@lidi.studio](mailto:lidi@lidi.studio) *(pending domain email setup)* |
| Status page | [status.lidi.studio](https://status.lidi.studio) *(pending)* |

---

*Painted, not posed. Remembered, not just photographed.*
