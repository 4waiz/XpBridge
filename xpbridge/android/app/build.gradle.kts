import org.gradle.api.GradleException
import java.io.File
import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val clientEnvFile = rootProject.file("../.env")
val allowedClientEnvKeys = setOf(
    "SUPABASE_URL",
    "SUPABASE_ANON_KEY",
    "STORAGE_BUCKET",
    "ENABLE_AI_CHAT",
)

fun parseEnvKeys(file: File): Set<String> =
    file.readLines()
        .asSequence()
        .map(String::trim)
        .filter { it.isNotEmpty() && !it.startsWith("#") && it.contains("=") }
        .map { it.substringBefore("=").trim() }
        .filter { it.isNotEmpty() }
        .toSet()

if (clientEnvFile.exists()) {
    val unsupportedClientEnvKeys = parseEnvKeys(clientEnvFile) - allowedClientEnvKeys
    if (unsupportedClientEnvKeys.isNotEmpty()) {
        throw GradleException(
            "Unsupported keys found in bundled Flutter .env: " +
                unsupportedClientEnvKeys.sorted().joinToString(", ") +
                ". Allowed keys: " +
                allowedClientEnvKeys.sorted().joinToString(", "),
        )
    }
}

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")

if (keystorePropertiesFile.exists()) {
    keystorePropertiesFile.inputStream().use(keystoreProperties::load)
}

val requiredSigningKeys = listOf("storeFile", "storePassword", "keyAlias", "keyPassword")
val hasReleaseSigning =
    keystorePropertiesFile.exists() &&
        requiredSigningKeys.all { !keystoreProperties.getProperty(it).isNullOrBlank() }

android {
    namespace = "com.xpbridge.app"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = "28.2.13676358"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        applicationId = "com.xpbridge.app"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            if (hasReleaseSigning) {
                storeFile = file(keystoreProperties.getProperty("storeFile"))
                storePassword = keystoreProperties.getProperty("storePassword")
                keyAlias = keystoreProperties.getProperty("keyAlias")
                keyPassword = keystoreProperties.getProperty("keyPassword")
            }
        }
    }

    buildTypes {
        release {
            if (hasReleaseSigning) {
                signingConfig = signingConfigs.getByName("release")
            }
        }
    }
}

tasks.matching { it.name in setOf("assembleRelease", "bundleRelease") }.configureEach {
    doFirst {
        if (!hasReleaseSigning) {
            throw GradleException(
                "Missing Android release signing config. Copy android/key.properties.example " +
                    "to android/key.properties, point storeFile at a real upload keystore, " +
                    "and fill in the real passwords before building a release artifact.",
            )
        }
    }
}

flutter {
    source = "../.."
}
