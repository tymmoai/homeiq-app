# Release signing (Play Console)

Release signing is already configured.

- **Keystore:** `android/app/homeiq-release.jks` (alias: `homeiq`)
- **Credentials:** `android/key.properties` (storePassword, keyPassword). Do not commit or share this file.
- **Build:** Run from project root: `flutter build appbundle --release`
- **Output:** `build/app/outputs/bundle/release/app-release.aab`

To change the keystore password later: use `keytool -storepasswd -keystore android/app/homeiq-release.jks` and update `android/key.properties` to match.
