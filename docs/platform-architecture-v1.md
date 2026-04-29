# Lidi Studio — Platform Architecture v1.1

> Companion to `brand-book-v2.2.md`.
> Brand book defines WHO, WHAT, HOW IT FEELS.
> This document defines WHERE, WITH WHAT, HOW IT WORKS.
> Approved 2026-04-27 (v1.0). Reconciled with provisioned server 2026-04-29 (v1.1). Active.

---

## 1. Executive Summary

> **Note (2026-04-29):** Initial planning specified Hetzner CX22 in Falkenstein at €4.51/mo. Actual provisioned server is **CPX21 in Hillsboro, Oregon at $13.99/mo**. The CPX21 has 50% more vCPU and 2× disk for ~$9/mo more — net positive for our workload. Hillsboro location reduces latency to Anchorage clientele significantly vs EU. RAM budget §2.17 unchanged. Decision recorded in [`/docs/decisions/server-decision.md`](decisions/server-decision.md) (ADR-002). Operational details in [`/infra/server-info.md`](../infra/server-info.md).

Lidi Studio runs end-to-end on a single Hetzner CPX21 VPS ($13.99/mo). One machine serves every public and private function: an Astro-built static frontend at the edge, Ghost for the journal, Cal.com for booking, DocuSeal for contracts, Stripe for payments, NocoDB for the internal CRM, Umami for analytics, Uptime Kuma for monitoring — all reverse-proxied by Caddy 2 and fronted by Cloudflare's free tier. PostgreSQL 16 + Redis as data layer. Domain `lidi.studio` is acquired. **Total fixed monthly platform cost: $13.99.** Stack subscription footprint: zero. Time to production-ready launch from the provisioned server: 4–6 weeks.

### Cost breakdown

| Item | Cost / month |
|---|---:|
| Hetzner CPX21 (3 vCPU AMD EPYC, 4 GB RAM, 80 GB NVMe SSD, 1 IPv4, Hillsboro OR) | $13.99 |
| Cloudflare DNS / CDN / WAF (Free) | $0.00 |
| Cloudflare R2 backup storage (10 GB free tier) | $0.00 |
| Brevo SMTP (Free, 300 emails / day) | $0.00 |
| GitHub Actions (Free, unlimited on public repo) | $0.00 |
| Domain `lidi.studio` (annual renewal, separate budget) | ~$1.80 |
| Stripe payment processing | transactional only (2.9% + $0.30/tx) |
| **Total fixed platform cost** | **$13.99 / mo** |

---

## 2. Technical Stack

### 2.1 Operating system — **Ubuntu 24.04 LTS**
Host OS. LTS until 2029. ~400 MB RAM, ~3 GB disk. License: free. Updates: `unattended-upgrades` for security patches automatically.

### 2.2 Container runtime — **Docker Engine 27.x + Docker Compose v2.29**
Single-machine multi-service orchestration. ~200 MB RAM baseline. License: Apache 2.0.

### 2.3 Reverse proxy — **Caddy 2.8**
TLS termination, auto Let's Encrypt, HTTP/3, internal routing. ~30 MB RAM, single binary. License: Apache 2.0.

### 2.4 Edge — **Cloudflare (Free tier)**
DNS, global CDN, WAF, DDoS shielding, rate limiting. Free permanently for our traffic profile. License: Cloudflare TOS.

### 2.5 Frontend framework — **Astro 4.x (hybrid mode)**
Public site framework. Content Collections with Zod schemas, native image optimization (Sharp), island architecture. **At runtime: ~80 MB RAM** (Node container for `/api/*`); static pages served by Caddy at zero per-page cost. License: MIT.

### 2.6 Journal CMS — **Ghost 5.x (self-hosted)**
Best-in-class visual editor for non-technical operators. Built-in member subscriptions and newsletter. JSON Content API consumed by Astro at build time. **~280 MB RAM**, ~500 MB disk + uploads. License: MIT.

### 2.7 Booking — **Cal.com 3.x (self-hosted)**
Open-source Calendly equivalent. Native Google Calendar / CalDAV / iCloud integration. Embed at `/book`. **~700 MB RAM**, ~300 MB disk. License: AGPLv3 (commercial cap not exceeded).

### 2.8 Contracts — **DocuSeal 1.x (self-hosted)**
Drag-drop field placement, signed PDF output, audit trail, webhook on signature. **~200 MB RAM**, ~200 MB disk. License: AGPLv3.

### 2.9 CRM — **NocoDB 0.250+**
Airtable-equivalent over PostgreSQL. Receives webhooks from Cal.com / DocuSeal / Stripe. **~250 MB RAM**, ~150 MB disk. License: AGPLv3.

