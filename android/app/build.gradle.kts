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
//    FileInputStream(envFile).use { props.load(it) }
    props.load(FileInputStream(envFile))
}
val kakaoKey: String = props.getProperty("KAKAO_NATIVE_APP_KEY") ?:  ""
val naverClientId: String = props.getProperty("NAVER_CLIENT_ID") ?:  ""
val naverClientSecret : String = props.getProperty("NAVER_CLIENT_SECRET") ?: ""
val naverClientName: String = props.getProperty("NAVER_CLIENT_NAME") ?:  ""


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
        // For more information,  see: https://flutter.dev/to/review-gradle-config.

        resValue("string", "kakao_native_app_key", kakaoKey)
        manifestPlaceholders["KAKAO_NATIVE_APP_KEY"] = kakaoKey

        resValue("string", "client_id", naverClientId)
        resValue("string", "client_name", naverClientName)
        resValue("string","client_secret",naverClientSecret)
        manifestPlaceholders["CLIENT_SECRET"]=naverClientSecret
        manifestPlaceholders["CLIENT_ID"] = naverClientId
        manifestPlaceholders["CLIENT_NAME"] = naverClientName
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}
