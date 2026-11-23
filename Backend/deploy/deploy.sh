#!/usr/bin/env bash
# Deploys the backend from this Mac to the VPS.
#   ./deploy/deploy.sh            -> full deploy (first time / config change)
#   ./deploy/deploy.sh --quick    -> code update only (skips server setup)
set -euo pipefail

SERVER="${SERVER:-root@63.189.197.251}"
DOMAIN="${DOMAIN:-mikka.jamshiddin.uz}"
EMAIL="${EMAIL:-jbm050690@gmail.com}"
APP_DIR=/opt/mikka

cd "$(dirname "$0")/.."

if [ ! -f .env.production ]; then
  echo "XATO: Backend/.env.production topilmadi (.env.production.example dan nusxa oling)."
  exit 1
fi

echo ">> 1. DNS tekshirilmoqda: $DOMAIN"
RESOLVED="$(dig +short "$DOMAIN" A | tail -n1)"
if [ "$RESOLVED" != "${SERVER#*@}" ]; then
  echo "OGOHLANTIRISH: $DOMAIN -> [${RESOLVED:-topilmadi}], kutilgan: ${SERVER#*@}"
  echo "ahost panelida A yozuv qo'shing va DNS tarqalishini kuting."
  [ "${1:-}" = "--quick" ] || exit 1
fi

echo ">> 2. Fayllar serverga yuborilmoqda..."
ssh "$SERVER" "mkdir -p $APP_DIR"
rsync -az --delete \
  --exclude node_modules --exclude dist --exclude generated \
  --exclude coverage --exclude .git --exclude '.env' --exclude '.DS_Store' \
  ./ "$SERVER:$APP_DIR/"

if [ "${1:-}" != "--quick" ]; then
  echo ">> 3. Server sozlanmoqda (Docker, Nginx, SSL)..."
  ssh "$SERVER" "bash $APP_DIR/deploy/server-setup.sh '$DOMAIN' '$EMAIL'"
fi

echo ">> 4. Konteyner build qilinib ishga tushirilmoqda..."
ssh "$SERVER" "cd $APP_DIR/deploy && docker compose -f docker-compose.prod.yml up -d --build && docker image prune -f"

echo ">> 5. Tekshiruv..."
sleep 8
ssh "$SERVER" "docker logs --tail 30 mikka-api"
curl -fsS -o /dev/null -w "HTTPS status: %{http_code}\n" "https://$DOMAIN/api-docs" || true

echo ""
echo "Tayyor: https://$DOMAIN  (Swagger: https://$DOMAIN/api-docs)"
