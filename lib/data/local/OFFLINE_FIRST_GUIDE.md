# Offline-First Architecture Guide

## Overview

The AttendPro app now implements a true offline-first architecture where:

1. **Local Database (Hive) is the Single Source of Truth**
   - All UI renders from local data
   - No Firebase dependency required for core functionality
   - Instant UI updates (optimistic updates)

2. **Firebase is Only a Background Sync Layer**
   - Syncs data asynchronously after app loads
   - Never blocks navigation or core operations
   - Failures are non-fatal

3. **Offline Queue System**
   - All writes (create/update/delete) are queued locally
   - Automatic retry when network is available
   - Track sync status: pending → syncing → synced/failed

## Architecture Diagram

```
┌─────────────────────────────────────────────────────┐
│                  UI Layer                            │
│  (Widgets, Screens, Providers)                       │
└────────────────────┬────────────────────────────────┘
                     │
┌────────────────────▼────────────────────────────────┐
│            Repository Layer (Hybrid)                 │
│  ┌─────────────────────────────────────────────┐   │
│  │ 1. Try read from LOCAL DB first             │   │
│  │ 2. If not found, return empty/fallback      │   │
│  │ 3. For writes: save to LOCAL + queue sync   │   │
│  └─────────────────────────────────────────────┘   │
└────────┬──────────────────────┬──────────────────┘
         │                      │
    ┌────▼──────┐        ┌──────▼────────┐
    │   LOCAL   │        │   OFFLINE     │
    │   DB      │        │   QUEUE       │
    │  (Hive)   │        │  (Pending     │
    │           │        │   Syncs)      │
    └───────────┘        └───────────────┘
                              │
                         ┌────▼────────────┐
                         │  Background     │
                         │  Sync Service   │
                         │  (AsyncTimer)   │
                         └────────────────┘
                              │
                         ┌────▼────────────┐
                         │   Firebase      │
                         │   (Optional)    │
                         └─────────────────┘
```

## Data Flow

### Reading Data (Always Local-First)

```
UI Provider
    ↓
Repository.getUser(id)
    ↓
LocalUserDataSource.getUserById(id)  ← Check LOCAL DB first
    ↓
Return user or null (never blocks, never fetches from Firebase at startup)
    ↓
UI renders immediately (optimistic UI)
```

### Writing Data (Optimistic + Queue)

```
UI calls Repository.saveAttendance(record)
    ↓
1. Save immediately to LOCAL DB
    ↓
2. Emit new data to UI (instant update - optimistic)
    ↓
3. Add to OFFLINE QUEUE for later sync
    ↓
UI updates instantly (user sees their data immediately)
    ↓
(Background) BackgroundSyncService picks up offline queue items
    ↓
Syncs to Firebase (can fail without blocking user)
    ↓
Mark synced or failed + retry
```

### Startup Flow (CRITICAL)

```
1. main() starts
2. LocalDatabaseService.initialize()  ← Initialize Hive + all boxes
3. Firebase.initializeApp() with 8s timeout (optional, can fail)
4. ProviderScope created
5. SmartAttendanceApp() built
6. Splash screen displayed
7. startup_provider runs (local-only operations)
8. authStateProvider checks local session cache
9. Navigation to Home or /login (within 5s guaranteed)
10. BackgroundSyncService.start()  ← After navigation, start syncing
```

**Key Point**: Firebase initialization can take up to 8 seconds or fail entirely. App continues offline with local data.

## File Structure

```
lib/data/local/
  ├── hive_models.dart                    # Hive model definitions
  ├── local_database_service.dart          # Hive initialization + box management
  ├── offline_queue_service.dart           # Offline queue management
  ├── background_sync_service.dart         # Background sync with Firebase
  ├── local_user_data_source.dart          # Example: local user data operations
  └── local_*.dart                         # Similar files for other entities

lib/data/repositories/
  ├── firebase_*.dart                      # Existing Firebase repositories
  └── (Future) hybrid_*.dart               # Hybrid repositories coordinating local + remote
```

## Implementing Offline-First for a New Repository

