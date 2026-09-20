# Mikka

Joy topish (place discovery), check-in va do'stlar bilan ijtimoiy
bog'lanishni birlashtiruvchi mobil platforma. Foydalanuvchi yaqin-atrofdagi
joylarni (kafe, restoran, park, muzey va h.k.) xaritada topadi, u yerga
borganini "check-in" orqali tasdiqlaydi, do'stlari bilan real-time chat va
video/audio qo'ng'iroq qiladi. Biznes egalari esa admin panel orqali o'z
joyini ro'yxatdan o'tkazadi, mahsulot/menyu, buyurtma va bron qilishlarni
boshqaradi.

## Mundarija

- [Asosiy imkoniyatlar](#asosiy-imkoniyatlar)
- [Arxitektura, bir qarashda](#arxitektura-bir-qarashda)
- [Tezkor boshlash](#tezkor-boshlash)

## Asosiy imkoniyatlar

- **Joy topish** — xarita orqali yaqin-atrofdagi joylar, radius (1/3/15 km)
  yoki shahar bo'yicha qidiruv, kategoriya filtri
- **Check-in** — GPS orqali joyda ekanligini tasdiqlash (server-side masofa
  tekshiruvi)
- **Ijtimoiy tarmoq** — do'stlar, obuna, shaxsiy chat, post/story,
  bildirishnoma, yutuq/nishonlar
- **Real-time audio/video qo'ng'iroq** — WebRTC + coturn TURN server
- **Biznes/admin panel** — joy va kategoriya boshqaruvi, biznes egaligini
  tasdiqlash, mahsulot/menyu, buyurtma va bron qilish
- **Autentifikatsiya** — email/parol va Google OAuth, JWT token, email
  tasdiqlash va parolni tiklash
- **API hujjatlari** — Swagger UI (`/api-docs`) orqali barcha endpoint'lar
  bilan tanishish mumkin ([`Backend/README.md`](Backend/README.md#api-hujjatlari-swagger))

Monorepo ikkita mustaqil loyihadan iborat:

```
Mikka-Mobile_mikka/
  Backend/   — NestJS + PostgreSQL/PostGIS REST + WebSocket API
  mobile/    — Flutter ilova (Android/iOS)
```

Har biri o'z README'siga ega — batafsil texnologiyalar, ishga tushirish
buyruqlari va arxitektura tafsilotlari uchun o'sha fayllarga qarang:

- [`Backend/README.md`](Backend/README.md)
- [`mobile/README.md`](mobile/README.md)

## Arxitektura, bir qarashda

```
┌─────────────────┐        HTTPS / WebSocket        ┌──────────────────────┐
│  Flutter mobil   │ ───────────────────────────────▶│   NestJS backend      │
│  ilova (Android/ │◀─────────────────────────────── │   (AWS EC2, mkka.uz)  │
│  iOS)            │                                  └──────────┬───────────┘
└─────────┬────────┘                                             │
          │ WebRTC (P2P audio/video,                              │ Prisma
          │ coturn TURN server orqali)                            ▼
          │                                              ┌──────────────────┐
          │                                              │ PostgreSQL +     │
          │                                              │ PostGIS          │
          │                                              │ (Supabase-da)    │
          │                                              └──────────────────┘
          │
          └── Supabase Storage (rasmlar, tekshiruv hujjatlari)
```

- **Mobil ilova** — barcha ekranlar (Explore/xarita, check-in, chat,
  do'stlar, profil, biznes-admin paneli) shu yerda. Riverpod orqali holatni
  boshqaradi, Dio orqali backend bilan gaplashadi.
- **Backend** — barcha biznes mantig'i, autentifikatsiya, joy qidiruvi
  (radius + region-fallback), check-in masofa tekshiruvi, real-time chat
  va qo'ng'iroq signalizatsiyasi shu yerda.
- **Baza** — Supabase-hosted PostgreSQL, PostGIS kengaytmasi bilan
  (geografik/masofa so'rovlari uchun: `ST_DWithin`, `ST_Contains`, ...).
  Fayllar (rasm, hujjat) uchun esa Supabase Storage.
- **Real-time aloqa ikki xil kanalda:** chat/holat/bildirishnoma —
  Socket.IO orqali backend serverdan o'tadi; audio/video qo'ng'iroqning
  o'zi esa WebRTC orqali qurilmadan-qurilmaga to'g'ridan-to'g'ri (backend
  faqat signalizatsiya va TURN kredensiallarini beradi).

## Tezkor boshlash

```bash
# 1) Backend'ni ishga tushirish (lokal Postgres/PostGIS Docker orqali)
cd Backend
npm install
cp .env.example .env   # va kerakli qiymatlarni to'ldiring
docker compose up -d
npx prisma migrate dev
npm run start:dev      # http://localhost:3112

# 2) Mobil ilovani (boshqa terminalda) ishga tushirish
cd ../mobile
flutter pub get
flutter run
```

Batafsil muhit o'zgaruvchilari, skriptlar va deploy jarayoni uchun har bir
papkaning o'z README'siga qarang.

## Litsenziya

Xususiy — ichki loyiha, tarqatish yoki `pub.dev`/ochiq manbaga chiqarish
uchun mo'ljallanmagan.
