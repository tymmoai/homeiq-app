# Launching HomeIQ on the App Store (iOS)

Your app is **one Flutter project** that builds for both **Google Play (Android)** and **App Store (iOS)**. The iOS bundle ID is set to **com.tymmo.homeiq** (same as Android package name).

---

## What you need for App Store

| Requirement | Details |
|-------------|---------|
| **Mac** | Building and uploading an iOS app requires a Mac (MacBook, iMac, or Mac mini). |
| **Xcode** | Install from the Mac App Store (free). Required to build and sign the iOS app. |
| **Apple Developer account** | Paid program ($99/year). Sign up at [developer.apple.com](https://developer.apple.com). |
| **iPhone or iPad (optional but recommended)** | To test the app on a real device before submitting. You can also use the iOS Simulator on the Mac. |

---

## Steps to build and submit for iOS

Do these **on your Mac**:

1. **Open the project**
   - Copy your project (or clone from Git) to the Mac.
   - Open `ios/Runner.xcworkspace` in **Xcode** (not the `.xcodeproj`).

2. **Select your team and signing**
   - In Xcode: select the **Runner** project → **Signing & Capabilities**.
   - Choose your **Team** (your Apple Developer account).
   - Ensure **Automatically manage signing** is checked.
   - Bundle ID is already **com.tymmo.homeiq**.

3. **Test on device or simulator**
   - Connect an iPhone or choose an iPhone simulator.
   - In terminal: `flutter run` (or Run from Xcode).
   - Use your Vivo for Android; use iPhone or simulator for iOS.

4. **Build for release**
   - In terminal (from project root):
     ```bash
     flutter build ipa
     ```
   - Or in Xcode: **Product → Archive**, then **Distribute App** to App Store Connect.

5. **Upload to App Store Connect**
   - Go to [App Store Connect](https://appstoreconnect.apple.com).
   - Create your app (if not done), set name, description, screenshots, etc.
   - Upload the build (from Xcode Organizer after Archive, or via `flutter build ipa` and then Transporter / Xcode).

6. **Submit for review**
   - In App Store Connect, complete the listing and submit the build for review.

---

## Summary

- **Android (Play Store):** Build AAB on any PC, test on your Vivo, upload to Play Console. ✅ You can do this now.
- **iOS (App Store):** Need a Mac + Xcode + Apple Developer account. Open this project on the Mac, build with `flutter build ipa` or Xcode Archive, then upload to App Store Connect.

Same app code for both; only the build and store process differ.
