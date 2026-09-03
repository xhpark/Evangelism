import java.util.Properties
import java.io.FileInputStream
import java.util.Base64
import java.nio.charset.StandardCharsets

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// 배포용 서명 설정.
// android/key.properties 파일이 있을 때만 release 빌드를 허용한다.
// (key.properties와 .jks 파일은 절대 저장소에 커밋하지 않는다 — .gitignore 등록됨)
// 키 생성:
//   keytool -genkey -v -keystore D:/keys/just-ee-release.jks -keyalg RSA //           -keysize 2048 -validity 10000 -alias just-ee
val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties()
val hasReleaseKeystore = keystorePropertiesFile.exists()
val isReleaseBuild = gradle.startParameter.taskNames.any {
    it.contains("release", ignoreCase = true)
}
if (isReleaseBuild) {
    if (!hasReleaseKeystore) {
        throw GradleException("Release signing requires android/key.properties.")
    }
    val rawDartDefines = project.findProperty("dart-defines") as String?
    val hasValidServerUrl = if (!rawDartDefines.isNullOrBlank()) {
        rawDartDefines.split(",").mapNotNull { entry ->
            try {
                val bytes = Base64.getDecoder().decode(entry)
                String(bytes, StandardCharsets.UTF_8)
            } catch (_: Exception) {
                null
            }
        }.any { define: String ->
            define.startsWith("LICENSE_API_URL=https://script.google.com/macros/s/", ignoreCase = false) &&
            define.endsWith("/exec", ignoreCase = false)
        }
    } else {
        false
    }
    if (!hasValidServerUrl) {
        throw GradleException(
            "Release APK build failed: LICENSE_API_URL is missing or invalid in --dart-define. " +
            "Please run 'powershell scripts/build_release_apk.ps1' or provide --dart-define=LICENSE_API_URL=https://script.google.com/macros/s/.../exec " +
            "to prevent generating an unactivatable APK."
        )
    }
}
if (hasReleaseKeystore) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    namespace = "com.evangelism.just_ee.just_ee_master"
    compileSdk = 37

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.evangelism.just_ee.just_ee_master"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        if (hasReleaseKeystore) {
            create("release") {
                keyAlias = keystoreProperties["keyAlias"] as String
                keyPassword = keystoreProperties["keyPassword"] as String
                storeFile = file(keystoreProperties["storeFile"] as String)
                storePassword = keystoreProperties["storePassword"] as String
            }
        }
    }

    buildTypes {
        release {
            signingConfig = if (hasReleaseKeystore) {
                signingConfigs.getByName("release")
            } else {
                // debug 빌드 구성 단계에서만 도달한다. release 태스크는 위에서 중단된다.
                signingConfigs.getByName("debug")
            }
            isMinifyEnabled = false
            isShrinkResources = false
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}
