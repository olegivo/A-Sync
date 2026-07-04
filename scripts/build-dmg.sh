#!/usr/bin/env bash
#
# Собирает PhotoPull.app из исполняемого таргета SwiftPM и упаковывает его в DMG.
#
# Требуется macOS с Xcode/Swift toolchain и установленным JDK (для сборки Kotlin
# XCFramework). Запуск из корня репозитория:
#
#     ./scripts/build-dmg.sh
#
# Результат: dist/PhotoPull-<version>.dmg
#
# Примечание: DMG получается НЕПОДПИСАННЫМ (нет Apple Developer аккаунта). При первом
# запуске Gatekeeper предупредит; обход описан в README (раздел «Установка из DMG»).
set -euo pipefail

APP_NAME="PhotoPull"
BUNDLE_ID="com.example.PhotoPull"
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUILD_CONFIG="release"
INFO_PLIST="${ROOT_DIR}/AppSupport/Info.plist"

VERSION="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "${INFO_PLIST}" 2>/dev/null || echo '0.1.0')"

STAGING_DIR="${ROOT_DIR}/.build/dmg-staging"
APP_BUNDLE="${STAGING_DIR}/${APP_NAME}.app"
DIST_DIR="${ROOT_DIR}/dist"
DMG_PATH="${DIST_DIR}/${APP_NAME}-${VERSION}.dmg"

echo "==> 1/5 Собираю Kotlin XCFramework (Shared)"
"${ROOT_DIR}/gradlew" -p "${ROOT_DIR}" :shared:assembleSharedReleaseXCFramework

echo "==> 2/5 Собираю исполняемый таргет (${BUILD_CONFIG})"
swift build --package-path "${ROOT_DIR}" -c "${BUILD_CONFIG}"

BIN_PATH="$(swift build --package-path "${ROOT_DIR}" -c "${BUILD_CONFIG}" --show-bin-path)/${APP_NAME}"
if [[ ! -f "${BIN_PATH}" ]]; then
    echo "ОШИБКА: не найден бинарник ${BIN_PATH}" >&2
    exit 1
fi

echo "==> 3/5 Собираю ${APP_NAME}.app"
rm -rf "${STAGING_DIR}"
mkdir -p "${APP_BUNDLE}/Contents/MacOS"
mkdir -p "${APP_BUNDLE}/Contents/Resources"

cp "${INFO_PLIST}" "${APP_BUNDLE}/Contents/Info.plist"
cp "${BIN_PATH}" "${APP_BUNDLE}/Contents/MacOS/${APP_NAME}"
chmod +x "${APP_BUNDLE}/Contents/MacOS/${APP_NAME}"
printf 'APPL????' > "${APP_BUNDLE}/Contents/PkgInfo"

# Ad-hoc подпись: убирает часть предупреждений и обязательна для Apple Silicon,
# чтобы бинарник вообще запускался. Полноценную подпись Developer ID не делаем.
echo "==> 4/5 Ad-hoc codesign"
codesign --force --deep --sign - --identifier "${BUNDLE_ID}" "${APP_BUNDLE}" || {
    echo "ПРЕДУПРЕЖДЕНИЕ: codesign не выполнен (продолжаю без подписи)" >&2
}

echo "==> 5/5 Упаковываю DMG"
rm -rf "${DIST_DIR}"
mkdir -p "${DIST_DIR}"
# Ссылка на /Applications для drag-and-drop установки.
ln -s /Applications "${STAGING_DIR}/Applications"

hdiutil create \
    -volname "${APP_NAME}" \
    -srcfolder "${STAGING_DIR}" \
    -ov \
    -format UDZO \
    "${DMG_PATH}"

echo ""
echo "Готово: ${DMG_PATH}"