### 2.10 Analytics — **Umami 2.x (self-hosted)**
GDPR-compliant by default (no cookies, no PII). ~2 KB tracking script. **~100 MB RAM**, ~100 MB disk. License: MIT.

### 2.11 Monitoring — **Uptime Kuma 1.x**
Open-source Pingdom/Statuspage equivalent. Public status page at `status.lidi.studio` is a trust signal. **~80 MB RAM**, ~50 MB disk. License: MIT.

### 2.12 Database — **PostgreSQL 16** + **Redis 7** + **SQLite**
Single Postgres instance, one logical database per service (`ghost`, `calcom`, `docuseal`, `nocodb`, `umami`). Redis 7 for Cal.com sessions and Ghost cache. SQLite for Uptime Kuma's local state. **~280 MB RAM** (Postgres) + **~50 MB RAM** (Redis), ~1 GB disk (will grow).

### 2.13 Outbound email — **Brevo SMTP (Free tier)**
300 emails/day free, permanent. Transactional + Ghost newsletter to ~500 subscribers fits comfortably.

### 2.14 Payments — **Stripe**
Industry standard. No monthly fee, 2.9% + €0.30 per transaction. Stripe Checkout hosted (no PCI burden). Webhooks update NocoDB.

### 2.15 Backups — **Restic + Cloudflare R2 (10 GB free)**
Restic deduplicates and encrypts client-side; R2 free tier covers our footprint indefinitely. **~30 MB RAM during cron-driven backups**.

### 2.16 Source + CI/CD — **GitHub + GitHub Actions**
Free private repos, free Actions runtime (2,000 min/mo). SSH-deploy to Hetzner over a deploy key.

### 2.17 RAM budget *(must fit 4 GB with ≥30% headroom)*

| Service | RAM allocated |
|---|---:|
| Ubuntu base + Docker engine | 600 MB |
| Caddy | 30 MB |
| Astro hybrid (API container) | 80 MB |
| Ghost | 280 MB |
| Cal.com | 700 MB |
| DocuSeal | 200 MB |
| NocoDB | 250 MB |
| Umami | 100 MB |
| Uptime Kuma | 80 MB |
| PostgreSQL 16 | 280 MB |
| Redis 7 | 50 MB |
| Restic (during backup) | 30 MB |
| **Committed** | **2,680 MB** |
| **Headroom** | **~1,400 MB (34%)** |

> **vCPU note (CPX21):** the provisioned server has 3 vCPU (AMD EPYC) vs the 2 vCPU originally planned. RAM budget above is unchanged. The extra vCPU gives Cal.com (the heaviest service, Next.js-based) and PostgreSQL more concurrent throughput headroom — particularly during Astro builds triggered by Ghost-publish webhooks, which happen synchronously with normal request handling.

---

## 3. Domain and Routing Map

Single apex domain: `lidi.studio`. Subpaths preferred over subdomains. Two exceptions: `status.lidi.studio` (separation prevents status page going down with main site) and webhook endpoints (same domain, server-rendered).

| Route | Service | Auth | SEO | Caddy approach |
|---|---|---|---|---|
| `/` | Astro static | public | yes | `file_server` from `/srv/astro/dist` |
| `/work` · `/work/[slug]` | Astro | public | yes | static |
| `/commissions` · `/commissions/[slug]` | Astro | public | yes | static |
| `/about` | Astro (with pron cue) | public | yes | static |
| `/archive` | Astro | public | yes | static |
| `/journal` · `/journal/[slug]` | Ghost | public | yes | `reverse_proxy ghost:2368` |
| `/begin` | Astro form (POST → `/api/inquiry`) | public | yes | static + API route |
| `/book` | Cal.com | public | yes | `reverse_proxy calcom:3000` |
| `/contracts/[token]` | DocuSeal | signed-link only | **no** | `reverse_proxy docuseal:3000` + token gate |
| `/admin` | NocoDB | basic auth + IP allowlist | **no** | `reverse_proxy nocodb:8080` + middleware |
| `/stats` | Umami | basic auth + IP allowlist | **no** | `reverse_proxy umami:3000` + middleware |
| `/links` | Astro | public | yes | static (link-in-bio mirror) |
| `/api/*` | Astro hybrid (Node) | mixed | **no** | `reverse_proxy astro-api:4321` |
| `status.lidi.studio` | Uptime Kuma | public | yes | separate Caddy site block |

