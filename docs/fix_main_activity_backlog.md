# Fix MainActivity Path Backlog

- [x] Task 1: Locate & Move MainActivity - Ensure `MainActivity.kt` (or `.java`) is physically located inside `android/app/src/main/kotlin/com/osoft/nutri_mobile_app/` (or `src/main/java/com/osoft/nutri_mobile_app/`).
- [x] Task 2: Verify Package Declaration - Open `MainActivity.kt` and ensure the very first line is `package com.osoft.nutri_mobile_app`.
- [x] Task 3: Clean & Rebuild - Run `fvm flutter clean`, remove any old build artifacts, run `fvm flutter pub get`, and verify the build.

## Root Cause
The physical path and package declaration were already correct, but the app module
was missing the Kotlin Gradle plugin. `android/app/build.gradle.kts` declared only
`com.android.application` and `dev.flutter.flutter-gradle-plugin`, so
`src/main/kotlin/**/*.kt` was never compiled. The manifest still referenced
`.MainActivity`, producing `ClassNotFoundException` at launch.

## Fix
Applied `id("org.jetbrains.kotlin.android")` in `android/app/build.gradle.kts`
(version resolved from `settings.gradle.kts`).

## Verification
- `build/app/tmp/kotlin-classes/release/com/osoft/nutri_mobile_app/MainActivity.class` now exists.
- Descriptor `com/osoft/nutri_mobile_app/MainActivity` found in `classes.dex` of the release APK.
- `fvm flutter build apk --release` succeeded.
