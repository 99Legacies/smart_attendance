import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_attendance/core/widgets/secondary_screen_scaffold.dart';
import 'package:smart_attendance/presentation/providers/providers.dart';
import 'package:smart_attendance/presentation/widgets/notifications_panel.dart';

/// Full-screen notifications route — single scaffold and app bar.
class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key, required this.userId});

  final String userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SecondaryScreenScaffold(
      title: 'Notifications',
      actions: [
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
      ],
      body: NotificationsPanel(userId: userId),
    );
  }
}
