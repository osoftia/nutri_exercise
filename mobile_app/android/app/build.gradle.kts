plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
    // El plugin de Flutter siempre al final
    id("dev.flutter.flutter-gradle-plugin")
}

// Extraemos las propiedades de Flutter de forma segura antes del bloque de configuración
val flutterMinSdk = flutter.minSdkVersion
val flutterTargetSdk = flutter.targetSdkVersion
val flutterVersionCode = flutter.versionCode
val flutterVersionName = flutter.versionName

configure<com.android.build.api.dsl.ApplicationExtension> {
    namespace = "com.example.nutri_mobile_app"
    compileSdk = 36
    ndkVersion = "28.2.13676358"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        isCoreLibraryDesugaringEnabled = true
    }

    defaultConfig {
        applicationId = "com.example.nutri_mobile_app"
        
        // Asignamos las variables extraídas de forma limpia sin usar paréntesis
        minSdk = flutterMinSdk
        targetSdk = flutterTargetSdk
        versionCode = flutterVersionCode
        versionName = flutterVersionName
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

tasks.withType<org.jetbrains.kotlin.gradle.tasks.KotlinCompile>().configureEach {
    compilerOptions {
        jvmTarget.set(org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17)
    }
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}

flutter {
    source = "../.."
}
