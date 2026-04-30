#!/bin/bash
# Lidi Studio — server bootstrap
# RUN AS ROOT ONCE on a fresh Ubuntu 22.04 LTS or newer Hetzner CPX21.
# Idempotent: safe to re-run.
#
# Configurable via env:
#   SSH_PORT  (default: 2222)
#   LIDI_USER (default: lidi)
#
# After this script completes, follow the post-setup checklist printed
# at the end. Reference: /infra/server-info.md "First-time setup checklist".

set -euo pipefail

if [ "$EUID" -ne 0 ]; then
  echo "Run as root: sudo bash $0"
  exit 1
fi

SSH_PORT="${SSH_PORT:-2222}"
LIDI_USER="${LIDI_USER:-lidi}"
HOSTNAME_TARGET="${HOSTNAME_TARGET:-lucena-prod}"

step() {
  echo ""
  echo "=== $1 ==="
}

# ──────────────── 1. Update system ────────────────
step "1. Update system"
apt-get update
DEBIAN_FRONTEND=noninteractive apt-get upgrade -y

# ──────────────── 1.5. Set hostname ────────────────
step "1.5. Set hostname → $HOSTNAME_TARGET"
hostnamectl set-hostname "$HOSTNAME_TARGET"
# Ensure /etc/hosts maps the new hostname to localhost (avoids sudo warnings)
if ! grep -qE "127\.0\.1\.1[[:space:]]+$HOSTNAME_TARGET" /etc/hosts; then
  sed -i.bak '/^127\.0\.1\.1/d' /etc/hosts
  echo "127.0.1.1 $HOSTNAME_TARGET" >> /etc/hosts
fi

# ──────────────── 2. Install required packages ────────────────
step "2. Install required packages"
DEBIAN_FRONTEND=noninteractive apt-get install -y \
  ufw fail2ban unattended-upgrades \
  curl jq git rsync restic \
  ca-certificates gnupg lsb-release \
  iproute2

# ──────────────── 3. Create lidi user ────────────────
step "3. Create lidi user"
if ! id "$LIDI_USER" &>/dev/null; then
  adduser --disabled-password --gecos "" "$LIDI_USER"
  usermod -aG sudo "$LIDI_USER"
  echo "Created user: $LIDI_USER"
else
  echo "User $LIDI_USER already exists, skipping"
fi

# Mirror authorized_keys from root if present
mkdir -p "/home/$LIDI_USER/.ssh"
if [ -f /root/.ssh/authorized_keys ]; then
  cp /root/.ssh/authorized_keys "/home/$LIDI_USER/.ssh/"
  chown -R "$LIDI_USER:$LIDI_USER" "/home/$LIDI_USER/.ssh"
  chmod 700 "/home/$LIDI_USER/.ssh"
  chmod 600 "/home/$LIDI_USER/.ssh/authorized_keys"
fi

# (a) Validate authorized_keys is non-empty before any SSH hardening.
# An empty file would silently lock us out after the sshd restart below.
if [ ! -s "/home/$LIDI_USER/.ssh/authorized_keys" ]; then
  echo "FATAL: /home/$LIDI_USER/.ssh/authorized_keys is missing or empty."
  echo "Refusing to harden SSH — would lock out all access."
  exit 1
fi
echo "✓ authorized_keys present and non-empty for $LIDI_USER"

# ──────────────── 4. Configure UFW ────────────────
# (b) UFW configured BEFORE sshd restart so port $SSH_PORT is allowed
# the moment sshd starts listening on it.
step "4. Configure UFW"
ufw --force reset
ufw default deny incoming
ufw default allow outgoing
ufw allow "$SSH_PORT/tcp"
ufw allow 80/tcp
ufw allow 443/tcp
ufw --force enable

# ──────────────── 5. Harden SSH ────────────────
step "5. Harden SSH"
cat > /etc/ssh/sshd_config.d/99-lidi.conf <<EOF
Port $SSH_PORT
PermitRootLogin no
PasswordAuthentication no
PubkeyAuthentication yes
AllowUsers $LIDI_USER
EOF

# (c) Validate sshd config syntax BEFORE restart.
# A broken config + restart = no more SSH access.
if ! sshd -t; then
  echo "FATAL: sshd config invalid. Aborting before restart."
  exit 1
fi
echo "✓ sshd config syntax OK"

systemctl restart ssh

# (e) Verify sshd is actually listening on the new port after restart.
# If this check fails, the current root session (port 22) is still alive
# so the operator has a chance to recover before disconnecting.
sleep 2
if ! ss -tlnp 2>/dev/null | grep -q ":$SSH_PORT "; then
  echo "FATAL: sshd is NOT listening on port $SSH_PORT after restart."
  echo "Investigate via: journalctl -u ssh -n 50"
  exit 1
fi
echo "✓ sshd is listening on port $SSH_PORT"

# ──────────────── 6. Configure fail2ban ────────────────
step "6. Configure fail2ban"
cat > /etc/fail2ban/jail.local <<EOF
[sshd]
enabled = true
port = $SSH_PORT
maxretry = 3
bantime = 1h
findtime = 10m
EOF
systemctl restart fail2ban
systemctl enable fail2ban

# ──────────────── 7. unattended-upgrades ────────────────
step "7. unattended-upgrades"
echo 'Unattended-Upgrade::Automatic-Reboot "false";' \
  > /etc/apt/apt.conf.d/52unattended-upgrades-local
dpkg-reconfigure --priority=low unattended-upgrades

# ──────────────── 8. Set timezone ────────────────
step "8. Timezone"
timedatectl set-timezone America/Anchorage

# ──────────────── 9. Install Docker ────────────────
step "9. Install Docker"
if ! command -v docker &>/dev/null; then
  install -m 0755 -d /etc/apt/keyrings
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg \
    | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
  chmod a+r /etc/apt/keyrings/docker.gpg
  echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" \
    > /etc/apt/sources.list.d/docker.list
  apt-get update
  apt-get install -y \
    docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
fi
usermod -aG docker "$LIDI_USER"

# ──────────────── 10. Create app directories ────────────────
# (d) Multi-tenant ready paths (matches ADR-003):
#   /opt/shared — shared infra (compose, scripts, .env)
#   /opt/sites  — per-tenant static/app artifacts (e.g. /opt/sites/lidi-studio/dist)
step "10. Create app directories"
mkdir -p /opt/shared /opt/sites /var/log/lidi /var/lib/lidi
chown -R "$LIDI_USER:$LIDI_USER" /opt/shared /opt/sites /var/log/lidi /var/lib/lidi

# ──────────────── Done ────────────────
echo ""
echo "═══════════════════════════════════════════"
echo "  ✅ Server setup complete"
echo "═══════════════════════════════════════════"
echo ""
echo "Next steps:"
echo "  1. Verify SSH on port $SSH_PORT works for user $LIDI_USER:"
echo "     ssh -p $SSH_PORT $LIDI_USER@<server-ip>"
echo "  2. Disable any open root SSH session"
echo "  3. Clone repo to /opt/shared:"
echo "     su - $LIDI_USER"
echo "     cd /opt/shared && git clone https://github.com/renoirlucena/lidi-studio.git ."
echo "  4. Create /opt/shared/.env from .env.example, fill in real values"
echo "  5. Bring stack up:"
echo "     cd /opt/shared/infra && docker compose up -d"
echo "  6. Configure Hetzner Cloud Firewall (Cloudflare IPs only on 80/443)"
echo "  7. Configure Cloudflare DNS records (see /infra/server-info.md)"
echo ""
