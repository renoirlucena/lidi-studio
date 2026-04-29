# Lidi Studio — Infrastructure

Self-hosted Docker Compose stack for `lidi.studio`. Runs on a single Hetzner CPX21 in Hillsboro, OR.

> **Authoritative reference:** [`/docs/platform-architecture-v1.md`](../docs/platform-architecture-v1.md) (v1.1) is the source of truth for stack rationale, RAM budget (§2.17), routing map (§3), security posture (§9), and deployment workflow (§10). This README is a hands-on operator's guide; it does not duplicate architecture decisions.
>
> **Server fact sheet:** [`/infra/server-info.md`](server-info.md) — IPs, plan, setup checklist.

---

## Contents

```
infra/
├── docker-compose.yml              # production stack (10 services)
├── docker-compose.dev.yml          # local-development override
├── caddy/
│   ├── Caddyfile                   # main routing for lidi.studio
│   ├── Caddyfile.status            # status.lidi.studio (separate site)
│   └── error-pages/
│       ├── 404.html                # Sargent Luminous, restrained
│       └── 5xx.html
├── postgres/
│   ├── init-databases.sh           # creates 5 logical DBs on first boot
│   └── postgresql.conf             # tuning for shared 4 GB host
├── scripts/
│   ├── setup-server.sh             # idempotent Ubuntu 24.04 bootstrap
│   ├── backup.sh                   # nightly Restic + R2 + Postgres dumps
│   ├── restore.sh                  # snapshot recovery, --apply confirmation
│   ├── health-check.sh             # post-deploy smoke tests
│   └── update-cloudflare-ips.sh    # weekly CF range refresh
├── monitoring/
│   └── uptime-kuma-monitors.json   # importable into Uptime Kuma admin UI
├── server-info.md                  # operational fact sheet
└── README.md                       # this file
```

---

## Prerequisites

| Tool | Version | Notes |
|---|---|---|
| Docker Engine | 27+ | with Compose v2 plugin |
| Docker Compose | v2.29+ | bundled `docker compose` (not `docker-compose`) |
| Restic | 0.16+ | for backups (host-installed, not containerized) |
| `curl`, `jq`, `rsync` | any recent | host-installed |
| `/opt/lidi/.env` | populated | copy from `/.env.example`, fill values |

The `setup-server.sh` script installs all of the above on a fresh Hetzner CPX21.

---

## Initial setup *(fresh server)*

```bash
# 1. As root on the freshly-provisioned Hetzner CPX21:
sudo bash infra/scripts/setup-server.sh
# Installs Docker, hardens SSH, configures UFW + fail2ban, creates `lidi` user

# 2. As the lidi user:
sudo su - lidi
git clone https://github.com/renoirlucena/lidi-studio.git /opt/lidi
cd /opt/lidi

# 3. Create and fill the env file (NEVER commit .env)
cp .env.example .env
chmod 600 .env
$EDITOR .env

# 4. Bring the stack up
cd infra
docker compose up -d

# 5. Verify
./scripts/health-check.sh
```

---

## Common commands

### Production

```bash
cd /opt/lidi/infra

# bring everything up
docker compose up -d

# bring everything down (keeps volumes)
docker compose down

# restart a single service
docker compose restart ghost

# tail logs for a service
docker compose logs -f calcom

# pull latest images and roll the stack
docker compose pull && docker compose up -d --remove-orphans

# show running services and health
docker compose ps

# enter a running container
docker compose exec ghost sh

# rebuild a service from source (when apps/web exists)
docker compose build astro-api
docker compose up -d astro-api
```

### Local development

```bash
# from repo root, dev override exposes ports for direct access
docker compose -f infra/docker-compose.yml -f infra/docker-compose.dev.yml up -d

# Direct access to:
#   Ghost      → localhost:2368
#   Cal.com    → localhost:3001
#   DocuSeal   → localhost:3002
#   NocoDB     → localhost:8080
#   Umami      → localhost:3003
#   Uptime Kuma→ localhost:3004
#   Postgres   → localhost:5432
#   Redis      → localhost:6379
#
# (Caddy and astro-api are disabled in dev — run `pnpm dev` from /apps/web instead)
```

---

## Backup and restore

### Manual backup
```bash
sudo /opt/lidi/infra/scripts/backup.sh
```

### Scheduled backup *(nightly at 03:00 America/Anchorage)*
Add to root crontab via `sudo crontab -e`:
```cron
0 3 * * *  /opt/lidi/infra/scripts/backup.sh
0 4 * * 0  /opt/lidi/infra/scripts/update-cloudflare-ips.sh > /var/log/lidi/cf-update.log 2>&1
```

### Inspect a snapshot without restoring *(safe dry-run)*
```bash
sudo /opt/lidi/infra/scripts/restore.sh --snapshot latest
# → extracts to /tmp/lidi-restore for inspection
```

### Restore a snapshot in place *(destructive)*
```bash
sudo /opt/lidi/infra/scripts/restore.sh --snapshot <id> --apply
# Stops the stack, overwrites volumes, restores Postgres dumps, brings stack back up.
# Will prompt for "yes" confirmation before proceeding.
```

