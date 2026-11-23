#!/usr/bin/env bash
# Deploys the Mikka backend from this Mac to the shared VPS (also hosts
# RoyalVIP). Mikka lives only in /opt/mikka, its own Nginx site file and
# its own "mikka" Docker project — nothing of RoyalVIP's is touched.
#
#   ./deploy/deploy.sh --check    -> read-only: show what's on the server
#   ./deploy/deploy.sh            -> full deploy (first time / config change)
#   ./deploy/deploy.sh --quick    -> code update only (skips server setup)
set -euo pipefail

SERVER="${SERVER:-root@63.189.197.251}"
DOMAIN="${DOMAIN:-mikka.jamshiddin.uz}"
EMAIL="${EMAIL:-jbm050690@gmail.com}"
MIKKA_PORT="${MIKKA_PORT:-4112}"
APP_DIR=/opt/mikka
MODE="${1:-}"

cd "$(dirname "$0")/.."

if [ "$MODE" = "--check" ]; then
  echo ">> Serverdagi holat (hech narsa o'zgartirilmaydi):"
  ssh "$SERVER" "
    echo '--- /opt va /var/www:'; ls /opt /var/www 2>/dev/null
    echo '--- Band portlar:'; ss -tlnp | awk 'NR>1{print \$4, \$6}' | sort -u
    echo '--- Nginx saytlari:'; ls -l /etc/nginx/sites-enabled/ 2>/dev/null; ls /etc/nginx/conf.d/ 2>/dev/null
    echo '--- server_name lar:'; grep -rh 'server_name' /etc/nginx/ 2>/dev/null | sort -u
    echo '--- Docker konteynerlar:'; docker ps --format '{{.Names}}  {{.Ports}}' 2>/dev/null
    echo \"--- $MIKKA_PORT-port:\"; ss -tln 'sport = :$MIKKA_PORT' | awk 'NR>1' | grep -q . && echo BAND || echo BO\\'SH
  "
  exit 0
fi

if [ ! -f .env.production ]; then
  echo "XATO: Backend/.env.production topilmadi (.env.production.example dan nusxa oling)."
  exit 1
fi

echo ">> 1. DNS tekshirilmoqda: $DOMAIN"
RESOLVED="$(dig +short "$DOMAIN" A | tail -n1)"
if [ "$RESOLVED" != "${SERVER#*@}" ]; then
  echo "OGOHLANTIRISH: $DOMAIN -> [${RESOLVED:-topilmadi}], kutilgan: ${SERVER#*@}"
  echo "ahost panelida A yozuv qo'shing va DNS tarqalishini kuting."
  [ "$MODE" = "--quick" ] || exit 1
fi

echo ">> 2. Fayllar $APP_DIR ga yuborilmoqda..."
ssh "$SERVER" "mkdir -p $APP_DIR"
# --delete is scoped to $APP_DIR only — it can't reach other projects.
rsync -az --delete \
  --exclude node_modules --exclude dist --exclude generated \
  --exclude coverage --exclude .git --exclude '.env' --exclude '.DS_Store' \
  ./ "$SERVER:$APP_DIR/"

if [ "$MODE" != "--quick" ]; then
  echo ">> 3. Server sozlanmoqda (faqat Mikka qismlari)..."
  ssh "$SERVER" "bash $APP_DIR/deploy/server-setup.sh '$DOMAIN' '$EMAIL' '$MIKKA_PORT'"
fi

echo ">> 4. Mikka konteyneri build qilinib ishga tushirilmoqda..."
# Prune only Mikka's own dangling images, never RoyalVIP's.
ssh "$SERVER" "cd $APP_DIR/deploy && MIKKA_PORT=$MIKKA_PORT docker compose -p mikka -f docker-compose.prod.yml up -d --build \
  && docker image prune -f --filter label=com.docker.compose.project=mikka"

echo ">> 5. Tekshiruv..."
sleep 8
ssh "$SERVER" "docker logs --tail 30 mikka-api"
curl -fsS -o /dev/null -w "HTTPS status: %{http_code}\n" "https://$DOMAIN/api-docs" || true

echo ""
echo "Tayyor: https://$DOMAIN  (Swagger: https://$DOMAIN/api-docs)"
echo "Mikka: $APP_DIR | port 127.0.0.1:$MIKKA_PORT | nginx: /etc/nginx/sites-available/mikka.conf"
