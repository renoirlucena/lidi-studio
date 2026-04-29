#!/bin/bash
# Lidi Studio — post-deploy smoke tests
# Used by deploy workflow to verify a fresh deploy succeeded.

set -uo pipefail

DOMAIN="${DOMAIN:-lidi.studio}"
EXIT=0
FAIL=()

check() {
  local name="$1"
  local url="$2"
  local expected="${3:-200}"
  local code
  code=$(curl -sS -o /dev/null -w "%{http_code}" --max-time 10 "$url" || echo "000")
  if [ "$code" = "$expected" ] || [ "$code" = "308" ] || [ "$code" = "301" ]; then
    echo "  ✓ $name ($code)"
  else
    echo "  ✗ $name (expected $expected, got $code)"
    FAIL+=("$name=$code")
    EXIT=1
  fi
}

echo "=== Lidi Studio health check ==="
check "Homepage"     "https://$DOMAIN/"
check "Journal"      "https://$DOMAIN/journal"
check "Booking"      "https://$DOMAIN/book"
check "API health"   "https://$DOMAIN/api/healthz"
check "Status page"  "https://status.$DOMAIN/"

echo ""
echo "=== Container status ==="
if [ -f /opt/lidi/infra/docker-compose.yml ]; then
  docker compose -f /opt/lidi/infra/docker-compose.yml ps --format "table {{.Name}}\t{{.Status}}" 2>/dev/null || true
fi

echo ""
if [ "$EXIT" -eq 0 ]; then
  echo "✅ All checks passed"
else
  echo "❌ Failed: ${FAIL[*]}"
fi

exit $EXIT