### Step 1: Create Local Data Source

File: `lib/data/local/local_catalog_data_source.dart`

```dart
import 'package:smart_attendance/data/local/hive_models.dart';
import 'package:smart_attendance/data/local/local_database_service.dart';

class LocalCatalogDataSource {
  // Read operations
  Future<Course?> getCourseById(String courseId) async {
    final hiveCourse = LocalDatabaseService.coursesBox.get(courseId);
    if (hiveCourse != null) {
      return _hiveToCourse(hiveCourse);
    }
    return null;
  }

  // Write operations
  Future<void> saveCourse(Course course) async {
    final hiveCourse = _courseToHive(course);
    await LocalDatabaseService.coursesBox.put(course.id, hiveCourse);
  }

  // Helper conversions
  static Course _hiveToCourse(HiveCourse hive) {
    return Course(
      id: hive.id,
      name: hive.name,
      departmentId: hive.departmentId,
      // ... other fields
    );
  }

  static HiveCourse _courseToHive(Course course) {
    return HiveCourse(
      id: course.id,
      name: course.name,
      departmentId: course.departmentId,
      // ... other fields
      syncedAt: DateTime.now(),
    );
  }
}
```

### Step 2: Create Hybrid Repository

File: `lib/data/repositories/hybrid_catalog_repository.dart`

```dart
import 'package:smart_attendance/data/local/local_catalog_data_source.dart';
import 'package:smart_attendance/data/repositories/firebase_catalog_repository.dart';
import 'package:smart_attendance/domain/repositories/catalog_repository.dart';

class HybridCatalogRepository implements CatalogRepository {
  final LocalCatalogDataSource _local;
  final FirebaseCatalogRepository _remote;

  HybridCatalogRepository({
    required LocalCatalogDataSource local,
    required FirebaseCatalogRepository remote,
  })  : _local = local,
        _remote = remote;

  // ALL reads come from LOCAL first
  @override
  Future<Course?> getCourseById(String id) async {
    // Try local first (instant, offline-safe)
    var course = await _local.getCourseById(id);
    if (course != null) {
      return course;
    }
    
    // If not in local DB, return null (don't block fetching from Firebase)
    // Sync from Firebase will happen in background
    return null;
  }

  // ALL writes go local + queue
  @override
  Future<void> createCourse(Course course) async {
    // 1. Save to local DB immediately
    await _local.saveCourse(course);
    
    // 2. Queue for Firebase sync
    await OfflineQueueService.enqueue(
      operation: 'create',
      collection: 'courses',
      documentId: course.id,
      data: course.toFirestore(),
    );
    
    // UI updates instantly (local data), sync happens silently
  }

  // Sync method called by BackgroundSyncService
  Future<void> syncWithFirebase() async {
    try {
      // Pull latest data from Firebase
      final remoteCourses = await _remote.getAllCourses();
      
      // Update local cache
      for (final course in remoteCourses) {
        await _local.saveCourse(course);
      }
    } catch (error) {
      // Firebase sync failure is non-fatal, app continues offline
      developer.log('Failed to sync courses: $error', name: 'Sync');
    }
  }
}
```

### Step 3: Update Provider

File: `lib/presentation/providers/providers.dart`

```dart
// OLD: Direct Firebase dependency
// final catalogRepositoryProvider = Provider<CatalogRepository>(
//   (ref) => FirebaseCatalogRepository(),
// );

// NEW: Hybrid repository (local-first)
final catalogRepositoryProvider = Provider<CatalogRepository>(
  (ref) => HybridCatalogRepository(
    local: LocalCatalogDataSource(),
    remote: FirebaseCatalogRepository(),
  ),
);
```

## Background Sync Service

Automatically started after app navigation:

```dart
// In splash_screen.dart or after successful navigation
Future<void> _startBackgroundSync() async {
  final syncService = BackgroundSyncService();
  await syncService.start();
  // Syncs every 30 seconds + on connectivity change
}
```

### Features

