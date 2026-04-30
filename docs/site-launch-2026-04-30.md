# Site launch — Lidi Studio v1
**Date:** 2026-04-30
**Operator:** Renoir
**Build window:** ~2h30 (under the 4h budget)

---

## 1. Status final

The Lidi Studio homepage is live in production at **https://lidi.studio/**.
The "Coming Soon" placeholder has been replaced by the full nine-section
site (nav · hero · manifesto · commissions · archive · about · journal ·
newsletter · footer). `https://www.lidi.studio/` redirects 301 → apex.

### Lighthouse (mobile audit, 2026-04-30)

| Category | Score | Target | Status |
|---|---|---|---|
| Performance | **91** | > 85 | ✅ |
| Accessibility | **96** | > 90 | ✅ |
| Best Practices | **100** | > 90 | ✅ |
| SEO | **92** | > 95 | ⚠ 3 pts under |

The SEO miss is not in our code — Cloudflare injects a non-standard
`Content-Signal: search=yes,ai-train=no` directive into `robots.txt`
(part of their AI bot scrape protection), which Lighthouse flags as
"Unknown directive". Decision: keep the bot blocking — 3 Lighthouse
points are worth less than denying GPTBot/ClaudeBot/CCBot/etc.
training rights. To verify: `curl -sS https://lidi.studio/robots.txt`.

### What ships

- **Hero** with `hero-angel-wings` AVIF, animated entrance
- **Manifesto** "Painted, not posed" — full body copy
- **Commissions** I–V: Hearth · Becoming · First Light · Mothering · Triptych
- **Archive** quote block from a recent sitting
- **About** bio + landscape painting credit
- **Journal** placeholder cards (3) — populate from Ghost when fixed
- **Newsletter** subscribe form (currently visual-only)
- **Footer** with mailto + status subdomain + brand mark

### Page weight

- HTML: 48,921 bytes (~49 KB)
- 16 photos in 3 formats each (5.09 MB → JPEG 1.60 MB / WebP 0.88 MB / AVIF 0.83 MB)
- Total volume on disk: 3.5 MB across 53 files
- 11 `<picture>` elements with AVIF → WebP → JPEG fallback chain

---

## 2. Stack atual (deploy topology)

```
GitHub repo (renoirlucena/lidi-studio)
        │
        │   manual rsync (today) or
        │   GitHub Actions (when SSH_PRIVATE_KEY secret is set)
        ▼
lucena-prod /tmp/lidi-site/
        │
        │   docker run --rm alpine cp -r /source /dist
        ▼
Docker named volume: infra_astro_dist
        │
        │   mounted read-only at /srv/astro
        ▼
lidi-caddy container
        │
        │   serves static + handles TLS
        ▼
Cloudflare (proxy + cache + AI-bot block)
        │
        ▼
   https://lidi.studio/
```

**No build step on the server.** The site is shipped as already-rendered
HTML + pre-optimized image variants. The Astro app under `/apps/web/`
is not running yet — the named volume that would carry an Astro build
artifact is being used as a static-file mount for the hand-built
HTML in `sites/lidi-studio/`. When Astro is ready, the volume's
content gets replaced and the Caddyfile config does not change.

**Why HTML, not Astro:** The 4-hour delivery window did not have room
for an Astro app + CMS pipeline. Static HTML gets to market today and
keeps every architectural option open for later.

---

## 3. Próximos marcos — gatilhos para activar componentes pausados

These are not on a calendar. They activate when reality demands it.

### Gatilho A — primeira sessão real confirmada

**Action:** activate Cal.com booking.

Today the commission CTAs are `mailto:lidi@lidi.studio?subject=...` —
which is correct for a studio that still triages every booking by hand.
Switch to Cal.com only when:
- Lidi has confirmed her studio policy (slots/durations/buffers)
- Inquiries by mail are happening often enough that mail triage
  becomes friction instead of intimacy

