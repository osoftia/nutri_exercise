# Package Refactor Backlog

- [x] Task 1: Update build.gradle.kts / build.gradle - Update `namespace` and `applicationId` to `com.osoft.nutri_mobile_app`.
- [x] Task 2: Update Kotlin/Java Source Paths & MainActivity - Move or update `MainActivity.kt` (or `.java`) to match the new package structure (`com/osoft/nutri_mobile_app`) and ensure its `package com.osoft.nutri_mobile_app` declaration matches.
- [x] Task 3: Global String Replacement - Search and replace any remaining occurrences of old bundle identifiers in resource files, manifests, and platform configs.
- [x] Task 4: Clean & Verify - Run `flutter clean`, `flutter pub get`, and verify the build.

## Notes
- iOS `PRODUCT_BUNDLE_IDENTIFIER` was updated from the legacy `com.example.nutriMobileApp` to `com.osoft.nutriMobileApp` (camelCase preserved because underscores are not valid in Apple bundle identifiers).
- Pre-existing `logs_error.txt` still contains historical `com.example.*` output from an old run; it is a captured log, not a platform config, so it was intentionally left untouched.
- Dart package name (`package:nutri_mobile_app/...`) is unrelated to the Android applicationId and was intentionally left unchanged.
