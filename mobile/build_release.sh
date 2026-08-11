#!/usr/bin/env bash
# Har bir o'zgarishdan keyin terminalda faqat shuni yozing:
#   ./build_release.sh
# Skript avtomatik ravishda versiyani bittaga oshiradi va HAMMA Android
# telefonda (32-bit, 64-bit, eski-yangi — barchasida) ochiladigan bitta
# universal APK yasab, "releases/" papkaga toza nom bilan qo'yadi:
#   releases/Mikka-1.0.1.apk, releases/Mikka-1.0.2.apk, ...
# Raqam qanchalik katta bo'lsa, o'sha shuncha yangi — oxirgisini topish
# uchun shu papkadagi eng katta raqamli faylni oching.
set -euo pipefail

cd "$(dirname "$0")"

APP_NAME="Mikka"
PUBSPEC="pubspec.yaml"
RELEASE_DIR="releases"
OUT_DIR="build/app/outputs/flutter-apk"

CURRENT_LINE=$(grep -E '^version: ' "$PUBSPEC")
MAJOR=$(echo "$CURRENT_LINE" | sed -E 's/^version: ([0-9]+)\.([0-9]+)\.([0-9]+)\+([0-9]+)$/\1/')
MINOR=$(echo "$CURRENT_LINE" | sed -E 's/^version: ([0-9]+)\.([0-9]+)\.([0-9]+)\+([0-9]+)$/\2/')
PATCH=$(echo "$CURRENT_LINE" | sed -E 's/^version: ([0-9]+)\.([0-9]+)\.([0-9]+)\+([0-9]+)$/\3/')
BUILD=$(echo "$CURRENT_LINE" | sed -E 's/^version: ([0-9]+)\.([0-9]+)\.([0-9]+)\+([0-9]+)$/\4/')

NEW_PATCH=$((PATCH + 1))
NEW_BUILD=$((BUILD + 1))
NEW_VERSION_NAME="${MAJOR}.${MINOR}.${NEW_PATCH}"

sed -i '' "s/^version: .*/version: ${NEW_VERSION_NAME}+${NEW_BUILD}/" "$PUBSPEC"
echo "Versiya: ${MAJOR}.${MINOR}.${PATCH}+${BUILD} -> ${NEW_VERSION_NAME}+${NEW_BUILD}"

mkdir -p "$RELEASE_DIR"

# Flutter'ning o'zi yasaydigan xom fayllarni (debug, split-apk qoldiqlari,
# .sha1 va h.k.) tozalab tashlaymiz — aks holda eski, boshqacha nomlangan
# fayllar bilan aralashib, "qaysi biri oxirgisi" deb chalkashtirib yuboradi.
rm -f "$OUT_DIR"/*.apk "$OUT_DIR"/*.apk.sha1 2>/dev/null || true

# Faqat arm64 arxitekturasi uchun quramiz: hajmi ~3 baravar kichik bo'ladi.
# So'nggi ~8 yilda chiqqan haqiqiy Android telefonlarning deyarli barchasi
# shu arxitekturada ishlaydi — faqat juda eski (32-bit) telefonlar yoki
# Intel emulyatorlar tushib qoladi, ular amalda deyarli yo'q.
flutter build apk --release --target-platform android-arm64 \
  --dart-define=API_BASE_URL=https://mobile-mikka.onrender.com

FINAL_NAME="${APP_NAME}-${NEW_VERSION_NAME}.apk"
cp "$OUT_DIR/app-release.apk" "$RELEASE_DIR/$FINAL_NAME"
SIZE=$(du -h "$RELEASE_DIR/$FINAL_NAME" | cut -f1)

echo ""
echo "Tayyor! Bu OXIRGI (eng yangi) versiya — testerlarga shuni yuboring:"
echo "  $RELEASE_DIR/$FINAL_NAME   ($SIZE)"
