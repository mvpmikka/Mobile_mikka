# Mikka Mobile

Joy topish, do'stlar bilan bog'lanish va real-time video/audio qo'ng'iroq
qiluvchi Flutter ilovasi. Backend sifatida [`../Backend`](../Backend)
papkasidagi NestJS API'dan foydalanadi.

## Texnologiyalar

| Qatlam | Texnologiya |
|---|---|
| Framework | Flutter (Dart SDK ^3.11.5) |
| Holat boshqaruvi | [Riverpod](https://riverpod.dev/) (`flutter_riverpod`) |
| Navigatsiya | [go_router](https://pub.dev/packages/go_router) |
| Tarmoq | [Dio](https://pub.dev/packages/dio) (HTTP client) |
| Xarita | `google_maps_flutter` |
| Joylashuv | `geolocator` |
| Real-time chat | `socket_io_client` |
| Audio/video qo'ng'iroq | `flutter_webrtc` (coturn TURN server bilan) |
| Google kirish | `google_sign_in` |
| Deep link | `app_links` (email tasdiqlash/parol tiklash havolalari uchun) |
| Xavfsiz saqlash | `flutter_secure_storage` (token'lar uchun) |
| Ruxsatlar | `permission_handler` (kamera, joylashuv, mikrofon) |
| Rasm tanlash | `image_picker` |

## Loyihaning tuzilishi

```
lib/
  core/        — ApiConfig (backend URL), Dio client, xato turlari
  models/      — API javoblarining Dart modellari (Place, Friend, ChatMessage, ...)
  providers/   — Riverpod provider'lari (auth, place, chat, friend, call, ...)
  services/    — API chaqiruvchi servis qatlami (bir servis = bitta backend moduli)
  screens/     — har bir ekran uchun bitta fayl (pastga qarang)
  theme/       — ranglar, kategoriya ikonkalari
  utils/       — xarita marker chizish kabi yordamchi funksiyalar
  widgets/     — qayta ishlatiluvchi UI komponentlari
```

### Ekranlar (`lib/screens/`)

- **Kirish/ro'yxatdan o'tish:** welcome, onboarding (4 sahifali tanishtiruv),
  login, register, forgot/reset password, email tasdiqlash
- **Asosiy:** `main_shell_screen` (pastki navigatsiya), `explore_screen`
  (xarita + yaqin joylar + shahar/radius filtri), `search_screen`,
  `nearby_places_screen`, `place_detail_screen`, `saved_places_screen`,
  `filters_screen`
- **Check-in:** `check_in_screen`, `checked_in_success_screen`,
  `already_checked_in_screen`
- **Ijtimoiy:** `friends_screen`, `friend_profile_screen`,
  `conversations_screen`, `message_thread_screen`, `activity_screen`,
  `create_post_screen`, `shorts_screen`
- **Qo'ng'iroq:** `call_screen`, `incoming_call_screen`
- **Profil:** `profile_screen`, `edit_profile_screen`, `privacy_screen`,
  `help_support_screen`
- **Admin/biznes panel** (`screens/admin/`): super-admin dashboard,
  foydalanuvchi/joy/kategoriya boshqaruvi, biznes egasi uchun alohida
  login/dashboard — buyurtmalar, bron qilishlar, mahsulot inventari,
  mijozlar va sharhlar boshqaruvi

## Backend bilan ulanish

`lib/core/api_config.dart` backend manzilini quyidagi tartibda aniqlaydi:

1. `--dart-define=API_BASE_URL=...` bilan berilgan qiymat (bo'lsa)
2. **Release build** — har doim production'ga ulanadi: `https://mobile-mikka.onrender.com`
3. **Debug/profile** — Android emulyator: `http://10.0.2.2:3112`, boshqa
   platformalar: `http://localhost:3112` (lokal backend ishga tushirilgan bo'lishi kerak)

Fizik qurilmada lokal backend'ni sinash uchun:

```bash
flutter run --dart-define=API_BASE_URL=http://<kompyuter-ip>:3112
```

## Ishga tushirish

```bash
flutter pub get
flutter run                 # debug, lokal backend (10.0.2.2/localhost) bilan
```

### Release APK yasash

Qo'lda emas — har doim skript orqali (versiyani avtomatik oshiradi va
`releases/`ga toza nom bilan qo'yadi):

```bash
./build_release.sh          # releases/Mikka-<versiya>.apk
```

Bu skript `--dart-define=API_BASE_URL=https://mobile-mikka.onrender.com`
bilan, faqat `arm64` arxitekturasi uchun (hajmi ~3 baravar kichik) quradi —
so'nggi ~8 yillik deyarli barcha real Android qurilmalar shu arxitekturada.

Qurilgan APK'ni USB orqali ulangan qurilmaga o'rnatish:

```bash
adb install -r releases/Mikka-<versiya>.apk
```

## Muhim arxitektura qarorlari

- **Nearby/Explore qidiruvi** — standart radius 3 km, foydalanuvchi
  Explore ekranidagi xaritada 1/3/15 km orasida tanlashi mumkin
  (`selectedRadiusMetersProvider`, backend'dagi belgilangan presetlarga mos).
- **Shahar tanlash** — Explore ekranining yuqorisidagi joylashuv nomini
  bosib, GPS o'rniga O'zbekistonning 10 ta yirik shahridan birini tanlash
  mumkin (`selectedCityProvider`); xarita kamerasi va qidiruv koordinatasi
  shunga mos yangilanadi.
- **Check-in masofa tekshiruvi** — backend tomonidan amalga oshiriladi
  (`CHECK_IN_MAX_DISTANCE_METERS`, standart 200m); mobil ilova faqat
  qurilmaning joriy GPS koordinatasini yuboradi, masofani o'zi hisoblamaydi.
- **Marker rasmlari** — joy markerlari kategoriya ikonkasi bilan
  (`PlaceMarker`), do'stlar markerlari profil rasmi bilan (`AvatarMarker`)
  chiziladi — Google'ning standart qizil pin'i ishlatilmaydi.

## Litsenziya

Xususiy — ichki loyiha, `pub.dev`ga chiqarish uchun emas
(`publish_to: 'none'`).