**Before flipping the switch:** fix the `DATABASE_DIRECT_URL` env var
in `infra/docker-compose.yml` (calcom is currently restart-looping for
this reason — see commit `baf0016` next-steps). After Cal.com is up,
swap the 4 commission CTAs and the Triptych CTA from `mailto:` to
embedded `cal.com/lidi-studio/<event>` flows.

### Gatilho B — primeira newsletter para sair

**Action:** activate Brevo SMTP and wire the form.

Today the newsletter form has `onsubmit="...textContent='Thank you'"`
— it shows confirmation but **does not actually subscribe anyone**.
This is documented inline as `<!-- REVIEW -->` in `src/index.html`.

Before sending the first letter:
1. Configure Brevo SMTP in `/opt/shared/.env` (`SMTP_HOST`,
   `SMTP_USER`, `SMTP_PASSWORD`, `SMTP_FROM`).
2. Pick a list provider (Brevo lists are fine; Mailchimp / Buttondown
   are alternatives).
3. Replace the form's `onsubmit` with a `fetch()` POST to whichever
   endpoint, or change `<form action>` to `mailto:` as an interim.

**Risk if launched before this is wired:** every "subscriber" is lost.
Subscribers seeing "Thank you" assume they are on the list and will
not retry.

### Gatilho C — primeiro post de blog escrito

**Action:** activate Ghost.

Today the journal section has 3 placeholder cards with sample titles
and dates (`On Composing a Sitting in Three Acts`, etc.).

Before writing the first real post:
1. Fix Ghost's broken Postgres driver (the official `ghost:5-alpine`
   image does not include the `pg` Node module). Three options,
   in order of preference:
   - **Switch to MySQL** (Ghost's officially supported DB) — add a
     `mysql:8` service to the compose, point Ghost at it.
   - **Switch to SQLite** — single file, no extra service. Loses
     scalability but Ghost-on-SQLite works fine for a personal blog.
   - **Custom Dockerfile** that does `RUN su-exec node yarn add pg`
     on top of `ghost:5-alpine`. Most fragile; resists upgrades.
2. Wire Caddy's `/journal*` route (already configured in
   `infra/caddy/sites/lidi-studio.caddy` line ~25) to a healthy
   ghost container.
3. Replace the 3 placeholder journal cards in `src/index.html`
   with real Ghost posts (or rewrite the journal section to fetch
   them at request time via Caddy reverse proxy).

---

## 4. Backup do .env — STATUS: ⚠ MISSING LOCALLY

Earlier in this work, two files were created to back up the rotated
production secrets:

- `./lucena-prod.env.backup` (current production .env, mirror)
- `./lucena-prod.env.rotated-2026-04-30` (snapshot of the old
  pre-rotation .env, kept as audit trail)

**As of 2026-04-30, neither file exists on disk locally.**
Verified with:

```
ls /Users/lucena/coding/projects/lidianelucena/lucena-prod.env.* 2>&1
# → no matches found
```

The `.gitignore` (line 124) covers them via `lucena-prod.env.*`, so
they were never committed — that part is fine. **But this means the
only copy of the production secrets is on the server at
`/opt/shared/.env` (600, lidi:lidi).**

Action required from operator:
1. **Confirm whether the .env was moved to a password manager.**
   If yes, no further action needed.
2. If it was deleted accidentally, pull a fresh local copy:
   ```
   scp lucena-prod:/opt/shared/.env ./lucena-prod.env.backup
   chmod 600 ./lucena-prod.env.backup
   ```
   Then store the contents in 1Password / Bitwarden / whatever
   vault you use.
3. Either way: schedule the Restic-to-R2 backup (`RESTIC_REPOSITORY`
   placeholder in `.env`) so this never depends on local disk again.

---

## 5. Como redesployar manualmente (sem GitHub Actions)

This is the procedure used for the 2026-04-30 launch and is still
the fallback path until the CI workflow is enabled.