- Automatic retry on network failures (max 3 retries)
- Retry delay: 5 minutes between attempts
- Tracks pending, syncing, and failed items
- Non-blocking (never delays navigation)
- Detects network changes automatically

## Offline Queue

All writes are queued with status tracking:

```
┌─────────────────┐
│    PENDING      │  Not yet attempted
└────────┬────────┘
         │
    ┌────▼─────┐
    │  SYNCING  │  In progress to Firebase
    └────┬─────┘
         │
    ┌────┴──────┬──────┐
    │           │      │
┌──▼──┐    ┌───▼──┐   │
│DONE │    │FAILED│   │
└─────┘    └───┬──┘   │
               │      │
          ┌────▼──────▼───┐
          │  RETRY (5m)   │
          └───────────────┘
```

## Error Resilience

### Firebase Failures Don't Crash the App

```dart
try {
  await Firebase.initializeApp(...);
} catch (error) {
  // Log error, continue anyway
  // App works with local data only
}
```

### Missing Remote Data Returns Empty List

```dart
Future<List<Course>> getAllCourses() async {
  // Try local first
  final local = await _local.getAllCourses();
  if (local.isNotEmpty) return local;
  
  // If local empty, still return empty (don't fetch Firebase)
  return [];
}
```

### Unsynced Writes Are Safe

```dart
Future<void> saveAttendance(AttendanceRecord record) async {
  // 1. Saved locally (UI updates)
  await _local.saveAttendanceRecord(record);
  
  // 2. Queued for sync (silent background operation)
  await OfflineQueueService.enqueue(...);
  
  // UI never waits for Firebase
}
```

## Testing Offline-First

### Test 1: Fully Offline
1. Turn off internet
2. Cold start app
3. Verify all screens load from local cache
4. Create new record
5. Turn on internet
6. Verify background sync completes

### Test 2: Network Failure During Sync
1. Start app online
2. Create records (they sync)
3. Kill network mid-sync
4. Verify app continues working
5. Restore network
6. Verify failed items retry automatically

### Test 3: Stale Data
1. Start offline with cached data
2. Go online
3. Someone else updates data
4. Background sync pulls updates
5. Local cache refreshes

## Debugging

### Check Local Database Stats

```dart
final stats = LocalDatabaseService.getStats();
// {users: 10, courses: 50, records: 200, ...}
```

### Check Offline Queue

```dart
final queueStats = OfflineQueueService.getStats();
// {total: 5, pending: 2, syncing: 0, failed: 3, maxRetries: 3}
```

### Check Sync Service Status

```dart
final syncService = BackgroundSyncService();
print(syncService.isRunning);  // true/false
print(syncService.isSyncing);  // true/false
```

## Important Notes

⚠️ **Firebase as Optional**
- Firebase can fail to initialize, app continues offline
- Firebase syncs don't block navigation
- Network outages don't affect core functionality

⚠️ **Local DB is Always Used**
- Providers read from local DB first
- Local data is always available
- Never return empty/null when data is cached locally

⚠️ **Optimistic UI**
- Updates appear instantly in local DB
- Firebase sync happens silently in background
- Users see their changes immediately

⚠️ **Sync is Non-Blocking**
- Users don't wait for Firebase
- Navigation happens within 5 seconds guaranteed
- Offline queue handles unsynced writes

## Performance Targets

- **Startup to Navigation**: < 2 seconds (all from local DB)
- **Background Sync**: 30-second periodic + network-triggered
- **Failed Sync Retry**: 5 minutes between attempts (max 3 retries)
- **UI Update After Write**: Instant (local DB only)

## Migration Checklist

For each repository:

- [ ] Create LocalDataSource (read/write to Hive)
- [ ] Create HybridRepository (local-first logic)
- [ ] Update Provider to use HybridRepository
- [ ] Test offline read operations
- [ ] Test offline write + queue + sync
- [ ] Test network failure recovery
- [ ] Update docs for new repository

## References

- [Hive Documentation](https://docs.hivedb.dev/)
- [Flutter Offline-First Best Practices](https://flutter.dev/docs)
- [Riverpod Provider Patterns](https://riverpod.dev/)
