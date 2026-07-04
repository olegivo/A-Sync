# AGENTS.md

## Cursor Cloud specific instructions

PhotoPull — это Kotlin Multiplatform (KMP) + нативное macOS-приложение (Swift/SwiftUI/
ImageCaptureCore). Общая логика импорта живёт в модуле `shared` (Kotlin), а UI и работа
с устройством — в `Sources/PhotoPull` (Swift).

### Что можно и что нельзя делать на Linux (Cursor Cloud)

- **Можно на Linux:** общая логика `shared` (JVM-таргет) и сборка сайта документации.
- **Нельзя на Linux:** macOS-приложение (`swift build`, `xcodegen`, `xcodebuild`,
  `./scripts/build-dmg.sh`). Требуются Xcode, Apple SDK и Kotlin/Native Apple-таргеты —
  их нет на Linux. Эти шаги проверяются только на macOS-раннере в CI (см. `.github/workflows/ci.yml`,
  job `macos-build`). Не пытайтесь собирать App/DMG на Linux.

### Команды (запускать из корня репозитория)

- **Тесты общей логики:** `./gradlew :shared:jvmTest --console=plain` (28 тестов, JVM).
- **Проверка/«lint»:** `./gradlew :shared:check`. Отдельного линтера (ktlint/detekt) в проекте
  нет; `check` на Linux прогоняет `jvmTest` и компилирует Kotlin/Native klib-ы. Нативные
  тесты (`macosArm64Test`/`macosX64Test`) при этом **SKIPPED** — это ожидаемо на Linux
  (линковка нативных исполняемых тестов недоступна), сборка остаётся BUILD SUCCESSFUL.
- **Сборка сайта документации (GitHub Pages):** `python3 scripts/build_site.py` → каталог
  `_site/`. Требует Python-пакет `markdown` (ставится update-скриптом). Локальный просмотр:
  `python3 -m http.server -d _site 8099`.

### Нюансы

- JDK 21 предустановлен; Gradle wrapper (9.1.0) сам скачивает дистрибутив при первом запуске.
- Предупреждение `'fun macosX64()' is deprecated` при конфигурации Gradle — безвредно.
- `kotlin.native.ignoreDisabledTargets=true` (`gradle.properties`) позволяет собирать/тестировать
  JVM-таргет на Linux без Apple-тулчейна.
- `_site/`, `.gradle/`, `build/` — генерируемые артефакты (в `.gitignore`), не коммитить.
