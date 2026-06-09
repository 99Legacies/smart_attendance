import 'dart:async';
import 'dart:developer' as developer;
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_attendance/presentation/providers/providers.dart';

final startupProvider = FutureProvider<StartupState>((ref) async {
  final logs = <String>[];
  const stepTimeout = Duration(seconds: 8);
  String? deviceId;
  String? localPath;
  String? lastError;

  void log(String message) {
    logs.add(message);
    developer.log(message, name: 'Startup');
  }

  Future<void> safeStep(String name, Future<void> Function() operation) async {
    try {
      await operation();
    } catch (error, stack) {
      final message = '$name failed: $error';
      lastError = message;
      logs.add(message);
      developer.log(message, name: 'Startup', error: error, stackTrace: stack);
    }
  }

  log('Startup: Local initialization started');

  // Firebase is already initialized in main.dart
  log('Startup: Firebase already initialized by main()');

  await safeStep('Local storage initialization', () async {
    final documents = await getApplicationDocumentsDirectory().timeout(
      stepTimeout,
    );
    await Directory(documents.path).create(recursive: true);
    localPath = documents.path;
    log('Startup: Local storage initialized at ${documents.path}');

    final prefs = await SharedPreferences.getInstance().timeout(stepTimeout);
    await prefs.setString('last_startup_path', documents.path);
    log('Startup: SharedPreferences initialized');
  });

  await safeStep('Device ID initialization', () async {
    deviceId = await ref
        .read(deviceServiceProvider)
        .getDeviceId()
        .timeout(stepTimeout);
    log('Startup: Device ID loaded: $deviceId');
  });

  log('Startup: All initialization completed');

  return StartupState(
    started: true,
    completed: true,
    deviceId: deviceId,
    localPath: localPath,
    lastError: lastError,
    logs: List.unmodifiable(logs),
  );
});

class StartupState {
  const StartupState({
    required this.started,
    required this.completed,
    required this.deviceId,
    required this.localPath,
    required this.lastError,
    required this.logs,
  });

  final bool started;
  final bool completed;
  final String? deviceId;
  final String? localPath;
  final String? lastError;
  final List<String> logs;
}
