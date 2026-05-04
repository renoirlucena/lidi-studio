# Web3Forms — Operator Next Steps

**Status as of Sprint 5 deploy (2026-05-03):** the inquiry form on
`/en/investment/` renders and validates client-side, but the access key
is the literal placeholder string. Until you do the steps below,
**every form submission silently fails** and a friendly fallback message
asks the visitor to email `lidi@lidi.studio` directly.

This is the single biggest "must-do" before promoting `/en/investment/`
on Instagram or any other channel.

---

## Total time: ~10 minutes

### Step 1 — Create the access key (3 min)

1. Go to https://web3forms.com/
2. In the "Get Access Key" box, enter `lidi@lidi.studio`
3. Click **Create Access Key**
4. Open the email Web3Forms sends and click the confirmation link
5. From the dashboard, copy the access key (looks like `a3c5e7g9-1234-5678-...`)
6. **Save it in a password manager (Bitwarden / 1Password)** — the dashboard
   doesn't show it again on a clean session

### Step 2 — Wire the key into the page (3 min)

The placeholder lives in **2 spots** in
`sites/lidi-studio/src/en/investment/index.html`. Find them with:

```bash
grep -n WEB3FORMS_KEY_PLACEHOLDER sites/lidi-studio/src/en/investment/index.html
# Expect 2 lines: an HTML <input value="..."> and a JS comparison string
```

Open the file in your editor and replace **both** occurrences of
`WEB3FORMS_KEY_PLACEHOLDER` with the real key.

The two lines look like:
- `<input type="hidden" name="access_key" value="WEB3FORMS_KEY_PLACEHOLDER">`
- `if (access === 'WEB3FORMS_KEY_PLACEHOLDER') { ... }` *(the fallback guard — keep it for safety even after you wire the real key, so a future placeholder regression is caught)*

**Don't commit the real key.** If you ever do by accident, rotate the key
in the Web3Forms dashboard immediately.

### Step 3 — Rebuild and redeploy (4 min)

```bash
cd sites/lidi-studio
node scripts/build.mjs

rsync -avz --delete -e "ssh -p 2222" dist-v2/ \
  lidi@5.78.177.39:/tmp/lidi-site-v7/

ssh lucena-prod "
  docker run --rm -v infra_astro_dist:/dist alpine \
    tar czf - -C /dist . > /tmp/lidi-pre-w3f-\$(date +%Y%m%d-%H%M).tar.gz
  docker run --rm -v infra_astro_dist:/dist -v /tmp/lidi-site-v7:/source:ro \
    alpine sh -c 'rm -rf /dist/* && cp -r /source/. /dist/'
"
```

### Step 4 — Verify (under a minute)

```bash
curl -sS https://lidi.studio/en/investment/ | grep -c WEB3FORMS_KEY_PLACEHOLDER
# Expect 0
```

Then open https://lidi.studio/en/investment/ in incognito, click any
"Reserve →" button, fill the form with a test name + your own email, hit
Send. Check that the email lands in `lidi@lidi.studio` within ~30 seconds.

If it doesn't:
- Check spam folder
- Check Web3Forms dashboard "Submissions" tab
- Verify the key matches exactly (no leading/trailing whitespace)

---

## After the key is live

You can update `FOUNDING_SPOTS_REMAINING` (currently `8`) in the same
`investment/index.html` file as bookings come in. It's the number inside
`<span class="investment-strip__count">8</span>`. When it hits 0, swap
the strip copy for "Founding Client tier closed" or similar.

The package highlights inside each `.investment-pkg__highlights` block
are placeholders. Confirm session length, image count, and what's
included with Lidi before promoting publicly. Each package's source has
a `<!-- REVIEW: highlights — confirm with Lidi -->` comment.

---

## Limits

- **Free tier:** 250 submissions/month. Plenty to start.
- **Anti-spam:** hCaptcha kicks in automatically on suspicious traffic;
  the `botcheck` honeypot field blocks naive scrapers.
- **Email destination:** `lidi@lidi.studio`, set in the Web3Forms account.

When you outgrow the free tier (250+ leads/month is a great problem to
have): $5/mo Pro plan lifts the cap to 1,000/month. Or migrate to
self-hosted Brevo SMTP via the `astro-api` container — already reserved
in `infra/docker-compose.yml` for exactly this.

---

## Why this is operator-only

The Web3Forms key is a credential. Putting it in a CI secret would work,
but for a one-person studio it's simpler to keep the key out of git
entirely and replace the placeholder manually. The fallback guard keeps
the form polite when the key is missing, so there's no urgency to
automate this.

See `docs/setup/web3forms.md` for the longer technical reference.
