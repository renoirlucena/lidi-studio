# Web3Forms Setup — Lidi Studio

The `/en/investment/` inquiry modal posts to [Web3Forms](https://web3forms.com/),
a hosted form-to-email relay. Until the operator wires up a real access key,
the form is a no-op (the placeholder string is rejected by the API).

## One-time setup

1. Visit https://web3forms.com/
2. Enter `lidi@lidi.studio` in the **"Get Access Key"** box.
3. Click **"Create Access Key"**.
4. Confirm the key from the email Web3Forms sends.
5. Copy the access key from the dashboard (format: `a3c5e7g9-1234-...`).
6. Save it in a password manager (you won't get a second copy on a clean session).

## Wire the key into the page

The placeholder lives in **two** spots in `sites/lidi-studio/src/en/investment/index.html`:

```bash
grep -n WEB3FORMS_KEY_PLACEHOLDER sites/lidi-studio/src/en/investment/index.html
# Expect 2 occurrences (the modal form's hidden input + a fallback comment)
```

Replace both with the real key, then rebuild and redeploy:

```bash
cd sites/lidi-studio
node scripts/build.mjs

rsync -avz --delete -e "ssh -p 2222" dist-v2/ \
  lidi@5.78.177.39:/tmp/lidi-site-v6/

ssh lucena-prod "
  docker run --rm -v infra_astro_dist:/dist alpine \
    tar czf - -C /dist . > /tmp/lidi-pre-w3f-\$(date +%Y%m%d-%H%M).tar.gz
  docker run --rm \
    -v infra_astro_dist:/dist \
    -v /tmp/lidi-site-v6:/source:ro \
    alpine sh -c 'rm -rf /dist/* && cp -r /source/. /dist/'
"
```

Verify:

```bash
curl -sS https://lidi.studio/en/investment/ | grep -c WEB3FORMS_KEY_PLACEHOLDER
# Expect 0
```

**Do NOT commit the real key to git.** The placeholder is what's tracked.
If you accidentally commit, rotate the key in the Web3Forms dashboard.

## Limits and behavior

- **Free tier:** 250 submissions / month. Plenty for a new portrait studio.
- **Anti-spam:** hCaptcha appears automatically when traffic looks suspicious;
  the form's hidden `botcheck` input is a honeypot.
- **Email destination:** `lidi@lidi.studio` (set in the Web3Forms account itself,
  not in the HTML — the `email` query param overrides this if you ever need to).
- **Confirmation page:** Web3Forms returns JSON; the modal handles it client-side
  and shows an inline thank-you message without a redirect.

## When you outgrow the free tier

- **$5/mo Pro plan:** lifts the cap to 1,000 submissions/month.
- **Self-hosted:** swap `action="https://api.web3forms.com/submit"` for your own
  Astro/Node API endpoint backed by Brevo SMTP. The astro-api container is
  reserved for this in `infra/docker-compose.yml`.

## Troubleshooting

| Symptom | Likely cause |
|---|---|
| Form submits but no email | Access key wrong, or Web3Forms can't deliver to lidi@lidi.studio (check spam) |
| Form silently fails | JavaScript blocked by browser, or the `access_key` value is the literal placeholder |
| hCaptcha appears every time | IP flagged as suspicious — usually a VPN issue |
| 429 response | Free-tier rate limit hit (50 req/hr per IP) |
