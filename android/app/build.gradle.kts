plugins {
    id("com.android.application")
    // START: FlutterFire Configuration
    id("com.google.gms.google-services")
    // END: FlutterFire Configuration
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

import org.gradle.api.artifacts.DependencyResolveDetails

android {
    namespace = "com.example.payment_reminder_app"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.example.payment_reminder_app"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        multiDexEnabled = true
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
        }
    }

    packagingOptions {
        jniLibs.pickFirsts.add("**/libc++_shared.so")
        jniLibs.pickFirsts.add("**/libjsc.so")
    }
}

configurations.all {
    resolutionStrategy.eachDependency { details: DependencyResolveDetails ->
        if (details.requested.group == "androidx.core" && details.requested.name == "core") {
            details.useVersion("1.12.0")
        }
        if (details.requested.group == "androidx.lifecycle" && details.requested.name.startsWith("lifecycle")) {
            details.useVersion("2.7.0")
        }
        if (details.requested.group == "androidx.activity" && details.requested.name == "activity") {
            details.useVersion("1.8.2")
        }
        if (details.requested.group == "androidx.fragment" && details.requested.name == "fragment") {
            details.useVersion("1.6.2")
        }
    }
}

dependencies {
    implementation("androidx.multidex:multidex:2.0.1")
}

flutter {
    source = "../.."
}
