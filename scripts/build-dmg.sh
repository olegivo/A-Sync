#!/usr/bin/env bash
#
# Собирает PhotoPull.app (полноценный Xcode App-таргет через XcodeGen) и упаковывает в DMG.
#
# Требуется macOS с Xcode, XcodeGen (`brew install xcodegen`) и JDK (для Kotlin XCFramework).
# Запуск из корня репозитория:
#
#     ./scripts/build-dmg.sh
#
# Результат: dist/PhotoPull-<version>.dmg
#
# Примечание: приложение подписывается ad-hoc (нет Apple Developer аккаунта). При первом
# запуске Gatekeeper предупредит; обход описан в README (раздел «Установка из DMG»).
set -euo pipefail

APP_NAME="PhotoPull"
BUNDLE_ID="io.github.olegivo.PhotoPull"
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
INFO_PLIST="${ROOT_DIR}/AppSupport/Info.plist"
ENTITLEMENTS="${ROOT_DIR}/AppSupport/PhotoPull.entitlements"

VERSION="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "${INFO_PLIST}" 2>/dev/null || echo '0.1.0')"

DERIVED="${ROOT_DIR}/.build/xcode"
STAGING_DIR="${ROOT_DIR}/.build/dmg-staging"
DIST_DIR="${ROOT_DIR}/dist"
DMG_PATH="${DIST_DIR}/${APP_NAME}-${VERSION}.dmg"

echo "==> 1/5 Собираю Kotlin XCFramework (Shared)"
"${ROOT_DIR}/gradlew" -p "${ROOT_DIR}" :shared:assembleSharedReleaseXCFramework

echo "==> 2/5 Генерирую Xcode-проект (XcodeGen)"
( cd "${ROOT_DIR}" && xcodegen generate )

echo "==> 3/5 Собираю App-таргет (Release, ad-hoc signing)"
xcodebuild \
    -project "${ROOT_DIR}/${APP_NAME}.xcodeproj" \
    -scheme "${APP_NAME}" \
    -configuration Release \
    -derivedDataPath "${DERIVED}" \
    CODE_SIGN_IDENTITY="-" \
    CODE_SIGNING_REQUIRED=NO \
    CODE_SIGNING_ALLOWED=YES \
    build

APP_SRC="${DERIVED}/Build/Products/Release/${APP_NAME}.app"
if [[ ! -d "${APP_SRC}" ]]; then
    echo "ОШИБКА: не найден бандл ${APP_SRC}" >&2
    exit 1
fi

echo "==> 4/5 Ad-hoc codesign (с entitlements)"
# Без --deep (помечен Apple как deprecated). Бандл не содержит вложенных фреймворков/дилибов
# (Shared.xcframework статический), поэтому достаточно подписать сам бандл.
codesign --force --sign - \
    --entitlements "${ENTITLEMENTS}" \
    --identifier "${BUNDLE_ID}" \
    "${APP_SRC}" || echo "ПРЕДУПРЕЖДЕНИЕ: codesign не выполнен" >&2

echo "==> 5/5 Упаковываю DMG"
rm -rf "${STAGING_DIR}" "${DIST_DIR}"
mkdir -p "${STAGING_DIR}" "${DIST_DIR}"
cp -R "${APP_SRC}" "${STAGING_DIR}/${APP_NAME}.app"
ln -s /Applications "${STAGING_DIR}/Applications"

hdiutil create \
    -volname "${APP_NAME}" \
    -srcfolder "${STAGING_DIR}" \
    -ov \
    -format UDZO \
    "${DMG_PATH}"

echo ""
echo "Готово: ${DMG_PATH}"
