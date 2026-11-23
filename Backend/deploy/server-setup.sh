#!/usr/bin/env bash
# One-time server preparation. Runs ON the server (deploy.sh invokes it).
# Installs Docker, Nginx and Certbot, enables the site and issues SSL.
# Safe to re-run: every step checks whether it is already done.
set -euo pipefail

DOMAIN="${1:?usage: server-setup.sh <domain> <email>}"
EMAIL="${2:?usage: server-setup.sh <domain> <email>}"
APP_DIR=/opt/mikka

export DEBIAN_FRONTEND=noninteractive

if ! command -v docker >/dev/null 2>&1; then
  echo ">> Docker o'rnatilmoqda..."
  curl -fsSL https://get.docker.com | sh
  systemctl enable --now docker
fi

if ! command -v nginx >/dev/null 2>&1; then
  echo ">> Nginx o'rnatilmoqda..."
  apt-get update -y
  apt-get install -y nginx
  systemctl enable --now nginx
fi

if ! command -v certbot >/dev/null 2>&1; then
  echo ">> Certbot o'rnatilmoqda..."
  apt-get update -y
  apt-get install -y certbot python3-certbot-nginx
fi

# Open HTTP/HTTPS only if ufw is active — never touch other rules
# (e.g. coturn ports) that may already exist on this server.
if command -v ufw >/dev/null 2>&1 && ufw status | grep -q "Status: active"; then
  ufw allow 80/tcp
  ufw allow 443/tcp
fi

echo ">> Nginx sayt konfiguratsiyasi: $DOMAIN"
sed "s/__DOMAIN__/$DOMAIN/g" "$APP_DIR/deploy/nginx/mikka.conf" \
  > /etc/nginx/sites-available/mikka.conf
ln -sf /etc/nginx/sites-available/mikka.conf /etc/nginx/sites-enabled/mikka.conf

# certbot rewrites the file to add SSL — keep its version if already issued.
if [ -d "/etc/letsencrypt/live/$DOMAIN" ]; then
  certbot install --nginx -d "$DOMAIN" --cert-name "$DOMAIN" --non-interactive --redirect || true
fi

nginx -t
systemctl reload nginx

if [ ! -d "/etc/letsencrypt/live/$DOMAIN" ]; then
  echo ">> SSL sertifikat olinmoqda..."
  certbot --nginx -d "$DOMAIN" -m "$EMAIL" --agree-tos --non-interactive --redirect
fi

echo ">> Server tayyor."
