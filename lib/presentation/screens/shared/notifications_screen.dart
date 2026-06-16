import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_attendance/core/constants/app_constants.dart';
import 'package:smart_attendance/core/widgets/secondary_screen_scaffold.dart';
import 'package:smart_attendance/presentation/providers/providers.dart';
import 'package:smart_attendance/presentation/widgets/notifications_panel.dart';

/// Full-screen notifications route — single scaffold and app bar.
class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key, required this.userId});

  final String userId;

  Future<void> _clearAllNotifications(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear all notifications'),
        content: const Text(
          'This will permanently delete all your notifications. This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Clear all'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    // Delete all notifications for this user in batches of 500
    final firestore = FirebaseFirestore.instance;
    QuerySnapshot snap;
    do {
      snap = await firestore
          .collection(AppConstants.notificationsCollection)
          .where('recipientId', isEqualTo: userId)
          .limit(500)
          .get();

      if (snap.docs.isEmpty) break;

      final batch = firestore.batch();
      for (final doc in snap.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    } while (snap.docs.length == 500);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SecondaryScreenScaffold(
      title: 'Notifications',
      actions: [
        // Mark all read
        Builder(
          builder: (context) {
            final fg = Theme.of(context).appBarTheme.foregroundColor;
            return TextButton(
              onPressed: () => ref
                  .read(notificationRepositoryProvider)
                  .markAllAsRead(userId),
              style: TextButton.styleFrom(foregroundColor: fg),
              child: const Text('Mark all read'),
            );
          },
        ),
        // Clear all notifications
        Builder(
          builder: (context) {
            return IconButton(
              icon: const Icon(Icons.delete_sweep_rounded),
              tooltip: 'Clear all notifications',
              onPressed: () => _clearAllNotifications(context),
            );
          },
        ),
      ],
      body: NotificationsPanel(userId: userId),
    );
  }
}
