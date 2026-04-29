# ADR-002 · Server Decision

| | |
|---|---|
| **Status** | LOCKED |
| **Date** | 2026-04-29 |
| **Decided by** | Operator (renoirlucena), based on inventory of existing Hetzner resources |
| **Supersedes** | Server specification in platform-architecture-v1.0 |
| **Reference architecture** | `/docs/platform-architecture-v1.md` (v1.1) |
| **Operational fact sheet** | `/infra/server-info.md` |

---

## Decision

**Adopt the existing Hetzner CPX21 server in Hillsboro, Oregon (US-West) as the production host for Lidi Studio**, instead of provisioning a new CX22 in Falkenstein/Helsinki (EU) as originally planned in platform-architecture v1.0.

| Spec | Planned (CX22) | Actual (CPX21) | Δ |
|---|---|---|---|
| vCPU | 2 | **3 (AMD EPYC)** | +50% |
| RAM | 4 GB | 4 GB | — |
| Disk | 40 GB SSD | **80 GB NVMe** | +100% |
| Location | Falkenstein, DE / Helsinki, FI | **Hillsboro, OR (US-West)** | EU → US |
| Cost | €4.51 / mo | **$9.99 + $0.60 IPv4 = $10.59 / mo** | +~$5.50 / mo |
| Backups (Hetzner) | optional | disabled (we use Restic + R2) | — |
| Server identifier | new | `lucena-prod` *(renamed from `openclaw-milbot` 2026-04-29; operator-scoped name supports multi-tenant — see ADR-003)* | — |
| Hetzner Server ID | — | `124960297` | — |
| IPv4 | — | `5.78.177.39` | — |
| IPv6 prefix | — | `2a01:4ff:1f0:b9be::/64` | — |

---

## Context

When platform-architecture v1.0 was authored on 2026-04-27, the cost-optimal target was the smallest Hetzner Cloud plan that fit the RAM budget (§2.17 of the architecture doc, ~2,680 MB committed with 30%+ headroom). That target was the CX22 (Intel-based, €4.51/mo, 2 vCPU, 4 GB RAM, 40 GB SSD), provisionable in any of Hetzner's EU data centres (Falkenstein DE, Nuremberg DE, Helsinki FI). EU residency was a soft preference for GDPR ergonomics.

Two days later, before any deploy work began, we inventoried existing Hetzner resources on the operator account and discovered an already-provisioned CPX21 in Hillsboro, OR (`5.78.177.39`, server ID `124960297`, currently named `openclaw-milbot` and powered on). This server pre-dated the project and was idle.

The question became: **provision a new CX22 in EU per the original plan, or adopt the existing CPX21 in Hillsboro?**

---

## Options considered

### Option A — Adopt the existing CPX21 in Hillsboro *(chosen)*
- Use what's already paid for and provisioned
- Rename in the Hetzner console: `openclaw-milbot` → `lucena-prod` *(done 2026-04-29)*
- Hardware exceeds plan: +50% vCPU, +100% disk, same RAM
- Hillsboro location is significantly closer to Anchorage clientele than EU

### Option B — Provision a new CX22 in Falkenstein per the original plan
- Stricter cost target (€4.51/mo vs $10.59/mo, ≈ -54%)
- EU data residency by default
- But: duplicates infrastructure with no operational gain
- Leaves CPX21 idle on the bill anyway

### Option C — Migrate the CPX21 from Hillsboro to an EU location
- Hetzner does not support inter-region migration; it would require full reprovisioning
- Eliminates the only real benefit of Option A (no friction, already paid)

---

## Decision rationale

**Option A wins on four axes; Option B wins only on cost optimization in absolute terms.**

1. **Hardware is technically superior to the plan.** The CPX21 has 50% more vCPU and 2× the disk for ~$5.50/mo more. The vCPU surplus matters: Cal.com (the heaviest service, Next.js-based) and Astro builds triggered synchronously by Ghost webhooks both benefit from concurrent throughput headroom. The disk surplus matters: photo uploads through Ghost will grow over time, and 80 GB pushes the "needs migration to scale" decision out by 2–3 years.

2. **Hillsboro reduces latency to Lidi's actual customer base.** Lidi's commission audience is Anchorage and JBER — coastal Alaska. RTT from Anchorage to Hillsboro is ~20–35 ms; to Falkenstein it's ~150–180 ms. For a Cal.com booking flow with multiple synchronous database writes, that delta is the difference between "fast" and "perceptibly waiting." For the Astro static frontend the difference is mostly absorbed by Cloudflare's edge cache anyway, but the *uncached* admin paths (`/admin`, `/ghost`, `/book`, `/contracts/[token]`) are all latency-sensitive and all hit the origin.

