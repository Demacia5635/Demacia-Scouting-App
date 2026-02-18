plugins {
    id("com.android.application")
    // START: FlutterFire Configuration
    // END: FlutterFire Configuration
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.scouting_qr_maker"
    compileSdk = 34  // Changed from flutter.compileSdkVersion
    ndkVersion = "25.1.8937393"
    
    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }
    
    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }
    
    defaultConfig {
        applicationId = "com.example.scouting_qr_maker"
        minSdk = flutter.minSdkVersion  // Changed from flutter.minSdkVersion
        targetSdk = 34  // Changed from flutter.targetSdkVersion
        versionCode = 1  // Changed from flutter.versionCode
        versionName = "1.0"  // Changed from flutter.versionName
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
