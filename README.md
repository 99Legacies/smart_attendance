# AttendPro Tracking System

Flutter app (Android, iOS, Web) with a Firebase backend, Clean Architecture, Riverpod state management, and anti-cheating attendance validation.

## Table of Contents

- [Features](#features)
- [Architecture](#architecture)
- [Setup](#setup)
  - [Prerequisites](#1-prerequisites)
  - [Configure Firebase](#2-configure-firebase)
  - [Seed admin (required)](#3-seed-admin-required)
  - [Run](#4-run)
  - [Platform permissions](#5-platform-permissions)
- [Anti-cheating summary](#anti-cheating-summary)
- [Web note](#web-note)
- [License](#license)

## Features

- **Roles**: Admin, Lecturer, Student with route-level access control
- **Auth**: Email/password (Firebase Auth), device ID enforcement, single-device restriction for students
- **Attendance**: Rotating QR codes (45s), GPS radius validation, device matching, duplicate prevention, targeted error messages
- **Student**: QR scan, attendance history, profile, absence requests with optional file upload
- **Lecturer**: Create sessions, live QR display, session list with analytics
- **Admin**: Manage departments, courses, students, device resets, and system analytics
- **UI**: Light/dark themes, responsive card-based layout

## Architecture

```
lib/
├── core/           # theme, constants, validators, widgets
├── domain/         # entities, repository interfaces, use cases
├── data/           # Firebase repos, models, services
├── presentation/   # providers, router, screens
├── app.dart
└── main.dart
```

## Setup

### 1. Prerequisites

- Flutter SDK 3.12+
- Firebase project configured for this app

### 2. Configure Firebase

```bash
cd smart_attendance
dart pub global activate flutterfire_cli
flutterfire configure
```

Replace `lib/firebase_options.dart` with the generated Firebase configuration values.

Enable the following services in the Firebase Console:

- Authentication → Email/Password
- Cloud Firestore
- Cloud Storage (for absence file uploads)

Deploy Firestore rules and indexes:

```bash
firebase deploy --only firestore:rules,firestore:indexes
```

### 3. Seed admin (required)

Create an admin account in Firebase Auth, then add a Firestore document in the `admins` collection using the admin UID as the document ID:

```json
{ "email": "admin@school.edu", "name": "System Admin" }
```

Important: add departments and courses from the admin dashboard before enrolling lecturers and students.

**Signup flow for students and lecturers:**

- Open Sign In → **Create an account**
- Choose **Student** or **Lecturer**
- Pick a department from the standard list
- Select courses

When first setting up departments, use the admin dashboard and the **Departments → Import Standard** action to seed preset departments.

### 4. Run

```bash
flutter pub get
flutter run -d chrome    # web
flutter run              # mobile
```

For tests:

```bash
flutter test
```

### 5. Platform permissions

**Android** (`android/app/src/main/AndroidManifest.xml`):

```xml
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION"/>
<uses-permission android:name="android.permission.CAMERA"/>
```

**iOS** (`ios/Runner/Info.plist`):

```xml
<key>NSCameraUsageDescription</key>
<string>Scan attendance QR codes</string>
<key>NSLocationWhenInUseUsageDescription</key>
<string>Verify you are on campus for attendance</string>
```

## Anti-cheating summary

| Check | Implementation |
|--------|----------------|
| QR expiry | 45s `qrExpiresAt`, auto-refresh on lecturer screen |
| One-time token | Token rotates after each successful scan using transactions |
| GPS | Haversine distance compared to session lat/long + radius |
| Device ID | Stored on registration/login; mismatch blocks scan |
| Single device | Student login rejects a second device |
| Duplicate | Firestore transaction + pre-check before insert |
| Suspicious activity | Logged to `security_logs` collection |

## Web note

Camera QR scanning is available on mobile using `mobile_scanner`. On web, students manually paste the `sessionId|token` payload or use a USB scanner that types the payload.

## License

MIT
