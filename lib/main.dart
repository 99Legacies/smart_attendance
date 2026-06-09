import 'dart:developer' as developer;

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_attendance/app.dart';
import 'package:smart_attendance/data/local/local_database_service.dart';
import 'package:smart_attendance/firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Initialize local database FIRST (before Firebase)
  try {
    developer.log('Initializing local database...', name: 'main');
    await LocalDatabaseService.initialize();
    developer.log('Local database initialized successfully', name: 'main');
  } catch (error, stack) {
    developer.log(
      'Failed to initialize local database: $error',
      name: 'main',
      error: error,
      stackTrace: stack,
    );
  }

  // 2. Initialize Firebase (non-blocking, will be retried)
  try {
    developer.log('Initializing Firebase...', name: 'main');
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    ).timeout(const Duration(seconds: 8));
    developer.log('Firebase initialized successfully', name: 'main');
  } catch (error, stack) {
    developer.log(
      'Firebase initialization failed: $error',
      name: 'main',
      error: error,
      stackTrace: stack,
    );
    // Continue anyway - app will work offline with local data
  }

  // 3. Run app with ProviderScope
  runApp(const ProviderScope(child: AttendProApp()));
}
