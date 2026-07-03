// swift-tools-version: 5.9
import PackageDescription

// PhotoPull — macOS-приложение для импорта фото/видео с iPhone через ImageCaptureCore.
//
// Структура намеренно разделена на два таргета:
//   * PhotoPullCore — чистая логика без зависимостей от Apple UI/ImageCaptureCore.
//     Компилируется и тестируется на любой платформе, где есть Swift (в т.ч. Linux CI).
//   * PhotoPull — исполняемый macOS-таргет (SwiftUI + ImageCaptureCore). Собирается
//     только на macOS 13+.
//
// Для сборки приложения открой Package.swift в Xcode на macOS и запусти схему PhotoPull.
let package = Package(
    name: "PhotoPull",
    platforms: [
        .macOS(.v13)
    ],
    targets: [
        .target(
            name: "PhotoPullCore"
        ),
        .executableTarget(
            name: "PhotoPull",
            dependencies: ["PhotoPullCore"]
        ),
        .testTarget(
            name: "PhotoPullCoreTests",
            dependencies: ["PhotoPullCore"]
        )
    ]
)
