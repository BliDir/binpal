plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.blidir.binpal"
    // flutter_local_notifications 23 and androidx.core 1.19 need API 37 to compile.
    // targetSdk stays on Flutter's default.
    compileSdk = 37
    ndkVersion = flutter.ndkVersion

    compileOptions {
        // flutter_local_notifications uses java.time APIs on older Android versions.
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "com.blidir.binpal"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        // From pubspec.yaml. Split-per-ABI APKs add 1000 * ABI_VERSION automatically.
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // Debug keys until a Play upload key exists (store listing work).
            signingConfig = signingConfigs.getByName("debug")
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro",
            )
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

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.5")
    // Photo check: ML Kit image labeling and Japanese text recognition (プラ,
    // アルミ, 紙) through Google Play Services, which downloads the models
    // when the app is installed (see AndroidManifest.xml). The plugins' own
    // bundled models and pipelines would add about 34 MB to the APK.
    implementation("com.google.android.gms:play-services-mlkit-text-recognition:19.0.1")
    implementation("com.google.android.gms:play-services-mlkit-text-recognition-japanese:16.0.1")
    implementation("com.google.android.gms:play-services-mlkit-image-labeling:16.0.8")
}

// The plugins' bundled ML Kit, replaced by the Play Services versions above.
// Custom and Firebase labeling models aren't used (see proguard-rules.pro).
configurations.all {
    exclude(group = "com.google.mlkit", module = "text-recognition")
    exclude(group = "com.google.mlkit", module = "image-labeling")
    exclude(group = "com.google.mlkit", module = "image-labeling-custom")
    exclude(group = "com.google.mlkit", module = "linkfirebase")
}
