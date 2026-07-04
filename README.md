# A-Sync — PhotoPull

**PhotoPull** — минималистичное macOS-приложение для импорта фото и видео с iPhone на Mac
через **ImageCaptureCore**. Приложение на телефоне не требуется.

Проект построен на **Kotlin Multiplatform (KMP)**: общая логика вынесена в модуль `shared`
(Kotlin) и переиспользуется как нативный фреймворк в macOS-приложении. Это задел под
будущее расширение на другие платформы (Android / iOS-компаньон) и, что важно уже сейчас,
позволяет тестировать логику на дешёвом Linux-CI.

📖 **Инструкция пользователя со скриншотами состояний:** [`docs/USER_GUIDE.md`](docs/USER_GUIDE.md)
(также публикуется как сайт **GitHub Pages** — см. раздел «Инструкция онлайн (GitHub Pages)»).

## Что делает MVP

- в настройках задаётся **папка приёма**, **режим** (`копировать` / `переместить`) и
  **фильтр «только новые файлы»** (импортировать только файлы новее, чем `сегодня − N дней`,
  по дате создания);
- **обнаружение iPhone** — по кабелю (USB) и по сети (Bonjour);
- **запуск импорта — ручной** (кнопка «Импортировать»).

## Архитектура

```
A-Sync/                         # Gradle KMP-проект
├─ settings.gradle.kts
├─ build.gradle.kts
├─ gradle/wrapper/…             # Gradle wrapper (9.1.0 — совместим с AGP 9)
├─ shared/                      # KMP-модуль общей логики (Kotlin)
│  ├─ build.gradle.kts          # таргеты: jvm + macos/ios (XCFramework "Shared")
│  └─ src/
│     ├─ commonMain/kotlin/com/async/shared/
│     │  ├─ TransferMode.kt      # режим копировать/переместить
│     │  ├─ FilenameResolver.kt  # разрешение конфликтов имён
│     │  ├─ DateFilter.kt        # фильтр «только новые файлы» по дате
│     │  └─ ImportResult.kt      # сводка импорта
│     └─ commonTest/kotlin/…     # тесты логики (гоняются на JVM/Linux, ×1)
├─ project.yml                 # спецификация Xcode App-таргета (XcodeGen)
├─ Package.swift                # быстрая проверка компиляции (SwiftPM), зависит от Shared.xcframework
├─ scripts/build-dmg.sh         # сборка .app + DMG
├─ Sources/PhotoPull/           # Swift + SwiftUI + ImageCaptureCore
│  ├─ Interop/SharedInterop.swift  # единственная точка Kotlin↔Swift-интеропа
│  ├─ State/                    # AppSettings, SettingsStore
│  ├─ Services/                 # CameraBrowser, Importer, DiscoveredDevice
│  └─ Views/                    # ContentView и разделы UI
└─ AppSupport/                  # Info.plist и entitlements для сборки .app в Xcode
```

Граница «общее vs платформенное» намеренно совпадает с границей «дёшево vs дорого в CI»:
чистая логика (`shared/commonMain`) тестируется на бесплатном Linux-раннере, а дорогой
macOS-раннер используется только для сборки Apple-артефактов.

## Как это работает (импорт)

Приложение использует системный фреймворк `ImageCaptureCore` (тот же механизм, что и
«Захват изображений»/«Фото»):

1. `ICDeviceBrowser` находит подключённые камеры, включая iPhone.
2. На выбранном устройстве открывается сессия (`requestOpenSession`).
3. После готовности каталога контента список фильтруется по дате создания
   (`ICCameraItem.creationDate` с фолбэком на `ICCameraFile.fileCreationDate`) — если включён
   фильтр «только новые файлы».
4. Отфильтрованные файлы скачиваются по одному (`requestDownloadFile(_:options:...)`) в папку
   назначения.
5. В режиме **«Переместить»** к загрузке добавляется опция
   `ICDeleteAfterSuccessfulDownload`, и оригинал удаляется с устройства после успешной загрузки.

## Ограничение Wi-Fi (важно)

Требование «обнаружение по Wi-Fi» имеет принципиальное ограничение: **iPhone, как правило,
не публикует свою фотоплёнку для Image Capture по Wi-Fi** (в отличие от части сетевых камер
с поддержкой PTP/IP). Поэтому:

- **USB (кабель)** — работает стабильно и полнофункционально; это основной канал MVP.
- **Wi-Fi** — сетевой режим обнаружения включён в коде (`ICDeviceLocationTypeMask.bonjour`)
  и будет работать для совместимых сетевых устройств, но **надёжное беспроводное обнаружение
  именно iPhone без приложения-компаньона на телефоне не гарантируется**.

## Сборка и запуск

### 1. Тесты общей логики (любой хост с JDK 17+, включая Linux)

```bash
./gradlew :shared:jvmTest
```

### 2. Сборка macOS-приложения (только macOS 13+, Xcode 15+)

Общий шаг для любого способа — собрать XCFramework из KMP-модуля:

```bash
./gradlew :shared:assembleSharedReleaseXCFramework
```

XCFramework появляется по пути `shared/build/XCFrameworks/release/Shared.xcframework`.

