import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_attendance/domain/entities/app_notification.dart';
import 'package:smart_attendance/domain/repositories/notification_repository.dart';
import 'package:smart_attendance/presentation/providers/providers.dart';
import 'package:smart_attendance/presentation/widgets/notifications_panel.dart';

import '../helpers/fake_repositories.dart';

Widget _wrap(Widget child, NotificationRepository repo) {
  return ProviderScope(
    overrides: [
      notificationRepositoryProvider.overrideWithValue(repo),
    ],
    child: MaterialApp(home: Scaffold(body: child)),
  );
}

AppNotification _notification({
  String id = 'n1',
  bool read = false,
}) => AppNotification(
  id: id,
  recipientId: 'user1',
  type: NotificationType.missedClass,
  title: 'Missed class',
  body: 'You were absent for CS101.',
  createdAt: DateTime(2025, 6, 15),
  read: read,
);

void main() {
  group('NotificationsPanel — states', () {
    testWidgets('shows loading spinner while stream is pending', (tester) async {
      final repo = FakeNotificationRepository(
        notificationsStream: const Stream.empty(),
      );

      await tester.pumpWidget(_wrap(
        const NotificationsPanel(userId: 'user1'),
        repo,
      ));

      // First frame: AsyncValue is loading
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows empty state when user has no notifications', (tester) async {
      final repo = FakeNotificationRepository(
        notificationsStream: Stream.value([]),
      );

      await tester.pumpWidget(_wrap(
        const NotificationsPanel(userId: 'user1'),
        repo,
      ));
      await tester.pump(); // allow stream to emit

      expect(find.text('No notifications yet'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('shows list of notifications when data is available', (tester) async {
      final items = [
        _notification(id: 'n1'),
        _notification(id: 'n2', read: true),
      ];
      final repo = FakeNotificationRepository(
        notificationsStream: Stream.value(items),
      );

      await tester.pumpWidget(_wrap(
        const NotificationsPanel(userId: 'user1'),
        repo,
      ));
      await tester.pump();

      expect(find.text('Missed class'), findsNWidgets(2));
      expect(find.text('You were absent for CS101.'), findsNWidgets(2));
    });

    testWidgets('shows friendly error when stream emits an error', (tester) async {
      final repo = FakeNotificationRepository(
        notificationsStream: Stream.error(
          Exception('permission-denied'),
        ),
      );

      await tester.pumpWidget(_wrap(
        const NotificationsPanel(userId: 'user1'),
        repo,
      ));
      await tester.pump();

      expect(find.text('Could not load notifications'), findsOneWidget);
      // Must NOT show raw exception text
      expect(find.textContaining('Exception'), findsNothing);
      expect(find.textContaining('permission-denied'), findsNothing);
    });

    testWidgets('unread notification title is bold', (tester) async {
      final repo = FakeNotificationRepository(
        notificationsStream: Stream.value([_notification(read: false)]),
      );

      await tester.pumpWidget(_wrap(
        const NotificationsPanel(userId: 'user1'),
        repo,
      ));
      await tester.pump();

      final richText = tester.widget<Text>(
        find.text('Missed class'),
      );
      expect(richText.style?.fontWeight, FontWeight.bold);
    });

    testWidgets('read notification title is normal weight', (tester) async {
      final repo = FakeNotificationRepository(
        notificationsStream: Stream.value([_notification(read: true)]),
      );

      await tester.pumpWidget(_wrap(
        const NotificationsPanel(userId: 'user1'),
        repo,
      ));
      await tester.pump();

      final richText = tester.widget<Text>(
        find.text('Missed class'),
      );
      expect(richText.style?.fontWeight, FontWeight.normal);
    });
  });
}
