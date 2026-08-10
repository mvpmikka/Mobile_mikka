#!/usr/bin/env bash
# Har safar kodda o'zgarish qilgach shu skriptni ishga tushiring:
#   ./build_release.sh
# U pubspec.yaml'dagi build raqamini avtomatik oshiradi (shuning uchun
# Android har doim buni "yangi versiya" deb tan oladi va eskisi ustiga
# o'rnatib qo'yadi), keyin release APK'larni yig'ib, versiyalangan nomlar
# bilan build/app/outputs/flutter-apk/ ichiga nusxalaydi.
set -euo pipefail

cd "$(dirname "$0")"

PUBSPEC="pubspec.yaml"
CURRENT_LINE=$(grep -E '^version: ' "$PUBSPEC")
VERSION_NAME=$(echo "$CURRENT_LINE" | sed -E 's/^version: ([0-9]+\.[0-9]+\.[0-9]+)\+([0-9]+)$/\1/')
CURRENT_BUILD=$(echo "$CURRENT_LINE" | sed -E 's/^version: ([0-9]+\.[0-9]+\.[0-9]+)\+([0-9]+)$/\2/')
NEW_BUILD=$((CURRENT_BUILD + 1))

sed -i '' "s/^version: .*/version: ${VERSION_NAME}+${NEW_BUILD}/" "$PUBSPEC"
echo "Versiya: ${VERSION_NAME}+${CURRENT_BUILD} -> ${VERSION_NAME}+${NEW_BUILD}"

flutter build apk --release --split-per-abi \
  --dart-define=API_BASE_URL=https://mobile-mikka.onrender.com
flutter build apk --release \
  --dart-define=API_BASE_URL=https://mobile-mikka.onrender.com

OUT_DIR="build/app/outputs/flutter-apk"
TAG="v${VERSION_NAME}-b${NEW_BUILD}"

cp "$OUT_DIR/app-arm64-v8a-release.apk" "$OUT_DIR/Mikka-${TAG}-arm64.apk"
cp "$OUT_DIR/app-armeabi-v7a-release.apk" "$OUT_DIR/Mikka-${TAG}-armeabi-v7a.apk"
cp "$OUT_DIR/app-x86_64-release.apk" "$OUT_DIR/Mikka-${TAG}-x86_64.apk"
cp "$OUT_DIR/app-release.apk" "$OUT_DIR/Mikka-${TAG}-universal.apk"

ARM64_SIZE=$(du -h "$OUT_DIR/Mikka-${TAG}-arm64.apk" | cut -f1)
UNIVERSAL_SIZE=$(du -h "$OUT_DIR/Mikka-${TAG}-universal.apk" | cut -f1)

echo ""
echo "Tayyor! Fayllar shu papkada: $OUT_DIR"
echo ""
echo "TESTERLARGA SHUNI YUBORING (hajmi kichik, oxirgi 6 yildagi barcha haqiqiy Android telefonlarda ochiladi):"
echo "  Mikka-${TAG}-arm64.apk       ($ARM64_SIZE)"
echo ""
echo "Faqat quyidagi holatlarda universal faylni yuboring (2-3 barobar katta, lekin har qanday qurilmada ochiladi):"
echo "  Mikka-${TAG}-universal.apk   ($UNIVERSAL_SIZE) <- juda eski (32-bit) telefon yoki noma'lum qurilma bo'lsa"
echo "  Mikka-${TAG}-armeabi-v7a.apk <- eski/32-bit telefonlar"
echo "  Mikka-${TAG}-x86_64.apk      <- faqat emulyator/Intel qurilmalar"
