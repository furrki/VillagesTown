plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.appgea.villages_town"
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
        applicationId = "com.appgea.villages_town"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    val signingNames = listOf("VILLAGESTOWN_KEYSTORE", "VILLAGESTOWN_STORE_PASSWORD", "VILLAGESTOWN_KEY_ALIAS", "VILLAGESTOWN_KEY_PASSWORD")
    val signingValues = signingNames.associateWith { providers.environmentVariable(it).orNull }
    val signingReady = signingValues.values.all { !it.isNullOrBlank() }
    val signingMessage = "Release signing requires: ${signingNames.joinToString()}"
    require(signingReady || signingValues.values.all { it == null }) { signingMessage }
    if (!signingReady) {
        gradle.taskGraph.whenReady {
            require(!hasTask(":app:preReleaseBuild")) { signingMessage }
        }
    }
    if (signingReady) {
        signingConfigs.create("release") {
            storeFile = rootProject.file(signingValues.getValue("VILLAGESTOWN_KEYSTORE")!!)
            storePassword = signingValues.getValue("VILLAGESTOWN_STORE_PASSWORD")
            keyAlias = signingValues.getValue("VILLAGESTOWN_KEY_ALIAS")
            keyPassword = signingValues.getValue("VILLAGESTOWN_KEY_PASSWORD")
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.findByName("release")
        }
    }
}

flutter {
    source = "../.."
}