### Annual restore drill
Spin up a temporary CX11, run `restore.sh` against it, verify the site comes up, document RTO. Untested backups don't count.

---

## Adding a new service

1. Add a service block to `docker-compose.yml`, following the existing template:
   - `restart: unless-stopped`
   - `mem_limit:` and `mem_reservation:` (always set both)
   - `healthcheck:` that validates real functionality, not just TCP open
   - `networks: [lidi-net]`
   - `depends_on:` with `condition: service_healthy` where applicable
2. If it serves HTTP, add a route in `caddy/Caddyfile`. Use `handle_path /prefix*` if the upstream expects to be at the root, or `handle /prefix*` if the upstream expects the prefix preserved.
3. If it stores state, add a named volume to the `volumes:` section at the bottom.
4. If it needs a Postgres database, add it to `postgres/init-databases.sh` and the corresponding `POSTGRES_DB_*` env var.
5. Update the RAM budget summary comment at the bottom of `docker-compose.yml` and the table in [`/docs/platform-architecture-v1.md`](../docs/platform-architecture-v1.md) §2.17.

---

## Troubleshooting

### Postgres won't start
- **Check volume permissions:** `docker volume inspect infra_postgres_data` — should be owned by the postgres UID inside the container.
- **First-boot init script:** `init-databases.sh` only runs when `/var/lib/postgresql/data` is empty. If you're seeing "database already exists" on first boot, the volume already has data — either mount fresh, or comment-out lines in the init script.
- **Memory limits:** if Postgres OOMs, check `mem_limit` in compose vs `shared_buffers` in `postgresql.conf` (currently 96 MB out of 350 MB budget — well within).

### Caddy can't get a TLS certificate
- **DNS not propagated:** `dig lidi.studio` should return the Hetzner IP. Cloudflare DNS can take up to 5 minutes.
- **Cloudflare proxy mode:** must be set to "Full (strict)" in Cloudflare SSL/TLS settings *after* Caddy issues the first cert.
- **Port 80 reachable:** Let's Encrypt's HTTP-01 challenge requires port 80 reachable from the internet. Verify UFW + Hetzner Cloud Firewall both allow it.
- **Logs:** `docker compose logs caddy | grep -i 'cert\|error'`

### Cal.com OOM on startup
- **Slow cold start:** Cal.com (Next.js) needs ~120s to boot the first time. The compose `start_period: 120s` accommodates this. If still OOMing, raise `mem_limit` to 1G temporarily.
- **Database connection:** check `DATABASE_URL` resolves; Cal.com's first boot runs migrations and is heavier than steady-state.

### Ghost reset password *(operator forgot password)*
```bash
docker compose exec ghost ghost user list
docker compose exec ghost ghost reset-password --user <email>
```

### View structured access logs
```bash
docker compose exec caddy tail -f /var/log/caddy/access.log
# Logs are JSON; pipe through jq for readability:
docker compose exec caddy tail -f /var/log/caddy/access.log | jq '.request.uri, .status'
```

### Container health failing but service responds
- The healthcheck command may be misaligned with the service's actual readiness path. Verify: `docker inspect lidi-<service> --format '{{.State.Health.Status}}'` and `docker inspect lidi-<service> --format '{{json .State.Health}}' | jq`.

### Disk full
- Docker reclaim: `docker system prune -af --volumes` *(careful: removes unused volumes)*
- Restic stale repo: `restic forget --keep-daily 30 --keep-monthly 12 --keep-yearly 5 --prune`
- Caddy logs: rotated automatically (100 MB roll, 7 keep), but verify rotation working

---

## Security notes

- `.env` lives at `/opt/lidi/.env` with mode 600, owned by `lidi`. **Never** committed to git.
- Postgres and Redis are NOT exposed on the host network in production — only reachable on the `lidi-net` Docker bridge. The dev override exposes them for local debugging only.
- `/admin` (NocoDB) and `/stats` (Umami) are protected by `basic_auth` at the Caddy layer in addition to the apps' own auth, AND by Hetzner Cloud Firewall IP allowlisting on ports 80/443. Both layers must be configured.
- Restic backups are encrypted client-side; the passphrase lives in `.env`, in 1Password, and in a sealed offline envelope. Losing the passphrase = losing the backups.
- `update-cloudflare-ips.sh` should run weekly to keep the Hetzner Cloud Firewall in sync with Cloudflare's edge ranges. Currently this writes to `/var/lib/lidi/cloudflare-ips/` — operator manually pastes into Hetzner Console until `hcloud` CLI automation is added.
- Hardening playbook: handed off to cybersecurity squad. See [`/docs/platform-architecture-v1.md`](../docs/platform-architecture-v1.md) §9 for the starting baseline.

---

## See also

- [`/docs/platform-architecture-v1.md`](../docs/platform-architecture-v1.md) — full architecture (v1.1)
- [`/docs/decisions/server-decision.md`](../docs/decisions/server-decision.md) — ADR-002, why CPX21
- [`/infra/server-info.md`](server-info.md) — operational fact sheet for `lidi-studio-prod`
- [`/.env.example`](../.env.example) — environment variable template
