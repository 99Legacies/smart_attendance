# AttendPro Tracking System

Flutter app (Android, iOS, Web) with Firebase backend, Clean Architecture, Riverpod state management, and anti-cheating attendance validation.

## Features

- **Roles**: Admin, Lecturer, Student with route-level access control
- **Auth**: Email/password (Firebase Auth), device ID on login, single-device enforcement for students
- **Attendance**: Rotating QR (45s), GPS radius check, device match, duplicate prevention, specific error messages
- **Student**: QR scan, history, profile, absence requests with optional file upload
- **Lecturer**: Create sessions, live QR display, session list with analytics
- **Admin**: Departments, courses, students (device reset), system analytics
- **UI**: Light/dark themes per design spec, card-based responsive layout

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
- Firebase project

### 2. Configure Firebase

```bash
cd smart_attendance
dart pub global activate flutterfire_cli
flutterfire configure
```

Replace `lib/firebase_options.dart` with generated values.

Enable in Firebase Console:

- Authentication → Email/Password
- Cloud Firestore
- Cloud Storage (for absence file uploads)

Deploy rules and indexes:

```bash
firebase deploy --only firestore:rules,firestore:indexes
```

### 3. Seed admin (required)

Create an admin in Firebase Auth, then add a Firestore document:

**Admin** — collection `admins`, document ID = Auth UID:

```json
{ "email": "admin@school.edu", "name": "System Admin" }
```

Use the admin dashboard to add **departments** and **courses** first.

**Students** and **lecturers** use one sign-up page:

- Sign In → **Create an account**
- Choose **Student** or **Lecturer**, pick a department from the standard list, and select courses
- Admin: open **Departments** → **Import Standard** to seed all preset departments before adding courses

### 4. Run

```bash
flutter pub get
flutter run -d chrome    # web
flutter run              # mobile
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
| One-time token | Token rotated after each successful scan (transaction) |
| GPS | Haversine distance vs session lat/long + radius |
| Device ID | Stored on registration/login; mismatch blocks scan |
| Single device | Student login rejects second device |
| Duplicate | Transaction + query before insert |
| Suspicious activity | `security_logs` collection |

## Web note

Camera QR scanning uses `mobile_scanner` on mobile. On web, students paste the `sessionId|token` payload manually (or use a USB scanner that types the payload).

## License

MIT