3. **No duplication of infrastructure.** Option B would leave the CPX21 idle on the Hetzner bill (it's already paid for, billing began the moment it was provisioned). Adopting it converts already-spent dollars into productive capacity. Option B effectively *adds* €4.51/mo to spend rather than saving anything.

4. **The €/$ delta is operationally trivial.** ~$5.50/mo extra = ~$66/year. Against the full cost of building, hosting, and maintaining a fine art photography platform — and especially against the value of one additional commission booking per year — this is in the noise.

The two arguments **for** Option B were:
- **Pure cost optimization.** Real, but trivial in absolute terms (see point 4 above).
- **EU GDPR residency.** Real, but the brand's customer base is overwhelmingly US-based (military families at JBER + civilians in Anchorage + occasional civilian visitors). The few EU visitors that may arrive via web will be disclosed-and-consented per GDPR Art. 13 in the privacy policy. If a future client genuinely requires EU residency (e.g., a press feature in a European magazine or a commissioned EU-resident sitting), reversal criteria below apply.

---

## Trade-offs accepted

| Trade-off | Mitigation |
|---|---|
| **+~$5.50/mo cost** ($66/yr) | Accepted as operationally trivial. |
| **US data residency instead of EU GDPR-native** | Privacy policy at `/privacy` will disclose US hosting + Hetzner as processor. Umami is no-PII by default. Ghost member emails are minimal-PII. Stripe handles payment data (PCI-compliant, separate). Cal.com personal data lives in our Postgres. No special-category PII (health, race, etc.) is collected. |
| **Hillsboro → EU latency penalty** | Acceptable for the few EU visitors expected. Cloudflare edge caches static frontend globally. |
| **Hetzner native backups disabled on this server** | Intentional — we use Restic + Cloudflare R2 per architecture §2.15, which is encrypted client-side and superior to Hetzner snapshot backups for this use case. |

---

## Consequences

### Immediate
- `/docs/platform-architecture-v1.md` updated to v1.1 to reflect actual server specs and cost
- `/infra/server-info.md` created as operational fact sheet (IPs, ID, plan, setup checklist)
- `/README.md` stack table updated
- This ADR (ADR-002) recorded as historical decision

### Pending operator actions *(tracked in `/infra/server-info.md` checklist)*
- Rename in Hetzner console: `openclaw-milbot` → `lucena-prod` *(done 2026-04-29)*
- SSH hardening (custom port, key-only, fail2ban)
- Docker + Docker Compose install
- UFW firewall rules
- Cloudflare DNS A records pointing to `5.78.177.39`

### Downstream squads
- **claude-code-mastery / infra build** — Docker Compose stack will deploy here. Reverse proxy (Caddy) terminates TLS on this host.
- **cybersecurity** — hardening playbook should target this specific server. SSH key fingerprint, fail2ban tunings, etc. will be recorded here once setup happens.
- **traffic-masters** — local SEO already targets Anchorage/JBER, so US hosting aligns naturally. No schema.org changes needed.

---

## Reversal criteria

This decision should be revisited if any of the following becomes true:

1. **A specific client contractually requires EU data residency** (e.g., a European press commission with GDPR-strict terms). In that case: provision a CX22 in Falkenstein, migrate Postgres + Ghost uploads + DocuSeal data, update DNS. Reversal cost: ~1 day of work + ~€4.51/mo additional running cost during overlap.

2. **Lidi Studio establishes a regular European clientele** (>10% of bookings from EU residents over a 6-month window). At that point, EU residency becomes a marketing asset, not just a compliance one.

3. **Hetzner discontinues or significantly degrades the CPX21 plan in Hillsboro**, or adds a substantial price increase that closes the cost gap.

4. **A privacy/legal incident reveals that US hosting created exposure that EU hosting would have avoided.** Treat as an after-the-fact lesson and migrate.

In any reversal, the migration path is well-understood: Restic restore from R2 onto a new Hetzner host, DNS swap via Cloudflare. Estimated downtime: <30 minutes if executed carefully.

---

## References

- Platform architecture: `/docs/platform-architecture-v1.md` (v1.1)
- Operational fact sheet: `/infra/server-info.md`
- ADR-001 (palette): `/docs/decisions/palette-decision.md`
- Hetzner Cloud pricing: https://www.hetzner.com/cloud/
- Cloudflare data-residency disclosure obligations under GDPR Art. 13
