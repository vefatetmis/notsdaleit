import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Release imza bilgilerini android/key.properties'ten okur (yoksa debug imza).
val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    namespace = "com.bronzecloud.notsdaleit"
    compileSdk = flutter.compileSdkVersion
    // Eklentilerin (path_provider, sqlite3_flutter_libs) istediği NDK sürümü.
    ndkVersion = "27.0.12077973"

    compileOptions {
        // flutter_local_notifications için gerekli (java.time desugaring).
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.bronzecloud.notsdaleit"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    // İki paralel kanal. "prod" = Play'e giden sürüm (applicationId aynen
    // com.bronzecloud.notsdaleit kalır). "dev" = geliştirme/paralel sürüm:
    // farklı applicationId (.dev) ile GERÇEK uygulamanın YANINA kurulur,
    // üstüne yazmaz; Play'e ASLA yüklenmez. Etiketi src/dev manifestinde
    // "notdaleit dev" olarak override edilir. Flavor eklendiği için artık her
    // flutter build/run komutuna --flavor prod|dev vermek ZORUNLU.
    flavorDimensions += "track"
    productFlavors {
        create("prod") {
            dimension = "track"
        }
        create("dev") {
            dimension = "track"
            applicationIdSuffix = ".dev"
            versionNameSuffix = "-dev"
        }
    }

    signingConfigs {
        create("release") {
            if (keystorePropertiesFile.exists()) {
                keyAlias = keystoreProperties["keyAlias"] as String
                keyPassword = keystoreProperties["keyPassword"] as String
                storeFile = rootProject.file(keystoreProperties["storeFile"] as String)
                storePassword = keystoreProperties["storePassword"] as String
            }
        }
    }

    buildTypes {
        release {
            // key.properties varsa gerçek yükleme anahtarıyla, yoksa debug ile imzala.
            signingConfig = if (keystorePropertiesFile.exists()) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }
            // Yerel (native) kod çökme raporlarının Play Console'da okunur
            // olması için sembol tablosunu AAB'ye göm (Play'deki "hata
            // ayıklama sembolleri" uyarısını giderir).
            ndk {
                debugSymbolLevel = "SYMBOL_TABLE"
            }
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}