**Полноценный App-таргет (рекомендуется).** Xcode-проект генерируется из `project.yml`
через [XcodeGen](https://github.com/yonaskolb/XcodeGen) — сам `.xcodeproj` в репозиторий не
коммитится, а детерминированно создаётся командой:

```bash
brew install xcodegen        # однократно
xcodegen generate            # создаст PhotoPull.xcodeproj
open PhotoPull.xcodeproj      # собрать/запустить схему PhotoPull (⌘R)
```

Этот таргет — настоящее приложение с `AppSupport/Info.plist`, entitlements (песочница, USB,
доступ к выбранной папке) и линковкой `Shared.xcframework`.

**Быстрая проверка компиляции (без бандла).** Есть также `Package.swift`, который собирает
исполняемый бинарник через SwiftPM (используется в CI для дешёвой проверки компиляции):

```bash
swift build
```

### 3. Сборка DMG для установки (macOS)

```bash
./scripts/build-dmg.sh
```

Скрипт собирает `Shared.xcframework`, генерирует Xcode-проект (`xcodegen`), собирает
App-таргет через `xcodebuild` (Release), подписывает ad-hoc с entitlements и создаёт
`dist/PhotoPull-<version>.dmg` со ссылкой на `/Applications` для drag-and-drop установки.
Требуется `brew install xcodegen`.

#### Скачивание DMG из CI

- **С каждого прогона CI** (PR/push в `main`): job **Build macOS app & DMG** в workflow
  `CI` собирает DMG и выкладывает его как artifact **PhotoPull-dmg**. Скачать:
  GitHub → **Actions** → нужный прогон → раздел **Artifacts**.
- **По тегу `vX.Y.Z`**: workflow **Release DMG** дополнительно прикрепляет DMG к
  **GitHub Release** — это постоянная ссылка для скачивания (раздел Releases).
- **Вручную**: workflow **Release DMG** → **Run workflow** (`workflow_dispatch`) → artifact.

> Artifact — это zip с `.dmg` внутри (GitHub всегда упаковывает artifacts в zip);
> распакуйте, чтобы получить сам `PhotoPull-<version>.dmg`.

#### Установка из DMG (обход Gatekeeper)

DMG **не подписан** Developer ID (нет Apple Developer аккаунта, публикация не планируется),
поэтому при первом запуске macOS покажет предупреждение «неизвестный разработчик». Варианты:

- ПКМ по приложению → **«Открыть»** → подтвердить; либо
- снять карантинный атрибут:

```bash
xattr -dr com.apple.quarantine /Applications/PhotoPull.app
```

## Совместимость версий (готовность к Android / AGP 9)

Тулчейн приведён к требованиям **Android Gradle Plugin 9**, чтобы будущий Android-таргет
подключался без миграции фундамента:

| Компонент | Версия | Требование AGP 9 | Статус |
|---|---|---|---|
| Gradle | 9.1.0 | ≥ 9.1.0 | ✅ |
| JDK | 17+ (в CI — 21) | ≥ 17 | ✅ |
| Kotlin | 2.4.0 | встроенная поддержка Kotlin в AGP 9 | ✅ |
| AGP | — (пока нет Android-таргета) | 9.0.1+ | добавляется вместе с Android-модулем |

Когда добавится Android-клиент (например, CMP или отдельное Android-приложение), нужно будет:

1. подключить `com.android.library` / `com.android.application` версии **9.x** (AGP 9 имеет
   встроенную поддержку Kotlin — отдельный `kotlin-android` не нужен);
2. добавить `androidTarget()` в `shared/build.gradle.kts` и блок `android { … }`;
3. установить Android SDK (Build Tools 36.0.0+, `compileSdk`/`targetSdk` ≥ 36);
4. android-unit-тесты общей логики также поедут на дешёвый Linux-раннер (×1).

## CI

Пайплайн (`.github/workflows/ci.yml`) разнесён по стоимости:

- **`logic-tests`** — `./gradlew :shared:jvmTest` на `ubuntu-latest` (×1, дёшево);
- **`macos-build`** — сборка XCFramework и `swift build` на `macos-14` (×10, только сборка).

## Инструкция онлайн (GitHub Pages)

Инструкция пользователя публикуется как статический сайт из `docs/USER_GUIDE.md`.

- Сборка сайта: `python3 scripts/build_site.py` (нужен `pip install markdown`) → каталог `_site/`.
- Деплой: workflow `.github/workflows/pages.yml` собирает сайт и публикует через
  `actions/deploy-pages` при push в `main` (или вручную через **Run workflow**).

**Как включить (однократно):**

1. **Settings → Pages → Source = «GitHub Actions»**.
2. Запустить workflow **Deploy user guide to GitHub Pages** (или сделать push в `main`).
3. Адрес сайта появится в логе джобы `deploy` и в **Settings → Pages**.

> ⚠️ Для **приватного** репозитория GitHub Pages доступен только на платных планах
> (GitHub Pro/Team/Enterprise). На бесплатном плане опубликовать Pages можно, только сделав
> репозиторий публичным.

## Статус проверки

- **Логика (`shared`)** — покрыта тестами и **прогнана на JVM локально (15 тестов, зелёные)**.
- **macOS-приложение и Kotlin↔Swift-интероп** — написаны под актуальные API, но требуют
  сборки в Xcode на macOS: среда разработки (Linux) не содержит Swift-тулчейна, Apple-SDK
  и Kotlin/Native Apple-таргетов. Реальные сценарии с устройством/USB проверяются вручную
  на Mac с подключённым iPhone.
