# Server — Operational fact sheet

> Production host for `lidi.studio`. This document is the single source of truth for server identity, network, and provisioning state. Update this file whenever the server's operational state changes.

---

## Identity

| Field | Value |
|---|---|
| **Hostname** | `lucena-prod` *(renamed in Hetzner console 2026-04-29 from `openclaw-milbot`)* |
| **Naming rationale** | Generic, operator-scoped name allows multi-tenant hosting (Lidi Studio + future FinanceLock + Booster Club + OpenClaw) on the same server. See ADR-003. |
| **Hetzner Server ID** | `124960297` |
| **Provider** | Hetzner Cloud |
| **Plan** | CPX21 |
| **Status** | ON · provisioned, idle (no services deployed yet) |

> ✅ **Renamed 2026-04-29.** Hostname is `lucena-prod` (operator-scoped, multi-tenant ready). The OS hostname inside the VM is set by `setup-server.sh` via `hostnamectl set-hostname` to match.

---

## Hardware

| Spec | Value |
|---|---|
| vCPU | 3 (AMD EPYC) |
| RAM | 4 GB |
| Storage | 80 GB NVMe SSD |
| Architecture | x86_64 |

---

## Network

| Field | Value |
|---|---|
| **IPv4** | `5.78.177.39` |
| **IPv6 prefix** | `2a01:4ff:1f0:b9be::/64` |
| **IPv6 (primary)** | `2a01:4ff:1f0:b9be::1` *(assumed first address of the prefix; confirm in console)* |
| **Location** | Hillsboro, Oregon, US |
| **Network zone** | `us-west` |
| **Datacenter** | `hil-dc1` *(Hetzner Hillsboro)* |
| **Included traffic** | 1 TB / month outbound |
| **Overage** | $7.40 per additional TB |

### DNS *(to configure)*
| Record | Type | Value | Cloudflare proxy |
|---|---|---|---|
| `lidi.studio` | A | `5.78.177.39` | ✓ orange (proxied) |
| `lidi.studio` | AAAA | `2a01:4ff:1f0:b9be::1` *(or actual primary)* | ✓ orange |
| `www.lidi.studio` | CNAME | `lidi.studio` | ✓ orange (301 → apex via Caddy) |
| `status.lidi.studio` | A | `5.78.177.39` | ✗ grey (DNS-only, separate from main) |
| `status.lidi.studio` | AAAA | *(same as primary IPv6)* | ✗ grey |
| `_dmarc` · SPF · DKIM | TXT | from Brevo | ✗ grey |
| MX | MX | from Brevo | ✗ grey |

---

## Backups

| Field | Value |
|---|---|
| **Hetzner native backups** | **DISABLED** *(intentional)* |
| **Backup strategy** | Restic + Cloudflare R2 (10 GB free tier) — see platform-architecture §2.15 |
| **Retention** | 30 daily · 12 monthly · 5 yearly *(Restic policy)* |
| **Encryption** | Restic client-side, passphrase in `.env` (mode 600) + 1Password + sealed offline envelope |

**Why disabled:** Hetzner snapshots cost ~20% surcharge, lock to vendor, and don't deduplicate. Restic + R2 is encrypted client-side, deduplicates, supports point-in-time restore from any time horizon, and survives Hetzner-account compromise.

---

## Cost

| Item | Amount |
|---|---:|
| Plan (CPX21 Hillsboro) | $9.99 / month |
| Primary IPv4 (separate billing) | $0.60 / month |
| Backups (disabled) | $0.00 |
| Traffic overage | $0.00 expected (well under 1 TB) |
| **Total** | **$10.59 / month** |

Decision rationale for adopting CPX21 over the originally-planned CX22: see [`/docs/decisions/server-decision.md`](../docs/decisions/server-decision.md) (ADR-002).

---

## Access — *currently NOT configured*

| Vector | State |
|---|---|
| SSH | ⏳ pending — Ed25519 key + custom port + fail2ban |
| Root login | ⏳ pending disable |
| Password auth | ⏳ pending disable |
| UFW firewall | ⏳ pending — allow [custom-SSH-port], 80, 443 only |
| Hetzner Cloud Firewall | ⏳ pending — Cloudflare IPs only on 80/443 |
| Console access | available via Hetzner web console (last-resort recovery) |

---

## Software stack — *currently bare Ubuntu*

| Layer | State |
|---|---|
| OS | Ubuntu 24.04 LTS *(assumed; confirm in console / on first SSH)* |
| Docker Engine 27 | ⏳ pending install |
| Docker Compose v2 | ⏳ pending install |
| Caddy 2.8 | ⏳ pending (containerized via compose) |
| PostgreSQL 16 | ⏳ pending (containerized) |
| Redis 7 | ⏳ pending (containerized) |
| Ghost · Cal.com · DocuSeal · NocoDB · Umami · Uptime Kuma | ⏳ pending (containerized) |
| Astro hybrid (Node container) | ⏳ pending (built via GitHub Actions) |
| Restic | ⏳ pending install |
| `unattended-upgrades` | ⏳ pending enable |
| `fail2ban` | ⏳ pending install + configure |

