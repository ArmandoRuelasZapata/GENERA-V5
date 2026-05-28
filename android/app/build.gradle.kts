plugins {
    id("com.android.application")
    // START: FlutterFire Configuration
    id("com.google.gms.google-services")
    // END: FlutterFire Configuration
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

import java.util.Properties
import java.io.FileInputStream
import java.util.Base64

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

val dartEnvironmentVariables = mutableMapOf<String, String>()
if (project.hasProperty("dart-defines")) {
    val definesString = project.property("dart-defines") as String
    definesString.split(",").forEach { entry ->
        val decodedBytes = Base64.getDecoder().decode(entry)
        val decodedString = String(decodedBytes, Charsets.UTF_8)
        val parts = decodedString.split("=")
        if (parts.size >= 2) {
            dartEnvironmentVariables[parts[0]] = parts.subList(1, parts.size).joinToString("=")
        }
    }
}

android {
    namespace = "com.example.theoriginallab_v2"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        // Necesario para flutter_local_notifications (y otros plugins) que usan APIs modernas
        isCoreLibraryDesugaringEnabled = true

        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = "17"
    }

    defaultConfig {
        applicationId = "com.theoriginallab.app"
        minSdk = 26 // flutter.minSdkVersion (Actualizado a Android 8)
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName

        manifestPlaceholders += mapOf(
            "MAPS_API_KEY" to (dartEnvironmentVariables["MAPS_API_KEY"] ?: "")
        )
    }

    signingConfigs {
        // Solo intentamos crear la firma de release si el archivo de contraseñas existe
        if (keystorePropertiesFile.exists()) {
            create("release") {
                keyAlias = keystoreProperties.getProperty("keyAlias")
                keyPassword = keystoreProperties.getProperty("keyPassword")
                storeFile = file(keystoreProperties.getProperty("storeFile"))
                storePassword = keystoreProperties.getProperty("storePassword")
            }
        }
    }

    buildTypes {
        getByName("release") {
            if (keystorePropertiesFile.exists()) {
                signingConfig = signingConfigs.getByName("release")
            } else {
                signingConfig = signingConfigs.getByName("debug")
            }
            
            // OWASP M7: Protecciones del Binario
            isMinifyEnabled = true       // Activa R8 (obfusca bytecode Java/Kotlin)
            isShrinkResources = true     // Elimina recursos sin usar (~15-25% menos APK)
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
        getByName("debug") {
            // Sin minificación en debug para hot-reload rápido
            isMinifyEnabled = false
            isShrinkResources = false
        }
    }
}

dependencies {
    // Core library desugaring (requerido por flutter_local_notifications)
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}

flutter {
    source = "../.."
}
