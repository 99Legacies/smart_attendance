import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:smart_attendance/core/theme/app_theme.dart';
import 'package:smart_attendance/core/widgets/app_card.dart';
import 'package:smart_attendance/domain/entities/app_notification.dart';
import 'package:smart_attendance/presentation/providers/providers.dart';

class NotificationsPanel extends ConsumerWidget {
  const NotificationsPanel({super.key, required this.userId});

  final String userId;

  IconData _iconFor(NotificationType type) {
    switch (type) {
      case NotificationType.absenceSubmitted:
        return Icons.event_busy;
      case NotificationType.absenceReviewed:
        return Icons.fact_check_outlined;
      case NotificationType.missedClass:
        return Icons.warning_amber_outlined;
      case NotificationType.courseProposalApproved:
        return Icons.check_circle_outline;
      case NotificationType.courseProposalRejected:
        return Icons.cancel_outlined;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationsAsync = ref.watch(notificationsProvider(userId));

    return notificationsAsync.when(
      data: (items) {
        if (items.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.notifications_none,
                  size: 64,
                  color: Theme.of(context).colorScheme.outline,
                ),
                const SizedBox(height: 16),
                Text(
                  'No notifications yet',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
          );
        }

        return ListView.separated(
          padding: AppTheme.screenPadding,
          itemCount: items.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (_, i) {
            final n = items[i];
            return AppCard(
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: n.read
                      ? Theme.of(context).colorScheme.surfaceContainerHighest
                      : Theme.of(context).colorScheme.primaryContainer,
                  child: Icon(_iconFor(n.type)),
                ),
                title: Text(
                  n.title,
                  style: TextStyle(
                    fontWeight: n.read ? FontWeight.normal : FontWeight.bold,
                  ),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 4),
                    Text(n.body),
                    const SizedBox(height: 4),
                    Text(
                      DateFormat.yMMMd().add_jm().format(n.createdAt),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
                isThreeLine: true,
                onTap: () async {
                  if (!n.read) {
                    await ref
                        .read(notificationRepositoryProvider)
                        .markAsRead(n.id);
                  }
                },
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
    );
  }
}

class NotificationBadgeIcon extends ConsumerWidget {
  const NotificationBadgeIcon({
    super.key,
    required this.userId,
    required this.onTap,
  });

  final String userId;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final countAsync = ref.watch(unreadNotificationCountProvider(userId));

    return countAsync.when(
      data: (count) => Badge(
        isLabelVisible: count > 0,
        label: Text(count > 9 ? '9+' : '$count'),
        child: IconButton(
          icon: const Icon(Icons.notifications_outlined),
          onPressed: onTap,
        ),
      ),
      loading: () => IconButton(
        icon: const Icon(Icons.notifications_outlined),
        onPressed: onTap,
      ),
      error: (_, __) => IconButton(
        icon: const Icon(Icons.notifications_outlined),
        onPressed: onTap,
      ),
    );
  }
}
