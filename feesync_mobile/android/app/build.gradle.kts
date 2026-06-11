plugins {
    id("com.android.application")
    // START: FlutterFire Configuration
    id("com.google.gms.google-services")
    // END: FlutterFire Configuration
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.feesync.feesync_mobile"
    compileSdk = 36
    // buildToolsVersion = "35.0.0"
    ndkVersion = "28.2.13676358"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        applicationId = "com.feesync.feesync_mobile"
        minSdk = flutter.minSdkVersion
        targetSdk = 36
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        multiDexEnabled = true

        // ndk {
        //     abiFilters.add("armeabi-v7a")
        //     abiFilters.add("arm64-v8a")
        //     abiFilters.add("x86_64")
        // }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
            // Disable R8 shrinking for beta to avoid stripping needed classes
            isMinifyEnabled = false
            isShrinkResources = false
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }

    packaging {
        resources {
            excludes.add("lib/armeabi/**")
            excludes.add("lib/mips/**")
            excludes.add("lib/mips64/**")
        }
    }
}

flutter {
    source = "../.."
}
