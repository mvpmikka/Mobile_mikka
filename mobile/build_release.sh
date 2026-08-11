#!/usr/bin/env bash
# Har safar kodda o'zgarish qilgach, terminalda shuni yozing:
#   ./build_release.sh
# Skript avtomatik ravishda versiyani bittaga oshiradi va bitta kichik,
# hamma (oxirgi ~8 yildagi) Android telefonda ochiladigan APK yasab,
# loyiha nomi + versiya bilan nomlab beradi. Masalan: Mikka-1.0.5.apk
set -euo pipefail

cd "$(dirname "$0")"

APP_NAME="Mikka"
PUBSPEC="pubspec.yaml"

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

# Faqat arm64 arxitekturasi uchun quramiz: hajmi kichik bo'ladi va so'nggi
# ~8 yilda chiqqan haqiqiy Android telefonlarning deyarli barchasi shu
# arxitekturada ishlaydi (faqat juda eski 32-bit telefonlar yoki
# emulyatorlar tushib qoladi).
flutter build apk --release --target-platform android-arm64 \
  --dart-define=API_BASE_URL=https://mobile-mikka.onrender.com

OUT_DIR="build/app/outputs/flutter-apk"
FINAL_NAME="${APP_NAME}-${NEW_VERSION_NAME}.apk"

cp "$OUT_DIR/app-release.apk" "$OUT_DIR/$FINAL_NAME"
SIZE=$(du -h "$OUT_DIR/$FINAL_NAME" | cut -f1)

echo ""
echo "Tayyor! Testerlarga shuni yuboring:"
echo "  $OUT_DIR/$FINAL_NAME   ($SIZE)"
