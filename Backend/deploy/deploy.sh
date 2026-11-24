#!/usr/bin/env bash
# Deploys the Mikka backend from this Mac to the VPS (also hosts RoyalVIP,
# dorixona, kidstv). Everything Mikka owns lives in /home/ubuntu/mikka:
#   backend/ (code + .env), nginx/mikka.conf, logs/
# plus its own "mikka" Docker project — other projects are never touched.
#
#   ./deploy/deploy.sh --check    -> read-only: show what's on the server
#   ./deploy/deploy.sh            -> full deploy (first time / config change)
#   ./deploy/deploy.sh --quick    -> code update only (skips server setup)
set -euo pipefail

SERVER="${SERVER:-ubuntu@63.189.197.251}"
DOMAIN="${DOMAIN:-mikka.jamshiddin.uz}"
EMAIL="${EMAIL:-jbm050690@gmail.com}"
MIKKA_PORT="${MIKKA_PORT:-4112}"
SSH_KEY="${SSH_KEY:-$HOME/Desktop/My_projects/keys/Keys.pem}"
export RSYNC_RSH="ssh -i $SSH_KEY"
ssh() { command ssh -i "$SSH_KEY" "$@"; }
ROOT_DIR=/home/ubuntu/mikka
APP_DIR=$ROOT_DIR/backend
MODE="${1:-}"

cd "$(dirname "$0")/.."

if [ "$MODE" = "--check" ]; then
  echo ">> Serverdagi holat (hech narsa o'zgartirilmaydi):"
  ssh "$SERVER" "sudo MIKKA_PORT=$MIKKA_PORT bash -s" <<'REMOTE'
echo '--- /opt, /var/www, ~ubuntu:'; ls /opt /var/www /home/ubuntu 2>/dev/null
echo '--- Band portlar:'; ss -tlnp | awk 'NR>1{print $4, $6}' | sort -u
echo '--- Nginx saytlari:'; ls -l /etc/nginx/sites-enabled/ /etc/nginx/conf.d/ 2>/dev/null
echo '--- server_name lar:'; grep -rh 'server_name' /etc/nginx/ 2>/dev/null | sort -u
echo '--- Docker konteynerlar:'; docker ps --format '{{.Names}}  {{.Ports}}' 2>/dev/null
echo '--- PM2:'; sudo -u ubuntu pm2 ls 2>/dev/null || true
echo "--- $MIKKA_PORT-port:"; ss -tln "sport = :$MIKKA_PORT" | awk 'NR>1' | grep -q . && echo BAND || echo BOSH
REMOTE
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
# .env is excluded from --delete so the server copy survives; the local
# .env.production is uploaded as the server's backend/.env.
rsync -az --delete \
  --exclude node_modules --exclude dist --exclude generated \
  --exclude coverage --exclude .git --exclude '.env' --exclude '.env.production' \
  --exclude '.DS_Store' --exclude storage \
  ./ "$SERVER:$APP_DIR/"
scp -q -i "$SSH_KEY" .env.production "$SERVER:$APP_DIR/.env"
ssh "$SERVER" "chmod 600 $APP_DIR/.env"

if [ "$MODE" != "--quick" ]; then
  echo ">> 3. Server sozlanmoqda (faqat Mikka qismlari)..."
  ssh "$SERVER" "sudo bash $APP_DIR/deploy/server-setup.sh '$DOMAIN' '$EMAIL' '$MIKKA_PORT'"
fi

echo ">> 4. Mikka konteyneri build qilinib ishga tushirilmoqda..."
# Prune only Mikka's own dangling images, never RoyalVIP's.
ssh "$SERVER" "cd $APP_DIR/deploy && sudo MIKKA_PORT=$MIKKA_PORT docker compose -p mikka -f docker-compose.prod.yml up -d --build \
  && sudo docker image prune -f --filter label=com.docker.compose.project=mikka"

echo ">> 5. Tekshiruv..."
sleep 8
ssh "$SERVER" "sudo docker logs --tail 30 mikka-api"
curl -fsS -o /dev/null -w "HTTPS status: %{http_code}\n" "https://$DOMAIN/api-docs" || true

echo ""
echo "Tayyor: https://$DOMAIN  (Swagger: https://$DOMAIN/api-docs)"
echo "Mikka: $ROOT_DIR | port 127.0.0.1:$MIKKA_PORT | nginx: $ROOT_DIR/nginx/mikka.conf"
