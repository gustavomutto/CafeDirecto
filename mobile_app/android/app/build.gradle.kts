import java.io.FileInputStream
import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Firma de lanzamiento (Google Play): si existe android/key.properties se usa esa clave;
// si no, se firma con la de depuración para que `flutter run --release` siga funcionando, CON AVISO.
// Con -PrequireReleaseSigning=true o REQUIRE_RELEASE_SIGNING=true (lo usa CI al publicar un Release)
// falta de clave = error: un APK público nunca va firmado con la clave de depuración (hallazgo H-04).
// Ver docs/PUBLICAR_EN_PLAY.md. key.properties y el .jks NUNCA se suben a GitHub.
val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties().apply {
    if (keystorePropertiesFile.exists()) load(FileInputStream(keystorePropertiesFile))
}
val requireReleaseSigning = project.findProperty("requireReleaseSigning") == "true" ||
    System.getenv("REQUIRE_RELEASE_SIGNING") == "true"
val buildingRelease = gradle.startParameter.taskNames.any { it.contains("Release", ignoreCase = true) }

android {
    namespace = "com.cafedirecto.cafe_directo"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        // Necesario para flutter_local_notifications (avisos en el teléfono)
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "com.cafedirecto.app"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        if (keystorePropertiesFile.exists()) {
            create("release") {
                keyAlias = keystoreProperties["keyAlias"] as String
                keyPassword = keystoreProperties["keyPassword"] as String
                storeFile = file(keystoreProperties["storeFile"] as String)
                storePassword = keystoreProperties["storePassword"] as String
            }
        }
    }

    buildTypes {
        release {
            signingConfig = if (keystorePropertiesFile.exists()) {
                signingConfigs.getByName("release")
            } else {
                if (buildingRelease && requireReleaseSigning) {
                    throw GradleException(
                        "Falta android/key.properties: una versión publicada no puede ir firmada con la clave de depuración.",
                    )
                }
                if (buildingRelease) {
                    logger.warn("⚠️  CaféDirecto: versión de lanzamiento firmada con la clave de DEPURACIÓN (solo para pruebas).")
                }
                signingConfigs.getByName("debug")
            }
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
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}
