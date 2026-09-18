# Mikka Backend

Mikka mobil ilovasi uchun REST + WebSocket API. Joy topish (place discovery),
check-in, ijtimoiy tarmoq (do'stlar, chat, story/post), real-time
audio/video qo'ng'iroqlar (WebRTC) va biznes-egalari uchun admin panelini
bitta NestJS xizmatida birlashtiradi.

## Texnologiyalar

| Qatlam | Texnologiya |
|---|---|
| Framework | [NestJS](https://nestjs.com/) 11 (Express platformasida) |
| Til | TypeScript |
| ORM | [Prisma](https://www.prisma.io/) 7 (`@prisma/adapter-pg`) |
| Baza | PostgreSQL + [PostGIS](https://postgis.net/) (masofa/geografik qidiruv uchun) — [Supabase](https://supabase.com/)'da joylashgan |
| Validatsiya | [Zod](https://zod.dev/) (class-validator o'rniga) |
| Auth | JWT (access + refresh token), Google OAuth, Passport |
| Real-time | Socket.IO (chat, qo'ng'iroq holati, presence) |
| WebRTC signalizatsiya | `flutter_webrtc` mobil klientlari uchun, coturn TURN server bilan |
| Fayl saqlash | Supabase Storage (rasmlar, tekshiruv hujjatlari) |
| Push xabarnoma | Firebase Cloud Messaging (Android), APNs (iOS) |
| Email | Brevo API (ustuvor) yoki SMTP fallback |
| Deploy | Render (Dockerfile orqali) |

## Loyihaning tuzilishi

Har bir domen o'z modulida — odatda `controller` / `services` / `repositories` /
`dto` / `types` qatlamlariga bo'lingan (repository qatlami xom SQL yoki
Prisma so'rovlarini controller/servisdan izolyatsiya qiladi):

```
src/
  admin/         — super-admin va biznes-admin boshqaruv paneli
  auth/          — ro'yxatdan o'tish, login, JWT, Google OAuth, email tasdiqlash
  badge/         — yutuq/nishon tizimi (masalan, N marta check-in qilgach)
  booking/       — joy bron qilish
  call/          — WebRTC audio/video qo'ng'iroq signalizatsiyasi
  chat/          — shaxsiy suhbatlar, xabarlar, reaksiyalar
  check-in/      — "men shu yerdaman" tasdiqlovi (200m radius tekshiruvi)
  customer/      — mijozlarni bloklash va boshqarish (biznes tomonidan)
  follow/        — obuna (follow/unfollow)
  friendship/    — do'stlik so'rovlari va do'stlar ro'yxati
  mail/          — email yuborish (Brevo/SMTP/console provider)
  notification/  — in-app bildirishnomalar
  order/         — mahsulot buyurtmalari
  place/         — joylar, kategoriyalar, radius/region-fallback qidiruv
  post/          — foydalanuvchi postlari (rasm bilan)
  presence/      — foydalanuvchi onlayn/oflayn holati
  privacy/       — maxfiylik sozlamalari
  product/       — biznes mahsulotlari (do'kon/menyu)
  review/        — joylarga baho va sharh
  saved-place/   — saqlangan joylar
  search/        — joy va foydalanuvchi qidiruvi
  upload/        — rasm yuklash (Supabase Storage + sharp bilan qayta ishlash)
  user/          — foydalanuvchi profili
  verification/  — biznes egaligini tasdiqlash (hujjat yuklash + admin ko'rib chiqish)
  config/        — muhit o'zgaruvchilari sxemasi (Zod)
  common/        — umumiy pipe'lar, kripto yordamchilari, websocket adapter
  prisma/        — Prisma xizmati (ulanish boshqaruvi)
```

### Asosiy ma'lumotlar modeli (`prisma/schema.prisma`)

`User`, `Place` (+ `PlaceCategory`, `Region`), `CheckIn`, `Review` /
`PlaceRatingSummary`, `Product` / `Order` / `Booking`, `FriendRequest` /
`Friendship` / `Follow`, `Conversation` / `Message`, `Post` / `Story`,
`CallSession`, `Notification`, `DeviceToken`, `BadgeDefinition` / `UserBadge`.

`Place.location` (geography nuqtasi) va `Place.regionId` ustunlari
**qo'lda emas**, DB trigger orqali avtomatik to'ldiriladi (lat/lng
o'zgarganda). Joy qidiruvi avval `ST_DWithin` bilan to'g'ridan-to'g'ri
radius bo'yicha izlaydi; agar hech narsa topilmasa, foydalanuvchi
joylashgan (seed qilingan poligon) `Region`ga tushib, o'sha region
ichidagi barcha joylarni qaytaradi (`searchMode: 'radius' | 'region_fallback'`).

## Ishga tushirish (lokal)

**Talablar:** Node.js 24.x, Docker (lokal PostgreSQL/PostGIS uchun).

```bash
npm install

# .env faylini yarating (pastdagi "Muhit o'zgaruvchilari" bo'limiga qarang)
cp .env.example .env

# Lokal PostGIS konteynerini ko'taring (localhost:5442)
docker compose up -d

# Prisma migratsiyalarini qo'llang
npx prisma migrate dev

npm run start:dev   # http://localhost:3112 (yoki .env'dagi PORT)
```

> **Eslatma:** `docker-compose.yml` faqat lokal development uchun — u faqat
> PostgreSQL/PostGIS'ni beradi, backend'ning o'zi native (`npm run start:dev`)
> holda ishga tushadi. Production'da bazaga Supabase orqali ulaniladi,
> backend esa Render'da `Dockerfile` orqali deploy qilinadi.

### Foydali skriptlar

| Buyruq | Vazifa |
|---|---|
| `npm run start:dev` | Hot-reload bilan dev server |
| `npm run build` | Production build (`dist/`) |
| `npm run start:prod` | Build qilingan kodni ishga tushirish |
| `npm run lint` | ESLint (avto-tuzatish bilan) |
| `npm run test` | Unit testlar (Jest) |
| `npm run test:e2e` | End-to-end testlar |
| `npm run test:cov` | Test coverage hisoboti |

## Muhit o'zgaruvchilari

To'liq ro'yxat va izohlar `.env.example`'da. Muhimlari:

- `DATABASE_URL` — PostgreSQL ulanish satri (PostGIS talab qilinadi)
- `JWT_ACCESS_SECRET` — tasodifiy generatsiya qilish: `node -e "console.log(require('crypto').randomBytes(48).toString('base64'))"`
- `SUPABASE_URL`, `SUPABASE_SERVICE_ROLE_KEY`, `SUPABASE_STORAGE_BUCKET` — fayl yuklash uchun
- `BREVO_API_KEY` yoki `MAIL_HOST`/... — email yuborish uchun (bo'sh qoldirilsa, email konsolga chiqadi)
- `ADMIN_EMAILS`, `SUPER_ADMIN_EMAILS` — vergul bilan ajratilgan email ro'yxati; shu email bilan ro'yxatdan o'tgan/kirgan foydalanuvchi avtomatik shu rolga ko'tariladi
- `CHECK_IN_MAX_DISTANCE_METERS` (standart: 200) — check-in uchun joydan ruxsat etilgan maksimal masofa (metrda)
- `CHECK_IN_COOLDOWN_MINUTES` (standart: 15) — bir xil joyga qayta check-in qilish oralig'i
- `TURN_HOST`, `TURN_SHARED_SECRET`, ... — coturn TURN server (bo'sh bo'lsa, qo'ng'iroqlar faqat STUN orqali, ya'ni bir xil tarmoqda ishlaydi)
- `FIREBASE_SERVICE_ACCOUNT_JSON`, `APNS_*` — push xabarnoma (bo'sh qoldirilsa, push o'chiq)

## Deploy

Production Render'da ishlaydi, repo ildizidagi `Backend/Dockerfile` orqali
build qilinadi. Muhit o'zgaruvchilari **git orqali emas**, Render
dashboard'ining **Environment** bo'limida to'g'ridan-to'g'ri boshqariladi —
u yerda saqlangan har qanday o'zgarish avtomatik qayta deploy'ni
ishga tushiradi.

## Litsenziya

Xususiy (UNLICENSED) — ichki loyiha, tarqatishga mo'ljallanmagan.
