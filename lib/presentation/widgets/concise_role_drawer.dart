import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:smart_attendance/core/navigation/app_navigation.dart';
import 'package:smart_attendance/domain/entities/user_role.dart';
import 'package:smart_attendance/presentation/providers/providers.dart';
import 'package:smart_attendance/presentation/screens/settings/about_screen.dart';
import 'package:smart_attendance/presentation/screens/settings/notification_settings_screen.dart';
import 'package:smart_attendance/presentation/screens/settings/preferences_screen.dart';
import 'package:smart_attendance/presentation/screens/shared/notifications_screen.dart';
import 'package:smart_attendance/presentation/widgets/report_export_sheet.dart';

/// Compact side drawer — secondary navigation only (main tabs stay on bottom bar).
class ConciseRoleDrawer extends ConsumerWidget {
  const ConciseRoleDrawer({
    super.key,
    required this.role,
    required this.userName,
    required this.userEmail,
    required this.userId,
    required this.menuItems,
    this.showReportExport = false,
  });

  final UserRole role;
  final String userName;
  final String userEmail;
  final String userId;
  final List<DrawerMenuItem> menuItems;
  final bool showReportExport;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            UserAccountsDrawerHeader(
              margin: EdgeInsets.zero,
              accountName: Text(
                userName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              accountEmail: Text(
                userEmail,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              currentAccountPicture: CircleAvatar(
                child: Text(
                  userName.isNotEmpty ? userName[0].toUpperCase() : '?',
                ),
              ),
            ),
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  ...menuItems.map(
                    (item) => ListTile(
                      dense: true,
                      leading: Icon(item.icon, size: 22),
                      title: Text(item.label),
                      onTap: () {
                        Navigator.pop(context);
                        item.onTap(context);
                      },
                    ),
                  ),
                  if (showReportExport) ...[
                    const Divider(height: 1),
                    ListTile(
                      dense: true,
                      leading: const Icon(Icons.download_outlined, size: 22),
                      title: const Text('Export report'),
                      onTap: () {
                        Navigator.pop(context);
                        showReportExportSheet(
                          context,
                          role: role,
                          userId: userId,
                        );
                      },
                    ),
                  ],
                  const Divider(height: 1),
                  ListTile(
                    dense: true,
                    leading: const Icon(Icons.tune_outlined, size: 22),
                    title: const Text('Preferences'),
                    onTap: () {
                      Navigator.pop(context);
                      AppNavigation.pushSecondary(
                        context,
                        title: 'Preferences',
                        body: const PreferencesScreen(),
                      );
                    },
                  ),
                  ListTile(
                    dense: true,
                    leading: const Icon(Icons.notifications_outlined, size: 22),
                    title: const Text('Notifications'),
                    onTap: () {
                      Navigator.pop(context);
                      AppNavigation.pushRoute(
                        context,
                        NotificationsScreen(userId: userId),
                      );
                    },
                  ),
                  ListTile(
                    dense: true,
                    leading: const Icon(Icons.settings_outlined, size: 22),
                    title: const Text('Alert settings'),
                    onTap: () {
                      Navigator.pop(context);
                      AppNavigation.pushSecondary(
                        context,
                        title: 'Alert settings',
                        body: const NotificationSettingsScreen(),
                      );
                    },
                  ),
                  ListTile(
                    dense: true,
                    leading: const Icon(Icons.info_outline, size: 22),
                    title: const Text('About'),
                    onTap: () {
                      Navigator.pop(context);
                      AppNavigation.pushSecondary(
                        context,
                        title: 'About',
                        body: const AboutScreen(),
                      );
                    },
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            ListTile(
              dense: true,
              leading: const Icon(Icons.logout, size: 22, color: Colors.red),
              title: const Text(
                'Sign out',
                style: TextStyle(color: Colors.red),
              ),
              onTap: () async {
                Navigator.pop(context);
                await ref.read(authRepositoryProvider).signOut();
                if (context.mounted) context.go('/login');
              },
            ),
          ],
        ),
      ),
    );
  }
}

class DrawerMenuItem {
  const DrawerMenuItem({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final void Function(BuildContext context) onTap;
}
