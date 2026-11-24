#!/usr/bin/env bash
# One-time server preparation. Runs ON the server (deploy.sh invokes it).
# The server also hosts RoyalVIP, dorixona and kidstv, so everything Mikka
# owns lives in its own folder, mirroring ~/royalvip:
#
#   /home/ubuntu/mikka/
#     backend/        code + docker-compose + .env
#     nginx/mikka.conf  Nginx site (sites-enabled symlinks here)
#     logs/           Nginx access/error logs
#
# Nothing belonging to the other projects is edited. Safe to re-run.
set -euo pipefail

DOMAIN="${1:?usage: server-setup.sh <domain> <email> <port>}"
EMAIL="${2:?usage: server-setup.sh <domain> <email> <port>}"
PORT="${3:?usage: server-setup.sh <domain> <email> <port>}"
ROOT_DIR=/home/ubuntu/mikka
APP_DIR=$ROOT_DIR/backend
SITE=$ROOT_DIR/nginx/mikka.conf
LINK=/etc/nginx/sites-enabled/mikka.conf

export DEBIAN_FRONTEND=noninteractive

# ---- Guards: refuse rather than break the other projects ----
WEB80="$(ss -tlnp 'sport = :80' | awk 'NR>1' || true)"
if [ -n "$WEB80" ] && ! echo "$WEB80" | grep -q nginx; then
  echo "XATO: 80-portni nginx emas, boshqa dastur egallagan:"
  echo "$WEB80"
  exit 1
fi

# Port busy is fine only if it's our own mikka-api container holding it.
PORT_BUSY="$(ss -tlnp "sport = :$PORT" | awk 'NR>1')"
if [ -n "$PORT_BUSY" ] && ! docker ps --format '{{.Names}}' 2>/dev/null | grep -qx mikka-api; then
  echo "XATO: $PORT-port band. Boshqa port tanlang: MIKKA_PORT=<port> ./deploy/deploy.sh"
  echo "$PORT_BUSY"
  exit 1
fi

# ---- Install only what is missing ----
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

# Open HTTP/HTTPS only if ufw is active — existing rules stay untouched.
if command -v ufw >/dev/null 2>&1 && ufw status | grep -q "Status: active"; then
  ufw allow 80/tcp
  ufw allow 443/tcp
fi

# ---- Mikka's own Nginx site file, inside the Mikka folder ----
mkdir -p "$ROOT_DIR/nginx" "$ROOT_DIR/logs"
chown ubuntu:ubuntu "$ROOT_DIR" "$ROOT_DIR/nginx" "$ROOT_DIR/logs"

# Once certbot has issued the cert it owns the file (adds the 443 block),
# so only write the template on the very first run.
if [ ! -f "$SITE" ]; then
  echo ">> Nginx sayt fayli yaratilmoqda: $SITE"
  sed -e "s/__DOMAIN__/$DOMAIN/g" -e "s/__PORT__/$PORT/g" \
    "$APP_DIR/deploy/nginx/mikka.conf" > "$SITE"
else
  # Port may have changed between deploys — update just the upstream line.
  sed -i -E "s#server 127\.0\.0\.1:[0-9]+;#server 127.0.0.1:$PORT;#" "$SITE"
fi
ln -sfn "$SITE" "$LINK"

# Validate the WHOLE config before reloading; on failure, unlink Mikka's
# site so the other projects keep running exactly as before.
if ! nginx -t; then
  echo "XATO: nginx konfiguratsiyasi noto'g'ri — Mikka sayti o'chirildi, boshqa loyihalarga ta'sir qilmadi."
  rm -f "$LINK"
  exit 1
fi
systemctl reload nginx

# certbot with -d only touches the server block for this domain.
if [ ! -d "/etc/letsencrypt/live/$DOMAIN" ]; then
  echo ">> SSL sertifikat olinmoqda: $DOMAIN"
  certbot --nginx -d "$DOMAIN" --cert-name "$DOMAIN" -m "$EMAIL" \
    --agree-tos --non-interactive --redirect
elif ! grep -q "ssl_certificate" "$SITE"; then
  certbot install --nginx -d "$DOMAIN" --cert-name "$DOMAIN" --non-interactive --redirect
fi

echo ">> Server tayyor (Mikka: $ROOT_DIR, port 127.0.0.1:$PORT, nginx: $SITE)."
