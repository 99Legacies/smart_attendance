import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:smart_attendance/data/local/hive_models.dart';
import 'package:smart_attendance/data/local/offline_queue_service.dart';

/// Background sync service
/// Handles syncing offline queue with Firebase
/// Runs only after app has loaded and navigated
class BackgroundSyncService {
  static BackgroundSyncService? _instance;
  static final _connectivity = Connectivity();
  late StreamSubscription<List<ConnectivityResult>> _connectivitySubscription;
  Timer? _periodicSyncTimer;
  bool _isRunning = false;
  bool _isSyncing = false;

  BackgroundSyncService._private();

  factory BackgroundSyncService() {
    _instance ??= BackgroundSyncService._private();
    return _instance!;
  }

  /// Start the background sync service
  Future<void> start() async {
    if (_isRunning) {
      developer.log('BackgroundSyncService already running', name: 'Sync');
      return;
    }

    try {
      developer.log('Starting BackgroundSyncService...', name: 'Sync');

      // Listen to connectivity changes
      _connectivitySubscription = _connectivity.onConnectivityChanged.listen((
        result,
      ) async {
        final hasInternet = result.any(
          (status) => status != ConnectivityResult.none,
        );
        if (hasInternet) {
          developer.log(
            'Internet connection restored, syncing...',
            name: 'Sync',
          );
          await _performSync();
        } else {
          developer.log(
            'Internet connection lost, queuing offline',
            name: 'Sync',
          );
        }
      });

      // Periodic sync every 30 seconds
      _periodicSyncTimer = Timer.periodic(const Duration(seconds: 30), (
        _,
      ) async {
        Future(() => _performSync());
      });

      // Initial sync attempt
      await Future.delayed(const Duration(seconds: 2));
      Future(() => _performSync());

      _isRunning = true;
      developer.log('BackgroundSyncService started', name: 'Sync');
    } catch (error, stack) {
      developer.log(
        'Failed to start BackgroundSyncService: $error',
        name: 'Sync',
        error: error,
        stackTrace: stack,
      );
    }
  }

  /// Stop the background sync service
  Future<void> stop() async {
    developer.log('Stopping BackgroundSyncService...', name: 'Sync');
    _isRunning = false;
    await _connectivitySubscription.cancel();
    _periodicSyncTimer?.cancel();
    developer.log('BackgroundSyncService stopped', name: 'Sync');
  }

  /// Perform sync operation
  Future<void> _performSync() async {
    if (_isSyncing) {
      developer.log('Sync already in progress, skipping', name: 'Sync');
      return;
    }

    _isSyncing = true;
    try {
      // Check connectivity
      final connectivityResult = await _connectivity.checkConnectivity();
      if (connectivityResult.contains(ConnectivityResult.none)) {
        developer.log('No internet connection, skipping sync', name: 'Sync');
        _isSyncing = false;
        return;
      }

      final pendingItems = OfflineQueueService.getPendingItems();
      final retryable = OfflineQueueService.getRetryableItems();
      final itemsToProcess = [...pendingItems, ...retryable];

      if (itemsToProcess.isEmpty) {
        developer.log('No pending items to sync', name: 'Sync');
        _isSyncing = false;
        return;
      }

      developer.log(
        'Starting sync of ${itemsToProcess.length} items',
        name: 'Sync',
      );

      for (final item in itemsToProcess) {
        developer.log(
          'Processing queue item ${item.id} (${item.operation})',
          name: 'Sync',
        );
        try {
          await _syncItem(item);
          developer.log('Sync success for item ${item.id}', name: 'Sync');
        } catch (e, st) {
          developer.log(
            'Sync failed for item ${item.id}: $e',
            name: 'Sync',
            error: e,
            stackTrace: st,
          );
        }
      }

      developer.log('Sync completed successfully', name: 'Sync');
    } catch (error, stack) {
      developer.log(
        'Sync failed: $error',
        name: 'Sync',
        error: error,
        stackTrace: stack,
      );
    } finally {
      _isSyncing = false;
    }
  }

  /// Sync a single offline queue item
  Future<void> _syncItem(HiveOfflineQueueItem item) async {
    try {
      await OfflineQueueService.markSyncing(item);

      final data = jsonDecode(item.data) as Map<String, dynamic>;
      final firestore = FirebaseFirestore.instance;
      final ref = firestore.collection(item.collection).doc(item.documentId);

      switch (item.operation.toLowerCase()) {
        case 'create':
          await ref.set(data);
          break;
        case 'update':
          await ref.update(data);
          break;
        case 'delete':
          await ref.delete();
          break;
        default:
          throw ArgumentError('Unknown operation: ${item.operation}');
      }

      await OfflineQueueService.markSynced(item);
      developer.log(
        'Synced: ${item.operation} ${item.collection}/${item.documentId}',
        name: 'Sync',
      );
    } catch (error, stack) {
      await OfflineQueueService.markFailed(
        item,
        'Sync failed: ${error.toString()}',
      );
      developer.log(
        'Failed to sync item ${item.id}: $error',
        name: 'Sync',
        error: error,
        stackTrace: stack,
      );
    }
  }

  bool get isRunning => _isRunning;
  bool get isSyncing => _isSyncing;
}