### Cloudflare DNS records
```
A     lidi.studio          → <Hetzner IPv4>      proxied (orange)
AAAA  lidi.studio          → <Hetzner IPv6>      proxied
CNAME www                  → lidi.studio         proxied (301 → apex)
A     status.lidi.studio   → <Hetzner IPv4>      DNS-only (grey)
TXT   _dmarc · SPF · DKIM (Brevo-provided)
MX    (Brevo-provided)
```

---

## 4. Information Architecture

```
/
├── /work                           [Portfolio entry · awareness→consideration]
│   └── /work/{the-becoming, first-light, the-mothering, the-hearth, the-triptych}
├── /commissions                    [Process & Investment · decision]
│   └── /commissions/{...same five slugs}
├── /about                          [Brand depth · trust · pron cue lives here]
├── /archive                        [Featured sittings · social proof]
├── /journal                        [Ghost-served editorial blog · SEO + nurture]
│   └── /journal/[slug]
├── /begin                          [Inquiry form · primary CTA]
├── /book                           [Cal.com embed · post-qualification]
├── /links                          [Instagram link-in-bio mirror]
├── /privacy · /terms               [Legal]
└── _private/
    ├── /admin                      [NocoDB CRM]
    ├── /stats                      [Umami analytics]
    └── /contracts/[token]          [DocuSeal signed links]
```

### Primary nav (5 items, fixed)
`Work · Commissions · Journal · About · Begin`

### Footer (3 columns)
- **Studio**: Work · Commissions · About · Archive
- **Journal**: Journal · Newsletter · Press
- **Contact**: lidi@lidi.studio · @lidi.studio · Anchorage, AK · status.lidi.studio · Privacy · Terms

---

## 5. User Flows *(see brand-book § Commission architecture)*

### Flow A — Cold visitor → Lead
`Instagram → /links → /work → /commissions → /begin → POST /api/inquiry → NocoDB.leads.insert + Brevo notify Lidi + Brevo auto-reply`

### Flow B — Lead → Booking
`Email reply with Cal.com link → /book → Cal.com webhook → NocoDB update → Lidi creates DocuSeal proposal → /contracts/[token] → DocuSeal webhook → NocoDB update + Brevo Stripe link → Stripe Checkout → Stripe webhook → NocoDB confirm + Brevo session-prep email`

### Flow C — Confirmed → Delivery
`Session day → Lidi shoots → 4-6 weeks editing → /galleries/[token] (Astro static + Caddy basic-auth) → balance Stripe link → +14 days testimonial request via Brevo`

### Flow D — Past client → Repeat (The Triptych funnel)
`Ghost member tag "maternity_completed" → 6-week post-newborn newsletter → /commissions/the-mothering → 9-month Triptych retrospective email`

### Flow E — Wife publishes journal post
`lidi.studio/ghost (2FA) → +New post → drag-drop images → publish → Ghost webhook → /api/webhooks/ghost → GitHub Actions repository_dispatch → Astro rebuild + deploy (~90s end-to-end)`

---

## 6. Frontend Architecture

> **Visual reference: `/mockups/claude-web/lidi-studio-homepage.html`.** That file is the canonical specification for the public site's editorial register, motion, and component composition. The Astro build at `/apps/web/` ports it.

### 6.1 Astro project structure

```
apps/web/
├── src/
│   ├── pages/                      # File-routed
│   │   ├── index.astro             # /
│   │   ├── work/                   # work/[slug].astro
│   │   ├── commissions/            # commissions/[slug].astro
│   │   ├── about.astro · archive.astro · begin.astro · links.astro
│   │   └── api/
│   │       ├── inquiry.ts          # POST → NocoDB + Brevo
│   │       └── webhooks/{calcom,docuseal,stripe,ghost}.ts
│   ├── components/
│   │   ├── layout/   (Nav · Footer · Section · Container · EditorialGrid)
│   │   ├── display/  (HeroFullBleed · ImagePlate · GalleryAsymmetric · PullQuote · Eyebrow · Divider)
│   │   ├── content/  (CommissionCard · ArchiveEntry · JournalCard · TestimonialBlock · ManifestoBlock)
│   │   ├── action/   (InquiryForm · NewsletterForm · CTAButton · BookingEmbed)
│   │   └── utility/  (PronunciationCue · MonogramMark · WaxSeal)
│   ├── layouts/
│   ├── content/                    # Content Collections (Zod)
│   │   ├── config.ts
│   │   ├── commissions/
│   │   └── archive/
│   ├── styles/
│   │   ├── tokens.css              # CSS custom properties (palette + type)
│   │   ├── reset.css · typography.css · motion.css
│   ├── lib/
│   │   ├── ghost.ts · nocodb.ts · brevo.ts · stripe.ts
│   └── assets/                     # Source-of-truth images
├── astro.config.mjs · package.json · tsconfig.json
```

