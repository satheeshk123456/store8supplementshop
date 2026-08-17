plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
    // Applies android/app/google-services.json at build time (see ../../../SETUP.md).
    id("com.google.gms.google-services")
}

android {
    // TODO before you publish: rename this package (Android Studio -> right-click the
    // com.example.store8 folder under app/src/main/kotlin -> Refactor -> Rename -> Rename
    // package, e.g. to com.store8.admin) and register that exact name in the Firebase console
    // (see ../../../SETUP.md) so google-services.json matches. Left as the default for now so
    // this project builds out of the box without any manual file moves.
    namespace = "com.example.store8"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        isCoreLibraryDesugaringEnabled = true // Fixed for Kotlin DSL syntax
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = "17" // Fixed the deprecation error by using a standard string
    }

    defaultConfig {
        applicationId = "com.example.store8"
        // Firebase Auth/Messaging require API 23+; Flutter's own default can be lower.
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

dependencies {
    // Added the required library for desugaring
coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}