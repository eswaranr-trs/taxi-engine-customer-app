import java.io.FileInputStream
import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
    id("com.google.firebase.crashlytics")
}

// Maps SDK key for the native map view. It is read by the OS at process start,
// so unlike the REST key it cannot come from /customer/auth/configs/mapApiKey —
// it has to be baked in at build time. Kept out of the manifest (and therefore
// out of git) by injecting it from the gitignored root .env.
//
// Use ANDROID_MAPS_API_KEY for a key restricted to Android apps (package +
// SHA-1). GOOGLE_MAPS_API_KEY is only a fallback so existing checkouts build.
val mapsApiKey: String = run {
    val envFile = rootProject.file("../.env")
    if (!envFile.exists()) return@run ""
    val props = Properties()
    FileInputStream(envFile).use { props.load(it) }
    (props.getProperty("ANDROID_MAPS_API_KEY")
        ?: props.getProperty("GOOGLE_MAPS_API_KEY")
        ?: "").trim()
}

if (mapsApiKey.isEmpty()) {
    logger.warn("WARNING: no ANDROID_MAPS_API_KEY/GOOGLE_MAPS_API_KEY in .env — the map view will render blank.")
}

android {
    namespace = "com.thereciprocalsolutions.orange_taxi_customer_app"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.thereciprocalsolutions.orange_taxi_customer_app"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName

        manifestPlaceholders["MAPS_API_KEY"] = mapsApiKey
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

dependencies {
    implementation(platform("com.google.firebase:firebase-bom:34.13.0"))
    implementation("com.google.firebase:firebase-analytics")

    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}

flutter {
    source = "../.."
}