### 6.2 Design tokens *(from brand-book-v2.2.md §7 + §8)*
```css
:root {
  --color-cream:    #F5EBDD;   /* primary */
  --color-mauve:    #D4B5B0;   /* secondary */
  --color-pearl:    #C9C2B8;   /* atmospheric */
  --color-gold:     #B89968;   /* accent */
  --color-charcoal: #4A3F38;   /* type only */

  --font-display:   "Cormorant Garamond", Georgia, serif;
  --font-display-2: "Italiana", Georgia, serif;
  --font-body:      "EB Garamond", Georgia, serif;
  --font-sans:      "Inter", system-ui, sans-serif;
  --font-mono:      "JetBrains Mono", ui-monospace, monospace;

  --section-y:      clamp(80px, 12vw, 160px);
  --gutter-x:       clamp(20px, 5vw, 80px);
  --ease-paper:     cubic-bezier(0.16, 1, 0.3, 1);
  --hairline:       1px solid var(--color-pearl);
}
```

### 6.3 Image pipeline
Astro `<Image />` + `<Picture />` → Sharp at build time → AVIF (primary) + WebP (fallback) at widths `[400, 800, 1200, 1600, 2000]`. Hero images additionally generate a 32px LQIP for blur-up. Aspect ratios: `4:5` portrait (default), `5:7` magazine cover, `2:3` 35mm. Never `1:1`. Never `16:9`.

### 6.4 Performance budget *(enforced via Lighthouse CI)*

| Metric | Target |
|---|---|
| LCP (4G mobile) | < 1.5s |
| CLS | < 0.05 |
| INP | < 200ms |
| Lighthouse Performance | ≥ 95 |
| Lighthouse Accessibility | ≥ 95 |
| Lighthouse SEO | 100 |
| Page weight (excl hero) | < 1.2 MB |
| Hero image | < 200 KB at 1920w (AVIF) |
| JS budget | < 50 KB gzipped |
| CSS budget | < 30 KB gzipped |

### 6.5 Refusal list (anti-template)
No auto-rotating carousels · no symmetric Pinterest grids · no "Welcome!" hero mat · no parallax · no full-screen video bg · no animated gradients · no infinite scroll on portfolio.

---

## 7. CMS Strategy *(operator: Lidi's wife, non-technical)*

- Admin URL: `lidi.studio/ghost` · auth: Ghost native + 2FA TOTP
- Roles: Owner = Lidi · Editor = wife (only)
- Tags (controlled vocabulary): `Maternity · Newborn · Motherhood · Family · Process · Behind the Scenes · Featured Sittings · Press · Studio Notes`
- Publish flow: Draft → Preview (mobile QR) → Publish + optional "Send by email" (newsletter)
- Astro consumes via Ghost Content API at build time + webhook-triggered rebuild on publish (~90s end-to-end)
- Backups: Postgres `ghost` DB nightly + uploads volume nightly → Restic → R2

### Operator never touches
Settings → Labs · Settings → Integrations · Settings → Theme · Members → Tiers / Portal · anything in Settings she doesn't recognize.

---

## 8. Booking + Contracts + Payments

End-to-end pipeline already mapped in §5 Flow B. Webhooks land at `lidi.studio/api/webhooks/[service]` (Astro hybrid Node container). All inbound webhooks require signature verification (HMAC-SHA256 with shared secret per source; Stripe uses native `stripe.webhooks.constructEvent`). All handlers are idempotent (check `webhook_events` table for `event.id`). Failure modes: NocoDB down → log + return 500 (source retries) · Brevo down → enqueue to local `email_queue` table, cron drains every 60s · invalid signature → 401 + alert.

### NocoDB schema (high level)
Tables: `leads · commissions · clients · payments · webhook_events · email_queue`.

---

## 9. Security Posture *(starting point for cybersecurity squad)*

