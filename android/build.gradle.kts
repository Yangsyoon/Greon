// android/build.gradle.kts

// 1. AGP 버전을 8.9.1 이상으로 업데이트하기 위해 buildscript 블록을 추가/수정합니다.
buildscript {
    repositories {
        google()
        mavenCentral()
    }
    dependencies {
        // AGP 버전을 8.10.0으로 업데이트하여 androidx 라이브러리 충돌을 해결합니다.
        classpath("com.android.tools.build:gradle:8.9.1")
    }
}

allprojects {
    repositories {
        google()
        mavenCentral()
    }

    // 🛠️ 주의: 이전에 추가했던 resolutionStrategy 블록을 제거합니다.
    // 플러그인과의 충돌 때문에 AGP 업데이트가 필요합니다.
}
// ----------------------------------------------------------------------

val newBuildDir: org.gradle.api.file.Directory = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: org.gradle.api.file.Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}

subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}