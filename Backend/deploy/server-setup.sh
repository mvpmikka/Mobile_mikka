#!/usr/bin/env bash
# One-time server preparation. Runs ON the server (deploy.sh invokes it).
# The server also hosts RoyalVIP, so this script only ADDS Mikka's own
# pieces (its folder, its Nginx site file, its certificate) and never edits
# or reloads anything belonging to the other project. Safe to re-run.
set -euo pipefail

DOMAIN="${1:?usage: server-setup.sh <domain> <email> <port>}"
EMAIL="${2:?usage: server-setup.sh <domain> <email> <port>}"
PORT="${3:?usage: server-setup.sh <domain> <email> <port>}"
APP_DIR=/opt/mikka
SITE=/etc/nginx/sites-available/mikka.conf

export DEBIAN_FRONTEND=noninteractive

# ---- Guards: refuse rather than break the existing project ----
WEB80="$(ss -tlnp 'sport = :80' | awk 'NR>1' || true)"
if [ -n "$WEB80" ] && ! echo "$WEB80" | grep -q nginx; then
  echo "XATO: 80-portni nginx emas, boshqa dastur egallagan:"
  echo "$WEB80"
  echo "RoyalVIP qanday web-server ishlatayotganini aniqlang — skript to'xtatildi."
  exit 1
fi

# Port busy is fine only if it's our own mikka-api container holding it.
PORT_BUSY="$(ss -tln "sport = :$PORT" | awk 'NR>1')"
MIKKA_ON_PORT="$(docker ps --filter name=^mikka-api$ --format '{{.Ports}}' 2>/dev/null | grep -c ":$PORT->" || true)"
if [ -n "$PORT_BUSY" ] && [ "$MIKKA_ON_PORT" = "0" ]; then
  echo "XATO: $PORT-port band. Boshqa port tanlang: MIKKA_PORT=<port> ./deploy/deploy.sh"
  ss -tlnp "sport = :$PORT"
  exit 1
fi

if [ -f /etc/nginx/sites-enabled/mikka.conf ] && ! grep -q "$DOMAIN" /etc/nginx/sites-enabled/mikka.conf; then
  echo "XATO: /etc/nginx/sites-enabled/mikka.conf mavjud, lekin boshqa domen uchun. Tekshiring."
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

# ---- Mikka's own Nginx site file ----
# Once certbot has issued the cert it owns the file (adds the 443 block),
# so only write the template on the very first run.
if [ ! -d "/etc/letsencrypt/live/$DOMAIN" ]; then
  echo ">> Nginx sayt fayli yaratilmoqda: $SITE"
  [ -f "$SITE" ] && cp "$SITE" "$SITE.bak.$(date +%s)"
  sed -e "s/__DOMAIN__/$DOMAIN/g" -e "s/__PORT__/$PORT/g" \
    "$APP_DIR/deploy/nginx/mikka.conf" > "$SITE"
else
  # Port may have changed between deploys — update just the upstream line.
  sed -i -E "s#server 127\.0\.0\.1:[0-9]+;#server 127.0.0.1:$PORT;#" "$SITE"
fi
ln -sf "$SITE" /etc/nginx/sites-enabled/mikka.conf

# Validate the WHOLE config before reloading; on failure, remove Mikka's
# site so RoyalVIP keeps running exactly as before.
if ! nginx -t; then
  echo "XATO: nginx konfiguratsiyasi noto'g'ri — Mikka sayti o'chirildi, RoyalVIP'ga ta'sir qilmadi."
  rm -f /etc/nginx/sites-enabled/mikka.conf
  exit 1
fi
systemctl reload nginx

# certbot with -d only touches the server block for this domain.
if [ ! -d "/etc/letsencrypt/live/$DOMAIN" ]; then
  echo ">> SSL sertifikat olinmoqda: $DOMAIN"
  certbot --nginx -d "$DOMAIN" --cert-name "$DOMAIN" -m "$EMAIL" \
    --agree-tos --non-interactive --redirect
fi

echo ">> Server tayyor (Mikka: $APP_DIR, port 127.0.0.1:$PORT, sayt: $SITE)."
