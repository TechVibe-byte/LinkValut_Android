# 🛡️ LinkVault

> A premium, offline-first Personal Knowledge Manager (PKM), Learning Tracker, and Resource Organizer built with Flutter.

LinkVault allows you to aggregate, categorize, track, and study your digital resources—ranging from YouTube videos and technical blogs to documentation pages and PDFs—all in one place. With gamified learning features like streaks and daily goals, an interactive analytics dashboard, secure local storage, local authentication, and easy QR-based sharing, LinkVault is your ultimate pocket library.

---

## ✨ Key Features

### 🗂️ 1. Smart Resource Cataloging
* **Custom Categories:** Organize links by platform type including *YouTube Videos, Playlists, Instagram Reels, Articles, Blogs, Documentation, PDFs,* and custom media.
* **Tagging & Filtering:** Categorize resources with custom tags and instantly filter or search your library.
* **Favorites & Archiving:** Mark critical resources as favorites or archive them to keep your active list clean.
* **Markdown Notes:** Add rich-text study notes directly to any resource using the built-in **Markdown Editor**.

### 🎮 2. Gamified Learning Queue & Tracker
* **Drag-and-Drop Queue:** Order your study queue using a fluid, reorderable list.
* **Learning States:** Track progress with *Not Started, In Progress,* and *Completed* stages, complete with a percentage tracker.
* **Daily Goals:** Set daily study targets and watch your daily progress indicator update in real-time.
* **Streaks:** Keep the learning habit alive! Tracks consecutive active days with automatic streak reset checks on app launch.
* **Activity Log:** Visualize your daily learning activity history.

### 📊 3. Rich Analytics & Insights
* **Interactive Charts:** Powered by `fl_chart`, visualize your progress status breakdown, learning trends, and category distribution.
* **Weekly Reports:** High-level summary of resources processed, completed, and average learning velocity.

### 🔒 4. Enterprise-Grade Security
* **Offline-First Storage:** High-performance database operations powered by **Hive**, keeping your data completely local and private.
* **Local App Lock:** Secure your knowledge base with a customizable local PIN code.
* **Biometric Auth:** Seamlessly unlock LinkVault using Face ID or Fingerprint authentication (via `local_auth`).

### 📲 5. Quick Share & Smart Import
* **QR Code Sharing:** Generate a QR code containing encoded deep-link metadata (`linkvault:import?...`) for instant cross-device sharing.
* **Simulated & Camera Scanning:** Scan codes or paste raw QR metadata to import resources in a single click.
* **JSON Backup & Restore:** Export your database to a portable JSON backup file and import it at any time.

---

## 🛠️ Tech Stack & Architecture

### Dependency Breakdown
* **State Management:** `provider` for clean, decoupled business logic.
* **Database:** `hive` & `hive_flutter` (NoSQL lightweight local storage).
* **Security & Auth:** `local_auth` (biometrics) and custom SHA-256 PIN hashing logic.
* **Charts:** `fl_chart` for performant, hardware-accelerated graphs.
* **Notifications:** `flutter_local_notifications` for scheduled learning reminders.
* **Utilities:** `shared_preferences` (theme state), `file_picker` (backups), `url_launcher` (opening links), `share_plus` (sharing files/links), `flutter_markdown` (rich notes), `flutter_slidable` (swipe gestures).

### Directory Structure
```text
lib/
├── core/                         # Core utilities, services & helpers
│   ├── database/                 # Hive DB helpers & initialization
│   ├── security/                 # Local PIN lock & biometric helpers
│   ├── backup/                   # JSON export and import logic
│   ├── notifications/            # Local scheduled push notifications
│   ├── theme/                    # App styles and light/dark theme providers
│   └── widgets/                  # Shared custom UI widgets (e.g. Markdown editor)
│
└── features/                     # Feature-driven modules (clean architecture)
    ├── dashboard/                # Home screen, wrapper, navigation
    ├── resources/                # Links list, detail screen, models, CRUD logic
    ├── learning/                 # Study queue management, streaks & daily goals
    ├── analytics/                # FL Chart analytics screens
    ├── qr/                       # QR code scanner and generator
    └── settings/                 # App config, security settings & backups
```

---

## 🚀 Getting Started

### Prerequisites
* Flutter SDK (Version `^3.12.1`)
* Android SDK (for Android builds) or Xcode (for iOS builds)

### Installation & Run

1. **Clone the repository and navigate to the directory:**
   ```bash
   cd linkvault
   ```

2. **Fetch dependencies:**
   ```bash
   flutter pub get
   ```

3. **Generate Hive Adapters:**
   If you modify the models or need to re-run the source generator:
   ```bash
   flutter pub run build_runner build --delete-conflicting-outputs
   ```

4. **Run the application in Debug Mode:**
   ```bash
   flutter run
   ```

5. **Build the production release APK (Android):**
   ```bash
   flutter build apk --release
   ```

---

## 🤖 Android Configuration Details

To support biometrics (`local_auth`) and file storage operations, the following configuration has been applied:

1. **MainActivity Transition:**
   Located at `android/app/src/main/kotlin/.../MainActivity.kt`. It extends `FlutterFragmentActivity` instead of `FlutterActivity` to properly support biometric prompt overlays.

2. **Permissions (AndroidManifest.xml):**
   * `<uses-permission android:name="android.permission.USE_BIOMETRIC"/>` (For fingerprint/Face ID authorization)
   * `<uses-permission android:name="android.permission.VIBRATE"/>` (For haptic feedback on notifications and scanning)
   * `<uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED"/>` (To schedule notifications after device reboots)

3. **SDK Versions (`android/app/build.gradle.kts`):**
   * `compileSdk = 34`
   * `minSdk = 23` (Required by biometric and file-picker modules)
   * `targetSdk = 34`

---

## 💾 Backup & Restore Format

Backup files are exported as standard JSON structures containing metadata:

```json
{
  "app": "LinkVault",
  "version": 1,
  "exportedAt": "2026-06-06T08:39:23.000Z",
  "resources": [
    {
      "id": "uuid-string",
      "title": "Flutter Documentation",
      "url": "https://docs.flutter.dev",
      "platformType": "Documentation",
      "tags": ["flutter", "docs"],
      "notes": "# Study Notes\nStart with the core layouts.",
      "isFavorite": true,
      "isRead": false,
      "progressPercentage": 25.0,
      "dateAdded": "2026-06-06T08:39:23.000Z",
      "lastUpdated": "2026-06-06T08:39:23.000Z",
      "learningStatus": "In Progress",
      "isArchived": false,
      "queueIndex": 0
    }
  ]
}
```
