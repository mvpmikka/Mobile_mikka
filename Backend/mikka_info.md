# Mikka — Ish jurnali

Bu fayl loyihada bajarilgan har bir vazifani va u **qanday** bajarilganini yozib boradigan davomiy jurnal. Har yangi vazifa tugagach, shu faylga yangi bo'lim qo'shiladi — eskilari o'zgartirilmaydi.

---

## 1. Check-in tizimi yakunlandi

**Nima qilindi:** `CheckInModule` — joyga borganini tasdiqlash (check-in) tizimi.
- `POST /places/:placeId/check-ins` — foydalanuvchi koordinatasi bilan check-in yaratish
- `GET /users/me/check-ins` — o'z check-inlarim ro'yxati (faqat egasiga, paginatsiya bilan)
- `GET /places/:placeId/check-ins/count` — joy uchun ommaviy hisoblagich (kim/qachon ko'rsatilmaydi, shuning uchun Privacy modulisiz ham ochiq)
- `DELETE /check-ins/:id` — faqat egasi o'chira oladi

**Qanday bajarildi:**
- Masofa tekshiruvi PostGIS orqali server tomonida hisoblanadi (`ST_Distance`), `CHECK_IN_MAX_DISTANCE_METERS` (`.env`, default 200m) dan uzoq bo'lsa rad etiladi.
- Takroriy check-in uchun `CHECK_IN_COOLDOWN_MINUTES` (default 15 daq.) — shu vaqt o'tmaguncha bir xil joyga qayta check-in qilib bo'lmaydi.
- `distanceMeters` audit uchun saqlanadi (o'chirilmaydi — `deletedAt` bilan soft-delete).
- Ko'rinish V1'da faqat egasiga — boshqa foydalanuvchi ko'rolmaydi (Privacy moduli hali yo'q edi).
- Prisma schema + migratsiya (`add_check_ins`), `Controller → Service → Repository` qatlamlari, Zod DTO validatsiyasi — loyihaning umumiy andozasiga mos.

---

## 2. `GET /places` — radius qidiruv + mintaqaviy fallback

**Nima qilindi:** Foydalanuvchi tanlagan radiusda (1/3/15 km, faqat shu uchtasi — erkin son emas) joy topilmasa, tizim avtomatik ravishda foydalanuvchi joylashgan **ma'muriy mintaqa** (viloyat/shahar) bo'yicha butun mintaqadagi joylarni qaytaradi, "hech narsa topilmadi" o'rniga.

**Qanday bajarildi:**
- Yangi `Region` modeli — PostGIS `geometry(MultiPolygon, 4326)` chegara bilan. `Place.regionId` DB trigger orqali avtomatik hisoblanadi (`sync_place_region`, point-in-polygon — `ST_Contains`), xuddi `location` ustuni kabi.
- Avval 2 ta **taxminiy** to'rtburchak mintaqa (Toshkent shahri, Samarqand viloyati) bilan mexanizm isbotlandi, keyin **geoBoundaries.org**dan (OpenStreetMap asosida, ochiq ODbL litsenziya) O'zbekistonning barcha **14 ta haqiqiy** ma'muriy chegarasi (12 viloyat + Toshkent shahri + Qoraqalpog'iston) yuklab olinib, `ST_GeomFromGeoJSON` orqali bazaga yozildi — alohida migratsiya bilan (`seed_real_uz_regions`), eski taxminiy ma'lumotni almashtirib.
- Javob metama'lumot bilan boyitildi: `searchMode` (`radius`/`region_fallback`/`none`), `requestedRadiusMeters`, `region`.
- Real shahar markazlari (Toshkent, Buxoro, Samarqand, Nukus) bilan sinovdan o'tkazildi — har biri to'g'ri mintaqasiga bog'landi.
- Bu funksiya faqat Place modulida (`PlaceRepository`/`PlaceService`) — Search moduliga tegilmadi (sizning tanlovingiz bo'yicha).

---

## 3. Local dev muhiti: Postgres + PostGIS + Docker

**Muammo:** Loyihaning `docker-compose.yml`i PostGIS talab qiladi, lekin mashinada avval Docker o'rnatilmagan edi, o'rniga tizim darajasidagi (native) Postgres 18 ishlab turgan edi — PostGIS'siz.

**Qanday hal qilindi (bosqichma-bosqich):**
1. Native Postgres 18'da `mikka` foydalanuvchisi parolini tuzatildi (`ALTER USER`).
2. PostGIS native Postgres'da yo'qligi aniqlandi → vaqtincha **Homebrew** orqali `postgresql@18` (PostGIS bilan tayyor) 5433-portda ishga tushirildi.
3. Keyin foydalanuvchi Docker Desktop'ni o'zi o'rnatdi → `docker-compose.yml` `postgis/postgis:16-3.4` image'iga, 5433-portga sozlandi (native Postgres bilan to'qnashmasin deb).
4. Homebrew Postgres va Docker konteyneri bir vaqtda bir portda ziddiyat qilgani aniqlandi (psql noto'g'ri instansga ulanib turgan edi) → Homebrew Postgres to'xtatildi, Docker yagona manba qilib qoldirildi.
5. Barcha migratsiyalar Docker konteyneriga qo'llandi, PostGIS'ning qo'shimcha kengaytmalari (`postgis_topology` va h.k.) migratsiya tarixida yo'qligi sababli "drift" xatoligi chiqdi → **foydalanuvchining aniq roziligi bilan** (`PRISMA_USER_CONSENT_FOR_DANGEROUS_AI_ACTION` orqali, Prisma'ning AI-agent xavfsizlik mexanizmiga rioya qilib) `prisma migrate reset` bajarildi.

---

## 4. Do'stlik (Friendship) moduli — Friend Requests, Friends, Block

**Nima qilindi:**
- `POST /friend-requests`, `GET /friend-requests/received|sent`, `POST /friend-requests/:id/accept|decline`, `DELETE /friend-requests/:id`
- `GET /users/me/friends`, `DELETE /users/me/friends/:friendUserId`
- `POST/DELETE /users/:userId/block`, `GET /users/me/blocked-users`

**Qanday bajarildi:**
- `FriendRequest` — `status` ustunisiz: qatorning mavjudligi "kutilmoqda" degani, qabul qilinganda o'chirilib `Friendship` yaratiladi (bitta tranzaksiyada).
- `Friendship` — **ikki qatorli denormalizatsiya** (A→B va B→A alohida qator) — "mening do'stlarim" so'rovi bitta indekslangan ustun orqali tez ishlaydi (millionlab foydalanuvchida ham).
- Kesishgan so'rov (ikkalasi bir-biriga so'rov yuborgan holat) — avtomatik qabul qilinmaydi, xatolik bilan "sizga allaqachon so'rov kelgan" deyiladi (sizning tanlovingiz).
- `Block` — CLAUDE.md'ning V1 ro'yxatida yo'q edi, lekin sizning aniq so'rovingiz bilan qo'shildi, **tor doirada**: faqat yangi do'stlik so'rovlarini oldini oladi va mavjud do'stlik/so'rovni buzadi — profil/sharh/chatni yashirmaydi (bu Privacy/Chat modullariga tegishli, hali qurilmagan).
- Uchalasi ham hard-delete (soft-delete emas) — bu oddiy holat almashtirish, moderatsiya kerak emas.
- 19 ta stsenariy bilan API orqali to'liq sinovdan o'tkazildi (dublikat, kesishgan, o'ziga so'rov, ruxsatlar, bloklash mavjud do'stlikni buzishi va h.k.).

---

## 5. Git: har bir fayl — alohida commit

Sizning aniq so'rovingiz bo'yicha, barcha vazifalarda **har bir o'zgargan/yangi fayl uchun alohida commit** yaratildi (bitta katta commit o'rniga), so'ng `main` branch'ga push qilindi. Maxfiy ma'lumot (`.env 2.bak` — ichida haqiqiy JWT sir bor edi) commitga qo'shilmadi, o'chirib tashlandi.

---

## 6. Privacy moduli — check-in ko'rinishini boshqarish

**Nima qilindi:**
- `PrivacySettings` modeli — bitta maydon: `checkInVisibility` (`PUBLIC`/`FRIENDS`/`PRIVATE`, default `FRIENDS`). Qator faqat sozlama o'zgartirilganda yaraladi (yo'q bo'lsa — default qiymat qaytadi).
- `GET/PATCH /users/me/privacy-settings` — o'z sozlamasini ko'rish/o'zgartirish.
- Yangi: `GET /users/:username/check-ins` — boshqa foydalanuvchining check-inlarini ko'rish, `checkInVisibility` orqali cheklanadi.

**Qanday bajarildi:**
- **Muhim arxitektura qarori:** `PrivacyModule` `FriendshipModule`ni o'zi ichida import qiladi va tashqariga faqat ikkita metod beradi — `getSettings()` va `canView(viewerId, ownerId, visibility)`. `CheckInModule` faqat `PrivacyModule`ni import qiladi, Friendship haqida umuman bilmaydi. Bu loyihada birinchi marta bir modul ikkinchisining **servisidan** to'g'ridan-to'g'ri foydalanmoqda (Review/CheckIn'dagi kabi oddiy "mavjudmi" tekshiruvidan farqli — bu haqiqiy biznes qoidasi, takrorlanmasligi kerak).
- `PUBLIC` ko'rinish tizimga kirmagan foydalanuvchi uchun ham ishlashi kerak edi — shuning uchun yangi `OptionalJwtAuthGuard` (token bo'lmasa xatolik bermaydi) va `@OptionalCurrentUser()` dekoratori (`auth` moduliga) qo'shildi — bu kelajakda boshqa "kirgan/kirmagan uchun boshqacha" endpointlar uchun ham qayta ishlatiladi.
- **Qo'lda sinov paytida topilgan muammo:** dastlabki versiyada `/users/:username/check-ins` o'z egasi ko'radigan to'liq ma'lumotni (aniq GPS koordinatalari bilan) boshqalarga ham ko'rsatib yuborayotgan edi. Tuzatildi: alohida `findManyByUserPublic` repository metodi (Prisma `select` bilan, faqat TS tipi orqali emas — chunki kengroq runtime obyekt baribir to'liq serialize bo'ladi) va `PublicCheckInItem` tipi qo'shildi — faqat joy nomi va vaqt, koordinatasiz.
- To'liq API orqali sinovdan o'tkazildi: default FRIENDS bilan begona foydalanuvchi ko'ra olmasligi, PUBLIC qilingach hatto anonim ham ko'rishi, PRIVATE qilingach hech kim (o'zidan boshqa) ko'ra olmasligi, do'st bo'lgach FRIENDS ostida ko'rish ishlashi, va tuzatilgan javobda koordinata endi yo'qligi.

---

## 7. Saqlangan joylar (Saved Places)

**Nima qilindi:**
- `POST/DELETE /places/:placeId/saved-places` — joyni saqlash/bekor qilish
- `GET /places/:placeId/saved-places/count` — ommaviy hisoblagich (nechta odam saqlagan)
- `GET /users/me/saved-places` — mening saqlaganlarim ro'yxati (joy xulosasi + saqlangan vaqt bilan)

**Qanday bajarildi:**
- Kolleksiya/papka yo'q — faqat tekis ro'yxat (CLAUDE.md: V1'ni sodda tut).
- **Saqlash va bekor qilish ikkalasi ham idempotent** — qayta bosilsa xato bermaydi (`upsert` / `deleteMany`). Bu FriendRequest (409) va Friendship.unfriend (404)dan ataylab farq qiladi: bookmark — bir martalik ijtimoiy harakat emas, mijoz ikki marta bossa ham xato ko'rsatish shart emas.
- Hisoblagich ommaviy (kim/qachon ko'rsatilmaydi) — Check-in hisoblagichi kabi, Privacy moduliga bog'liq emas.
- 10 stsenariy bilan sinovdan o'tkazildi: saqlash, qayta saqlash (xatosiz), ro'yxat, hisoblagich, mavjud bo'lmagan joy (404), bekor qilish, qayta bekor qilish (xatosiz), autentifikatsiyasiz (401).

---

## 8. Admin moduli

**Nima qilindi:**
- `GET /admin/stats` — jami foydalanuvchi/joy/sharh/check-in soni
- `GET /admin/users` (qidiruv bilan), `GET /admin/users/:id` — foydalanuvchi boshqaruvi
- `POST/DELETE /admin/users/:id/ban` — bloklash/blokdan chiqarish
- `DELETE /reviews/:id` — endi ADMIN har qanday sharhni ham o'chira oladi (moderatsiya)

**Qanday bajarildi:**
- **Muhim aniqlashtirish:** Joy/kategoriya uchun admin CRUD allaqachon mavjud edi (`PlaceController`da `@Roles(Role.ADMIN)` bilan) — Admin moduli ularni takrorlamadi. Faqat hech kim egallamagan narsa — ko'p jadval bo'yicha statistika — haqiqatan yangi `AdminModule`da qoldi. Foydalanuvchi boshqaruvining **haqiqiy logikasi** (`listForAdmin`, `getForAdmin`, `ban`, `unban`) `UserService`da qoladi, `AdminService` faqat unga murojaat qiladi.
- **Yo'nalish ziddiyati:** `GET /users/:username` (ochiq profil) bilan bir xil shaklga ega `GET /users/:id` (admin) qo'sha olmasligim sababli, barcha admin-foydalanuvchi endpointlari `/admin/*` nom fazosiga ko'chirildi.
- **`isBanned`** — `deletedAt`dan alohida yangi maydon (qaytariladigan moderatsiya, `deletedAt` esa doimiy va hech qachon "undelete" qilinmaydi).
- **Bloklashda darhol ta'sir qilishi uchun** — `TokenService.revokeAllForUser` chaqiriladi (parolni tiklashda ishlatilgan xuddi shu mexanizm), aks holda bloklangan foydalanuvchi 30 kunlik refresh token bilan tizimda qolib ketardi. Shu sababli `AdminModule` endi `AuthModule`ni ham import qiladi (`TokenService` eksport qilindi).
- **Sinov paytida topilgan kamchilik:** `isBanned` tekshiruvi dastlab faqat oddiy `login()`ga qo'shilgan edi, `loginWithGoogle()`ning ikkala yo'lida (mavjud identity va email orqali topish/yaratish) umuman yo'q edi — payqalib, ikkalasiga ham qo'shildi.
- O'zini-o'zi bloklashning oldi olingan (yagona admin o'zini bloklab qolib ketmasligi uchun).
- To'liq real oqim bilan sinovdan o'tkazildi (haqiqiy `/auth/register` + `/auth/login`): RBAC (403/401), statistika, ro'yxat/qidiruv, bloklash → login rad etilishi → refresh token darhol bekor bo'lishi → blokdan chiqarish → login qayta ishlashi, o'zini bloklash xatoligi, va sharh moderatsiyasi (egasi bo'lmagan/admin bo'lmagan foydalanuvchi rad etiladi, admin o'chira oladi).

---

## 9. Story moduli (Do'stlar ko'rishi kuzatuvi bilan)

**Nima qilindi:**
- `POST /stories` `{text?, imageUrl?, placeId?}` — kamida bittasi majburiy, 24 soatdan keyin avtomatik tugaydi
- `GET /stories/feed` — do'stlarim + o'zim, har birida `viewedByMe` belgisi
- `GET /users/:username/stories` — muayyan foydalanuvchi story'lari (Privacy-gated)
- `DELETE /stories/:id` — muddatidan oldin o'chirish (egasi yoki ADMIN)
- `POST /stories/:id/view` — ko'rilgan deb belgilash (idempotent)
- `GET /stories/:id/viewers` — FAQAT egasi ko'radi

**Qanday bajarildi:**
- **Muhim refaktoring:** `CheckInVisibility` enumini `ContentVisibility`ga o'zgartirdim, chunki `storyVisibility` ham xuddi shu uchta qiymatni (PUBLIC/FRIENDS/PRIVATE) ishlatadi — `PrivacyService.canView()`ni aynan shuning uchun umumiy qilib qurgan edim. Migratsiya `ALTER TYPE ... RENAME` bilan yozildi (Prisma avtomatik generatsiya qilgan variant ustunni o'chirib qayta yaratardi — **mavjud ma'lumotni yo'qotardi**, buni migratsiya faylining o'zidagi "Warnings" izohini o'qib payqadim).
- `PATCH /users/me/privacy-settings` endi **qisman yangilash** qabul qiladi (ikkala maydon ham ixtiyoriy) — ikkita mustaqil sozlama paydo bo'lgach, mijoz har safar ikkalasini ham yuborishga majbur bo'lmasligi kerak edi.
- **Eng muhim nozik joy:** oddiy `canView()` feed uchun yetarli emas edi — do'stim `storyVisibility`ni `PRIVATE` qo'ysa, u hali ham mening do'stim, lekin uning story'si feed'imda ko'rinmasligi kerak. Shuning uchun `PrivacyService.filterOutPrivate()` qo'shildi — do'stlar ro'yxatidan kimlar aniq `PRIVATE` qo'yganini alohida tekshiradi. Qo'lda sinovda tasdiqlandi: do'stim `PRIVATE` qo'yishi bilan uning story'si mening feed'imdan darhol yo'qoldi, garchi Friendship o'zgarmagan bo'lsa ham.
- `FriendshipRepository.findAllFriendIds` — yangi, ataylab **paginatsiyasiz** metod (feed uchun "barcha do'stlarim ID'si" kerak, bitta sahifasi emas) — hech qachon controller orqali tashqariga chiqarilmaydi.
- Story'ning "kim ko'rgani" ro'yxati story'ning o'z ko'rinish sozlamasidan **mustaqil** — har doim faqat egasi ko'radi (Instagram/Snapchat'dagi kabi farq: kontent ko'rinishi va tomoshabinlar ro'yxati ikki xil narsa).
- Muddat tugashi uchun cron job **yo'q** — barcha faol so'rovlar `expiresAt > now()` bilan filtrlaydi, `deletedAt` andozasiga o'xshab; muddati o'tgan qatorlar bazada qoladi (V1 uchun yetarli).
- To'liq real oqim bilan sinovdan o'tkazildi: do'st ko'radi/begona ko'rmaydi, PUBLIC qilingach anonim ham ko'rishi, **PRIVATE qo'yilgach do'stning feed'idan yo'qolishi**, ko'rishni belgilash (idempotent), viewerlar ro'yxati (faqat egasi), o'z story'siga o'z-ko'rishning no-op ekanligi, muddatidan oldin o'chirish, va admin moderatsiyasi.

---

## 10. Chat moduli (real-vaqtli WebSocket bilan)

**Nima qilindi:**
- `POST/GET /conversations`, `GET/PATCH /conversations/:id`, qatnashchi qo'shish/olib tashlash/chiqib ketish, `PATCH /conversations/:id/read`
- `GET/POST /conversations/:id/messages`, `DELETE /messages/:id`
- `POST/DELETE /messages/:id/reactions`
- **WebSocket** (`/chat` namespace) — yangi xabar/o'chirilgan xabar/reaksiya yangilanishi haqida real-vaqtli bildirishnoma

**Qanday bajarildi:**
- Loyihada birinchi marta WebSocket infratuzilmasi qo'shildi (`@nestjs/websockets` + `socket.io`). **REST — yagona haqiqiy manba** (barcha yozish amallari oddiy REST orqali, to'liq Zod validatsiya va guard'lar bilan); WebSocket **faqat push** uchun — allaqachon ulangan mijozlarga "narsa o'zgardi" deb xabar beradi, o'zi hech qanday yozish amalini qabul qilmaydi.
- **Soddalashtirilgan xona strategiyasi:** har bir ulangan foydalanuvchi faqat **o'zining** xonasiga qo'shiladi (`user:{id}`), suhbat bo'yicha alohida xonalar yo'q — mijoz "join_conversation" kabi voqealarni boshqarishi shart emas. Server xabar yaratilganda suhbat qatnashchilari ro'yxatini o'zi topib, har birining shaxsiy xonasiga yuboradi.
- **WebSocket autentifikatsiyasi `JwtAuthGuard`dan butunlay boshqacha** — Passport HTTP so'rov/javob tsikli uchun mo'ljallangan, socket.io handshake'da ishlamaydi. Shuning uchun `ChatGateway` tokenni to'g'ridan-to'g'ri `JwtService.verifyAsync` orqali tekshiradi va foydalanuvchi mavjudligi/bloklanmaganligini qayta tekshiradi. Buning uchun `AuthModule` endi butun `JwtModule`ni eksport qiladi (avval faqat `TokenService`).
- **Nozik joy — reaksiya broadcast'i:** `reactedByMe` maydoni har bir ko'ruvchi uchun individual (REST javobida to'g'ri), lekin WebSocket orqali BARCHA qatnashchilarga BITTA xabar yuboriladi — shuning uchun reaksiya push'ida bu maydon butunlay olib tashlanadi, faqat `{emoji, count}` yuboriladi. Yangi xabar push'i uchun bu muammo yo'q, chunki yangi yaratilgan xabarda hali hech qanday reaksiya yo'q.
- Shaxsiy suhbat **get-or-create** — bir kishiga ikkinchi marta "yangi" suhbat ochishga urinilsa, mavjud suhbat qaytariladi (WhatsApp'dagi kabi).
- Suhbat yaratish/qatnashchi qo'shish **faqat do'stlar bilan** mumkin (`FriendshipRepository.exists`) — spam/bezovtalikdan himoya; mavjud suhbatga bu keyinchalik ta'sir qilmaydi (do'stlikni bekor qilsa ham suhbat ishlayveradi).
- Guruhdan chiqish `leftAt` bilan belgilanadi (qator o'chirilmaydi) — o'tgan xabarlar egasiga bog'liqligicha qoladi. Shaxsiy suhbatdan "chiqish" tushunchasi yo'q.
- **Test uchun** `socket.io-client` bilan alohida Node skripti yozildi (loyihaning `node_modules`iga `NODE_PATH` orqali ishora qilib) — Bob WebSocket orqali ulanib turganda, Alice REST orqali xabar yuborganda, Bob real vaqtda `new_message` voqeasini olishi tasdiqlandi. Noto'g'ri token bilan ulanish ham sinovdan o'tkazildi (server darhol uzadi) — birinchi test skripti buni noto'g'ri tekshirgan edi ("connect" voqeasi baribir bir marta otiladi, socket.io handshake NestJS'ning autentifikatsiya tekshiruvidan oldin tugagani uchun; keyin darhol uziladi).
- To'liq real oqim bilan sinovdan o'tkazildi: shaxsiy/guruh suhbat yaratish, do'st bo'lmaganlar bilan rad etish, xabar yuborish/javob berish, bo'sh xabar (400), mavjud bo'lmagan joy (404), qatnashchi bo'lmagan foydalanuvchi rad etilishi, o'qilmagan xabar soni, reaksiya qo'yish/almashtirish, guruhni nomlash (faqat yaratuvchi), guruhdan chiqish, xabarni o'chirish (egasi/admin), va real-vaqtli WebSocket push.

---

## 11. Notification moduli (V1'ning oxirgi moduli)

**Nima qilindi:**
- `GET /notifications`, `GET /notifications/unread-count`, `PATCH /notifications/:id/read`, `PATCH /notifications/read-all`
- Bildirishnoma turlari: `FRIEND_REQUEST`, `NEW_MESSAGE` (joy ulashish shu ichida, matn "ulashdi" deb o'zgaradi), `STORY_UPDATE`
- Real-vaqtli push (`/notifications` WebSocket namespace)

**Qanday bajarildi:**
- **Loyihada birinchi marta voqea-asoslangan (event-driven) arxitektura**: `@nestjs/event-emitter` qo'shildi. Friendship/Chat/Story modullari Notification haqida **umuman bilmaydi** — ular shunchaki voqea chiqaradi (`friend-request.created`, `message.created`, `story.created`), Notification esa alohida tinglovchilar orqali javob beradi. Bu boshqa barcha modul-aro bog'lanishlardan farqli (masalan Privacy→Friendship) — chunki u yerda "bitta iste'molchi, bitta ishlab chiqaruvchi" edi, bu yerda esa "bitta iste'molchi, bir nechta bog'liq bo'lmagan ishlab chiqaruvchi" — aynan voqea uchun mo'ljallangan holat.
- Har bir voqeaning ta'rifi (nomi + payload shakli) **ishlab chiqaruvchi modulning o'zida** saqlanadi (`src/friendship/events/`, `src/chat/events/`, `src/story/events/`), Notification papkasida emas.
- **Ikki xil payload shakli, ataylab**: `FriendRequestCreatedEvent`/`StoryCreatedEvent` faqat ID'larni tashiydi (tinglovchi username'ni o'zi mahalliy qidiradi), lekin `MessageCreatedEvent` tayyor render qilingan ma'lumotni (qabul qiluvchilar ro'yxati, matn, joy nomi) tashiydi — chunki `MessageService.send` buni WebSocket broadcast uchun bir necha soniya oldin allaqachon hisoblab qo'ygan, qayta so'rov yuborish behuda bo'lardi.
- **Nozik joy:** Story uchun "faqat shu bitta muallifning o'zi PRIVATE qo'yganmi" tekshiruvi `PrivacyService.getSettings()` orqali, `filterOutPrivate()` orqali EMAS — ikkinchisi "ko'p egalar ro'yxatidan kimlar chiqarib tashlanishi kerak" (feed uchun) savoliga javob beradi, bu yerda esa faqat bitta odam (muallif) va savol soddaroq.
- **Ikkinchi WebSocket gateway** (`NotificationGateway`) — `ChatGateway`bilan bir xil shaklda (shaxsiy xona, faqat push), lekin alohida klass. Ulanish-autentifikatsiya mantig'i (`authenticateSocketUser`, `userRoom`) `src/common/websocket/`ga chiqarilib, ikkalasida ham qayta ishlatiladi (`ChatGateway` ham shu umumiy funksiyadan foydalanadigan qilib refaktor qilindi) — kod takrorlanmasin deb.
- To'liq real oqim bilan sinovdan o'tkazildi: do'stlik so'rovi → bildirishnoma, xabar → bildirishnoma, joy ulashish → maxsus matn, **PRIVATE story → do'stning o'qilmagan soni o'zgarmasligi**, o'qilgan deb belgilash/barchasini belgilash, va real-vaqtli WebSocket push (Bob ulangan holda, Alice xabar yuborganda, Bob bildirishnomani darhol oldi).

---

**Barcha 14 ta V1 moduli tugallandi:** Auth, User, Place/Place Category, Search, Review, Upload, Mail, Check-in, Friendship, Privacy, Saved Places, Admin, Story, Chat, Notification.