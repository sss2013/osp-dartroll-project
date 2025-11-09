import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val envFile = rootProject.file(".env")
val props = Properties()
if (envFile.exists()) {
    props.load(FileInputStream(envFile))
}
val kakaoKey: String = props.getProperty("KAKAO_NATIVE_APP_KEY") ?: ""
val naverClientId: String = props.getProperty("CLIENT_ID") ?: ""
val naverClientName: String = props.getProperty("CLIENT_NAME") ?: ""


android {
    namespace = "S25osp.kr.ac.kumoh.dartroll_front"

    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "S25osp.kr.ac.kumoh.dartroll_front"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.

        resValue("string", "kakao_native_app_key", kakaoKey)
        resValue("string", "naver_client_id", naverClientId)
        resValue("string", "naver_client_name", naverClientName)
        manifestPlaceholders["KAKAO_NATIVE_APP_KEY"] = kakaoKey
        manifestPlaceholders["NAVER_CLIENT_ID"] = naverClientId
        manifestPlaceholders["NAVER_CLIENT_NAME"] = naverClientName
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}