---

## First-time setup checklist

Atomic, ordered. Each item should be checked off as completed and dated.

### Hetzner console
- [x] Rename server: `openclaw-milbot` → `lucena-prod` *(done 2026-04-29 in Hetzner console)*
- [ ] Confirm IPv6 primary address (first usable in `2a01:4ff:1f0:b9be::/64`)
- [ ] Confirm Ubuntu 24.04 LTS is the OS image *(rebuild if not)*
- [ ] Hetzner backups: leave **DISABLED** *(decision recorded — Restic + R2 covers it)*

### Cloudflare DNS *(can run before SSH setup; harmless)*
- [ ] Add A record `lidi.studio` → `5.78.177.39` · proxy ON (orange)
- [ ] Add AAAA record `lidi.studio` → primary IPv6 · proxy ON
- [ ] Add CNAME `www` → `lidi.studio` · proxy ON
- [ ] Add A record `status.lidi.studio` → `5.78.177.39` · proxy OFF (grey, DNS-only)
- [ ] Add AAAA record `status.lidi.studio` → primary IPv6 · proxy OFF
- [ ] Verify SSL/TLS mode set to "Full (strict)" once Caddy issues certs

### SSH hardening
- [ ] Generate Ed25519 keypair on local machine *(if not already)*
- [ ] Add public key to server via Hetzner console (cloud-init) or initial root SSH
- [ ] First login as root, confirm key works
- [ ] Create non-root user `lidi` with sudo
- [ ] Copy `authorized_keys` from root to `lidi`
- [ ] Edit `/etc/ssh/sshd_config`:
  - [ ] `Port 2222` *(or chosen custom port)*
  - [ ] `PermitRootLogin no`
  - [ ] `PasswordAuthentication no`
  - [ ] `PubkeyAuthentication yes`
  - [ ] `AllowUsers lidi`
- [ ] `sudo systemctl restart ssh`
- [ ] Verify `ssh -p 2222 lidi@5.78.177.39` works
- [ ] Verify root SSH is rejected
- [ ] Verify password SSH is rejected

### System hardening
- [ ] `apt update && apt upgrade -y`
- [ ] Install `unattended-upgrades` and configure to apply security updates
- [ ] Install `fail2ban`, enable SSH jail (custom port-aware)
- [ ] Configure UFW:
  - [ ] `ufw default deny incoming`
  - [ ] `ufw default allow outgoing`
  - [ ] `ufw allow 2222/tcp` *(custom SSH port)*
  - [ ] `ufw allow 80/tcp`
  - [ ] `ufw allow 443/tcp`
  - [ ] `ufw enable`
- [ ] Set timezone: `timedatectl set-timezone America/Anchorage`
- [ ] Configure `auditd` for sudo logging *(optional, hardening squad task)*

### Docker
- [ ] Install Docker Engine via official repo
- [ ] Install Docker Compose v2 plugin
- [ ] Add `lidi` to `docker` group
- [ ] Verify `docker compose version` works

### Hetzner Cloud Firewall *(layer 2 of defense, in addition to UFW)*
- [ ] Create firewall in Hetzner console named `lucena-prod`
- [ ] Inbound rules:
  - [ ] Port 2222/tcp from `<your-home-IP>/32` (and any other authorized admin IPs)
  - [ ] Port 80/tcp + 443/tcp from Cloudflare IP ranges (auto-update via cron from `https://www.cloudflare.com/ips-v4`)
- [ ] Attach firewall to server `lucena-prod`

### Smoke tests
- [ ] `curl -I https://lidi.studio` — expect 200/308 once Astro is deployed
- [ ] `curl -I https://status.lidi.studio` — expect 200 once Uptime Kuma is up
- [ ] SSH from outside Cloudflare-allowed IPs is **denied** *(verify firewall works)*
- [ ] SSH on port 22 is **denied** *(custom port only)*
- [ ] Root SSH is **denied** even with valid key

---

## Operator notes / observations

*Add timestamped notes here as the server's operational state evolves. Format: `## YYYY-MM-DD — short title`.*

### 2026-04-29 — Initial inventory
Server discovered already-provisioned in Hetzner account, currently named `openclaw-milbot`, idle. Decision recorded in ADR-002 to adopt rather than provision new. No services deployed yet. Bare Ubuntu (presumed). Pending all setup tasks above.

---

## See also

- [`/docs/platform-architecture-v1.md`](../docs/platform-architecture-v1.md) — full architecture (v1.1)
- [`/docs/decisions/server-decision.md`](../docs/decisions/server-decision.md) — ADR-002, rationale for this server choice
- [`/.env.example`](../.env.example) — `HETZNER_HOST`, `HETZNER_SSH_PORT`, `HETZNER_SSH_USER` will be set to this server's values once SSH is configured
- Hetzner Cloud Console: https://console.hetzner.cloud/
