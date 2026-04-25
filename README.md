# ZNOTE 📝

ZNOTE is a secure, feature-rich note-taking application built with Flutter and Firebase. It offers a seamless experience for capturing ideas, managing tasks, and keeping sensitive information private.

## ✨ Features

- **Google Authentication:** Secure and easy sign-in using your Google account.
- **Real-time Sync:** All your notes are synced across devices instantly using Cloud Firestore.
- **Rich Note Content:** Support for text blocks and interactive checklists.
- **Pinning:** Keep your most important notes at the top of your list.
- **Redaction (Security):** Lock sensitive notes behind device authentication (Fingerprint, Face ID, Pattern, or PIN).
- **Dark Mode Support:** Easy on the eyes with automatic and manual theme switching.
- **Responsive Grid Layout:** Beautifully organized notes for easy browsing.

## 🛡️ Security

ZNOTE prioritizes your privacy. The "Redact" feature uses the `local_auth` package to integrate with your device's native security. If a note is redacted, it cannot be viewed or edited without successful biometric or device-level (PIN/Pattern) authentication.

## 🚀 Getting Started

### Prerequisites

- Flutter SDK
- A Firebase project

### Setup

1. **Clone the repository:**
   ```bash
   git clone https://github.com/Mohamed-MX/ZNOTE.git
   cd ZNOTE
   ```

2. **Install dependencies:**
   ```bash
   flutter pub get
   ```

3. **Firebase Configuration:**
   - Create a project on the [Firebase Console](https://console.firebase.google.com/).
   - Add an Android and/or iOS app.
   - Download the `google-services.json` (Android) or `GoogleService-Info.plist` (iOS) and place them in the correct directories.
   - Enable **Google Sign-In** and **Firestore** in the Firebase console.

4. **Run the app:**
   ```bash
   flutter run
   ```

## 🛠️ Built With

- [Flutter](https://flutter.dev/) - UI Toolkit
- [Firebase Auth](https://firebase.google.com/docs/auth) - Authentication
- [Cloud Firestore](https://firebase.google.com/docs/firestore) - NoSQL Database
- [Provider](https://pub.dev/packages/provider) - State Management
- [Local Auth](https://pub.dev/packages/local_auth) - Local Biometrics/Security

