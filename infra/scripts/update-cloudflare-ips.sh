#!/bin/bash
# Lidi Studio — Cloudflare IP refresher
# Fetches the current Cloudflare edge IP ranges and writes them to a
# local file for the operator (or a future hcloud-CLI automation) to
# apply to the Hetzner Cloud Firewall.
#
# Run weekly via cron (root):
#   0 4 * * 0 /opt/lidi/infra/scripts/update-cloudflare-ips.sh > /var/log/lidi/cf-update.log 2>&1

set -euo pipefail

OUT_DIR="/var/lib/lidi/cloudflare-ips"
mkdir -p "$OUT_DIR"

CF_V4=$(curl -fsSL --max-time 30 https://www.cloudflare.com/ips-v4)
CF_V6=$(curl -fsSL --max-time 30 https://www.cloudflare.com/ips-v6)

V4_COUNT=$(echo "$CF_V4" | wc -l | tr -d ' ')
V6_COUNT=$(echo "$CF_V6" | wc -l | tr -d ' ')

echo "$(date -u +"%Y-%m-%dT%H:%M:%SZ")  Cloudflare IPv4 ranges: $V4_COUNT  ·  IPv6 ranges: $V6_COUNT"

# Write to disk (atomic via temp file)
echo "$CF_V4" > "$OUT_DIR/ips-v4.txt.tmp" && mv "$OUT_DIR/ips-v4.txt.tmp" "$OUT_DIR/ips-v4.txt"
echo "$CF_V6" > "$OUT_DIR/ips-v6.txt.tmp" && mv "$OUT_DIR/ips-v6.txt.tmp" "$OUT_DIR/ips-v6.txt"

echo "Wrote: $OUT_DIR/ips-v4.txt"
echo "Wrote: $OUT_DIR/ips-v6.txt"

# TODO: when hcloud CLI is installed and authenticated on the host, push
# these ranges to the Hetzner Cloud Firewall named lidi-studio-prod via:
#
#   hcloud firewall update <firewall-id> --rules-file <(jq -n \
#     --arg v4 "$CF_V4" --arg v6 "$CF_V6" \
#     '{rules: [
#        {direction: "in", protocol: "tcp", port: "80",
#         source_ips: (($v4|split("\n")) + ($v6|split("\n")))},
#        {direction: "in", protocol: "tcp", port: "443",
#         source_ips: (($v4|split("\n")) + ($v6|split("\n")))}
#      ]}')
#
# Until that automation is in place, the operator updates rules manually
# in the Hetzner Console after each weekly refresh, using the contents
# of $OUT_DIR/ips-v4.txt and ips-v6.txt as the allowed source list.

exit 0
