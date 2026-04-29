#!/bin/bash
# Lidi Studio — multi-tenant onboarding helper
# Drops a skeleton Caddyfile fragment for a new tenant and prints
# the remaining manual steps. See ADR-003 for the multi-tenant design.
#
# Usage:
#   ./add-site.sh <slug> <domain> <prefix>
#
# Example:
#   ./add-site.sh financelock financelock.app fl

set -euo pipefail

SLUG="${1:?Usage: $0 <slug> <domain> <prefix>}"
DOMAIN="${2:?Usage: $0 <slug> <domain> <prefix>}"
PREFIX="${3:?Usage: $0 <slug> <domain> <prefix>}"

# Resolve the sites/ directory relative to this script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SITES_DIR="${SCRIPT_DIR%/scripts}/caddy/sites"

if [ ! -d "$SITES_DIR" ]; then
  echo "Error: sites directory not found at $SITES_DIR"
  exit 1
fi

CADDY_FILE="$SITES_DIR/${SLUG}.caddy"

if [ -e "$CADDY_FILE" ]; then
  echo "Error: $CADDY_FILE already exists. Refusing to overwrite."
  exit 1
fi

echo "Adding site:"
echo "  Slug:             $SLUG"
echo "  Domain:           $DOMAIN"
echo "  Container prefix: ${PREFIX}-"
echo "  Caddy file:       $CADDY_FILE"
echo ""

# Skeleton Caddyfile — minimal but production-shaped.
cat > "$CADDY_FILE" <<EOF
# ${SLUG} — ${DOMAIN}
# Multi-tenant site block. See sites/README.md for convention.

${DOMAIN} {
	header {
		Strict-Transport-Security "max-age=31536000; includeSubDomains"
		X-Content-Type-Options "nosniff"
		X-Frame-Options "DENY"
		Referrer-Policy "strict-origin-when-cross-origin"
		-Server
	}

	# Replace with the upstream container for this site.
	# reverse_proxy ${PREFIX}-app:8080

	log {
		output file /var/log/caddy/${SLUG}.log {
			roll_size 100MB
			roll_keep 7
			roll_keep_for 720h
		}
		format json
	}
}
EOF

echo "Created $CADDY_FILE"
echo ""
cat <<EOF
Next steps:
  1. Edit $CADDY_FILE — uncomment and adjust the reverse_proxy line.
  2. Add the upstream service to /opt/lucena/infra/docker-compose.yml
     using container_name '${PREFIX}-...' and joining the lidi-net network.
  3. If a database is needed, add a logical DB:
        docker exec lidi-postgres psql -U \$POSTGRES_USER -c \\
          'CREATE DATABASE ${SLUG};'
  4. Configure Cloudflare DNS for ${DOMAIN} (orange-clouded A record
     to the server's IPv4 + AAAA to its IPv6).
  5. Bring the new service up:
        docker compose up -d ${PREFIX}-app
  6. Reload Caddy without downtime:
        docker exec lidi-caddy caddy reload --config /etc/caddy/Caddyfile
  7. Smoke-test:
        curl -I https://${DOMAIN}/
EOF
