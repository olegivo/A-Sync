// swift-tools-version: 5.9
import PackageDescription

// macOS-приложение PhotoPull.
//
// Общая логика вынесена в KMP-модуль `shared` (Kotlin) и поставляется сюда как
// бинарный XCFramework `Shared.xcframework`. Перед сборкой приложения его нужно собрать:
//
//     ./gradlew :shared:assembleSharedReleaseXCFramework
//
// XCFramework появится по пути shared/build/XCFrameworks/release/Shared.xcframework
// и подключится к таргету PhotoPull через .binaryTarget ниже.
//
// Собирается только на macOS 13+ (нужны SwiftUI и ImageCaptureCore).
let package = Package(
    name: "PhotoPull",
    platforms: [
        .macOS(.v13)
    ],
    targets: [
        .binaryTarget(
            name: "Shared",
            path: "shared/build/XCFrameworks/release/Shared.xcframework"
        ),
        .executableTarget(
            name: "PhotoPull",
            dependencies: ["Shared"]
        )
    ]
)
