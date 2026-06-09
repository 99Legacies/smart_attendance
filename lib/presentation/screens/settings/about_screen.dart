import 'package:flutter/material.dart';
import 'package:smart_attendance/core/constants/app_info.dart';
import 'package:smart_attendance/core/theme/app_theme.dart';
import 'package:smart_attendance/core/widgets/app_card.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: AppTheme.screenPadding,
      children: [
        AppCard(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Icon(
                  Icons.qr_code_scanner,
                  size: 72,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(height: 16),
                Text(
                  AppInfo.name,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 4),
                Text('Version ${AppInfo.version} (${AppInfo.build})'),
                const SizedBox(height: 16),
                Text(
                  AppInfo.description,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 16),
                Text(
                  AppInfo.copyright,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        AppCard(
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.security_outlined),
                title: const Text('Secure attendance'),
                subtitle: const Text(
                  'QR codes, geolocation, and device binding reduce fraud.',
                ),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.groups_outlined),
                title: const Text('Role-based access'),
                subtitle: const Text(
                  'Separate experiences for students, lecturers, and admins.',
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
