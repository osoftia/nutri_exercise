# Manifest & Release Fix Backlog

- [ ] Task 1: Inspect Android Manifest - Check `android/app/src/main/AndroidManifest.xml` and any product/library manifests for duplicate permissions, missing `android:exported` attributes on broadcast receivers/activities, or conflicting namespace attributes introduced by recent plugins (notifications, share_plus).
- [ ] Task 2: Gradle Compatibility - Verify `android/app/build.gradle` and `android/build.gradle` for correct `minSdkVersion` (should be at least 21, preferably 23+ for notifications) and compile SDK versions.
- [ ] Task 3: Local Release Simulation - Run a dry-run analysis or check build configuration to ensure no syntax or merger conflicts exist.
- [ ] Task 4: Git Commit & Push - Commit the fixes and push to main so GitHub Actions can successfully build the release APK.
