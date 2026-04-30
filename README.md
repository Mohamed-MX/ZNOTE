# ZNOTE 📝

ZNOTE is a secure, feature-rich note-taking application built with Flutter and Firebase. It offers a seamless experience for capturing ideas, managing tasks, and keeping sensitive information private.

<table>
  <tr>
  <img width="1376" height="768" alt="Gemini_Generated_Image_df1wnjdf1wnjdf1w" src="https://github.com/user-attachments/assets/69cd48d7-0132-44e7-9e5b-2db362c6787b" />
  </tr>
  <tr>
    <td><img src="https://github.com/user-attachments/assets/8966ed6b-340e-4972-b014-0083a951f1a7" alt="Login Screen" width="250"/></td>
    <td><img src="https://github.com/user-attachments/assets/398448c9-ec79-4a5a-b31c-0b811ca3b6a3" alt="Empty Notes" width="250"/></td>
    <td><img src="https://github.com/user-attachments/assets/4ee8a941-437d-4e96-ae13-1ccacf078e0b" alt="Grid View Light" width="250"/></td>
  </tr>
  <tr>
    <td><img src="https://github.com/user-attachments/assets/4a68dfa9-c7ea-49ac-bda3-ef6a567dd810" alt="Note View" width="250"/></td>
    <td><img src="https://github.com/user-attachments/assets/ca6b4c79-477d-4380-88c5-497b842e647b" alt="Note Keyboard" width="250"/></td>
  </tr>
  <tr>
    <td><img src="https://github.com/user-attachments/assets/11156aea-1d25-4471-be2f-c49aeb96d88c" alt="Grid View Dark" width="250"/></td>
    <td><img src="https://github.com/user-attachments/assets/2f4d0f76-8232-42ce-a572-8a8a3f942dd0" alt="Note View Dark" width="250"/></td>
  </tr>
</table>

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
   git clone [https://github.com/Mohamed-MX/ZNOTE.git](https://github.com/Mohamed-MX/ZNOTE.git)
   cd ZNOTE
