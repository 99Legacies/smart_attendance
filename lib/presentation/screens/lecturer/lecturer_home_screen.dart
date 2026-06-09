import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:smart_attendance/core/theme/app_theme.dart';
import 'package:smart_attendance/presentation/widgets/design_system/app_card.dart';

class LecturerHomeScreen extends StatelessWidget {
  const LecturerHomeScreen({
    super.key,
    required this.lecturerName,
    required this.onNewSession,
    required this.onSessions,
    required this.onAbsences,
    required this.onProposeCourse,
  });

  final String lecturerName;
  final VoidCallback onNewSession;
  final VoidCallback onSessions;
  final VoidCallback onAbsences;
  final VoidCallback onProposeCourse;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: AppTheme.screenPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              _StatMini(
                icon: Icons.play_circle_outline,
                label: 'Sessions',
                value: '—',
                color: AppTheme.primary,
              ),
              const SizedBox(width: 10),
              _StatMini(
                icon: Icons.people_outline,
                label: 'Students',
                value: '—',
                color: AppTheme.secondary,
              ),
              const SizedBox(width: 10),
              _StatMini(
                icon: Icons.inbox_outlined,
                label: 'Absences',
                value: '—',
                color: AppTheme.warning,
                onTap: onAbsences,
              ),
            ],
          ).animate().fadeIn(duration: 300.ms),
          const SizedBox(height: 16),
          AppCard(
            padding: const EdgeInsets.all(20),
            onTap: onNewSession,
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    gradient: AppTheme.successGradient,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.add, color: Colors.white, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Start new session',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Text(
                        'Generate QR and track attendance live',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withValues(alpha: 0.6),
                            ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Text('Quick actions', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          _ActionTile(
            icon: Icons.list_alt_rounded,
            title: 'Session history',
            subtitle: 'View past attendance sessions',
            color: AppTheme.primary,
            onTap: onSessions,
          ),
          _ActionTile(
            icon: Icons.inbox_outlined,
            title: 'Absence requests',
            subtitle: 'Review and respond to student requests',
            color: AppTheme.warning,
            onTap: onAbsences,
          ),
          _ActionTile(
            icon: Icons.post_add_outlined,
            title: 'Propose new course',
            subtitle: 'Submit a course for admin approval',
            color: const Color(0xFF7C3AED),
            onTap: onProposeCourse,
          ),
        ],
      ),
    );
  }
}

class _StatMini extends StatelessWidget {
  const _StatMini({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: AppCard(
        padding: const EdgeInsets.all(14),
        onTap: onTap,
        animate: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            Text(
              label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.6),
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: AppCard(
        onTap: onTap,
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.titleSmall),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.55),
                        ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.4),
            ),
          ],
        ),
      ),
    );
  }
}
