# ADR-003 · Multi-tenant infrastructure architecture

| | |
|---|---|
| **Status** | LOCKED |
| **Date** | 2026-04-29 |
| **Decided by** | Operator (renoirlucena) |
| **Reference** | [`/infra/README.md`](../../infra/README.md) · [`/infra/caddy/sites/README.md`](../../infra/caddy/sites/README.md) |
| **Related** | ADR-002 (server choice), ADR-001 (palette) |

---

## Decision

Architect the server `lucena-prod` (Hetzner CPX21) as **multi-tenant ready from day one**, even though only Lidi Studio is in production initially.

The investment is small (~30 lines of extra config, one helper script) and prevents a 1–2 hour refactor when the second tenant arrives.

---

## Context

The operator's project pipeline contains four sites that will share a single Hetzner host over the next 12 months:

| Project | Status | Purpose |
|---|---|---|
| **Lidi Studio** | active, deploying first | Fine art photography brand for Lidiane Lopez (Anchorage, AK) |
| **FinanceLock** | Phase 3, pending | Cybersecurity portfolio piece for Space Force OTS application |
| **Booster Club** | planned | School volunteer site |
| **OpenClaw** | planned | Telegram bot |

If we provision four separate Hetzner servers, we pay 4× the monthly cost (~$42/mo extra), maintain 4× the patches/firewalls/backups/monitors, and produce four overlapping operational documents. None of the projects has the traffic profile that justifies dedicated hardware.

The CPX21 has substantial RAM headroom (~38% with the current Lidi Studio stack) and Hetzner's upgrade path to CPX31 (8 GB RAM) is in-place and takes ~30 seconds of downtime. The natural choice is multi-tenant on shared hardware, with strict tenant isolation at the application layer.

---

## Options considered

### Option A — One server per tenant
- Cost: ~4× current ($42+/mo extra over 12 months)
- Operational overhead: 4× firewalls, backups, patch cycles, monitors, certificates
- No shared resources to leverage
- **Rejected** — wasteful at this scale.

### Option B — Multi-tenant from day one *(chosen)*
- Cost: same single CPX21 ($10.59/mo)
- ~30 lines of extra config today (modular Caddyfile imports + container prefix convention)
- One helper script (`add-site.sh`) for fast onboarding
- Hetzner upgrade to CPX31 deferred until 2nd tenant joins
- Disciplined isolation: per-tenant logical DB, per-tenant container prefix, per-tenant log file
- **Chosen.**

### Option C — Single-tenant now, refactor when 2nd tenant arrives
- Cheapest in the immediate term (~0 extra lines)
- High risk of technical debt: a working production site is harder to refactor than a greenfield one
- The 1–2 h refactor is ~3× more effort than the 30-line up-front investment
- **Rejected** — false economy.

---

## Decision rationale

Option B chosen on four grounds:

1. **Cost savings.** ~$30+/mo over the lifetime of the four projects, and the savings start the day the second tenant arrives. At our scale this is real money.

2. **Prevention is cheaper than refactor.** The cost of doing it right now (~30 lines, no rework) is smaller than the cost of doing it later (~1–2 h refactor + risk of breaking a live site). The cheap-now/expensive-later asymmetry is well-documented across software architecture; we accept it here.

3. **Discipline alignment with cybersecurity portfolio.** FinanceLock is a Space Force OTS portfolio piece. Building it on a multi-tenant host that demonstrates strict isolation, per-tenant secrets, tenant-aware logging, and container naming hygiene is itself a portfolio artifact. Doing it sloppily would undermine the cybersecurity narrative.

4. **Hetzner upgrade path is smooth.** When the 2nd tenant pushes RAM utilization past ~70%, the migration to CPX31 (8 GB RAM, ~$23/mo) is `hcloud server change-type` + reboot — about 30 seconds of downtime. We do not need to plan for this today.

---

## Implementation

### Today (single-tenant in production)
- `/opt/lucena/` — repository checkout, contains all infra and apps for current and future tenants
- `infra/caddy/Caddyfile` — global config + `import sites/*.caddy`
- `infra/caddy/sites/lidi-studio.caddy` — Lidi Studio's site block
- `infra/caddy/sites/README.md` — convention documentation
- `infra/scripts/add-site.sh` — onboarding helper
- Container prefix `lidi-` for all Lidi Studio services (`lidi-caddy`, `lidi-ghost`, `lidi-postgres`, etc.)
- Postgres has 5 logical databases for Lidi Studio services; `init-databases.sh` extends naturally for future tenants
- Per-tenant Caddy access logs: `/var/log/caddy/<slug>.log`

