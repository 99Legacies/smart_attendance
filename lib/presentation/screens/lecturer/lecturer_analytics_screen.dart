import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_attendance/core/constants/app_constants.dart';
import 'package:smart_attendance/core/theme/app_theme.dart';
import 'package:smart_attendance/core/widgets/app_card.dart';
import 'package:smart_attendance/domain/entities/user_role.dart';
import 'package:smart_attendance/presentation/widgets/report_export_sheet.dart';

class LecturerAnalyticsScreen extends ConsumerWidget {
  const LecturerAnalyticsScreen({super.key, required this.lecturerId});

  final String lecturerId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(_lecturerStatsProvider(lecturerId));

    return SingleChildScrollView(
      padding: AppTheme.screenPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () => showReportExportSheet(
                context,
                role: UserRole.lecturer,
                userId: lecturerId,
              ),
              icon: const Icon(Icons.download_outlined),
              label: const Text('Export report'),
            ),
          ),
          statsAsync.when(
            data: (stats) => GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: MediaQuery.sizeOf(context).width > 500 ? 2 : 1,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 2.2,
              children: [
                _StatCard('Sessions', stats.sessions, Icons.event),
                _StatCard('Records', stats.records, Icons.fact_check),
                _StatCard('Present', stats.present, Icons.check_circle_outline),
                _StatCard('Late', stats.late, Icons.schedule),
                _StatCard('Absent', stats.absent, Icons.person_off_outlined),
              ],
            ),
            loading: () => const Padding(
              padding: EdgeInsets.all(32),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (e, _) => Padding(
              padding: const EdgeInsets.all(16),
              child: Center(child: Text('$e')),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard(this.label, this.value, this.icon);

  final String label;
  final int value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Row(
        children: [
          Icon(icon, size: 36, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('$value', style: Theme.of(context).textTheme.headlineSmall),
              Text(label),
            ],
          ),
        ],
      ),
    );
  }
}

class _LecturerStats {
  const _LecturerStats({
    required this.sessions,
    required this.records,
    required this.present,
    required this.late,
    required this.absent,
  });

  final int sessions;
  final int records;
  final int present;
  final int late;
  final int absent;
}

final _lecturerStatsProvider = FutureProvider.family<_LecturerStats, String>((
  ref,
  lecturerId,
) async {
  final db = FirebaseFirestore.instance;
  final sessionsSnap = await db
      .collection(AppConstants.sessionsCollection)
      .where('lecturerId', isEqualTo: lecturerId)
      .get();
  final sessionIds = sessionsSnap.docs.map((d) => d.id).toSet();

  final recordsSnap = await db
      .collection(AppConstants.recordsCollection)
      .limit(1000)
      .get();

  var present = 0, late = 0, absent = 0, total = 0;
  for (final doc in recordsSnap.docs) {
    final sid = doc.data()['sessionId'] as String? ?? '';
    if (!sessionIds.contains(sid)) continue;
    total++;
    final status = doc.data()['status'] as String? ?? '';
    switch (status) {
      case 'present':
        present++;
      case 'late':
        late++;
      case 'absent':
        absent++;
    }
  }

  return _LecturerStats(
    sessions: sessionsSnap.docs.length,
    records: total,
    present: present,
    late: late,
    absent: absent,
  );
});
