pluginManagement {

    resolutionStrategy {
        eachPlugin {
            // 어떤 플러그인이든 'kotlin-android'를 요청하면,
            if (requested.id.id == "org.jetbrains.kotlin.android") {
                // 버전을 1.9.10으로 강제합니다.
                useVersion("2.2.0")
            }
        }
    }

    val flutterSdkPath = run {
        val properties = java.util.Properties()
        file("local.properties").inputStream().use { properties.load(it) }
        val flutterSdkPath = properties.getProperty("flutter.sdk")
        require(flutterSdkPath != null) { "flutter.sdk not set in local.properties" }
        flutterSdkPath
    }

    includeBuild("$flutterSdkPath/packages/flutter_tools/gradle")



    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }

}
// 파일 상단이나 pluginManagement 블록 아래에 이 부분을 추가합니다.
dependencyResolutionManagement {
    repositories {
        google()
        mavenCentral()
    }
    versionCatalogs {
        create("libs") {
            // 사용할 코틀린 버전을 여기에 명시적으로 정의합니다.
            // 경고 메시지에 따라 2.1.0으로 설정합니다.
            version("kotlin", "2.1.0")
        }
    }
}

plugins {
    id("dev.flutter.flutter-plugin-loader") version "1.0.0"
    id("com.android.application") version "8.7.0" apply false
    // START: FlutterFire Configuration
    id("com.google.gms.google-services") version("4.3.15") apply false
    // END: FlutterFire Configuration
    id("org.jetbrains.kotlin.android") version "2.1.0" apply false
}

include(":app")
