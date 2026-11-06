# 🅿️ ParkSnap — Automated Gate Vehicle Logging

> Replace your paper parking register with AI-powered license plate scanning.

ParkSnap uses your phone camera + **Gemini 2.5 Flash** to scan license plates, extract vehicle details, and log everything to a local SQLite database — no backend required.

---

## ✨ Features

| Feature | Detail |
|---|---|
| 📷 Camera Viewfinder | Full-screen with animated plate targeting reticle |
| 🤖 Gemini AI OCR | Extracts plate, vehicle type, and confidence score |
| 🗄️ Offline SQLite | All data stored on-device via `sqflite` |
| 🔑 Secure API Key | Stored once using `flutter_secure_storage` |
| 🔍 Real-time Search | Filter logs by plate number instantly |
| ⬛ Dark Tactical UI | High-contrast, field-ready design |
| ✅ Exit Stamping | One-tap checkout stamps exit timestamp |

---

## 🛠 Prerequisites

| Tool | Version |
|---|---|
| Flutter SDK | >= 3.0.0 |
| Dart SDK | >= 3.0.0 |
| Android Studio / Xcode | Latest stable |
| Physical device | Recommended (emulators may lack camera) |
| Gemini API Key | From https://aistudio.google.com/app/apikey |

---

## 🚀 Quick Start

### 1. Navigate to project

```bash
cd /home/akuma/.gemini/antigravity/scratch/parksnap
```

### 2. Install dependencies

```bash
flutter pub get
```

### 3. Run on Android (USB debugging on)

```bash
flutter run
```

### 4. Run on iOS (requires Xcode)

```bash
cd ios && pod install && cd ..
flutter run
```

---

## 🔑 Gemini API Key Setup

1. Visit https://aistudio.google.com/app/apikey
2. Click Create API Key
3. Copy the key (starts with AIzaSy...)
4. On first launch, ParkSnap will ask you to paste it
5. Stored securely via flutter_secure_storage

To reset: Dashboard -> Menu (three dots) -> Reset API Key

---

## 📁 Project Structure

```
lib/
├── main.dart
├── models/vehicle_log.dart
├── database/database_helper.dart
├── services/gemini_service.dart
├── services/camera_service.dart
├── providers/vehicle_log_provider.dart
├── providers/camera_provider.dart
├── screens/splash_screen.dart
├── screens/dashboard_screen.dart
├── screens/camera_scanner_screen.dart
├── screens/verify_confirm_screen.dart
├── widgets/scan_action_card.dart
├── widgets/vehicle_log_card.dart
├── widgets/plate_viewfinder.dart
└── theme/app_theme.dart
```

---

## 📱 App Flow

```
App Launch -> SplashScreen
  First time  -> Enter Gemini API Key -> Dashboard
  Returning   -> Dashboard (auto-skip)
                 |
                 +-- Tap SCAN or FAB
                 |      -> CameraScannerScreen
                 |           -> Capture -> Gemini API
                 |                -> VerifyConfirmScreen
                 |                     [Save]   -> Dashboard
                 |                     [Retake] -> Camera
                 |
                 +-- Tab: INSIDE (live list)
                 +-- Tab: ALL LOGS (history)
                 +-- Search (real-time plate filter)
                 +-- EXIT button (stamps exit_timestamp)
```

---

## 🗄️ Database Schema

Table: vehicle_logs

| Column | Type | Notes |
|---|---|---|
| id | TEXT PK | UUID v4 |
| license_plate | TEXT | Uppercase |
| vehicle_type | TEXT | Car/Bike/Truck/Other |
| entry_timestamp | TEXT | ISO 8601 |
| exit_timestamp | TEXT? | Nullable |
| flat_or_visitor_info | TEXT | Optional |
| status | TEXT | Inside / Exited |
| image_path | TEXT | Local file path |
| confidence | REAL | 0-100 from Gemini |

---

## ⚙️ Android Notes

- minSdkVersion: 23 (required for flutter_secure_storage)
- Permissions: CAMERA, INTERNET, FLASHLIGHT, READ_MEDIA_IMAGES
- Test on a physical device

## 🍎 iOS Notes

- Run `pod install` inside the ios/ directory before first build
- Required: NSCameraUsageDescription in Info.plist

---

## 📦 Key Dependencies

| Package | Purpose |
|---|---|
| camera | Live viewfinder and capture |
| google_generative_ai | Gemini 2.5 Flash API |
| sqflite | SQLite database |
| provider | State management |
| flutter_secure_storage | Encrypted API key storage |
| uuid | Log ID generation |
| google_fonts | Chivo and JetBrains Mono |
| permission_handler | Runtime camera permissions |
