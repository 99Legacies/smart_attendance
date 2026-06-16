import 'dart:developer' as developer;

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_attendance/app.dart';
import 'package:smart_attendance/data/local/local_database_service.dart';
import 'package:smart_attendance/firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

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

  var firebaseReady = false;
  try {
    developer.log('Initializing Firebase...', name: 'main');

    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }

    firebaseReady = true;
    developer.log('Firebase initialized successfully', name: 'main');
  } catch (error, stack) {
    developer.log(
      'Firebase initialization failed: $error',
      name: 'main',
      error: error,
      stackTrace: stack,
    );
  }

  if (!firebaseReady) {
    developer.log(
      'Starting in offline-first mode with Firebase unavailable',
      name: 'main',
    );
  }

  runApp(const ProviderScope(child: AttendProApp()));
}
