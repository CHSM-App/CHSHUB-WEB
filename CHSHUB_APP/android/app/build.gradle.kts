plugins {
    id("com.android.application")
    id("kotlin-android")

    // 🔹 Flutter Gradle Plugin must be applied after Android/Kotlin
    id("dev.flutter.flutter-gradle-plugin")

    // 🔹 Google Services plugin for Firebase
    id("com.google.gms.google-services")
}

android {
    namespace = "com.example.society_app"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = "27.0.12077973" // flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        applicationId = "com.example.society_app"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // TODO: Replace with your own release signing config
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    implementation("androidx.core:core:1.12.0")

   implementation(platform("com.google.firebase:firebase-bom:33.1.2"))
    implementation("com.google.firebase:firebase-messaging")
     coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.4")
}