- SSH key-only (Ed25519), root disabled, custom port, fail2ban
- UFW: deny default · allow 80/443 from Cloudflare IP ranges only · custom SSH port
- Cloudflare proxy ON · WAF managed ruleset · rate limit `/api/inquiry` ≤5 req/min/IP
- PostgreSQL bound to Docker network only
- TLS 1.3 only · HSTS preload submitted
- Secrets: `/opt/lidi/.env` mode 600, never in git · `.env.example` committed with empty values
- Admin routes: 2FA + Caddy basic_auth + IP allowlist · `X-Robots-Tag: noindex`
- Backup encryption: Restic passphrase in 1Password + sealed offline envelope · annual restore drill
- GDPR: Umami no-PII · Ghost member opt-in · privacy policy at `/privacy` · data hosted in Hetzner Hillsboro OR (US-West). EU customer data flows must be disclosed in privacy policy per GDPR Art. 13. Trade-off accepted in ADR-002 — see `/docs/decisions/server-decision.md` for reversal criteria if EU residency is later required.

---

## 10. Deployment and CI/CD

- **Repo:** monorepo at `lidi-studio` (this repo)
- **Branch strategy:** `main` = production · feature branches `feat/<short>` · PRs only to main · no staging environment initially
- **CI workflow** (`.github/workflows/ci.yml`, on PR): typecheck → lint → build → Lighthouse CI → tests
- **Deploy workflow** (`.github/workflows/deploy.yml`, on merge to main OR `repository_dispatch` from Ghost):
  1. Build Astro
  2. Build & push Docker images to GHCR
  3. SSH to Hetzner, `git pull && docker compose pull && docker compose up -d --remove-orphans`
  4. Health-check loop (30s, 5 attempts) on `/healthz`
  5. Failure → `docker compose rollback` + Telegram alert
  6. Success → Uptime Kuma push hook + Telegram notification
- **Rollback:** `git revert` → push → workflow redeploys prior good build (~5 min)
- **Zero-downtime:** Compose `up -d --remove-orphans --no-deps` per service · Caddy graceful reload · static layer never goes down

---

## 11. Observability and Maintenance

### Uptime Kuma monitors
| Monitor | Type | Interval | Alert |
|---|---|---|---|
| `/` (keyword "Painted, not posed.") | HTTPS | 60s | Telegram + email after 2 fails |
| `/journal` keyword | HTTPS | 5m | as above |
| `/api/healthz` 200 | HTTPS | 60s | as above |
| `/book` 200 | HTTPS | 5m | as above |
| `status.lidi.studio` self-check | HTTPS | 60s | — |
| Postgres TCP (internal) | TCP | 60s | as above |
| Disk usage push | push | 10m | alert > 80% |
| Cert expiry per domain | HTTPS-cert | 6h | alert at 14 days |

### Maintenance cadence
- **Monthly (15 min):** `docker compose pull && up -d` · `df -h` · verify Restic snapshots · `caddy validate` · eyeball top pages · `apt update`
- **Quarterly (1h):** Lighthouse top-5 · linkinator broken-link scan · Postgres `VACUUM ANALYZE` · `auditd` review · end-to-end `/api/inquiry` test
- **Annually:** restore-from-backup drill · domain renewal · major version review · vendor account review

---

## 12. Handoff notes per squad

- **claude-code-mastery** (Astro build phase) → `/apps/web/` + `/infra/` · acceptance: live `lidi.studio` hits §6.4 budgets, end-to-end inquiry-to-deposit transaction works
- **design-squad** → component visual specs + page mockups (mobile/tablet/desktop) + motion specs + asset prep guidelines + print spec sheet
- **copy-master** → every word on every page in v2.2 voice + Studio activation rules + pron rule + 12 transactional email templates
- **storytelling** → About narrative + 5 commission editorial pages + 12 seed journal posts
- **hormozi-squad** → investment levels per commission · guarantee architecture · bonus stacks · Triptych payment plans · 4/year scarcity mechanics
- **traffic-masters** → keyword research · schema.org markup · meta strategy · Google Business Profile · local backlinks · Pinterest + Instagram organic
- **cybersecurity** → §9 starting point · hardening playbook · IR runbook · backup verification · quarterly pen-test
- **AIOX** → §5 + §8 · automation specs per flow · email sequence designs · NocoDB automations · notification routing · status-driven follow-ups

---

## 13. Versioning

| Version | Date | Status | Note |
|---|---|---|---|
| v1.0 | 2026-04-27 | superseded by v1.1 | Initial platform architecture · companion to brand-book-v2.2.md · planned Hetzner CX22 €4.51/mo Falkenstein · stack locked |
| **v1.1** | **2026-04-29** | **active** | **Server provisioned: CPX21 in Hillsboro OR (`lidi-studio-prod`, IP `5.78.177.39`). Specs and cost adjusted: 3 vCPU · 4 GB RAM · 80 GB SSD · $13.99/mo. Stack and architecture otherwise unchanged from v1.0. See ADR-002 for decision rationale; see `/infra/server-info.md` for operational details.** |
