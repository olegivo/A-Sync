import org.jetbrains.kotlin.gradle.plugin.mpp.apple.XCFramework

plugins {
    kotlin("multiplatform")
}

kotlin {
    // JVM-таргет: на нём гоняются тесты общей логики на любом хосте (в т.ч. Linux CI, ×1).
    jvm {
        testRuns["test"].executionTask.configure {
            useJUnitPlatform()
        }
    }

    // Apple-таргеты: собираются только на macOS-хосте. Из них собирается XCFramework,
    // который подключается к нативному macOS-приложению (Swift).
    val xcf = XCFramework("Shared")

    val appleTargets = listOf(
        macosArm64(),
        macosX64(),
        // Заготовки под будущее расширение (iOS-компаньон / CMP):
        iosArm64(),
        iosSimulatorArm64()
    )

    appleTargets.forEach { target ->
        target.binaries.framework {
            baseName = "Shared"
            isStatic = true
            xcf.add(this)
        }
    }

    sourceSets {
        val commonMain by getting
        val commonTest by getting {
            dependencies {
                implementation(kotlin("test"))
            }
        }
    }
}
