# Min SDK Fix Backlog
- [x] Task 1: Update android/app/build.gradle - Open `android/app/build.gradle`. Locate the `defaultConfig` block. Change `minSdkVersion` from `21` (or `flutter.minSdkVersion`) to `23`.
- [x] Task 2: Update AndroidManifest.xml (Debug) - Open `android/app/src/debug/AndroidManifest.xml`. If it explicitly defines `android:minSdkVersion="21"`, either remove that line (letting it inherit from build.gradle) or change it to `23`.
- [x] Task 3: Verify & Clean - Run `flutter clean`, `flutter pub get`, and attempt a `flutter run`.