### When the 2nd tenant joins
- Run `infra/scripts/add-site.sh <slug> <domain> <prefix>` to drop a skeleton site block
- Add the new tenant's services to `docker-compose.yml` with the assigned container prefix
- Add a logical Postgres DB via `docker exec lidi-postgres psql -c 'CREATE DATABASE ...'`
- Configure Cloudflare DNS, reload Caddy, smoke-test
- If RAM crosses ~70% of CPX21 budget, schedule the CPX31 upgrade

### When tenant load justifies separate Postgres instances
- Change `host: postgres` to `host: <tenant>-postgres` in each tenant's environment
- The shared `lidi-postgres` becomes Lidi-only; new instances spin up per-tenant
- Backups script auto-discovers all `*-postgres` containers (small change)

---

## Container prefix convention

| Tenant | Prefix | Example services |
|---|---|---|
| Lidi Studio | `lidi-` | `lidi-caddy` *(shared reverse proxy)*, `lidi-postgres` *(shared)*, `lidi-ghost`, `lidi-calcom` |
| FinanceLock *(future)* | `fl-` | `fl-app`, `fl-worker` |
| Booster Club *(future)* | `bc-` | `bc-app`, `bc-db` |
| OpenClaw *(future)* | `oc-` | `oc-bot` |

Notes:
- `lidi-caddy` and `lidi-postgres` are *shared* infrastructure for now (Caddy serves all tenants; Postgres holds one logical DB per service per tenant). When isolation justifies it, we split.
- The `lidi-` prefix on shared infra is historical (Lidi Studio shipped first) — when refactoring becomes worthwhile, rename to `shared-caddy` and `shared-postgres`. Not blocking.

---

## Trade-offs accepted

| Trade-off | Severity | Mitigation |
|---|---|---|
| **Postgres single point of failure** for all tenants | High | Restic + R2 PITR backups (daily, encrypted, retained 30/12/5). Quarterly restore drill. Per-tenant DB makes recovery selective. |
| **Caddy single point of failure** for all tenants | Medium | Health check + Telegram alert. Modular Caddyfile means a broken tenant block fails Caddy validation locally before reaching prod (CI catches it). 5-minute restore via container restart. |
| **Naming discipline required** | Low | `add-site.sh` enforces the prefix convention by template. README documents it. Reviewers reject PRs that violate. |
| **Shared RAM budget** across tenants | Medium | Per-tenant `mem_limit` in compose. Uptime Kuma push monitor on disk + (future) host-level RAM utilization. CPX31 upgrade path documented and trivial. |
| **Shared Caddy logs directory** | Low | Per-tenant `log` block writes to `<slug>.log`, no cross-contamination. Logrotate per file. |

---

## Reversal criteria

This decision should be revisited if any of these become true:

1. **A tenant pushes the RAM budget past CPX31 capacity** (8 GB) — at that point, split out the heaviest tenant to its own server. Migration is straightforward (Restic restore on new host, DNS swap).

2. **A tenant requires hard regulatory isolation** that cannot be satisfied at the application layer (e.g., HIPAA, ITAR, EU sovereignty for a non-US tenant) — split that tenant to a region-appropriate host.

3. **A tenant's traffic profile causes latency degradation for the others** (e.g., FinanceLock attracts a sudden traffic spike that starves Lidi Studio of CPU during a sitting handoff) — split the noisy tenant to its own host.

4. **A tenant is sold, transferred, or open-sourced** — clean separation is required regardless of cost.

In any reversal, the migration path is the same as ADR-002's reversal: Restic restore from R2, DNS swap. ~30 minutes of downtime if executed carefully.

---

## References

- [`/docs/platform-architecture-v1.md`](../platform-architecture-v1.md) — full architecture (v1.1)
- [`/docs/decisions/server-decision.md`](server-decision.md) — ADR-002 (server choice)
- [`/infra/caddy/sites/README.md`](../../infra/caddy/sites/README.md) — sites convention
- [`/infra/scripts/add-site.sh`](../../infra/scripts/add-site.sh) — onboarding helper
- Hetzner Cloud upgrade: `hcloud server change-type` https://docs.hetzner.cloud/
