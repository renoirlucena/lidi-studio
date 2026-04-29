# Caddy sites — multi-tenant convention

This directory holds **per-site Caddyfile fragments**, loaded by the main `../Caddyfile` via `import sites/*.caddy`. Each tenant on this server gets its own file.

> **Why this exists:** the server `lucena-prod` is multi-tenant ready from day one. Lidi Studio is the only site in production today, but FinanceLock, Booster Club, and OpenClaw are coming. Modular Caddyfile imports let us add a tenant by dropping one file and reloading Caddy — no edits to shared config, no merge conflicts, no risk of breaking a working site. See [`/docs/decisions/multi-tenant-decision.md`](../../../docs/decisions/multi-tenant-decision.md) (ADR-003).

---

## Convention

### File naming
- One file per public domain.
- Filename: `<project-slug>.caddy` (kebab-case, matches the project's identifier).
- Example: `lidi-studio.caddy` for `lidi.studio`.

### File contents
Each file is a standalone Caddyfile fragment. It may contain:
- One or more named site blocks (`example.com { ... }`)
- Site-specific redirect blocks (e.g. `www.example.com → example.com`)
- Per-site security headers, routing, error pages, logs

It must NOT contain:
- The global `{ ... }` block — that lives in the main Caddyfile.
- The `import` statement — only the main Caddyfile imports.
- Any side effects that affect other tenants.

### Container naming convention *(for the upstream services this site talks to)*
| Tenant | Container prefix | Example |
|---|---|---|
| Lidi Studio | `lidi-` | `lidi-ghost`, `lidi-calcom`, `lidi-postgres` *(shared)* |
| FinanceLock *(future)* | `fl-` | `fl-app`, `fl-worker` |
| Booster Club *(future)* | `bc-` | `bc-app`, `bc-db` |
| OpenClaw *(future)* | `oc-` | `oc-bot` |

The Postgres and Redis instances are shared across tenants today (one logical database per service), but the container prefix convention keeps service ownership unambiguous. When tenant load justifies it, separate Postgres instances per tenant become trivial — change `host: postgres` to `host: lidi-postgres` in each tenant's env.

### Logging
Each tenant writes its own access log:
- `/var/log/caddy/<slug>.log`

Rotation: 100 MB roll, 7 keep, 720 h retention (configured per site).

---

## Adding a new site

Use the helper script:
```bash
/opt/lucena/infra/scripts/add-site.sh <slug> <domain> <prefix>
# example:
/opt/lucena/infra/scripts/add-site.sh financelock financelock.app fl
```

The script:
1. Creates `sites/<slug>.caddy` from a skeleton template
2. Prints the next steps (compose service, DB, DNS, reload)

After editing the new file, reload Caddy without downtime:
```bash
docker exec lidi-caddy caddy reload --config /etc/caddy/Caddyfile
```

---

## Current sites

| Slug | Domain | Status |
|---|---|---|
| `lidi-studio` | `lidi.studio` | ✅ active |
| `financelock` | `financelock.app` | ⏳ planned |
| `booster-club` | TBD | ⏳ planned |
| `openclaw` | TBD | ⏳ planned |

---

## See also

- [`/docs/decisions/multi-tenant-decision.md`](../../../docs/decisions/multi-tenant-decision.md) — ADR-003
- [`../Caddyfile`](../Caddyfile) — main config (global + imports only)
- [`../Caddyfile.status`](../Caddyfile.status) — `status.lidi.studio` (separate site, separate file)
