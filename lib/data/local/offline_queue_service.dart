import 'dart:convert';
import 'dart:developer' as developer;

import 'package:uuid/uuid.dart';

import 'package:smart_attendance/data/local/hive_models.dart';
import 'package:smart_attendance/data/local/local_database_service.dart';

/// Manages offline queue for unsynced writes
/// Stores all create/update/delete operations that need to sync to Firebase
class OfflineQueueService {
  static const _uuid = Uuid();
  static const int _maxRetries = 3;
  static const Duration _retryDelay = Duration(minutes: 5);

  /// Add a write operation to the offline queue
  static Future<void> enqueue({
    required String operation, // 'create', 'update', 'delete'
    required String collection,
    required String documentId,
    required Map<String, dynamic> data,
  }) async {
    try {
      final item = HiveOfflineQueueItem(
        id: _uuid.v4(),
        operation: operation,
        collection: collection,
        documentId: documentId,
        data: jsonEncode(data),
        createdAt: DateTime.now(),
        status: 'pending',
      );

      await LocalDatabaseService.offlineQueueBox.add(item);

      developer.log(
        'Queued offline operation: $operation in $collection/$documentId',
        name: 'OfflineQueue',
      );
    } catch (error, stack) {
      developer.log(
        'Failed to enqueue operation: $error',
        name: 'OfflineQueue',
        error: error,
        stackTrace: stack,
      );
      rethrow;
    }
  }

  /// Get all pending queue items
  static List<HiveOfflineQueueItem> getPendingItems() {
    return LocalDatabaseService.offlineQueueBox.values
        .where((item) => item.status == 'pending')
        .toList();
  }

  /// Get items ready to retry (waited long enough)
  static List<HiveOfflineQueueItem> getRetryableItems() {
    final now = DateTime.now();
    return LocalDatabaseService.offlineQueueBox.values.where((item) {
      if (item.status != 'failed') return false;
      final retryCount = item.retryCount ?? 0;
      if (retryCount >= _maxRetries) return false;

      // Exponential backoff: base 60s * 2^retryCount (capped)
      final capped = retryCount > 6 ? 6 : retryCount;
      final backoffSeconds = 60 * (1 << capped);
      final last = item.lastRetryAt ?? item.createdAt;
      return now.difference(last).inSeconds >= backoffSeconds;
    }).toList();
  }

  /// Mark item as syncing
  static Future<void> markSyncing(HiveOfflineQueueItem item) async {
    try {
      final index = _findItemIndex(item);
      if (index >= 0) {
        final updated = HiveOfflineQueueItem(
          id: item.id,
          operation: item.operation,
          collection: item.collection,
          documentId: item.documentId,
          data: item.data,
          createdAt: item.createdAt,
          status: 'syncing',
          retryCount: item.retryCount,
          lastRetryAt: item.lastRetryAt,
          error: item.error,
        );
        await LocalDatabaseService.offlineQueueBox.putAt(index, updated);
        developer.log(
          'Marked item as syncing: ${item.id}',
          name: 'OfflineQueue',
        );
      }
    } catch (error, stack) {
      developer.log(
        'Failed to mark item as syncing: $error',
        name: 'OfflineQueue',
        error: error,
        stackTrace: stack,
      );
    }
  }

  /// Mark item as synced (remove it)
  static Future<void> markSynced(HiveOfflineQueueItem item) async {
    try {
      final index = _findItemIndex(item);
      if (index >= 0) {
        await LocalDatabaseService.offlineQueueBox.deleteAt(index);
        developer.log('Removed synced item: ${item.id}', name: 'OfflineQueue');
      }
    } catch (error, stack) {
      developer.log(
        'Failed to mark item as synced: $error',
        name: 'OfflineQueue',
        error: error,
        stackTrace: stack,
      );
    }
  }

  /// Mark item as failed with error and retry count
  static Future<void> markFailed(
    HiveOfflineQueueItem item,
    String? error,
  ) async {
    try {
      final index = _findItemIndex(item);
      if (index >= 0) {
        final retryCount = (item.retryCount ?? 0) + 1;
        final updated = HiveOfflineQueueItem(
          id: item.id,
          operation: item.operation,
          collection: item.collection,
          documentId: item.documentId,
          data: item.data,
          createdAt: item.createdAt,
          status: 'failed',
          retryCount: retryCount,
          lastRetryAt: DateTime.now(),
          error: error,
        );
        await LocalDatabaseService.offlineQueueBox.putAt(index, updated);
        developer.log(
          'Marked item as failed (retry $retryCount): ${item.id}\nError: $error',
          name: 'OfflineQueue',
        );
      }
    } catch (error, stack) {
      developer.log(
        'Failed to mark item as failed: $error',
        name: 'OfflineQueue',
        error: error,
        stackTrace: stack,
      );
    }
  }

  /// Clear all processed items (should only be called after sync completion)
  static Future<void> clear() async {
    await LocalDatabaseService.offlineQueueBox.clear();
    developer.log('Offline queue cleared', name: 'OfflineQueue');
  }

  /// Get queue stats for debugging
  static Map<String, dynamic> getStats() {
    final box = LocalDatabaseService.offlineQueueBox;
    final items = box.values.toList();
    return {
      'total': items.length,
      'pending': items.where((i) => i.status == 'pending').length,
      'syncing': items.where((i) => i.status == 'syncing').length,
      'failed': items.where((i) => i.status == 'failed').length,
      'maxRetries': _maxRetries,
      'retryDelay': '${_retryDelay.inMinutes} minutes',
    };
  }

  static int _findItemIndex(HiveOfflineQueueItem item) {
    final box = LocalDatabaseService.offlineQueueBox;
    for (int i = 0; i < box.length; i++) {
      if (box.getAt(i)?.id == item.id) {
        return i;
      }
    }
    return -1;
  }
}