```bash
# From repo root
cd sites/lidi-studio

# Build (regenerate dist/ from sources)
mkdir -p dist
cp -r public/* dist/
cp src/index.html dist/

# Optional: re-optimize images if you replaced anything in public/photos/
# (skip this if no photo changes — the existing AVIF/WebP variants
#  in the repo are already optimized)
# npm install --no-save sharp
# node scripts/optimize-images.mjs

# Stage to server
rsync -avz --delete -e "ssh -p 2222" \
  dist/ \
  lidi@5.78.177.39:/tmp/lidi-site/

# Replace the named volume contents via a helper alpine container
ssh lucena-prod "
  docker run --rm \
    -v infra_astro_dist:/dist \
    -v /tmp/lidi-site:/source:ro \
    alpine sh -c 'rm -rf /dist/* && cp -r /source/. /dist/'
"

# Verify
curl -sS -o /dev/null -w 'HTTP %{http_code} | %{size_download}b\n' https://lidi.studio/
```

Caddy serves the volume read-only and does not need a reload — file
changes in the volume are visible to Caddy immediately on the next
request.

**Rollback:** the previous content lives in the rsync `--delete`'d
state, so there is no rollback unless you keep a snapshot. The pragmatic
fallback is `git checkout <prev commit> -- sites/lidi-studio/` and
re-running the procedure.

---

## 6. Como ativar o GitHub Actions deploy

The workflow file already exists locally at
`.github/workflows/deploy-site.yml` (untracked — intentionally kept
out of the launch commit until the secret is in place).

### One-shot activation

```bash
# 1. Add the deploy key as a repo secret
#    Settings → Secrets and variables → Actions → New repository secret
#    Name:  SSH_PRIVATE_KEY
#    Value: full contents of ~/.ssh/lucena_prod (the PRIVATE key — not the .pub)

# 2. Commit and push the workflow
git add .github/workflows/deploy-site.yml
git commit -m "ci: enable lidi-studio deploy workflow"
git push origin main

# 3. The next push that touches sites/lidi-studio/** will fire the
#    workflow automatically. To run it once on the current main as
#    a smoke test:
#    Actions tab → "Deploy lidi-studio site" → Run workflow → main
```

### What the workflow does

Triggers on `push` to `main` for paths under `sites/lidi-studio/**`
or the workflow file itself, plus manual `workflow_dispatch`.
Concurrency-limited so consecutive pushes cancel in-flight runs.

Steps:
1. Checkout
2. Setup Node 20
3. Install `sharp` for image optimization
4. Build `dist/` — re-optimize photos only if AVIF variants are missing
5. Setup ssh-agent with `SSH_PRIVATE_KEY`
6. Add server to `known_hosts` via `ssh-keyscan`
7. rsync `dist/` to `lidi@5.78.177.39:/tmp/lidi-site/`
8. Run helper alpine to copy into the named volume
9. Verify HTTPS 200

### Failure modes to expect

- **First run after enabling will fail** if you push the workflow
  before adding the secret — that is harmless and self-clearing.
- **`ssh-keyscan` failures** if Hetzner Cloud Firewall is reattached
  with stricter rules. Not a problem today (firewall removed during
  the rotation episode), but if you re-add the firewall to lock down
  port 2222, allowlist GitHub Actions IP ranges or pin a self-hosted
  runner.
- **Sharp install timeout** if Node 25 ever ends up in `actions/setup-node`
  defaults — the workflow pins Node 20 explicitly to avoid that.

### When to deprecate manual deploys

After the first three workflow-driven deploys land cleanly, delete or
archive the manual procedure in §5. Until then, keep both — the manual
path is the lifeline if CI breaks during a critical content update.

---

## Provenance

- Site source: `mockups/claude-web/lidi-studio-homepage.html` (1,128 lines)
  → adapted to `sites/lidi-studio/src/index.html`
- Copy audit: `sites/lidi-studio/COPY-AUDIT.md` — 11 inline `<!-- REVIEW -->`
  markers in the HTML, mirrored as a structured table
- Lighthouse JSON: `/tmp/lighthouse.json` (581 KB; not committed)
- Launch commit: `baf0016` `feat(sites): lidi-studio production site v1`
- Previous: `fdd4177` (gitignore broaden), `349a80b` (setup-server fixes)
